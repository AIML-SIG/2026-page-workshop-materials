# Performing Graphical Exploration Using GitHub Copilot's Agent Mode

This tutorial provides examples of graphical exploration tasks and demonstrates how to use GitHub Copilot to perform these tasks efficiently. By using GitHub Copilot to assist with these data analysis tasks, you can save time and improve the efficiency of your data analysis workflow.


## Performing PD Dataset Exploratory Analysis

1. Open a new GitHub Copilot chat window in VS Code by clicking on the logo at the top right panel and switch to `Agent` mode.
2. One after the other, copy and paste the entire prompts that are provided below.
3. These **prompts are designed to ask the user via the chat window to provide the full file paths** for the dataset and definition files. Use these paths:
   - **Dataset file:** `/workspaces/2026-page-workshop-materials/00_data/tobramycin_pd.csv`
   - **Definition file:** `/workspaces/2026-page-workshop-materials/01_genai_coding_assistants/.utils/define-pddataset.json`

<details><summary><b>Click to unfold and copy & paste the prompt</b></summary>

```text
# Pharmacometric PD Dataset Exploration

>>> ROLE: Act as an expert pharmacometrician in exploratory analysis of exposure-response supporting datasets.

>>> INFO: For a description of each column in the dataset read the dataset mapping from the JSON file provided in the repository. This file contains descriptions and tags for each column, including `covariate`, `iscategorical`, and `pkmetric`.

The JSON file describing the dataset columns should have the following structure:

{
  "columns": [
    {
      "header": "age",
      "description": "Age of the subject in years",
      "covariate": true,
      "pkmetric": false,
      "iscategorical": false
    },
    ...
  ]
}

**In R:** After loading with `fromJSON()`, access variable properties as columns of a data frame `as.data.frame(define$columns)`


>>> SETUP: Before proceeding, please ask the user to provide:
1. The full file path to the dataset CSV file (e.g., `/path/to/dataset.csv`)
2. The full file path to the dataset definition JSON file (e.g., `/path/to/define-dataset.json`)

>>> TASK: Using R, **create and save an R script** named `03-pddata_exploration.R` to perform graphical analysis on the provided PD-level dataset. The workflow MUST include:

---

## Environment
- Use R programming language
- Set working directory to /workspaces/2026-page-workshop-materials/01_genai_coding_assistants
- Create a `03-results_pd_exploration` folder (if not present) to store all outputs
- Use `ggplot2` for all plots
- Print informative messages at each major step of the workflow
- Read the JSON mapping and derive variable groups programmatically:
  - Covariates: columns with `covariate = true`
  - PK metrics: columns with `pkmetric = true`
  - ETAs: columns whose names start with `eta_`

## Data preparation

1. Build a subject-level analysis dataset using one row per `id`.
2. For columns that vary within `id`, retain the first non-missing value and report a warning listing such columns.
3. Ensure categorical covariates are converted to factors using dataset coding as labels where possible.

## PK metric summary statistics

4. Create a **PK metric summary table** including all variables tagged as `pkmetric = true` in the JSON.
5. For each PK metric report: N, missing (%), mean, median, SD and range.
6. Save this table as CSV in `03-results_pd_exploration`.

## ETA vs covariate graphical analysis

7. For each ETA variable, create one combined plot showing all covariates:
  - Continuous covariate: scatter plot with linear regression line and annotated Spearman rho.
  - Categorical covariate: boxplot + jittered points.
8. Save outputs as PNG files in a subfolder `03-results_pd_exploration/eta_vs_covariates`.

## PK metric vs covariate graphical analysis

9. For each PK metric variable, create one combined plot showing all covariates:
  - Continuous covariate: scatter plot with linear regression line and annotated Spearman rho.
  - Categorical covariate: boxplot + jittered points.
10. Save outputs as PNG files in a subfolder `03-results_pd_exploration/pkmetrics_vs_covariates`.

## Response vs covariate graphical analysis

11. Create a single combined plot showing all covariates versus the proportion of `nephro_binary == 1`:
  - Continuous covariate: quartile plot stratified by the proportion of `nephro_binary == 1` within each quartile, all in one figure (e.g., using facets or grouped layout).
  - Categorical covariate: grouped bar plots or faceted plots showing proportion of `nephro_binary == 1` for all categorical covariates together.
12. Save these combined outputs as PNG files in a subfolder `03-results_pd_exploration/nephro_binary_vs_covariates`.

## Exposure-Response graphical analysis

13. Create a single combined plot showing all PK metric variables:
  - Boxplots with jittered points for each PK metric, stratified by `nephro_binary` categories, all in one figure (e.g., using facets or grouped layout).
14. Create a single combined plot with quartile plots showing the distribution of all PK metrics, stratified by the proportion of `nephro_binary == 1` within each quartile (e.g., using facets or grouped layout).
15. Save these combined outputs as PNG files in `03-results_pd_exploration/nephro_binary_vs_pkmetrics`.

```

