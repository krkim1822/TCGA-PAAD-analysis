FROM rocker/tidyverse:4.5.1

WORKDIR /project

ENV RENV_CONFIG_REPOS_OVERRIDE=https://packagemanager.posit.co/cran/latest

RUN R -q -e 'install.packages("renv")'

# Copy project files
COPY . .

# Restore packages 
RUN mkdir -p /project/output /report && \
    R -q -e 'renv::restore(prompt = FALSE)'

# Set report output directory
ENV REPORT_DIR=/report

# Run the complete analysis and generate the report
CMD ["make", "all"]
