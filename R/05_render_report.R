here::i_am("R/05_render_report.R")

rmarkdown::render(
  input = here::here("final_report.Rmd"),
  output_file = "final_report.html",
  output_dir = here::here(),
  knit_root_dir = here::here()
)
