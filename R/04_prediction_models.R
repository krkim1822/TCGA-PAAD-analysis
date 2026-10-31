here::i_am("R/04_prediction_models.R")

output_dir <- here::here("output")

if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

library(caret)
library(pROC)
library(dplyr)
library(glmnet)
library(randomForest)

set.seed(550)

# ----------------------------------------
# Load processed data
# ----------------------------------------
analysis_data <- readRDS(
  here::here("data", "paad_analysis_data.rds")
)

expr_data <- analysis_data$expression
clin_data <- analysis_data$clinical

# ----------------------------------------
# Construct sample x gene matrix
# ----------------------------------------
ml_x <- t(as.matrix(expr_data))

colnames(ml_x) <- rownames(expr_data)
rownames(ml_x) <- colnames(expr_data)

ml_y <- factor(
  as.character(clin_data$grade_group),
  levels = c("High", "Low_Intermediate")
)

stopifnot(
  identical(rownames(ml_x), as.character(clin_data$sampleID))
)

# ----------------------------------------
# Train/test split
# ----------------------------------------
train_idx <- createDataPartition(ml_y, p = 0.75, list = FALSE)

x_train_all <- ml_x[train_idx, , drop = FALSE]
x_test_all <- ml_x[-train_idx, , drop = FALSE]

y_train <- ml_y[train_idx]
y_test <- ml_y[-train_idx]

# ----------------------------------------
# Select top 500 variable genes using training samples only to prevent data leakage
# ----------------------------------------
train_gene_vars <- apply(x_train_all, 2, var, na.rm = TRUE)

valid_genes <- which(is.finite(train_gene_vars) &train_gene_vars > 0)

top_gene_idx <- head(
  valid_genes[
    order(
      train_gene_vars[valid_genes],
      decreasing = TRUE
    )
  ],
  500
)

selected_genes <- colnames(x_train_all)[top_gene_idx]

x_train <- x_train_all[ ,selected_genes, drop = FALSE]
x_test <- x_test_all[ , selected_genes, drop = FALSE]

# Make column names compatible with modeling
feature_names <- make.names(
  selected_genes,
  unique = TRUE
)

colnames(x_train) <- feature_names
colnames(x_test) <- feature_names

# ----------------------------------------
# Cross-validation settings
# ----------------------------------------
train_ctrl <- trainControl(
  method = "cv",
  number = 5,
  classProbs = TRUE,
  summaryFunction = twoClassSummary,
  savePredictions = "final",
  sampling = "down"
)

# ----------------------------------------
# Logistic Regression (top 10 PCs)
# ----------------------------------------
# PCA fitted using training data only

pca_train <- prcomp(
  x_train,
  center = TRUE,
  scale. = TRUE
)

train_pca_df <- as.data.frame(
  pca_train$x[, 1:10, drop = FALSE]
)

test_pca_df <- as.data.frame(
  predict(
    pca_train,
    newdata = x_test
  )[, 1:10, drop = FALSE]
)

set.seed(550)

fit_logistic <- train(
  x = train_pca_df,
  y = y_train,
  method = "glm",
  family = binomial(),
  metric = "ROC",
  trControl = train_ctrl
)


# ----------------------------------------
# Elastic Net
# ----------------------------------------
set.seed(550)

fit_enet <- train(
  x = x_train,
  y = y_train,
  method = "glmnet",
  metric = "ROC",
  tuneLength = 5,
  trControl = train_ctrl,
  preProcess = c("center", "scale")
)

# ----------------------------------------
# Random Forest
# ----------------------------------------
set.seed(550)

fit_rf <- train(
  x = x_train,
  y = y_train,
  method = "rf",
  metric = "ROC",
  ntree = 200,
  tuneGrid = data.frame(
    mtry = c(10, 25, 50)
  ),
  trControl = train_ctrl
)

# ----------------------------------------
# Test-set predictions
# ----------------------------------------
prob_log <- predict(
  fit_logistic,
  newdata = test_pca_df,
  type = "prob"
)[["High"]]

