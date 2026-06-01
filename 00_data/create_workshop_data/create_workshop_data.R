# =============================================================================
# create_workshop_data.R — single-script pipeline for the PAGE workshop dataset
#
# Runs the tobramycin PK simulation, the nephrotoxicity PD + ML pipeline,
# and writes three committed CSVs straight to ../hands_on/data/:
#
#   tobramycin_pk.csv       — sparse ADPC (clinical-trial-like, many rows)
#   tobramycin_pd.csv       — 300 × 23 subject-level features (participants see this)
#   tobramycin_clusters.csv — 300 × 2 hidden ground truth (reveal block)
#
# Also writes ../slides/figs/classical_resid_vs_time.png, which the
# ml_toolkit_intro deck references and which needs longitudinal residuals.
#
# Run from this directory:
#   Rscript create_workshop_data.R
#
# Reproducibility: set.seed(2026) is called twice — once before the PK
# pipeline, once before run_nephro_pd() — to match the seed semantics of the
# original two-script pipeline. Do not reorder calls in helpers.R or here.
# =============================================================================

if (!requireNamespace("renv", quietly = TRUE)) {
  install.packages("renv", repos = "https://cloud.r-project.org")
}
if (file.exists("renv.lock")) {
  renv::restore(prompt = FALSE)
}

suppressPackageStartupMessages({
  library(rxode2)
  library(tidyverse)
  library(uwot)
  library(e1071)
  library(patchwork)
  library(xgboost)
  library(SHAPforxgboost)
  library(dbscan)
})

# --- path resolution -------------------------------------------------------

get_script_dir <- function() {
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- sub("^--file=", "", args[grepl("^--file=", args)])
  if (length(file_arg) > 0 && nzchar(file_arg)) {
    return(dirname(normalizePath(file_arg)))
  }
  ofile <- sys.frames()[[1L]]$ofile
  if (!is.null(ofile)) return(dirname(normalizePath(ofile)))
  getwd()
}
here_dir   <- get_script_dir()
repo_root  <- normalizePath(file.path(here_dir, ".."), mustWork = TRUE)
hands_data <- file.path(repo_root, "hands_on", "data")
slide_figs <- file.path(repo_root, "slides", "figs")
recipes    <- file.path(repo_root, "hands_on", "recipes")
dir.create(hands_data, showWarnings = FALSE, recursive = TRUE)
dir.create(slide_figs, showWarnings = FALSE, recursive = TRUE)

source(file.path(here_dir, "helpers.R"))

# --- PK pipeline -----------------------------------------------------------

set.seed(2026)

message("Simulating covariates...")
covariates_df <- simulate_covariates(n = 300)

message("Computing individual PK parameters...")
pk_params_df <- compute_individual_pk(covariates_df)

message("Compiling rxode2 model...")
pk_model <- define_pk_model()

message("Building sparse event table...")
event_data <- build_event_data(pk_params_df)

message("Running sparse PK simulation...")
sim_sparse <- simulate_sparse_pk(pk_model, event_data, pk_params_df)

message("Assembling ADPC dataset...")
adpc_df <- assemble_adpc(sim_sparse, event_data, pk_params_df)

message("Exporting PK dataset...")
out_pk <- file.path(hands_data, "tobramycin_pk.csv")
write_csv(adpc_df, out_pk)

message("Running dense simulation for exposure metrics...")
exposure_metrics <- compute_exposures(pk_model, pk_params_df)

message("Assembling subject-level dataset...")
subject_df <- assemble_subject_dataset(pk_params_df, exposure_metrics)

# --- PD + ML pipeline ------------------------------------------------------
# Re-seed to mirror the old 02_PD_nephrotoxicity.R, which had its own
# set.seed(2026) at the top before calling run_nephro_pd().
set.seed(2026)

message("Running nephrotoxicity PD + XGBoost + SHAP + UMAP pipeline...")
res             <- run_nephro_pd(subject_df, nephro_config, seed = 2026)
subject_summary <- res$subject_summary

