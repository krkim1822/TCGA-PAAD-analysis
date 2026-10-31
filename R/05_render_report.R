here::i_am("R/05_render_report.R")

# Read report configuration
config <- yaml::read_yaml(
  here::here("config.yml")
)

# Render report using metadata from config.yml
rmarkdown::render(
  input = here::here("final_report.Rmd"),
  output_file = "final_report.html",
  output_dir = here::here(),
  knit_root_dir = here::here(),
  output_yaml = NULL,
  params = list(
    report_title = config$title,
    report_author = config$author
  )
)