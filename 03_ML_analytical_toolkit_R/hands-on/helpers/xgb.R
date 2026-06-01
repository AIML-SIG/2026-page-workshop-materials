suppressPackageStartupMessages({
  library(parsnip)
  library(workflows)
  library(rsample)
  library(tune)
  library(yardstick)
  library(xgboost)
  library(dplyr)
})

# Fit an XGBoost binary classifier with stratified v-fold CV; returns $fit + mean CV AUC.
fit_xgb_classification <- function(data, formula,
                           trees      = 500,
                           tree_depth = 5,
                           learn_rate = 0.05,
                           seed       = 2026,
                           v          = 5) {
  resp <- all.vars(formula)[1]
  # xgboost classification needs a factor target, not 0/1 numeric
  if (!is.factor(data[[resp]])) {
    stop("Response '", resp,
         "' must be a factor (e.g., factor(nephro_binary, levels = c(0, 1))).")
  }

  set.seed(seed)  # reproducible folds + boosting

  # the three knobs to tune for your own data
  spec <- boost_tree(
    trees      = trees,
    tree_depth = tree_depth,
    learn_rate = learn_rate
  ) |>
    set_engine("xgboost") |>
    set_mode("classification")

  # v-fold CV, stratified on the response to keep class balance per fold
  folds <- vfold_cv(data, v = v, strata = !!sym(resp))

  cv_results <- fit_resamples(
    spec,
    preprocessor = formula,
    resamples    = folds,
    metrics      = metric_set(roc_auc, yardstick::spec, precision, recall, f_meas),
    control      = control_resamples(save_pred = FALSE)
  )

  fit <- fit(spec, formula, data = data)  # final model on all rows

  # Per-fold metrics: one row per (metric × fold)
  cv_per_fold <- collect_metrics(cv_results, summarize = FALSE) |>
    select(.metric, id, .estimate)

  # Wide table (rows = metrics, cols = folds) + mean [min–max] summary
  cv_metrics <- cv_per_fold |>
    tidyr::pivot_wider(names_from = id, values_from = .estimate) |>
    dplyr::rowwise() |>
    dplyr::mutate(
      mean    = mean(dplyr::c_across(dplyr::starts_with("Fold"))),
      min     = min(dplyr::c_across(dplyr::starts_with("Fold"))),
      max     = max(dplyr::c_across(dplyr::starts_with("Fold"))),
      summary = sprintf("%.3f [%.3f–%.3f]", mean, min, max)
    ) |>
    dplyr::ungroup()

  # Scalar mean CV AUC, kept for backwards-compatibility with downstream chunks
  cv_auc <- cv_metrics |>
    dplyr::filter(.metric == "roc_auc") |>
    dplyr::pull(mean) |>
    round(3)

  list(
    fit        = fit,
    cv_auc     = cv_auc,
    cv_metrics = cv_metrics,
    trees      = trees,
    tree_depth = tree_depth,
    learn_rate = learn_rate
  )
}

# Fit an XGBoost regression model with v-fold CV; returns $fit, CV RMSE/R2, training R2.
fit_xgb_regression <- function(data, formula,
                               trees      = 500,
                               tree_depth = 3,
                               learn_rate = 0.05,
                               seed       = 2026,
                               v          = 5) {
  set.seed(seed)

  # same knobs, regression mode
  spec <- boost_tree(
    trees      = trees,
    tree_depth = tree_depth,
    learn_rate = learn_rate
  ) |>
    set_engine("xgboost") |>
    set_mode("regression")

  folds <- vfold_cv(data, v = v)  # no strata for a continuous target

  cv_results <- fit_resamples(
    spec,
    preprocessor = formula,
    resamples    = folds,
    metrics      = metric_set(rmse, rsq),
    control      = control_resamples(save_pred = FALSE)
  )

  fit <- fit(spec, formula, data = data)

  cv_metrics <- collect_metrics(cv_results)
  cv_rmse <- cv_metrics |> filter(.metric == "rmse") |> pull(mean) |> round(3)
  cv_rsq  <- cv_metrics |> filter(.metric == "rsq")  |> pull(mean) |> round(3)

  # training R^2 too — compare against cv_rsq to spot overfitting
  resp  <- all.vars(formula)[1]
  preds <- predict(fit, new_data = data) |> pull(.pred)
  y     <- data[[resp]]
  ss_res   <- sum((y - preds)^2)
  ss_tot   <- sum((y - mean(y))^2)
  train_r2 <- round(1 - ss_res / ss_tot, 3)

  list(
    fit        = fit,
    cv_rmse    = cv_rmse,
    cv_rsq     = cv_rsq,
    train_r2   = train_r2,
    trees      = trees,
    tree_depth = tree_depth,
    learn_rate = learn_rate
  )
}

