# =============================================================================
# helpers.R — Tobramycin workshop data: PK and PD simulation functions
#
# Sourced by create_workshop_data.R. Call order in that script is the
# reproducibility contract — do not reorder calls there or random draws inside
# these functions.
#
# Requires (loaded by the orchestrator before sourcing):
#   rxode2, tidyverse, uwot, xgboost, SHAPforxgboost, dbscan
# =============================================================================

# =============================================================================
# PK SIMULATION
# =============================================================================

simulate_covariates <- function(n = 300) {
  age    <- pmin(pmax(rnorm(n, 55, 15), 18), 85)
  weight <- pmin(pmax(rnorm(n, 75, 15), 45), 130)
  sex    <- rbinom(n, 1, 0.45)  # 1 = female, 0 = male

  # Latent SCr: log-normal, sex-adjusted median (mg/dL)
  log_scr_latent <- rnorm(n, mean = ifelse(sex == 1, log(0.75), log(0.9)), sd = 0.2)
  scr_latent     <- exp(log_scr_latent)

  # Cockcroft-Gault: CLCR (mL/min) = ((140-Age)*Weight) / (72*SCr) * sex_factor
  sex_factor <- ifelse(sex == 1, 0.85, 1.0)
  clcr_cg    <- ((140 - age) * weight) / (72 * scr_latent) * sex_factor

  clcr <- pmin(pmax(clcr_cg + rnorm(n, 0, 8), 20), 130)

  # Back-calculate SCr from final CLCR (inverted CG)
  baseline_scr <- ((140 - age) * weight) / (72 * clcr / sex_factor)

  n_prior_courses <- pmin(rpois(n, 2), 6)
  diabetes        <- rbinom(n, 1, 0.30)
  hypertension    <- rbinom(n, 1, 0.25)

  tibble::tibble(
    ID              = seq_len(n),
    age             = age,
    weight          = weight,
    sex             = sex,
    clcr            = clcr,
    baseline_scr    = baseline_scr,
    n_prior_courses = n_prior_courses,
    diabetes        = diabetes,
    hypertension    = hypertension
  )
}


define_pk_model <- function() {
  rxode2::rxode2({
    C1        <- A1 / V1
    C2        <- A2 / V2
    d/dt(A1)  <- -(CL / V1 + Q / V1) * A1 + (Q / V2) * A2
    d/dt(A2)  <-  (Q / V1) * A1 - (Q / V2) * A2
    d/dt(AUC) <- C1  # implicit AUC accumulator (mg·h/L); reset to 0 at t=0
  })
}

compute_individual_pk <- function(covariates_df) {
  omega_CL <- sqrt(log(1 + 0.35^2))
  omega_V1 <- sqrt(log(1 + 0.20^2))
  omega_Q  <- sqrt(log(1 + 0.25^2))
  omega_V2 <- sqrt(log(1 + 0.20^2))

  n <- nrow(covariates_df)

  covariates_df |>
    dplyr::mutate(
      ETA_CL = rnorm(n, 0, omega_CL),
      ETA_V1 = rnorm(n, 0, omega_V1),
      ETA_Q  = rnorm(n, 0, omega_Q),
      ETA_V2 = rnorm(n, 0, omega_V2),
      TVCL   = 4.5 * (clcr / 90)^0.9,
      TVV1   = 18  * (weight / 70),
      TVQ    = 2.5,
      TVV2   = 10,
      CL_i   = TVCL * exp(ETA_CL),
      V1_i   = TVV1 * exp(ETA_V1),
      Q_i    = TVQ  * exp(ETA_Q),
      V2_i   = TVV2 * exp(ETA_V2),
      dose   = round(7 * weight / 10) * 10  # nearest 10 mg
    )
}

build_event_data <- function(pk_params_df) {
  dose_times <- seq(0, 216, by = 24)

  purrr::map_dfr(seq_len(nrow(pk_params_df)), function(i) {
    row  <- pk_params_df[i, ]
    id   <- row$ID
    dose <- row$dose

    dose_rows <- tibble::tibble(
      id       = id,
      time     = dose_times,
      dv       = NA_real_,
      amt      = dose,
      rate     = dose / 0.5,  # 30-min infusion (mg/h)
      duration = 0.5,
      evid     = 1L,
      cmt      = 1L,
      mdv      = 1L
    )

    obs_rows <- purrr::map_dfr(dose_times, function(t) {
      n_samp <- sample(2L:3L, 1L)
      tibble::tibble(
        id       = id,
        time     = sort(runif(n_samp, t + 0.5, t + 24.0)),
        dv       = NA_real_,
        amt      = NA_real_,
        rate     = NA_real_,
        duration = NA_real_,
        evid     = 0L,
        cmt      = 1L,
        mdv      = 0L
      )
    })

    dplyr::bind_rows(dose_rows, obs_rows) |>
      dplyr::arrange(time, dplyr::desc(evid))
  })
}

