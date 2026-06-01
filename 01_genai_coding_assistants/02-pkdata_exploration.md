# Performing Graphical Exploration Using GitHub Copilot's Agent Mode

This tutorial provides examples of graphical exploration tasks and demonstrates how to use GitHub Copilot to perform these tasks efficiently. By using GitHub Copilot to assist with these data analysis tasks, you can save time and improve the efficiency of your data analysis workflow.


## Performing PK Dataset Exploratory Analysis

1. Open a new GitHub Copilot chat window in VS Code by clicking on the logo at the top right panel and switch to `Agent` mode.
2. One after the other, copy and paste the entire prompts that are provided below.
3. These **prompts are designed to ask the user via the chat window to provide the full file paths** for the dataset and definition files. Use these paths:
   - **Dataset file:** `/workspaces/2026-page-workshop-materials/00_data/tobramycin_pk.csv`
   - **Definition file:** `/workspaces/2026-page-workshop-materials/01_genai_coding_assistants/.utils/define-pkdataset.json`

<details><summary><b>Click to unfold and copy & paste the prompt</b></summary>

```text
# Pharmacometric PK Dataset Exploration

>>> ROLE: Act as an expert pharmacometrician in PopPK analysis exploratory analysis. 

>>> INFO: For a description of each column in the dataset read the dataset mapping from the JSON file provided in the repository. This file contains descriptions of all columns in the dataset, including their names, types, and roles (e.g., ID, TIME, EVID, observations, covariates).

The JSON file describing the dataset columns should have the following structure:

{
  "columns": [
    {
      "header": "age",
      "description": "Age of the subject in years",
      "covariate": true,
      "nonmem_essential": false,
      "iscategorical": false
    },
    ...
  ]
}

**In R:** After loading with `fromJSON()`, access variable properties as columns of a data frame `as.data.frame(define$columns)`

>>> SETUP: Before proceeding, please ask the user to provide:
1. The full file path to the dataset CSV file (e.g., `/path/to/dataset.csv`)
2. The full file path to the dataset definition JSON file (e.g., `/path/to/define-dataset.json`)

>>> TASK: Using R, **create and save a R script** named `02-pkdata_exploration.R` to perform graphical analysis on the provided NONMEM PK dataset. The workflow MUST include:

---

## Environment
- Use R programming language
- Set working directory to /workspaces/2026-page-workshop-materials/01_genai_coding_assistants
- Create a `02-results_exploration` folder (if not present) to store all outputs
- Use `ggplot2` for all plots
- Print informative messages at each major step of the workflow

## Demographics table

1. Create a summary statistics **descriptive table of demographic data** using covariates that MUST report {for continuous covariates: mean, median, SD and range OR for categorical covariates: number and % per group}. Include overall number of participants in the study. If the covariate is static over time for each subject, keep unique value per subject.
2. Save as CSV in the `02-results_exploration` folder.

## PK sampling scheme table

3. Create a summary statistics **descriptive table of PK observed data** (EVID=0 and MDV=0) reporting: 
  - Total no. of tobramycin courses	
  - Total no. of observed tobramycin concns per subject	{mean & SD}
  - Total no. of observed tobramycin concentrations	
  - Initial tobramycin dose {mean & SD}
  - Initial tobramycin dosage (normalized by body weight) {mean & SD}
  - Total no. of peak concentrations (0.5–2 h postdose, TSLD)
  - Tobramycin peak concentration value (0.5–2h postdose, TSLD) {mean & SD}
  - All these columns MUST be included

## Visualization of PK profiles

4. For EVID=0 and MDV=0 plot all individual concentration vs. time profiles in a single plot. 
  - Use the same color for all subjects
  - Use one line per subject omit legend
  - Save as `02-plot_conc_vs_time.png` in the `02-results_exploration` folder.
5. Repeat the previous plot with a log10 y-axis. Note that zero concentrations (if any) must be filtered out before log10 plot.
  - Save as `02-plot_conc_vs_time_log.png` in the `02-results_exploration` folder.
6. For EVID=0 and MDV=0 plot all individual concentration vs. time since last dosing event (TSLD, if not existing create the column) in a single plot. 
  - Use the same color for all subjects
  - Use separate lines for each single dose
  - Use log10 Y axis
  - Save as `02-plot_conc_vs_tsld_log.png` in the `02-results_exploration` folder.

## Covariate correlation analysis

8. Pairwise covariate comparison:
   - Produce one plot with inclusing all paired covariates
   - For categorical vs continuous covariates: Generate a boxplot with X axis the categorical covariate and Y axis the continuous covariate
   - For continuous vs continuous covariates: Generate a scatter plot with annotated correlation coefficient and linear regression line
   - Save as `02-plot_covariate_pairwise.png` in the `02-results_exploration` folder.

```