# --- Per-subject residual proxy from adpc ----------------------------------
resid_summary <- adpc_df |>
  filter(evid == 0, !is.na(dv), !is.na(ipred), ipred > 0) |>
  mutate(prop_resid = (dv - ipred) / ipred) |>
  group_by(ID) |>
  summarise(
    mean_abs_iwres = mean(abs(prop_resid)),
    n_obs          = n(),
    .groups        = "drop"
  )

# --- Build the two committed workshop tibbles ------------------------------
workshop_features <- subject_summary |>
  left_join(resid_summary, by = "ID") |>
  transmute(
    id                  = ID,
    age, weight, sex, clcr, baseline_scr,
    diabetes, hypertension, n_prior_courses,
    eta_cl              = ETA_CL,
    eta_v1              = ETA_V1,
    eta_q               = ETA_Q,
    eta_v2              = ETA_V2,
    auc24               = AUC24,
    cmin                = Cmin,
    cumulative_auc      = cumulative_AUC,
    cmax_central        = Cmax_central,
    cmax_peripheral     = Cmax_peripheral,
    nephro_binary,
    nephro_risk_score,
    peak_delta_scr      = peak_delta_SCr,
    mean_abs_iwres,
    n_obs
  ) |>
  arrange(id)

workshop_truth <- subject_summary |>
  transmute(id = ID, true_cluster) |>
  arrange(id)

out_pd       <- file.path(hands_data, "tobramycin_pd.csv")
out_clusters <- file.path(hands_data, "tobramycin_clusters.csv")
write_csv(workshop_features, out_pd)
write_csv(workshop_truth,    out_clusters)

# --- classical_resid_vs_time.png for the slides ----------------------------
# Generated here because the longitudinal adpc rows do not survive into the
# committed workshop CSVs (which carry per-subject scalars only).
source(file.path(recipes, "00_theme.R"))

resid_pts <- adpc_df |>
  filter(evid == 0, !is.na(dv), !is.na(ipred), ipred > 0) |>
  mutate(prop_resid = (dv - ipred) / ipred)

p_resid <- ggplot(resid_pts, aes(time, prop_resid)) +
  geom_hline(yintercept = 0, colour = "grey50") +
  geom_point(alpha = 0.18, size = 0.9, colour = isop_blue) +
  geom_smooth(method = "loess", se = TRUE, colour = isop_orange,
              fill = "#FAD2B4", linewidth = 0.9) +
  labs(title    = "Classical residual plot — proportional residual vs time",
       subtitle = sprintf("%d observations · loess overlay · no obvious trend",
                          nrow(resid_pts)),
       x        = "Time (h)",
       y        = "(DV − IPRED) / IPRED") +
  theme_workshop(13)

ggsave(file.path(slide_figs, "classical_resid_vs_time.png"),
       plot = p_resid, width = 7.5, height = 4.6, dpi = 150, bg = "white")

# --- Summary ---------------------------------------------------------------
cat("=========================================================\n")
cat("tobramycin_pk.csv:      ", out_pk, "\n")
cat("  Rows:    ", nrow(adpc_df), "\n")
cat("  Columns: ", ncol(adpc_df), "\n")
cat("tobramycin_pd.csv:      ", out_pd, "\n")
cat("  Rows:    ", nrow(workshop_features), "\n")
cat("  Columns: ", ncol(workshop_features), "\n")
cat("  Event rate (nephro_binary):",
    round(mean(workshop_features$nephro_binary) * 100, 1), "%\n")
cat("tobramycin_clusters.csv:", out_clusters, "\n")
cat("  Rows:    ", nrow(workshop_truth), "\n")
cat("  True cluster sizes:\n")
print(table(workshop_truth$true_cluster))
cat("classical_resid_vs_time.png:  ",
    file.path(slide_figs, "classical_resid_vs_time.png"), "\n")
cat("ARI (SHAP hierarchical):     ", round(res$ari[["hclust_shap"]], 3), "\n")
cat("XGBoost CV AUC:              ", res$xgb_auc, "\n")
cat("=========================================================\n")

