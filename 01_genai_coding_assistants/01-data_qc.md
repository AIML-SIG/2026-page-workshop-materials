# Data Quality Checks Using GitHub Copilot's Agent Mode

This tutorial provides examples of data quality checks and demonstrates how to use GitHub Copilot to perform these tasks efficiently. By using GitHub Copilot to assist with these data analysis tasks, you can save time and improve the efficiency of your data analysis workflow.

## Performing Data Quality Checks

1. Open a new GitHub Copilot chat window in VS Code by clicking on the logo at the top right panel and switch to `Agent` mode.
2. One after the other, copy and paste the entire prompts that are provided below.
3. These **prompts are designed to ask the user via the chat window to provide the full file paths** for the dataset and definition files. Use these paths:
   - **Dataset file:** `/workspaces/2026-page-workshop-materials/00_data/tobramycin_pk.csv`
   - **Definition file:** `/workspaces/2026-page-workshop-materials/01_genai_coding_assistants/.utils/define-pkdataset.json`

<details><summary><b>Click to unfold and copy & paste the prompt</b></summary>

```text
# Pharmacometric Data Sanity Check

>>> ROLE: Act as an expert pharmacometrician in performing nonmem PopPK dataset quality checks

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

>>> TASK: Using R, **create and save a script** named `01-data_qc.R` to perform comprehensive data sanity checks on the provided NONMEM PK dataset. The workflow MUST include:

---

## Environment
- Use R programming language
- Set working directory to /workspaces/2026-page-workshop-materials/01_genai_coding_assistants
- Create a `01-results_qc` folder (if not present) to store all outputs.

## Data Checks
1. Count the number of unique individuals (`ID`).
2. For each individual, count the number of administered doses (`EVID == 1`).
3. Give and overview of different dosing regimens administered reporting dosing amount (`AMT` when `EVID == 1`) and frequency.
4. For each individual, count the number of concentration samples (`EVID == 0` and `MDV == 0`).
5. For each individual, check for duplicated concentrations and/or sampling time points.
6. Identify any negative concentration or dosing records.
7. Identify missing concentrations (`EVID == 0` and `MDV == 1`).
8. Identify missing covariate values 
9. Check if covariate values are static or varying over time.
10. TIME is monotonically increasing within each subject
11. Identify dosing EVID=1 records with missing AMT
12. Identify observation EVID=0 records with non-missing DV but MDV=1
13. Flag Zero concentrations in observed records
14. Flag observations before first dose (pre-dose samples)
15. Save all results as CSV tables in the `01-results_qc` folder.

## Quality Control
16. Check there are no quotation marks (single nor double) on the header row.
17. Do NOT implement any additional quality checks.

```

</details>



## Reporting Data Quality 

Now let's try to get an interpretation of the results. **This section will show the most variability** between runs, as report writing is more creative and subjective than data processing. Report structure, writing style, and presentation can differ between runs. Focus on whether the content is scientifically accurate and complete.

### Part A: Quick & Practical Reporting Prompt

🎯 **Learning objective:** Experience how a simple, realistic reporting prompt performs. Notice what works well and what could be improved.


<details><summary><b>Click to unfold and copy & paste the prompt</b></summary>

``` text
# Report results in a Word document
1. Acting as a pharmacometrician expert in popPK, provide a summary and interpretation of the dataset quality check results stored in `01-results_qc`.
2. Create a `reports` folder (if not existing) to store all outputs.
3. **Create and save** a Quarto document with the quality assessment
4. Render the Quarto document to Word format.

## Quarto Report Requirements
The Quarto report MUST include:
- A description of all key findings (not just file references)
- A summary table whether the respective check was or not successful
- The summary table should be colour-coded status tables (✓=green/✗=red).
- Provide a direct, written interpretation of the assessment, highlighting main findings, issues, and recommendations.

### Example Quarto Structure

- Data-Check Summary Table
- Detailed Quality Assessment Report
- Recommendations
- Is this a valid nonmem dataset?

Please include only the sections provided in the example

```

</details>

🔍 **Reflection questions before moving to Part B:**
- How was the report structured?
- Were all key findings clearly presented?
- What would you change in the prompt to improve the report quality?

---

### Part B: Curated Reporting Prompt

🎯 **Learning objective:** See how a more detailed, technically precise reporting prompt produces more consistent structure, style, and content organization. Notice the trade-off: more control requires more effort in prompt design.

<details><summary><b>Click to unfold and copy & paste the prompt</b></summary>

``` text
# Report Results in a Word Document

1. **Acting as a pharmacometrician expert in popPK**, provide a summary and interpretation of the dataset quality check results stored in `01-results_qc`.
2. Create a `reports/` folder (if not already existing) to store all outputs.
3. **Create and save** a Quarto document (`.qmd`) with the quality assessment inside `reports/`.
4. **Render** the Quarto document to Word (`.docx`) format.


## Quarto Document — YAML Header

The document must use the following YAML front matter:

---
title: "[Drug] PopPK Dataset — Quality Control Report"
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
- Sets `qc_dir` as a relative path pointing to `01-results_qc/` (relative to the `reports/` folder, e.g. `../01-results_qc`)
- Reads **all QC result CSVs** into named R objects
- Pre-computes all **derived scalar values** used in inline R code throughout the narrative (e.g. `n_subjects`, `obs_min`, `obs_max`, `obs_med`, `amt_min`, `amt_max`, `n_amt_levels`, etc.)
- Defines the **colour palette** for flextable formatting:
  - PASS: background `#C6EFCE`, text `#276221`
  - FAIL: background `#FFC7CE`, text `#9C0006`
  - INFO: background `#DEEAF1`, text `#1F4E79`