</details>


## Reporting Dataset Exploratory Analysis

Once the graphical exploration is complete, the next step is to summarise the findings in a structured report. This section provides two prompts for this task — a **basic version** and a more **curated version**. Try the basic prompt first: it is intentionally open-ended and gives the model significant freedom to decide the report structure, content, and formatting. This is a good exercise to observe how Copilot interprets an underspecified task.

<details><summary><b>Click to unfold and copy & paste the prompt</b></summary>

``` text
# Report results in a Word document

1. Acting as a pharmacometrician, provide a summary and interpretation of the exploratory results stored in `03-results_pd_exploration`.
2. Create a `reports` folder (if not existing) to store all outputs.
3. **Create and save** a Quarto document with the result interpretation (including plots). Use a regulatory compliant tone.
4. Render the Quarto document to Word format in `reports` folder

## Quarto Report Requirements
- The Quarto report must:
  - Include a summary table of all key findings (not just file references).
  - Provide a direct, written interpretation of the results, highlighting main findings, issues, and recommendations.
  - Place both the summary table and interpretation before plots and appendix.

### Example Quarto Structure

- Interpretation of Results
- Recommendations
- PK metric summary statistics table
- ETA vs covariates visualizations
- PK metrics vs covariates visualizations
- Response vs covariates visualizations
- Exposure-Response visualizations

Please include only the sections provided in the example

```
 </details>

### [Extra] Curated Reporting Prompt

The prompt above leaves most decisions to the model. Compare its output to what you get with the curated version below, which provides precise instructions for every aspect of the report: YAML front matter, table styling, narrative structure, inline R values, figure captions, and formatting rules. The key lesson is that **specificity drives reproducibility** — the more context and constraints you give the model, the closer the output will be to a submission-ready document with minimal manual editing.

<details><summary><b>Click to unfold and copy & paste the prompt</b></summary>

``` text
# Report Results in a Word Document

1. **Acting as a pharmacometrician**, provide a summary and interpretation of the exploratory results stored in `03-results_pd_exploration`.
2. Create a `reports/` folder (if not already existing) to store all outputs.
3. **Create and save** a Quarto document (`.qmd`) with the result interpretation (including plots) inside `reports/`. Use a **regulatory-compliant tone**.
4. **Render** the Quarto document to Word (`.docx`) format in the `reports/` folder.


## Quarto Document — YAML Header

The document must use the following YAML front matter:

---
title: "[Drug] Population Pharmacokinetics: Exploratory Data Analysis Report"
date: today
format:
  docx:
    toc: true
    toc-title: "Table of Contents"
    number-sections: false
execute:
  echo: false
  warning: false
  message: false
---


## Setup Chunk

Include a hidden `setup` chunk (`include=FALSE`) that:

- Loads `dplyr` and `flextable`
- Sets `res_dir` as a relative path pointing to `03-results_pd_exploration/` (relative to the `reports/` folder, e.g. `../03-results_pd_exploration`)
- Reads **all result CSVs and tables** into named R objects
- Pre-computes all **derived scalar values** used in inline R code throughout the narrative (e.g. `n_subj`, `age_mean`, `age_sd`, `wt_mean`, `wt_sd`, `clcr_mean`, `clcr_sd`, `dose_mg_mean`, `n_obs`, `obs_mean`, `cmax_mean`, `cmax_cv`, percentages for categorical variables, etc.)
- Defines the **flextable styling palette**:
  - Header background: `#1F4E79`, header text: `white`
  - Alternating row background: `#EEF3F9`