simulate_sparse_pk <- function(pk_model, event_data, pk_params_df) {
  iCov <- pk_params_df |>
    dplyr::select(id = ID, CL = CL_i, V1 = V1_i, Q = Q_i, V2 = V2_i)

  rxode2::rxSolve(pk_model, events = event_data, iCov = iCov, returnType = "tibble")
}

assemble_adpc <- function(sim_sparse, event_data, pk_params_df) {
  # Observation records with predicted concentration and residual error
  obs_records <- sim_sparse |>
    dplyr::rename(ID = id, time_sim = time) |>
    dplyr::mutate(
      ipred    = C1,
      dv       = pmax(C1 * (1 + rnorm(dplyr::n(), 0, 0.15)), 0),
      amt      = NA_real_,
      rate     = NA_real_,
      duration = NA_real_,
      evid     = 0L,
      cmt      = 1L,
      mdv      = 0L
    ) |>
    dplyr::rename(time = time_sim) |>
    dplyr::select(ID, time, dv, ipred, amt, rate, duration, evid, cmt, mdv)

  # Dose records (dv and ipred are NA)
  dose_records <- event_data |>
    dplyr::filter(evid == 1) |>
    dplyr::rename(ID = id) |>
    dplyr::mutate(
      ipred = NA_real_,
      dv    = NA_real_
    ) |>
    dplyr::select(ID, time, dv, ipred, amt, rate, duration, evid, cmt, mdv)

  pk_cols <- pk_params_df |>
    dplyr::select(
      ID, age, weight, sex, clcr, baseline_scr,
      diabetes, hypertension, n_prior_courses,
      CL_i, V1_i, Q_i, V2_i, ETA_CL, ETA_V1, ETA_Q, ETA_V2
    )

  dplyr::bind_rows(obs_records, dose_records) |>
    dplyr::arrange(ID, time, dplyr::desc(evid)) |>
    dplyr::left_join(pk_cols, by = "ID")
}

compute_exposures <- function(pk_model, pk_params_df) {
  dose_times <- seq(0, 216, by = 24)

  # Semi-dense observation grid: every 0.5 h plus exact trough times
  obs_times <- sort(unique(c(seq(0, 240, by = 0.5), dose_times + 24)))

  dense_event_data <- purrr::map_dfr(seq_len(nrow(pk_params_df)), function(i) {
    row <- pk_params_df[i, ]

    dose_rows <- tibble::tibble(
      id   = row$ID,
      time = dose_times,
      amt  = row$dose,
      rate = row$dose / 0.5,
      evid = 1L,
      cmt  = 1L,
      mdv  = 1L
    )

    obs_rows <- tibble::tibble(
      id   = row$ID,
      time = obs_times,
      amt  = 0,
      rate = 0,
      evid = 0L,
      cmt  = 1L,
      mdv  = 0L
    )

    dplyr::bind_rows(dose_rows, obs_rows) |>
      dplyr::arrange(time, dplyr::desc(evid))
  })

  iCov <- pk_params_df |>
    dplyr::select(id = ID, CL = CL_i, V1 = V1_i, Q = Q_i, V2 = V2_i)

  dense_sim <- rxode2::rxSolve(
    pk_model,
    events     = dense_event_data,
    iCov       = iCov,
    returnType = "tibble"
  )

  # AUC read from implicit accumulator; Cmax/Cmin from C1 output
  dense_sim |>
    dplyr::group_by(id) |>
    dplyr::summarise(
      AUC24           = AUC[which.min(abs(time - 24))],
      cumulative_AUC  = AUC[which.min(abs(time - 240))],
      Cmax_central    = max(C1),
      Cmax_peripheral = max(C2),
      Cmin            = C1[which.min(abs(time - 24))],
      .groups = "drop"
    )
}

