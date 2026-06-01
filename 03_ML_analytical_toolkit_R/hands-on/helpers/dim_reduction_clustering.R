suppressPackageStartupMessages({
  library(uwot)
  library(cluster)
  library(tibble)
  library(dplyr)
})

# 2D UMAP embedding then PAM into k clusters; returns a U1/U2/cluster tibble.
run_dim_reduction_clustering <- function(mat, k = 3, n_neighbors = 15, min_dist = 0.05,
                                         seed = 2026, scale = TRUE) {
  stopifnot(is.matrix(mat) || is.data.frame(mat))
  mat <- as.matrix(mat)
  if (scale) {
    mat <- scale(mat)             # z-score so no column dominates the distance
    mat[!is.finite(mat)] <- 0     # zero-variance cols -> NaN, kill them
  }

  set.seed(seed)
  # n_neighbors / min_dist are the embedding knobs; n_threads=1 keeps it reproducible
  emb <- uwot::umap(
    mat,
    n_neighbors = n_neighbors,
    min_dist    = min_dist,
    metric      = "euclidean",
    n_threads   = 1,
    verbose     = FALSE
  )

  # cluster in the 2D embedding, not raw space — k = number of clusters
  pam_fit <- cluster::pam(emb, k = k, metric = "euclidean")

  tibble::tibble(
    U1      = emb[, 1],
    U2      = emb[, 2],
    cluster = factor(pam_fit$clustering)
  )
}

# Scatter the UMAP embedding, coloured by colour_col (cluster, true label, outcome...).
plot_umap <- function(df_u, label, colour_col = "cluster") {
  ggplot2::ggplot(df_u, ggplot2::aes(U1, U2, colour = .data[[colour_col]])) +
    ggplot2::geom_point(alpha = 0.75, size = 2) +
    ggplot2::scale_colour_manual(values = cluster_pal) +
    ggplot2::labs(title = paste0("UMAP — ", label),
                  x = "UMAP 1", y = "UMAP 2", colour = "Cluster") +
    theme_workshop(11)
}

# Adjusted Rand Index between two labelings (1 = identical, ~0 = chance).
adjusted_rand_index <- function(a, b) {
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
