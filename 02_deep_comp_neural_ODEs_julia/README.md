# Deep Compartment Models & Neural ODEs — Workshop Module

This module introduces deep learning–based pharmacokinetic modeling in Julia, covering Deep Compartment Models (DCMs), Neural ODEs, and hybrid Universal Differential Equation (UDE) approaches applied to a tobramycin population PK case study.

---

## Tutorial Overview

| File | Topic |
|---|---|
| [hands-on/workshop.qmd](hands-on/workshop.qmd) | Hands-on tutorial: DCMs, Neural ODEs, hybrid UDEs, and model interpretation |

---

## Source Code (`src/`)

The `src/` folder contains Julia source files that implement the core modeling utilities used throughout the workshop.

| File | Description |
|---|---|
| [`src/data/load.jl`](src/data/load.jl) | Data loading helper — reads `tobr-simulation.csv` into a `Population` object with covariates `[wt, age, sex, crcl]` |
| [`src/model/helpers.jl`](src/model/helpers.jl) | Utility functions: `InitialScale` layer, weight transfer between models, and population-to-dataframe conversion |
| [`src/model/hybrid-ude.jl`](src/model/hybrid-ude.jl) | `HybridModel` definition combining a covariate encoder with a Neural ODE for hybrid UDE modeling |


---

<p align="center"><small><em>PAGE 2026 AI/ML Satellite Workshop · Dubrovnik · June 2, 2026</em></small></p>
<p align="center"><small><em>ISoP AI/ML Special Interest Group</em></small></p>