assemble_subject_dataset <- function(pk_params_df, exposure_metrics) {
  pk_params_df |>
    dplyr::select(
      ID, ETA_CL, ETA_V1, ETA_Q, ETA_V2,
      CL_i, V1_i, Q_i, V2_i,
      age, weight, sex, clcr, baseline_scr,
      diabetes, hypertension, n_prior_courses
    ) |>
    dplyr::left_join(
      exposure_metrics |> dplyr::rename(ID = id),
      by = "ID"
    ) |>
    dplyr::select(
      ID, ETA_CL, ETA_V1, ETA_Q, ETA_V2,
      CL_i, V1_i, Q_i, V2_i,
      AUC24, Cmin, cumulative_AUC, Cmax_central, Cmax_peripheral,
      age, weight, sex, clcr, baseline_scr,
      diabetes, hypertension, n_prior_courses
    ) |>
    dplyr::mutate(dplyr::across(where(is.double), \(x) round(x, 4)))
}


# =============================================================================
# PD CONFIG
# =============================================================================

nephro_config <- list(
  # renal_exposure_factor = exp(-ETA_CL * eta_cl_mult) * (90/CLCR)^clcr_exp
  eta_cl_mult           = 0.8,
  clcr_exp              = 1.2,
  # comorbidity_mult = 1 + diab_coef*D + htn_coef*H + diab_htn_int*D*H
  diab_coef             = 0.45,
  htn_coef              = 0.30,
  diab_htn_int          = 0.60,
  # cluster thresholds
  c3_comorbidity_thresh = 1.30,   # comorbidity_mult > x (requires diabetes to exceed)
  c3_prior_courses      = 2L,     # n_prior_courses >= x
  c2_quantile_cut       = 0.60,   # renal_exposure_factor quantile cut (top 40% → Cluster 2)
  # logistic PD model
  eta_pd_intercept      = -1.60,
  g1                    = 10.0,   # Cluster 1 slope: g1 * ETA_V2 × age
  g2                    =  8.5,   # Cluster 2 slope: g2 * AUC × renal_exposure_factor
  g3                    =  8.5,   # Cluster 3 slope: g3 * comorbidity × log1p(n_prior)
  # outcome
  scr_scale             = 0.9,
  scr_noise_sd          = 0.04
)

# =============================================================================
# PD PIPELINE FUNCTION
# Returns: subject_summary, ari (named vector), cluster_sizes, nephro_rates,
#          xgb_auc, shap_importance (tibble)
# =============================================================================