## Required Sections

Include **only** the four sections below, in this order:

### 1. Data-Check Summary Table

- Render a `flextable` summarising all QC checks from `qc_summary.csv`
- Classify each row as **PASS**, **FAIL**, or **INFO** based on `check_id` and `n_flagged`
- Use Unicode symbols: ✓ (`\u2713`) for PASS, ✗ (`\u2717`) for FAIL, ℹ (`\u2139`) for INFO
- Apply **row-level background and text colour** using the palette defined in setup
- Column widths: Check `0.5"`, Description `3.2"`, Result `2.0"`, Status `0.5"`
- Apply `theme_booktabs()`, bold headers, centred status column, font size 10pt throughout
- Add caption: *"Table 1. Summary of dataset quality control checks."*
- Below the table, include a **legend line** using inline R to render the Unicode symbols:

  *Legend: ℹ = Informational count; ✓ = PASS — no issues detected; ✗ = FAIL — issues flagged.*

### 2. Detailed Quality Assessment Report

Provide a **fully written, narrative interpretation** — not a list of file references. Use **inline R** (`` `r ...` ``) throughout to embed computed values directly in the prose. Structure the narrative with the following subsections:

#### Dataset Overview
Describe the number of unique subjects, the drug, the type of data (plasma concentration-time profiles), the NONMEM structural columns present, and the covariate set. State suitability for PopPK analysis.

#### Structural Integrity and Header
Comment on header formatting (absence of quotes, lowercase column names), correct use of the NONMEM missing data indicator (`.`), and absence of structural issues.

#### Time Records
Confirm whether `TIME` is monotonically non-decreasing for all subjects, and explain why this matters for NONMEM's ODE solver.

#### Dosing Records
Report number of doses per subject, route of administration (populate `RATE`/`DURATION` if IV infusion), inter-dose interval, range and number of distinct dose amounts. Interpret the dose variability in clinical context (e.g. TDM-guided dosing, weight/renal adjustment). Confirm absence of missing `AMT` on `EVID = 1` records.

#### Observation Records
Report the range and median of concentration samples per subject. Enumerate all observation-level checks that returned zero flagged records as a **bullet list**, including:
- No duplicated time points within individuals
- No duplicate concentration records
- No negative or zero observed concentrations
- No pre-dose concentration samples
- No contradictory `MDV` flags
- No `EVID = 0, MDV = 1` records

#### Covariate Assessment
State the number of covariates, list them, confirm completeness (zero missing values), and confirm all are static (time-invariant). Embed a **covariate summary flextable** (Table 2) with columns: Covariate, Variability (Static/Time-varying), Missing records. Apply PASS background colour to all rows. Caption: *"Table 2. Covariate completeness and variability summary."* After the table, highlight the most PK-relevant covariates and provide a brief pharmacokinetic rationale (e.g. renal elimination → `clcr` as candidate covariate on CL).

### 3. Recommendations

Provide **4 numbered recommendations** as concise, actionable paragraphs (not bullet points). Each recommendation should have a **bold lead sentence** followed by a brief justification. Cover:

1. Priority covariate(s) for structural covariate modelling, with mechanistic rationale
2. Exploration of the dose individualisation basis (graphical EDA of dose vs. covariates)
3. Verification of the intended sampling design (peak/trough/mid-interval coverage)
4. A clear statement on whether data cleaning is required before NONMEM submission

Use inline R to embed numeric values (e.g. dose range, sample count range) where relevant.

### 4. Is this a valid NONMEM dataset?

- Open with a **bold one-sentence verdict** (Yes/No + justification)
- Render a `flextable` (Table 3) with columns: Criterion, Detail, Status
- Include **8 standard validity criteria**:
  1. Essential NONMEM columns present
  2. Missing data encoded correctly
  3. Header free of quotation marks
  4. No negative or zero concentrations
  5. TIME monotonically non-decreasing
  6. EVID/MDV flags consistent
  7. No duplicate records
  8. All covariate data complete
- All rows should be PASS (green), with ✓ in the Status column
- Column widths: Criterion `2.2"`, Detail `3.3"`, Status `0.5"`
- Caption: *"Table 3. NONMEM dataset validity assessment."*
- Close with a **bold concluding sentence** confirming the dataset is ready for PopPK modelling

## Style & Formatting Rules

| Rule | Requirement |
|---|---|
| Inline values | Always use `` `r variable` `` — never hard-code numbers in prose |
| Flextable style | `theme_booktabs()` on all tables; bold headers; font size 10pt |
| Colour coding | PASS/FAIL/INFO palette defined once in setup, reused across all tables |
| Section separators | Use `---` (horizontal rule) between major sections |
| Emphasis | Use `**bold**` for key findings, verdicts, and lead sentences in recommendations |
| No echo | All chunks must have `echo: false`; suppress warnings and messages globally |
| Paths | All file paths relative to `reports/`; never use absolute paths |
```

</details>

🔍 **Reflection questions after completing both parts:**
- How did the report structure differ between Part A and Part B?
- When would you use the simple prompt vs. the curated one in your real work?
- What are the trade-offs between prompt simplicity and report quality control?
- How do you decide when an AI-generated report is "good enough"?

🔍 **Final reflection:**
- How did your report compare to the solution example?
- What elements were well-covered vs. missing?
- How would you refine the reporting prompt for your specific needs?

---

<p align="center"><small><em>PAGE 2026 AI/ML Satellite Workshop · Dubrovnik · June 2, 2026</em></small></p>
<p align="center"><small><em>ISoP AI/ML Special Interest Group</em></small></p>