here::i_am("R/01_data_preprocessing.R")

library(data.table)
library(dplyr)

raw_data_dir <- here::here("data_raw")
data_dir <- here::here("data")
if (!dir.exists(raw_data_dir)) {
  dir.create(raw_data_dir, recursive = TRUE)
}
if (!dir.exists(data_dir)) {
  dir.create(data_dir, recursive = TRUE)
}

# ----------------------------------------
# Download TCGA-PAAD data
# ----------------------------------------
expr_url <- paste0(
  "https://tcga-xena-hub.s3.us-east-1.amazonaws.com/",
  "download/TCGA.PAAD.sampleMap%2FHiSeqV2.gz"
)

clin_url <- paste0(
  "https://tcga-xena-hub.s3.us-east-1.amazonaws.com/",
  "download/TCGA.PAAD.sampleMap%2FPAAD_clinicalMatrix"
)

expr_dest <- here::here(
  "data_raw", "tcga_paad_expression.tsv.gz"
)

clin_dest <- here::here(
  "data_raw", "tcga_paad_clinical.tsv"
)

if (!file.exists(expr_dest)) {
  download.file(expr_url, expr_dest, mode = "wb")
}

if (!file.exists(clin_dest)) {
  download.file(clin_url, clin_dest, mode = "wb")
}

# ----------------------------------------
# Load raw data
# ----------------------------------------
expr_raw <- fread(expr_dest)
clin_raw <- fread(clin_dest)

stopifnot(
  "sampleID" %in% names(clin_raw),
  "neoplasm_histologic_grade" %in% names(clin_raw)
)

# ----------------------------------------
# Histologic Grade Binary Labeling (G1/G2 & G3/G4) 
# ----------------------------------------
clin_label <- clin_raw %>%
  filter(!is.na(neoplasm_histologic_grade) & 
           # Filter out GX, which means the grade cannot be assessed by the pathologist examining the sample. 
           neoplasm_histologic_grade %in% c("G1", "G2", "G3", "G4")) %>%
  mutate(
    grade_group = case_when(
      neoplasm_histologic_grade %in% c("G1", "G2") ~ "Low_Intermediate",
      neoplasm_histologic_grade %in% c("G3", "G4") ~ "High"
    ),
    grade_group = factor(grade_group, levels = c("Low_Intermediate", "High"))
  )


# ----------------------------------------
# Match clinical and gene expression samples
# ----------------------------------------
sample_idx <- intersect(colnames(expr_raw), clin_label$sampleID)

clin_data <- clin_label %>%
  filter(sampleID %in% sample_idx) %>%
  arrange(match(sampleID, sample_idx)) %>%
  distinct(sampleID, .keep_all = TRUE)

expr_data <- expr_raw[, ..sample_idx]

# ----------------------------------------
# Save processed data
# ----------------------------------------
analysis_data <- list(
  expression = expr_data,
  clinical = clin_data
)

saveRDS(
  analysis_data,
  file = here::here("data", "paad_analysis_data.rds")
)

cat("Data preprocessing completed.\n")
cat("Number of samples:", nrow(clin_data), "\n")
cat("Number of genes:", nrow(expr_data), "\n")
cat("Grade distribution:\n")
print(table(clin_data$grade_group))