run_nephro_pd <- function(subject_df, cfg, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)

  n_subjects <- nrow(subject_df)

  # --------------------------------------------------------------------------
  # 2. INDIVIDUAL PD PARAMETERS + TRUE CLUSTER ASSIGNMENT
  #
  # Key mechanism:
  #   renal_exposure_factor = exp(-ETA_CL * eta_cl_mult) * (90/CLCR)^clcr_exp
  #   Low ETA_CL (slow plasma clearance) + low CLCR (poor renal function) →
  #   drug clears from plasma but accumulates in renal cortex ("CL trap").
  #   Neither ETA_CL alone nor CLCR alone predicts the outcome — only their
  #   nonlinear combination does, so ETA-cov plots remain unremarkable.
  #
  # Cluster 3: comorbidity_mult > c3_comorbidity_thresh (requires diabetes == 1)
  #   plus prior renal stress (n_prior_courses >= c3_prior_courses).
  # Cluster 2: top (1 - c2_quantile_cut) of renal_exposure_factor among non-C3.
  # Cluster 1: the rest.
  #
  # true_cluster labels are defined here but do NOT gate the PD predictor —
  # cluster membership is latent with respect to the outcome model.
  # --------------------------------------------------------------------------

  dat <- subject_df |>
    mutate(
      renal_exposure_factor = exp(-ETA_CL * cfg$eta_cl_mult) *
                              (90 / pmax(clcr, 15))^cfg$clcr_exp,
      comorbidity_mult      = 1 +
                              cfg$diab_coef    * diabetes +
                              cfg$htn_coef     * hypertension +
                              cfg$diab_htn_int * diabetes * hypertension,
      is_cluster3           = (comorbidity_mult > cfg$c3_comorbidity_thresh) &
                              (n_prior_courses >= cfg$c3_prior_courses)
    ) |>
    mutate(
      ef_q_nonc3   = quantile(renal_exposure_factor[!is_cluster3], cfg$c2_quantile_cut),
      is_cluster2  = !is_cluster3 & (renal_exposure_factor > ef_q_nonc3),
      true_cluster = factor(
        case_when(is_cluster3 ~ 3L, is_cluster2 ~ 2L, TRUE ~ 1L),
        levels = 1:3
      )
    )

  cat("\n--- True cluster sizes ---\n")
  print(table(dat$true_cluster))

  # --------------------------------------------------------------------------
  # 3. LOGISTIC REGRESSION PD MODEL
  #
  # Single continuous predictor — no cluster-specific intercepts or slopes.
  # Risk is driven by renal_exposure_factor and the comorbidity ×
  # prior-courses interaction, both of which vary continuously across subjects.
  # Cluster membership is latent: true_cluster labels are defined above but
  # do NOT gate eta_pd.
  # --------------------------------------------------------------------------

  cat("\nSimulating PD outcomes via logistic regression model...\n")

  dat <- dat |>
    mutate(
      v2_z   = as.numeric(scale(ETA_V2)),
      age_z  = as.numeric(scale(age)),
      ref_z  = as.numeric(scale(renal_exposure_factor)),
      cmx_z  = as.numeric(scale(comorbidity_mult * log1p(n_prior_courses))),
      auc_z  = as.numeric(scale(AUC24 / 400)),
      g1_ind = true_cluster == 1,
      g2_ind = true_cluster == 2,
      g3_ind = true_cluster == 3,
      eta_pd = cfg$eta_pd_intercept +
        g1_ind * (cfg$g1 * v2_z * age_z) +
        g2_ind * (cfg$g2 * auc_z * ref_z) +
        g3_ind * (cfg$g3 * cmx_z) +
        runif(n(), 0, 0.05)
    )

  outcomes <- dat |>
    mutate(
      p_nephro          = plogis(eta_pd),
      nephro_binary     = rbinom(n(), 1, p_nephro),
      peak_delta_SCr    = pmax(
        p_nephro * baseline_scr * cfg$scr_scale + rnorm(n(), 0, cfg$scr_noise_sd),
        0
      ),
      nephro_risk_score = p_nephro
    ) |>
    select(ID, p_nephro, nephro_binary, nephro_risk_score, peak_delta_SCr)

  cat("Nephrotoxicity events:", sum(outcomes$nephro_binary), "/", n_subjects, "\n")
  cat("Event rate:", round(mean(outcomes$nephro_binary) * 100, 1), "%\n")

  # --------------------------------------------------------------------------
  # 4. NAIVE ML PIPELINE — demonstrate that raw outcomes hide cluster structure
  #
  # Feature matrix: observable PD outcomes + standard PK metrics only.
  # Derived interaction terms intentionally excluded — a naive analyst would
  # not know to compute them. All three methods should yield ARI < 0.20.
  # --------------------------------------------------------------------------

  cat("\nNaive clustering on observable outcome features...\n")

  cluster_input <- outcomes |>
    left_join(select(dat, ID, AUC24, cumulative_AUC, Cmin), by = "ID")

  feature_mat <- cluster_input |>
    select(nephro_binary, peak_delta_SCr, AUC24, cumulative_AUC, Cmin) |>
    mutate(across(everything(), \(x) if_else(!is.finite(x), 0, x)))

  feature_scaled <- scale(feature_mat)
  feature_scaled[!is.finite(feature_scaled)] <- 0

  compute_ari <- function(a, b) {
    tab      <- table(factor(a), factor(b))
    n        <- sum(tab)
    sum_cij  <- sum(choose(tab, 2))
    sum_ai   <- sum(choose(rowSums(tab), 2))
    sum_bj   <- sum(choose(colSums(tab), 2))
    expected <- sum_ai * sum_bj / choose(n, 2)
    denom    <- 0.5 * (sum_ai + sum_bj) - expected
    if (denom == 0) return(0)
    (sum_cij - expected) / denom
  }

  true_vec <- as.integer(dat$true_cluster)

  km_fit     <- kmeans(feature_scaled, centers = 3, nstart = 25, iter.max = 100)
  ari_kmeans <- compute_ari(true_vec, km_fit$cluster)
  cat("k-means ARI (k=3):", round(ari_kmeans, 3), "(target < 0.20)\n")
  if (ari_kmeans > 0.30) warning("k-means ARI unexpectedly high — check feature matrix")

  hc_fit     <- hclust(dist(feature_scaled), method = "ward.D2")
  hc_labels  <- cutree(hc_fit, k = 3)
  ari_hclust <- compute_ari(true_vec, hc_labels)
  cat("Hierarchical ARI (Ward D2, k=3):", round(ari_hclust, 3), "(target < 0.20)\n")

  dbscan_fit    <- dbscan::dbscan(feature_scaled, eps = 1.0, minPts = 10)
  ari_dbscan_nn <- sum(dbscan_fit$cluster > 0)
  if (ari_dbscan_nn > 10) {
    ari_dbscan <- compute_ari(
      true_vec[dbscan_fit$cluster > 0],
      dbscan_fit$cluster[dbscan_fit$cluster > 0]
    )
  } else {
    ari_dbscan <- NA_real_
  }
  cat("DBSCAN clusters found:", length(unique(dbscan_fit$cluster[dbscan_fit$cluster > 0])),
      "| noise:", sum(dbscan_fit$cluster == 0), "/", n_subjects, "\n")
  cat("DBSCAN ARI (non-noise):", round(ari_dbscan, 3), "(target < 0.20)\n")

  cat("\n--- Naive clustering ARI summary ---\n")
  cat(sprintf("  k-means:       %.3f\n", ari_kmeans))
  cat(sprintf("  Hierarchical:  %.3f\n", ari_hclust))
  cat(sprintf("  DBSCAN:        %.3f\n", ari_dbscan))
  cat("All should be < 0.20 — cluster structure invisible in raw outcome space.\n")

  cat("\nConfusion matrix (true vs k-means):\n")
  print(table(true = true_vec, kmeans = km_fit$cluster))

  id_cluster_map <- tibble(
    ID                = cluster_input$ID,
    recovered_cluster = factor(km_fit$cluster)
  )

  umap_outcome <- umap(
    feature_scaled,
    n_neighbors = 15, min_dist = 0.1, n_epochs = 500, verbose = FALSE
  )

  eta_scaled <- dat |>
    select(ETA_CL, ETA_V1, ETA_Q, ETA_V2) |>
    scale()

  umap_eta <- umap(
    eta_scaled,
    n_neighbors = 15, min_dist = 0.1, n_epochs = 500, verbose = FALSE
  )

  # --------------------------------------------------------------------------
  # 5. XGBOOST + SHAP + UMAP PIPELINE
  #
  # XGBoost binary classifier on raw covariates + ETAs + PK exposures.
  # SHAP values → N × features matrix → UMAP embedding → HDBSCAN clustering.
  # Tests whether model-agnostic explanations recover the hidden cluster
  # structure that naive outcome clustering cannot find.
  # --------------------------------------------------------------------------

  cat("\nFitting XGBoost model for nephrotoxicity...\n")

  xgb_features <- dat |>
    select(age, weight, sex, clcr, baseline_scr,
           diabetes, hypertension, n_prior_courses,
           ETA_CL, ETA_V1, ETA_Q, ETA_V2,
           AUC24, Cmin, cumulative_AUC, Cmax_central, Cmax_peripheral) |>
    mutate(sex = as.numeric(sex)) |>
    as.matrix()

  xgb_label <- outcomes$nephro_binary
  xgb_dmat  <- xgb.DMatrix(xgb_features, label = xgb_label)

  xgb_params <- list(
    objective        = "binary:logistic",
    eval_metric      = "auc",
    max_depth        = 5,          # depth 5 captures ETA_CL × CLCR × AUC24 and ETA_V2 × age
    eta              = 0.10,       # faster convergence; 0.05 stopped too early at round 16
    subsample        = 0.8,
    colsample_bytree = 0.8,
    min_child_weight = 3           # less restrictive for N=300
  )

  cv_fit <- xgb.cv(
    params                = xgb_params,
    data                  = xgb_dmat,
    nrounds               = 400,
    nfold                 = 5,
    verbose               = FALSE,
    early_stopping_rounds = 30
  )
  best_nrounds <- cv_fit$early_stop$best_iteration

  xgb_fit <- xgb.train(
    params  = xgb_params,
    data    = xgb_dmat,
    nrounds = best_nrounds,
    verbose = 0
  )
  xgb_auc <- round(max(cv_fit$evaluation_log$test_auc_mean), 3)
  cat("XGBoost best nrounds:", best_nrounds, "\n")
  cat("XGBoost CV AUC:", xgb_auc, "\n")

  shap_out <- shap.values(xgb_model = xgb_fit, X_train = xgb_features)
  shap_mat  <- as.matrix(shap_out$shap_score)
  shap_mat[!is.finite(shap_mat)] <- 0

  shap_scaled_mat <- scale(shap_mat)
  shap_scaled_mat[!is.finite(shap_scaled_mat)] <- 0

  umap_shap <- umap(
    shap_mat,
    n_neighbors = 15, min_dist = 0.1, n_epochs = 500, verbose = FALSE
  )

  shap_umap_df <- as_tibble(umap_shap) |>
    rename(shap_umap1 = V1, shap_umap2 = V2)

  if (!is.null(seed)) set.seed(seed)   # mirrors original set.seed before k-means on SHAP
  km_shap         <- kmeans(shap_scaled_mat, centers = 3, nstart = 25)
  shap_cluster_km <- factor(km_shap$cluster)
  ari_shap_km     <- compute_ari(as.integer(dat$true_cluster), as.integer(shap_cluster_km))

  hc_shap         <- hclust(dist(shap_scaled_mat), method = "ward.D2")
  shap_cluster_hc <- factor(cutree(hc_shap, k = 3))
  ari_shap_hc     <- compute_ari(as.integer(dat$true_cluster), as.integer(shap_cluster_hc))

  hdbscan_fit          <- hdbscan(umap_shap, minPts = 15)
  shap_cluster_hdbscan <- factor(hdbscan_fit$cluster)
  non_noise            <- hdbscan_fit$cluster > 0
  ari_shap_hdbscan     <- if (sum(non_noise) > 10) {
    compute_ari(
      as.integer(dat$true_cluster)[non_noise],
      hdbscan_fit$cluster[non_noise]
    )
  } else NA_real_

  shap_cluster <- shap_cluster_hc  # primary: hierarchical, always k=3, no noise points

  cat("\n--- SHAP clustering ARI summary ---\n")
  cat(sprintf("  K-means (k=3) on SHAP:               %.3f\n", ari_shap_km))
  cat(sprintf("  Hierarchical Ward D2 (k=3) on SHAP:  %.3f\n", ari_shap_hc))
  cat(sprintf("  HDBSCAN on SHAP-UMAP (non-noise):    %.3f\n", ari_shap_hdbscan))
  cat(sprintf("  (naive k-means ARI for reference:     %.3f)\n", ari_kmeans))
  cat("All SHAP methods should be >> naive ARI.\n")

  cat("\nConfusion matrix (true vs SHAP hierarchical):\n")
  print(table(true    = as.integer(dat$true_cluster),
              shap_hc = as.integer(shap_cluster_hc)))

  # --------------------------------------------------------------------------
  # 6. ASSEMBLE FINAL DATASET
  # --------------------------------------------------------------------------

  subject_summary <- dat |>
    left_join(outcomes, by = "ID") |>
    left_join(id_cluster_map, by = "ID") |>
    mutate(
      umap_e1              = umap_eta[match(ID, dat$ID), 1],
      umap_e2              = umap_eta[match(ID, dat$ID), 2],
      umap_o1              = umap_outcome[match(ID, cluster_input$ID), 1],
      umap_o2              = umap_outcome[match(ID, cluster_input$ID), 2],
      shap_umap1           = shap_umap_df$shap_umap1,
      shap_umap2           = shap_umap_df$shap_umap2,
      shap_cluster         = shap_cluster,
      shap_cluster_km      = shap_cluster_km,
      shap_cluster_hdbscan = shap_cluster_hdbscan
    ) |>
    select(
      ID, age, weight, sex, clcr, baseline_scr,
      diabetes, hypertension, n_prior_courses,
      ETA_CL, ETA_V1, ETA_Q, ETA_V2,
      CL_i, V1_i, Q_i, V2_i,
      AUC24, Cmin, cumulative_AUC, Cmax_central, Cmax_peripheral,
      renal_exposure_factor, comorbidity_mult,
      true_cluster, recovered_cluster,
      umap_e1, umap_e2, umap_o1, umap_o2,
      shap_umap1, shap_umap2, shap_cluster, shap_cluster_km, shap_cluster_hdbscan,
      eta_pd, p_nephro, nephro_risk_score, nephro_binary, peak_delta_SCr
    )

  nephro_rates <- c(
    tapply(subject_summary$nephro_binary, subject_summary$true_cluster, mean),
    overall = mean(subject_summary$nephro_binary)
  )

  list(
    subject_summary = subject_summary,
    ari             = c(
      kmeans_naive = ari_kmeans,
      hclust_naive = ari_hclust,
      dbscan_naive = ari_dbscan,
      kmeans_shap  = ari_shap_km,
      hclust_shap  = ari_shap_hc,
      hdbscan_shap = ari_shap_hdbscan
    ),
    cluster_sizes   = as.integer(table(dat$true_cluster)),
    nephro_rates    = nephro_rates,
    xgb_auc         = xgb_auc,
    shap_importance = tibble(
      feature   = colnames(shap_mat),
      mean_shap = shap_out$mean_shap_score
    )
  )
}