</details>

## Reporting Dataset Exploratory Analysis

Once the graphical exploration is complete, the next step is to summarise the findings in a structured report. This section provides two prompts for this task — a **basic version** and a more **curated version**. Try the basic prompt first: it is intentionally open-ended and gives the model significant freedom to decide the report structure, content, and formatting. This is a good exercise to observe how Copilot interprets an underspecified task.

<details><summary><b>Click to unfold and copy & paste the prompt</b></summary>

``` text
# Report results in a Word document

1. Acting as a pharmacometrician, provide a summary and interpretation of the exploratory results  stored in `02-results_exploration`.
2. Create a `reports` folder (if not existing) to store all outputs.
3. **Create and save** a Quarto document with the result interpretation (including plots). Use a regulatory compliant tone.
4. Render the Quarto document to Word format.

## Quarto Report Requirements
- The Quarto report must:
  - Include a summary table of all key findings (not just file references).
  - Provide a direct, written interpretation of the results, highlighting main findings, issues, and recommendations.
  - Place both the summary table and interpretation before plots and appendix.

### Example Quarto Structure

- Interpretation of Results
- Recommendations
- Demographics table
- PK sampling scheme table
- Visualizations

Please include only the sections provided in the example

```

</details>

### [Extra] Curated Reporting Prompt

The prompt above leaves most decisions to the model. Compare its output to what you get with the curated version below, which provides precise instructions for every aspect of the report: YAML front matter, table styling, narrative structure, inline R values, figure captions, and formatting rules. The key lesson is that **specificity drives reproducibility** — the more context and constraints you give the model, the closer the output will be to a submission-ready document with minimal manual editing.

<details><summary><b>Click to unfold and copy & paste the prompt</b></summary>

``` text
# Report Results in a Word Document

1. **Acting as a pharmacometrician**, provide a summary and interpretation of the exploratory results stored in `02-results_exploration`.
2. Create a `reports/` folder (if not already existing) to store all outputs.
3. **Create and save** a Quarto document (`.qmd`) with the result interpretation (including plots) inside `reports/`. Use a **regulatory-compliant tone**.
4. **Render** the Quarto document to Word (`.docx`) format.


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
- Sets `res_dir` as a relative path pointing to `02-results_exploration/` (relative to the `reports/` folder, e.g. `../02-results_exploration`)
- Reads **all result CSVs and tables** into named R objects (e.g. `demo`, `pk_tb`)
- Pre-computes all **derived scalar values** used in inline R code throughout the narrative (e.g. `n_subj`, `age_mean`, `age_sd`, `wt_mean`, `wt_sd`, `clcr_mean`, `clcr_sd`, `clcr_min`, `clcr_max`, `dose_mg_mean`, `dose_mgkg_mean`, `n_obs`, `obs_mean`, `obs_sd`, `n_peak`, `cmax_mean`, `cmax_sd`, `cmax_cv`, percentages for categorical variables like `pct_male`, `pct_female`, `pct_diabetes`, `pct_hypert`, `pct_naive`, etc.)
- Sets `flextable` defaults: font family `Calibri`, font size `10`, padding top/bottom `3`
- Defines the **flextable styling palette**:
  - Header background: `hdr_bg <- "#1F4E79"`, header text: `hdr_col <- "white"`
  - Alternating row background: `alt_bg <- "#EEF3F9"`

## Required Sections

Include **only** the five sections below, in this order:

### 1. Interpretation of Results

This section must open with a **Key Findings** subsection.

#### Key Findings

- Create a data frame with three columns: **Finding**, **Value**, **Assessment**
- Include rows summarising (using inline R values):
  - Study population (e.g., "300 subjects")
  - Age (mean ± SD, range using Unicode symbols: `\u00b1`, `\u2013`)
  - Body weight (mean ± SD, range)
  - Creatinine clearance (mean ± SD, range)
  - Sex distribution (% male / % female)
  - Key comorbidities prevalence (diabetes, hypertension, etc.)
  - Prior drug exposure (% with ≥1 prior course using `\u2265`)
  - Dosing regimen (number of doses, interval, route)
  - Weight-normalised dose (mean ± SD, CV%)
  - Total PK observations (with comma separator for thousands)
  - Observations per subject (mean ± SD)
  - Peak concentrations (mean ± SD, sample size with non-breaking space `\u202f`)
  - Inter-individual variability in Cmax (CV%)
- Render as `flextable` with:
  - `theme_booktabs()`
  - **Header styling**: background `hdr_bg`, text `hdr_col`, bold
  - **Alternating row background**: `alt_bg` on even rows (`seq(2, nrow(kf), by = 2)`)
  - Column widths: Finding `2.1"`, Value `1.9"`, Assessment `2.9"`
  - Font size: `9pt` throughout
  - Caption: *"Table 1. Key findings from the exploratory analysis."*


