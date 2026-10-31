here::i_am("R/02_summary_table.R")

library(dplyr)
library(tidyr)

output_dir <- here::here("output")

if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

# ----------------------------------------
# Load processed data
# ----------------------------------------
analysis_data <- readRDS(
  here::here("data", "paad_analysis_data.rds")
)

clin_data <- analysis_data$clinical

# ----------------------------------------
# Format functions
# ----------------------------------------
format_n_pct <- function(x) {
  n_valid <- sum(!is.na(x))
  n_case <- sum(x, na.rm = TRUE)
  
  if (n_valid == 0) {
    return("NA")
  }
  
  sprintf(
    "%d (%.1f%%)",
    n_case,
    100 * n_case / n_valid
  )
}

format_mean_sd <- function(x) {
  x <- suppressWarnings(as.numeric(x))
  x <- x[!is.na(x)]
  
  if (length(x) < 2) {
    return("NA")
  }
  
  sprintf(
    "%.1f (%.1f)",
    mean(x),
    sd(x)
  )
}

# ----------------------------------------
# Baseline characteristics table
# ----------------------------------------
summary_table <- clin_data %>%
  group_by(grade_group) %>%
  summarise(
    `Sample Count (n)` = as.character(n()),
    
    `Age at Diagnosis, Mean (SD)` =
      format_mean_sd(
        age_at_initial_pathologic_diagnosis
      ),
    
    `Male, n (%)` =
      format_n_pct(
        ifelse(
          is.na(gender),
          NA,
          toupper(gender) == "MALE"
        )
      ),
    
    `Female, n (%)` =
      format_n_pct(
        ifelse(
          is.na(gender),
          NA,
          toupper(gender) == "FEMALE"
        )
      ),
    
    `Early Pathologic Stage (I), n (%)` =
      format_n_pct(
        ifelse(
          is.na(pathologic_stage),
          NA,
          pathologic_stage %in% c(
            "Stage I", "Stage IA", "Stage IB"
          )
        )
      ),
    
    `Intermediate Pathologic Stage (II), n (%)` =
      format_n_pct(
        ifelse(
          is.na(pathologic_stage),
          NA,
          pathologic_stage %in% c(
            "Stage II", "Stage IIA", "Stage IIB"
          )
        )
      ),
    
    `Advanced Pathologic Stage (III-IV), n (%)` =
      format_n_pct(
        ifelse(
          is.na(pathologic_stage),
          NA,
          pathologic_stage %in% c(
            "Stage III", "Stage IIIA", "Stage IIIB",
            "Stage IIIC", "Stage IV"
          )
        )
      ),
    
    .groups = "drop"
  ) %>%
  pivot_longer(
    cols = -grade_group,
    names_to = "Clinical Characteristic",
    values_to = "Value"
  ) %>%
  pivot_wider(
    names_from = grade_group,
    values_from = Value
  ) %>%
  select(
    `Clinical Characteristic`,
    Low_Intermediate,
    High
  )

# ----------------------------------------
# Save table
# ----------------------------------------
saveRDS(
  summary_table,
  file = here::here("output", "summary_table.rds")
)