# Tune an XGBoost classifier (tree_depth × learn_rate grid) with stratified v-fold
# CV on the training set; refit on all training rows with the best params.
# Returns $fit + best params + raw tune object + per-fold metrics for the winner.
tune_xgb_classification <- function(train_data, formula,
                                    grid       = NULL,
                                    trees      = 500,
                                    seed       = 2026,
                                    v          = 5) {
  resp <- all.vars(formula)[1]
  if (!is.factor(train_data[[resp]])) {
    stop("Response '", resp,
         "' must be a factor (e.g., factor(nephro_binary, levels = c(0, 1))).")
  }
  if (is.null(grid)) {
    grid <- expand.grid(tree_depth = c(2L, 3L, 5L),
                        learn_rate = c(0.05, 0.10, 0.30))
  }

  set.seed(seed)

  spec <- boost_tree(
    trees      = trees,
    tree_depth = tune(),
    learn_rate = tune()
  ) |>
    set_engine("xgboost") |>
    set_mode("classification")

  folds <- vfold_cv(train_data, v = v, strata = !!sym(resp))

  tune_results <- tune::tune_grid(
    spec,
    preprocessor = formula,
    resamples    = folds,
    grid         = grid,
    metrics      = metric_set(roc_auc, yardstick::spec, precision, recall, f_meas),
    control      = tune::control_grid(save_pred = FALSE, verbose = FALSE)
  )

  best_params <- tune::select_best(tune_results, metric = "roc_auc")

  final_spec <- tune::finalize_model(spec, best_params)
  fit        <- parsnip::fit(final_spec, formula, data = train_data)

  # Per-fold values for the winning (tree_depth, learn_rate) cell, in the same
  # wide format fit_xgb_classification returns so downstream chunks can reuse it.
  cv_per_fold <- tune::collect_metrics(tune_results, summarize = FALSE) |>
    dplyr::filter(tree_depth == best_params$tree_depth,
                  learn_rate == best_params$learn_rate) |>
    dplyr::select(.metric, id, .estimate)

  cv_metrics_best <- cv_per_fold |>
    tidyr::pivot_wider(names_from = id, values_from = .estimate) |>
    dplyr::rowwise() |>
    dplyr::mutate(
      mean    = mean(dplyr::c_across(dplyr::starts_with("Fold"))),
      min     = min(dplyr::c_across(dplyr::starts_with("Fold"))),
      max     = max(dplyr::c_across(dplyr::starts_with("Fold"))),
      summary = sprintf("%.3f [%.3f–%.3f]", mean, min, max)
    ) |>
    dplyr::ungroup()

  best_cv_auc <- cv_metrics_best |>
    dplyr::filter(.metric == "roc_auc") |>
    dplyr::pull(mean) |>
    round(3)

  list(
    fit             = fit,
    best_params     = best_params,
    best_cv_auc     = best_cv_auc,
    tune_results    = tune_results,
    cv_metrics_best = cv_metrics_best,
    trees           = trees
  )
}

# Tile plot of mean CV roc_auc across a (tree_depth, learn_rate) tuning grid.
xgb_tune_heatmap <- function(tune_results,
                             title = "Tuning surface — mean CV ROC-AUC") {
  grid_auc <- tune::collect_metrics(tune_results) |>
    dplyr::filter(.metric == "roc_auc") |>
    dplyr::mutate(
      tree_depth = factor(tree_depth),
      learn_rate = factor(learn_rate)
    )

  ggplot(grid_auc, aes(learn_rate, tree_depth, fill = mean)) +
    geom_tile(colour = "white", linewidth = 0.6) +
    geom_text(aes(label = sprintf("%.3f", mean)), colour = "white", size = 4) +
    scale_fill_gradient(low = blue, high = orange, name = "CV ROC-AUC") +
    labs(title = title, x = "learn_rate", y = "tree_depth") +
    theme_workshop(11)
}

# Plot gain-based feature importance from a parsnip model_fit or raw xgb.Booster.
xgb_importance_plot <- function(fit, title = "XGBoost feature importance") {
  engine <- if (inherits(fit, "model_fit")) extract_fit_engine(fit) else fit
  imp <- xgb.importance(model = engine) |>
    tibble::as_tibble() |>
    dplyr::mutate(Feature = forcats::fct_reorder(Feature, Gain))  # order bars by Gain

  ggplot(imp, aes(x = Gain, y = Feature)) +
    geom_col(fill = blue, alpha = 0.85) +
    labs(title    = title,
         subtitle = "Gain = average improvement per split using this feature",
         x        = "Gain", y = NULL) +
    theme_workshop(11)
}
