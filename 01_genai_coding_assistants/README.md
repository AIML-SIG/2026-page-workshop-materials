# GenAI Coding Assistants — Workshop Module

This module introduces GitHub Copilot's inline and Agent Mode for pharmacometric data analysis tasks. It provides step-by-step tutorials with ready-to-use prompts, starting from a simple inline warm-up exercise and progressing to data quality checks, PK/PD exploratory analysis, and an optional extra model-building exercise.

> ⚠️ **Important Note on AI Output Variability**
> These exercises use GitHub Copilot in Agent mode, which is powered by a Large Language Model (LLM). Unlike session 2 and 3 coding exercises, **outputs will vary between runs** — this is normal and expected behavior. Do not worry if your results look different from the solution files; focus on whether your outputs are **scientifically sound and complete**.

> 💡 **Heads up:** During the exercises, GitHub Copilot may ask for permission to access folders or execute functions. This is expected behavior — you can safely allow these requests to proceed.

---

## Tutorial Overview

| File | Topic |
|---|---|
| [00-warmup.md](00-warmup.md) | Inline Mode Warm-up |
| [01-data_qc.md](01-data_qc.md) | Data Quality Checks |
| [02-pkdata_exploration.md](02-pkdata_exploration.md) | PK Data Exploratory Analysis |
| [03-pddata_exploration.md](03-pddata_exploration.md) | PD Data Exploratory Analysis |
| [04-pkmodel_building.md](04-pkmodel_building.md) | **[EXTRA]** PK Model Building and Conversion |


---

## Utilities (`.utils/`)

The `.utils/` folder contains machine-readable configuration files used by the Copilot prompts to provide structured context about the dataset and NONMEM model specifications.

| File | Description |
|---|---|
| [`define-pkdataset.json`](.utils/define-pkdataset.json) | Column-level description of the PopPK dataset (`00_data/tobramycin_pk.csv`): column names, types, roles (ID, TIME, EVID, covariates, etc.), and NONMEM relevance flags |
| [`define-pddataset.json`](.utils/define-pddataset.json) | Column-level description of the PKPD dataset (`00_data/tobramycin_pd.csv`): column names, types, roles (pkmetrics, covariates, etc.) |
| [`define-advan.json`](.utils/define-advan.json) | NONMEM ADVAN subroutine reference table: model descriptions, compartment structures, parameterization subroutines, and basic parameters for all built-in PREDPP models |

These files are referenced in the Copilot prompts, allowing the agent to ground its code generation in dataset- and model-specific facts without requiring manual copy-paste of metadata.

---

<p align="center"><small><em>PAGE 2026 AI/ML Satellite Workshop · Dubrovnik · June 2, 2026</em></small></p>
<p align="center"><small><em>ISoP AI/ML Special Interest Group</em></small></p>
