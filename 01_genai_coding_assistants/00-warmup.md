# Getting Started — Inline Mode with GitHub Copilot

This tutorial introduces GitHub Copilot's **inline interaction mode** — a lightweight, in-editor experience that lets you generate and edit code directly inside a file without switching to a separate chat panel. It is a great way to warm up before moving on to the more powerful Agent Mode used in the other tutorials.

You will create a simple R script that generates an artificial dataset and plots **body weight vs. BMI** using `ggplot2`.

---

## What is Inline Mode?

Unlike Agent Mode (which runs in a separate chat panel and can browse files, run code, and chain multiple steps), **inline mode** works directly in the editor:

- Open any file and press `Ctrl+I` (Windows/Linux) or `Cmd+I` (Mac) to open the inline Copilot prompt
- Type your request and Copilot will insert or replace code at the cursor position
- You can accept, discard, or iterate on the suggestion without leaving the file

> **Note:** Use inline mode for focused, single-step code generation tasks. For multi-step workflows (like the ones in tutorials 01–03), switch to Agent Mode.

---

## Step 1 — Create an Empty R Script

1. In VS Code, create a new file called `warmup.R` inside the `01_genai_coding_assistants/` folder
2. Open the file in the editor — it should be completely empty
3. Click somewhere inside the file to place your cursor

---

## Step 2 — Generate an Artificial Dataset

Place your cursor at the top of the empty file. Press `Ctrl+I` / `Cmd+I` to open the inline prompt and paste the following:

```text
Create an artificial dataset in R with 100 subjects. Each subject should have a randomly generated body weight (WT) in kg (normally distributed, mean 70, sd 15, rounded to 1 decimal) and height (HT) in meters (normally distributed, mean 1.70, sd 0.10, rounded to 2 decimals). Compute BMI as WT / HT^2 rounded to 1 decimal. Store everything in a data frame called df.
```

Accept the suggestion. Your file should now contain a code block that creates `df`.

---

## Step 3 — Add a Basic Scatter Plot

Place your cursor **below** the dataset block. Press `Ctrl+I` / `Cmd+I` and paste the following:

```text
Using ggplot2, add a basic scatter plot of body weight (WT, x-axis) vs BMI (y-axis) from df, with black points. Store the plot in a variable called p.
```

Accept the suggestion.

---

## Step 4 — Annotate with a Linear Regression Line

**Highlight the scatter plot code block** you just accepted to focus Copilot's attention on it. Then press `Ctrl+I` / `Cmd+I` and paste:

```text
Add a linear regression trend line to p using geom_smooth with method lm, colour blue, and no confidence interval band. Annotate the plot with the Pearson correlation coefficient (r = ...) using geom_text, placed in the top-left corner of the plot, also in blue.
```

Accept the suggestion.

---

## Step 5 — Add Axis Labels and Title

Place your cursor **below** the previous block. Press `Ctrl+I` / `Cmd+I` and paste:

```text
Add axis labels to p: x-axis "Body Weight (kg)", y-axis "BMI (kg/m²)", and a plot title "Body Weight vs BMI". Use a minimal theme.
```

Accept the suggestion.

---

## Step 6 — Save the Plot to a File

Place your cursor at the end of the file. Press `Ctrl+I` / `Cmd+I` and paste:

```text
Save the plot to a file called "bmi_vs_wt.png" in a subfolder called `00-results_warmup` at `/workspaces/2026-page-workshop-materials/01_genai_coding_assistants` (create it if it does not exist) using ggsave with width = 7 and height = 5 inches.
```

Accept the suggestion.

---


> **Tip:** If a suggestion is not quite right, do not accept it. Press `Ctrl+I` / `Cmd+I` again and refine your prompt — for example, adding more detail about axis labels or colour aesthetics. Inline mode is iterative.
