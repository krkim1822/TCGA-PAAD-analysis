final_report.html: final_report.Rmd config.yml R/05_render_report.R output/summary_table.rds output/pca_plot.rds output/model_results.rds
	Rscript R/05_render_report.R

output/summary_table.rds: R/02_summary_table.R data/paad_analysis_data.rds
	Rscript R/02_summary_table.R

output/pca_plot.rds: R/03_pca_figure.R data/paad_analysis_data.rds
	Rscript R/03_pca_figure.R

output/model_results.rds: R/04_prediction_models.R data/paad_analysis_data.rds
	Rscript R/04_prediction_models.R

data/paad_analysis_data.rds: R/01_data_preprocessing.R
	Rscript R/01_data_preprocessing.R

.PHONY: clean
clean:
	rm -f output/*.rds output/*.png final_report.html
