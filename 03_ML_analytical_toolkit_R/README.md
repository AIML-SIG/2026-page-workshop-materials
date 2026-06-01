# ML Analytical Toolkit in R — Workshop Module

This module demonstrates a practical machine learning workflow for pharmacometric PK/PD data analysis in R. Using a tobramycin PK/PD cohort, participants apply XGBoost, SHAP-based model interpretation, UMAP dimensionality reduction, and PAM clustering to uncover hidden patient subgroups and identify drivers of nephrotoxicity risk.

---

## Tutorial Overview

| File | Topic |
|---|---|
| [hands-on/tutorial.qmd](hands-on/tutorial.qmd) | Hands-on tutorial: XGBoost, SHAP, UMAP + PAM clustering |
| [solutions/tutorial_with_answers.html](solutions/tutorial_with_answers.html) | Rendered tutorial with all answers filled in |

---

## Helpers (`hands-on/helpers/`)

The `helpers/` folder contains self-contained R scripts that encapsulate the core modeling steps. They are sourced at the top of the tutorial and can be reused independently.

| File | Description |
|---|---|
| [`helpers/ggplot_theme.R`](hands-on/helpers/ggplot_theme.R) | `theme_workshop()` — custom `ggplot2` theme and shared colour palette (`blue`, `outcome_pal`, …) used throughout the tutorial plots |
| [`helpers/xgb.R`](hands-on/helpers/xgb.R) | `fit_xgb_classification()` — fits an XGBoost binary classifier with stratified *v*-fold CV via tidymodels and returns the final fit plus per-fold metrics (ROC AUC, specificity, precision, recall, F1) summarised as `mean [min–max]`. Also exposes `fit_xgb_regression()` and `xgb_importance_plot()` |
| [`helpers/shap.R`](hands-on/helpers/shap.R) | SHAP utilities built on `shapviz`: `compute_shap()`, `shap_matrix()`, `shap_top_features()`, `shap_beeswarm()`, `shap_waterfall()`, `shap_dependence()` — for population-level importance, single-patient decomposition, and dependence / interaction plots |
| [`helpers/dim_reduction_clustering.R`](hands-on/helpers/dim_reduction_clustering.R) | `run_dim_reduction_clustering()` — projects a feature matrix to 2D with UMAP (`uwot`) and clusters the embedding with PAM (`cluster`); plus `plot_umap()` for the standard side-by-side panels and `adjusted_rand_index()` for scoring a clustering against ground truth |

---

## Tutorial workflow

The hands-on tutorial walks through four blocks on the same simulated tobramycin cohort:

1. **Setup** — load packages and helpers, glance at the cohort, confirm the ETA distributions look unimodal (cluster structure is hidden).
2. **XGBoost** — fit `nephro_binary ~ .` with 5-fold stratified CV. The walkthrough first shows the four explicit tidymodels steps (`spec → folds → fit_resamples → fit`) scoring five complementary metrics (ROC AUC, specificity, precision, recall, F1) reported per fold and as `mean [min–max]` across folds. Subsequent chunks use `fit_xgb_classification()` to keep exercises short.
3. **SHAP** — decompose predictions with `compute_shap()`, then explore the model via beeswarm, single-patient waterfall, and CLCR dependence plots.
4. **UMAP + PAM** — cluster the same 300 patients in three different input spaces (posthoc PK, outcome, SHAP) and compare side by side.
5. **Reveal** — join the hidden `true_cluster` labels and score each clustering with adjusted Rand index to show that SHAP-space recovers the latent phenotypes that PK- and outcome-space miss.

Each modelling block ends with a required **🔧 Try it** exercise (one small modification) and optional **🚀 Bonus** chunks (collapsed by default) that go further.

---

<p align="center"><small><em>PAGE 2026 AI/ML Satellite Workshop · Dubrovnik · June 2, 2026</em></small></p>
<p align="center"><small><em>ISoP AI/ML Special Interest Group</em></small></p>
