FROM rocker/r-ver:4.3

# Install git first
RUN apt-get update && apt-get -y install sudo git

# Clone csmtools repository and move to /uc6_csmtools directory, make it WORKDIR
RUN git clone https://github.com/leroy-bml/uc6_csmTools.git /uc6_csmTools
WORKDIR /uc6_csmTools

# Install system dependencies (using scripts from the cloned repo)
RUN chmod +x ./install_requirements.sh && ./install_requirements.sh

# install DSSAT (using scripts from the cloned repo)
RUN chmod +x ./install_dssat.sh && ./install_dssat.sh

# Install R packages with CRAN mirror (try minimal set first)
RUN R -e 'install.packages("renv", repos="https://cloud.r-project.org/")' 
# RUN R -e 'install.packages("remotes", repos="https://cloud.r-project.org/")' 
RUN R -e 'install.packages("argparse", repos="https://cloud.r-project.org/")' 

# Install csmTools package dependencies using renv
RUN R -e 'options(renv.download.override = utils::download.file); renv::restore()'

# Copy the CLI script
COPY csmtools_cli.R /uc6_csmTools/csmtools_cli.R
RUN chmod +x /uc6_csmTools/csmtools_cli.R


CMD ["Rscript", "/uc6_csmTools/csmtools_cli.R"]
