here::i_am("R/03_pca_figure.R")

output_dir <- here::here("output")

if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

library(ggplot2)

# ----------------------------------------
# Load processed data
# ----------------------------------------
analysis_data <- readRDS(
  here::here("data", "paad_analysis_data.rds")
)

expr_data <- analysis_data$expression
clin_data <- analysis_data$clinical

# ----------------------------------------
# Select top 500 variable genes
# ----------------------------------------
gene_vars <- apply(expr_data, 1, var, na.rm = TRUE)
expr_data_filter <- expr_data[!is.na(gene_vars) & gene_vars > 0, ]
top500_idx <- order(gene_vars[!is.na(gene_vars) & gene_vars > 0], decreasing = TRUE)[1:500]
expr_top500 <- expr_data_filter[top500_idx, ]

# ----------------------------------------
# Principal Component Analysis
# ----------------------------------------
pca_fit <- prcomp(t(expr_top500), center = TRUE, scale. = TRUE)
var_exp <- 100 * pca_fit$sdev^2 / sum(pca_fit$sdev^2)
pca_df <- data.frame(
  SampleID = colnames(expr_top500),
  PC1 = pca_fit$x[, 1],
  PC2 = pca_fit$x[, 2],
  Grade = clin_data$grade_group
)

# ----------------------------------------
# PCA plot
# ----------------------------------------
pca_plot <- ggplot(
  pca_df,
  aes(x = PC1, y = PC2, color = Grade, fill = Grade)
) +
  stat_ellipse(
    geom = "polygon",
    alpha = 0.15,
    level = 0.85,
    show.legend = FALSE
  ) +
  geom_point(
    size = 3.2,
    alpha = 0.85,
    shape = 21,
    color = "black",
    stroke = 0.4
  ) +
  scale_color_manual(
    name = "Histologic Grade",
    values = c(
      "Low_Intermediate" = "#1f78b4",
      "High" = "#e31a1c"
    ),
    labels = c(
      "Low_Intermediate" = "Low Grade (G1/G2)",
      "High" = "High Grade (G3/G4)"
    )
  ) +
  scale_fill_manual(
    name = "Histologic Grade",
    values = c(
      "Low_Intermediate" = "#1f78b4",
      "High" = "#e31a1c"
    ),
    labels = c(
      "Low_Intermediate" = "Low Grade (G1/G2)",
      "High" = "High Grade (G3/G4)"
    )
  ) +
  labs(
    title = paste(
      "Figure 1. PCA",
      "of TCGA-PAAD Gene Expression"
    ),
    subtitle = paste0(
      "Based on the top ",
      nrow(expr_top500),
      " high-variance genes"
    ),
    x = sprintf(
      "PC 1 (%.1f%% Variance Explained)",
      var_exp[1]
    ),
    y = sprintf(
      "PC 2 (%.1f%% Variance Explained)",
      var_exp[2]
    ),
    caption = paste(
      "Source: TCGA-PAAD (UCSC Xena);",
      "Ellipses represent 85% confidence regions."
    )
  ) +
  theme_classic(base_size = 12) +
  theme(
    plot.title = element_text(
      face = "bold",
      size = 13
    ),
    plot.subtitle = element_text(
      color = "gray30",
      size = 10.5
    ),
    legend.position = "bottom",
    legend.title = element_text(face = "bold")
  )

# ----------------------------------------
# Save PCA figure and supporting results
# ----------------------------------------
saveRDS(
  pca_plot,
  file = here::here("output", "pca_plot.rds")
)

saveRDS(
  list(
    pca_df = pca_df,
    variance_explained = var_exp[1:2],
    selected_genes = rownames(expr_top500)
  ),
  file = here::here("output", "pca_results.rds")
)

ggsave(
  filename = here::here("output", "pca_plot.png"),
  plot = pca_plot,
  width = 8,
  height = 6,
  dpi = 300
)
