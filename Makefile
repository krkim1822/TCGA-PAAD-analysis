.PHONY: all report install clean

# Run the complete analysis
all: final_report.html

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

# Run the Docker container and save the report locally
report:
	mkdir -p report
	docker run --rm --pull=always \
		-v "$(CURDIR)/report:/report" \
		-e REPORT_DIR=/report \
		krkim1822/tcga-paad-analysis:latest

install:
	Rscript -e "renv::restore(prompt = FALSE)"

clean:
	rm -f output/*.rds output/*.png final_report.html
