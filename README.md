# TCGA-PAAD Tumor Grade Prediction

## Project Overview

This project investigates whether gene expression profiles can distinguish between low-grade (G1/G2) and high-grade (G3/G4) pancreatic tumors using data from The Cancer Genome Atlas Pancreatic Adenocarcinoma (TCGA-PAAD) cohort.

The analysis includes:

- Preprocessing gene expression and clinical data
- Summary of baseline demographic and clinical characteristics by histologic grade
- Principal Component Analysis (PCA) of gene expression profiles
- Tumor grade prediction using Logistic Regression, Elastic Net, and Random Forest

## Data

Gene expression and clinical data were obtained from the **TCGA-PAAD cohort** through the [UCSC Xena repository](https://xena.ucsc.edu/).

The original datasets include:

- **Gene expression:** RNA-seq expression profiles (RSEM normalized counts, log2-transformed)
- **Clinical data:** Patient demographics and histologic tumor grade information

The processed dataset is stored in `data/paad_analysis_data.rds`.
The original data can be downloaded using `R/01_data_preprocessing.R`.

## Repository Structure

```text
tcga-paad-grade-prediction/
├── R/
│   ├── 01_data_preprocessing.R
│   ├── 02_summary_table.R
│   ├── 03_pca_figure.R
│   ├── 04_prediction_models.R
│   └── 05_render_report.R
├── data/
│   └── paad_analysis_data.rds
├── data_raw/
├── output/
├── final_report.Rmd
├── Makefile
├── README.md
└── .gitignore
```

### Description of Files

| File | Description |
|---|---|
| `R/01_data_preprocessing.R` | Downloads and preprocesses TCGA-PAAD expression and clinical data |
| `R/02_summary_table.R` | Generates Table 1: Baseline patient characteristics by histologic grade |
| `R/03_pca_figure.R` | Generates Figure 1: PCA visualization of gene expression profiles |
| `R/04_prediction_models.R` | Trains and evaluates Logistic Regression, Elastic Net, and Random Forest models; generates Table 2 |
| `R/05_render_report.R` | Renders the final HTML report |
| `data/paad_analysis_data.rds` | Processed dataset used for analysis |
| `final_report.Rmd` | Generate final report |
| `Makefile` | Defines dependencies and commands for reproducing the analysis |

## Analysis Workflow

1. **Data Preprocessing:** Download and integrate TCGA-PAAD clinical and gene expression data, retain primary tumor samples, and classify tumors into low-grade (G1/G2) and high-grade (G3/G4) groups.
2. **Descriptive Analysis:** Summarize demographic and clinical characteristics across histologic grade groups.
3. **PCA:** Visualize transcriptomic variation using the 500 genes with the highest expression variance.
4. **Predictive Modeling:** Split samples into training (75%) and test (25%) sets, fit three classification models, and evaluate their out-of-sample performance.
5. **Report Generation:** Combine analytical results into a reproducible HTML report.

## Reproducing the Analysis

### 1. Requirements
The analysis requires R and the following R packages:

```r
install.packages(c(
  "here", "data.table", "dplyr", "tidyr",
  "ggplot2", "knitr", "kableExtra",
  "rmarkdown", "caret", "pROC",
  "glmnet", "randomForest"
))
```

### 2. Generate the Final Report

Clone the repository and navigate to the project directory. Then run the following command.
```bash
make
```

The Makefile runs the necessary analysis scripts and generates **`final_report.html`** in the project root directory.

To remove generated analysis outputs and the HTML report, run:

```bash
make clean
```

To rebuild the report after cleaning:

```bash
make
```

## Required Table and Figure

**Table 1: Baseline Characteristics by Histologic Grade**

- Source code: `R/02_summary_table.R`
- Output: `output/summary_table.rds`

**Figure 1: Principal Component Analysis of Gene Expression**

- Source code: `R/03_pca_figure.R`
- Outputs: `output/pca_plot.rds` and `output/pca_plot.png`

**Table 2: Machine Learning Model Performance**

- Source code: `R/04_prediction_models.R`
- Output: `output/model_comp_table.rds`

All tables and figures are incorporated into `final_report.Rmd`.