- Sets `flextable` defaults: font family `Calibri`, font size `10`, padding top/bottom `3`


## Required Sections

Include **only** the seven sections below, in this order:

### 1. Interpretation of Results

This section must open with a **Key Findings** subsection.

#### Key Findings

- Render a `flextable` with three columns: **Finding**, **Value**, **Assessment**
- Include rows summarising:
  - Study population size
  - Age (mean ± SD, range)
  - Body weight (mean ± SD, range)
  - Creatinine clearance (mean ± SD, range)
  - Sex distribution (% male / % female)
  - Prevalence of key comorbidities (diabetes, hypertension, etc.)
  - Prior drug exposure (if applicable)
  - Dosing regimen (number of doses, interval, route)
  - Weight-normalised dose (mean ± SD, CV%)
  - Total PK observations
  - Observations per subject (mean ± SD)
  - Peak concentrations (mean ± SD, sample size)
  - Inter-individual variability in Cmax (CV%)
- Apply **alternating row background** (`#EEF3F9` on even rows)
- Apply **header styling**: background `#1F4E79`, text `white`, bold
- Column widths: Finding `2.1"`, Value `1.9"`, Assessment `2.9"`
- Font size: `9pt` throughout
- Caption: *"Table 1. Key findings from the exploratory analysis."*



After the table, provide **three narrative subsections** with inline R values embedded throughout:

#### Population Characteristics
Describe the study population size, age distribution, sex distribution, body weight range, renal function (CLCR range and mean ± SD), and prevalence of clinically relevant comorbidities. Interpret the CLCR variability in the context of the drug's elimination pathway and its anticipated impact on clearance (CL) variability. Mention prior drug exposure prevalence if relevant to the population (e.g., chronic infection cohorts).

#### Dosing Regimen
Report the dosing schedule (frequency, route, number of doses), weight-normalised dose (mean ± SD, CV%), and absolute dose range. Confirm whether the dosing was protocol-defined and comment on the degree of dose-weight proportionality. Explain the implication for covariate modelling: if dose is perfectly proportional to weight, weight explains all dose variability, and analysts should be mindful of collinearity when interpreting covariate effects on CL and V.

#### PK Sampling and Observed Concentrations
Report the total number of PK observations, observations per subject (mean ± SD), and confirm suitability for compartmental modelling. Report the number of peak concentration samples, the observed mean Cmax ± SD (with CV%), and compare to clinical targets if applicable. Comment on the multi-exponential decline pattern observed in individual concentration-time profiles and its consistency with the expected compartmental behaviour of the drug.



### 2. Recommendations

Provide **4–6 numbered recommendations** as concise, actionable paragraphs (not bullet points). Each recommendation should have a **bold lead sentence** followed by a brief justification. Cover:

1. Priority covariate(s) for structural covariate modelling, with mechanistic rationale (e.g., CLCR on CL for renally eliminated drugs)
2. Evaluation of weight using allometric scaling on V (and CL if physiologically justified)
3. Assessment of secondary covariates (sex, comorbidities, prior exposure) after primary structural covariates are established
4. Investigation of any clinically relevant categorical covariates (e.g., prior drug exposure, disease severity)
5. Confirmation of sampling times or exposure targets before clinical interpretation (if applicable)
6. Recommendation to proceed to compartmental model development (one- vs. two-compartment, random effects structure)

Use inline R to embed numeric values (e.g., CLCR range, weight range, Cmax mean) where relevant.



### 3. PK Metric Summary Statistics Table