pred_log <- predict(
  fit_logistic,
  newdata = test_pca_df
)

prob_enet <- predict(
  fit_enet,
  newdata = x_test,
  type = "prob"
)[["High"]]

pred_enet <- predict(
  fit_enet,
  newdata = x_test
)

prob_rf <- predict(
  fit_rf,
  newdata = x_test,
  type = "prob"
)[["High"]]

pred_rf <- predict(
  fit_rf,
  newdata = x_test
)

# ----------------------------------------
# ROC-AUC evaluation
# ----------------------------------------
roc_log <- roc(
  response = y_test,
  predictor = prob_log,
  levels = c("Low_Intermediate", "High"),
  direction = "<",
  quiet = TRUE
)

roc_enet <- roc(
  response = y_test,
  predictor = prob_enet,
  levels = c("Low_Intermediate", "High"),
  direction = "<",
  quiet = TRUE
)

roc_rf <- roc(
  response = y_test,
  predictor = prob_rf,
  levels = c("Low_Intermediate", "High"),
  direction = "<",
  quiet = TRUE
)

# ----------------------------------------
# Confusion matrices
# ----------------------------------------
cm_log <- confusionMatrix(
  pred_log,
  y_test,
  positive = "High"
)

cm_enet <- confusionMatrix(
  pred_enet,
  y_test,
  positive = "High"
)

cm_rf <- confusionMatrix(
  pred_rf,
  y_test,
  positive = "High"
)

# ----------------------------------------
# Model comparison table
# ----------------------------------------
model_comp_table <- data.frame(
  `Model Architecture` = c(
    "Logistic Regression",
    "Elastic Net",
    "Random Forest"
  ),
  
  `Test ROC-AUC` = c(
    sprintf("%.3f", as.numeric(auc(roc_log))),
    sprintf("%.3f", as.numeric(auc(roc_enet))),
    sprintf("%.3f", as.numeric(auc(roc_rf)))
  ),
  
  `Accuracy` = c(
    sprintf("%.1f%%", 100 * cm_log$overall["Accuracy"]),
    sprintf("%.1f%%", 100 * cm_enet$overall["Accuracy"]),
    sprintf("%.1f%%", 100 * cm_rf$overall["Accuracy"])
  ),
  
  `Sensitivity (High Grade Recall)` = c(
    sprintf("%.1f%%", 100 * cm_log$byClass["Sensitivity"]),
    sprintf("%.1f%%", 100 * cm_enet$byClass["Sensitivity"]),
    sprintf("%.1f%%", 100 * cm_rf$byClass["Sensitivity"])
  ),
  
  `Specificity` = c(
    sprintf("%.1f%%", 100 * cm_log$byClass["Specificity"]),
    sprintf("%.1f%%", 100 * cm_enet$byClass["Specificity"]),
    sprintf("%.1f%%", 100 * cm_rf$byClass["Specificity"])
  ),
  
  check.names = FALSE
)

# ----------------------------------------
# Save model results
# ----------------------------------------
model_results <- list(
  comparison_table = model_comp_table,
  
  logistic = fit_logistic,
  elastic_net = fit_enet,
  random_forest = fit_rf,
  
  roc_logistic = roc_log,
  roc_elastic_net = roc_enet,
  roc_random_forest = roc_rf,
  
  cm_logistic = cm_log,
  cm_elastic_net = cm_enet,
  cm_random_forest = cm_rf,
  
  selected_genes = selected_genes,
  train_samples = rownames(x_train),
  test_samples = rownames(x_test),
  test_grade = y_test
)

saveRDS(
  model_results,
  file = here::here("output", "model_results.rds"),
  compress = "xz"
)

saveRDS(
  model_comp_table,
  file = here::here("output", "model_comp_table.rds")
)

cat("Model training and evaluation completed.\n")
cat("Training samples:", nrow(x_train), "\n")
cat("Test samples:", nrow(x_test), "\n")