After the table, provide **three narrative subsections** with inline R values embedded throughout:

#### Population Characteristics
Describe the study population size, age distribution, sex distribution, body weight range, renal function (CLCR range and mean ± SD), and prevalence of clinically relevant comorbidities. Interpret the CLCR variability in the context of the drug's elimination pathway and its anticipated impact on clearance (CL) variability. Mention prior drug exposure prevalence and its clinical context (e.g., chronic infection cohorts).

#### Dosing Regimen
Report the dosing schedule (frequency, route, number of doses), weight-normalised dose (mean ± SD, CV%), and absolute dose range. Confirm whether the dosing was protocol-defined and comment on the degree of dose-weight proportionality. Explain the implication for covariate modelling: if dose is perfectly proportional to weight, weight explains all dose variability, and analysts should be mindful of collinearity when interpreting covariate effects on CL and V.

#### PK Sampling and Observed Concentrations
Report the total number of PK observations, observations per subject (mean ± SD), and confirm suitability for compartmental modelling. Report the number of peak concentration samples, the observed mean Cmax ± SD (with CV%), and compare to clinical targets if applicable. Comment on the multi-exponential decline pattern observed in individual concentration-time profiles and its consistency with the expected compartmental behaviour of the drug.

### 2. Recommendations

Provide **6 numbered recommendations** as concise, actionable paragraphs (not bullet points). Each recommendation should have a **bold lead sentence** followed by a brief justification. Cover:

1. Priority covariate for structural covariate modelling (e.g., CLCR on CL), with mechanistic rationale and suggested functional form
2. Evaluation of weight using allometric scaling on V (and CL if physiologically justified)
3. Assessment of secondary covariates (sex, comorbidities) after primary structural covariates are established
4. Investigation of prior drug exposure as a categorical covariate
5. Confirmation of sampling times or exposure targets before clinical interpretation
6. Recommendation to proceed to compartmental model development (one- vs. two-compartment, random effects structure)

Use inline R to embed numeric values (e.g., CLCR range, weight range, Cmax mean, prior exposure percentage) where relevant.

### 3. Demographics Table

- Read the demographics CSV into `demo` object
- Replace `NA` values with empty strings for clean display: `demo_display[is.na(demo_display)] <- ""`
- Render as `flextable` with:
  - `theme_booktabs()`
  - **Header styling**: background `hdr_bg`, text `hdr_col`, bold
  - **Alternating row background**: `alt_bg` on even rows
  - **Bold category headers**: Apply bold to rows where `Mean (SD)` and `n (%)` are empty, excluding "Overall N" and indented subcategories
  - Column widths: Variable `2.4"`, N `0.5"`, Mean (SD) `1.3"`, Median `0.9"`, Range `1.3"`, n (%) `1.0"`
  - Font size: `9pt`
  - Caption: *"Table 2. Baseline demographic and clinical characteristics (N = [n_subj])."* (use Unicode non-breaking space `\u202f`)
