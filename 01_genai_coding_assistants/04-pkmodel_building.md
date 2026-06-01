# Model Building and Conversion Using GitHub Copilot's Agent Mode

This tutorial will guide you through the process of creating a new NONMEM model file, writing the initial code with the help of GitHub Copilot, modifying and enhancing the model, and converting it to `nlmixr`.

## Building a PopPK model using NONMEM

1. Open a new GitHub Copilot chat window in VS Code by clicking on the logo at the top right panel and switch to `Agent` mode.
2. One after the other, copy and paste the entire prompts that are provided below.
3. These **prompts are designed to ask the user via the chat window to provide the full file paths** for the dataset and definition files. Use these paths:
   - **Dataset file:** `/workspaces/2026-page-workshop-materials/00_data/tobramycin_pk.csv`
   - **Definition file:** `/workspaces/2026-page-workshop-materials/01_genai_coding_assistants/.utils/define-pkdataset.json`

<details><summary><b>Click to unfold and copy & paste the prompt</b></summary>

```text
# Pharmacometric NONMEM Model Building

>>> ROLE: Act as an expert pharmacometrician in PopPK analysis and NONMEM modeling software. 

>>> DATA INFO: For a description of each column in the dataset read the dataset mapping from the JSON file provided in the repository. This file contains descriptions of all columns in the dataset, including their names, types, and roles (e.g., ID, TIME, EVID, observations, covariates).

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

>>> NONMEM INFO: For NONMEM model building specifications, look for the JSON file `/workspaces/2026-page-workshop-materials/01_genai_coding_assistant/.utils/define-advan.json` in the repository. This JSON file contains the ADVAN subroutine selections, differential equation requirements and model structure details.

>>> SETUP: Before proceeding, please ask the user to provide:
1. The full file path to the dataset CSV file (e.g., `/path/to/dataset.csv`)
2. The full file path to the dataset definition JSON file (e.g., `/path/to/define-dataset.json`)
3. Note that the dataset definition JSON file and the ADVAN subroutine (already given in this prompt) JSON file serve for different purposes and both should be considered.

>>> TASK: Using NONMEM, **create and save a NONMEM control file**. The model MUST include:

---

1. two-compartment model 
2. intravenous administration
3. linear clearance
4. add log-normal IIV to all PK parameters
5. combined residual error
6. `$INPUT` and `$DATA` should be adapted to the PK dataset
7. For `$DATA` use IGNORE=@ and absolute dataset path 
8. use `ADVAN13` and write the differential equations in `$DES` block
9. create a `models` folder (if not present) to store the model file
10. save the model file using `*.con` extension 
11. If any doubts or need additional clarity prompt the user to provide further information. If multiple clarifications are needed, ask one by one. 
12. Once finished, review your code for dimensional consistency and common sign errors in the binding equations. List any potential pitfalls you found

```

</details>

## Converting the NONMEM model to `nlmixr`

Once the NONMEM control file has been created, use the following prompt to convert it to an `nlmixr` model in R.

<details><summary><b>Click to unfold and copy & paste the prompt</b></summary>

```text
# Pharmacometric NONMEM to nlmixr Conversion

>>> ROLE: Act as an expert pharmacometrician with deep knowledge of both NONMEM and the R package `nlmixr2`.

>>> MODEL INFO: Read the NONMEM control file saved in the `models/` folder of this repository. Use it as the source model to convert.

>>> TASK: **Convert the NONMEM control file to an equivalent `nlmixr2` model in R**. The conversion MUST:

---

1. Faithfully reproduce the model structure (compartments, routes of administration, clearance)
2. Translate all differential equations from `$DES` into the `model()` block using `nlmixr2` syntax
3. Translate IIV definitions from `$OMEGA` using `ini()` block with appropriate `eta` terms
4. Translate residual error from `$SIGMA` into the correct `nlmixr2` error model
5. Map all `$THETA` initial estimates into the `ini()` block
6. Ensure the `$INPUT` column mapping is reflected in the `nlmixr2` dataset expectations
7. Save the resulting R script in the `models/` folder with a `*.R` extension
8. If any doubts or need additional clarity prompt the user to provide further information. If multiple clarifications are needed, ask one by one.
9. Once finished, review the converted model for correctness and list any potential issues or differences in behaviour between the NONMEM and `nlmixr2` implementations

```

</details>

---

<p align="center"><small><em>PAGE 2026 AI/ML Satellite Workshop · Dubrovnik · June 2, 2026</em></small></p>
<p align="center"><small><em>ISoP AI/ML Special Interest Group</em></small></p>