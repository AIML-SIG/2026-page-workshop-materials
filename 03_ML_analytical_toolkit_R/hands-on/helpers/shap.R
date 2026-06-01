suppressPackageStartupMessages({
  library(shapviz)
  library(ggplot2)
})

# Build a shapviz object (SHAP values) for an XGBoost fit on feature matrix X.
compute_shap <- function(xgb_fit, X) {
  shapviz(xgb_fit, X_pred = X, X = X)
}

# Extract the N x p SHAP value matrix from a shapviz object (NA/Inf -> 0 for UMAP).
shap_matrix <- function(shp) {
  m <- shapviz::get_shap_values(shp)
  if (is.null(m)) m <- shp$S   # fallback for older shapviz
  m[!is.finite(m)] <- 0        # UMAP chokes on NA/Inf
  m
}

# Keep the k features with highest mean |SHAP|; drops low-signal noise before UMAP.
shap_top_features <- function(shap_mat, k = 8) {
  importance <- colMeans(abs(shap_mat))  # rank by mean |SHAP|
  keep       <- names(sort(importance, decreasing = TRUE))[seq_len(min(k, ncol(shap_mat)))]
  shap_mat[, keep, drop = FALSE]
}

# SHAP mean-|SHAP| bar — population importance, magnitude only (no direction).
shap_importance_bar <- function(shp, max_display = 10L,
                                title = "Mean |SHAP| — feature importance") {
  sv_importance(shp, kind = "bar", max_display = max_display, fill = blue) +
    labs(title    = title,
         x = "Mean |SHAP|", y = NULL) +
    theme_workshop(11)
}

# SHAP beeswarm — population view, one dot per patient.
shap_beeswarm <- function(shp, max_display = 10L,
                          title = "SHAP beeswarm — population view") {
  sv_importance(shp, kind = "beeswarm", max_display = max_display) +
    labs(title    = title) +
    theme_workshop(11)
}

# SHAP waterfall — decompose a single patient's prediction (row_id of X).
shap_waterfall <- function(shp, row_id,
                           title = paste0("SHAP waterfall — Patient ID: ", row_id)) {
  sv_waterfall(shp, row_id = row_id) +
    labs(title = title) +
    theme_workshop(11)
}

# SHAP dependence plot for feature v, optionally coloured by color_var.
shap_dependence <- function(shp, v, color_var = NULL,
                            title = paste0("SHAP dependence — ", v)) {
  sv_dependence(shp, v = v, color_var = color_var) +
    labs(title = title) +
    theme_workshop(11)
}