- Below the table, include footnote: *"Continuous variables: Mean (SD), Median, and Range reported. Categorical variables: n (%) per category."*

### 4. PK Sampling Scheme Table

- Read the PK sampling CSV into `pk_tb` object
- Render as `flextable` with:
  - `theme_booktabs()`
  - **Header styling**: background `hdr_bg`, text `hdr_col`, bold
  - **Alternating row background**: `alt_bg` on even rows
  - Column widths: Variable `4.6"`, Value `1.3"`
  - Font size: `9pt`
  - Caption: *"Table 3. Summary of PK sampling scheme and observed [drug] concentrations."*
- Below the table, include footnote: *"TSLD = time since last dose. Peak concentrations defined as observations collected 0.5–2 h post-dose."*

### 5. Visualizations

Include **4 figure chunks** using `knitr::include_graphics()`:

---
#| fig-cap: "Figure 1. Individual [drug] plasma concentration–time profiles (linear scale). Each line represents one subject. Grey spaghetti overlay illustrates the range of observed PK behaviour across [n_subj] subjects receiving [dosing regimen]."
#| out-width: "100%"
knitr::include_graphics("../02-results_exploration/02-plot_conc_vs_time.png")
---

---
#| fig-cap: "Figure 2. Individual [drug] plasma concentration–time profiles (log₁₀ scale). The log-linear representation reveals multi-exponential decline between doses and confirms the absence of zero or implausible concentration values."
#| out-width: "100%"
knitr::include_graphics("../02-results_exploration/02-plot_conc_vs_time_log.png")
---

---
#| fig-cap: "Figure 3. Individual [drug] concentration profiles overlaid by dose occasion versus time since last dose (TSLD, log₁₀ scale). Alignment by TSLD removes the time offset between dose events and allows direct visual comparison of within-interval PK behaviour across all dosing occasions. The consistent profile shape indicates limited between-occasion variability."
#| out-width: "100%"
knitr::include_graphics("../02-results_exploration/02-plot_conc_vs_tsld_log.png")
---

---
#| fig-cap: "Figure 4. Pairwise covariate correlation matrix. Lower and upper triangle panels for continuous variable pairs show individual data points, ordinary least-squares regression lines, and annotated Pearson correlation coefficients with associated p-values. Mixed panels (one continuous, one categorical variable) display box-and-whisker plots with the categorical variable on the x-axis. Diagonal panels show marginal distributions (density for continuous variables; frequency bars for categorical variables)."
#| out-width: "100%"
knitr::include_graphics("../02-results_exploration/02-plot_covariate_pairwise.png")
---

## Style & Formatting Rules

| Rule | Requirement |
|---|---|
| Tone | Regulatory-compliant: formal, precise, evidence-based |
| Inline values | Always use `` `r variable` `` — never hard-code numbers in prose |
| Unicode symbols | Use `\u00b1` (±), `\u2013` (–), `\u2265` (≥), `\u202f` (narrow no-break space) |
| Flextable style | `theme_booktabs()` on all tables; bold headers; alternating row backgrounds |
| Header styling | Background `#1F4E79`, text `white`, bold |
| Alternating rows | Background `#EEF3F9` on even rows |
| Font | Calibri, 9–10pt for tables, standard for body text |
| Section separators | Use `---` (horizontal rule) between major sections |
| Emphasis | Use `**bold**` for key findings, lead sentences in recommendations, and important values |
| Figure captions | Must include detailed interpretation with drug name and sample size |
| No echo | All chunks must have `echo: false`; suppress warnings and messages globally |
| Paths | All file paths relative to `reports/`; never use absolute paths |
| Figure numbering | Sequential: Figure 1, Figure 2, Figure 3, Figure 4 |
| Table numbering | Sequential: Table 1, Table 2, Table 3 |

```
</details>

---

<p align="center"><small><em>PAGE 2026 AI/ML Satellite Workshop · Dubrovnik · June 2, 2026</em></small></p>
<p align="center"><small><em>ISoP AI/ML Special Interest Group</em></small></p>