- Render a `flextable` summarising PK metrics (e.g., Cmax, AUC, Ctrough, etc.) with columns such as: **Metric**, **N**, **Mean (SD)**, **Median**, **Range**, **CV%**
- Apply **alternating row background** and **header styling** as defined in setup
- Column widths adjusted to content (typically: Metric `2.0"`, N `0.5"`, Mean (SD) `1.3"`, Median `0.9"`, Range `1.3"`, CV% `0.8"`)
- Font size: `9pt`
- Caption: *"Table 2. Summary statistics for pharmacokinetic metrics."*
- Below the table, include a footnote explaining any abbreviations or definitions (e.g., *"TSLD = time since last dose. Peak concentrations defined as observations collected 0.5–2 h post-dose."*)


### 4. ETA vs Covariates Visualizations

For each ETA (random effect) plot:

---
#| fig-cap: "Figure X. [ETA name] versus [covariate]. [Brief interpretation: e.g., 'No systematic trend observed, supporting the absence of a covariate effect on CL.']"
#| out-width: "100%"
knitr::include_graphics("../03-results_pd_exploration/[filename].png")
---

- Include one figure chunk per ETA-covariate relationship
- Number figures sequentially
- Provide a brief interpretive caption for each plot (1–2 sentences)

### 5. PK Metrics vs Covariates Visualizations

For each PK metric (e.g., Cmax, AUC) vs covariate plot:

---
#| fig-cap: "Figure X. [PK metric] versus [covariate]. [Brief interpretation: e.g., 'Positive correlation observed between Cmax and body weight, consistent with dose proportionality.']"
#| out-width: "100%"
knitr::include_graphics("../03-results_pd_exploration/[filename].png")
---

- Include one figure chunk per metric-covariate relationship
- Number figures sequentially
- Provide a brief interpretive caption for each plot

### 6. Response vs Covariates Visualizations

For each response (e.g., efficacy endpoint, adverse event) vs covariate plot:

---
#| fig-cap: "Figure X. [Response variable] versus [covariate]. [Brief interpretation: e.g., 'Higher response rates observed in subjects with CLCR >80 mL/min.']"
#| out-width: "100%"
knitr::include_graphics("../03-results_pd_exploration/[filename].png")
---

- Include one figure chunk per response-covariate relationship
- Number figures sequentially
- Provide a brief interpretive caption for each plot

### 7. Exposure-Response Visualizations

For each exposure-response relationship plot:

---
#| fig-cap: "Figure X. [Response variable] versus [exposure metric]. [Brief interpretation: e.g., 'Sigmoidal relationship observed between AUC and probability of response, supporting an Emax model structure.']"
#| out-width: "100%"
knitr::include_graphics("../03-results_pd_exploration/[filename].png")
---

- Include one figure chunk per exposure-response relationship
- Number figures sequentially
- Provide a brief interpretive caption for each plot (1–2 sentences describing the observed relationship and its modelling implications)

## Style & Formatting Rules

| Rule | Requirement |
|---|---|
| Tone | Regulatory-compliant: formal, precise, evidence-based |
| Inline values | Always use `` `r variable` `` — never hard-code numbers in prose |
| Flextable style | `theme_booktabs()` on all tables; bold headers; alternating row backgrounds |
| Header styling | Background `#1F4E79`, text `white`, bold |
| Alternating rows | Background `#EEF3F9` on even rows |
| Font | Calibri, 9–10pt for tables, standard for body text |
| Section separators | Use `---` (horizontal rule) between major sections |
| Emphasis | Use `**bold**` for key findings, lead sentences in recommendations, and verdicts |
| Figure captions | Must include brief interpretation (1–2 sentences) |
| No echo | All chunks must have `echo: false`; suppress warnings and messages globally |
| Paths | All file paths relative to `reports/`; never use absolute paths |
| Figure numbering | Sequential across all sections (Figure 1, Figure 2, ..., Figure N) |
| Table numbering | Sequential across all sections (Table 1, Table 2, ..., Table N) |

```

</details>

 ---

<p align="center"><small><em>PAGE 2026 AI/ML Satellite Workshop · Dubrovnik · June 2, 2026</em></small></p>
<p align="center"><small><em>ISoP AI/ML Special Interest Group</em></small></p>