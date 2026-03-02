FROM rocker/r-ver:4.4.3

# Install git + network/cert deps needed by renv downloads
RUN apt-get update && apt-get -y install \
    sudo git ca-certificates curl libcurl4-openssl-dev libssl-dev && \
    update-ca-certificates

# Install renv and argparse BEFORE entering the csmTools project directory,
# so renv does not auto-activate and intercept install.packages with GitHub remotes.
RUN R -e 'install.packages(c("renv","argparse"), repos="https://cloud.r-project.org/")'

# Clone csmtools repository and move to /csmTools directory, make it WORKDIR
RUN git clone https://github.com/fairagro/csmTools.git /csmTools
WORKDIR /csmTools

# Install system dependencies (using scripts from the cloned repo)
RUN chmod +x ./install_requirements.sh && ./install_requirements.sh

# install DSSAT (using scripts from the cloned repo)
RUN chmod +x ./install_dssat.sh && ./install_dssat.sh

# Force renv away from Posit PPM/RSPM
ENV RENV_CONFIG_PPM_ENABLED=FALSE
ENV RENV_CONFIG_RSPM_ENABLED=FALSE
ENV RENV_CONFIG_REPOS_OVERRIDE=https://cloud.r-project.org

# Restore; exclude base/recommended packages already bundled with R.
# Falls back to latest CRAN version for any package whose exact archived version is unavailable.
RUN R -e '\
    options(repos=c(CRAN=Sys.getenv("RENV_CONFIG_REPOS_OVERRIDE")), download.file.method="libcurl"); \
    renv::consent(provided=TRUE); \
    skip <- rownames(installed.packages(priority=c("base","recommended"))); \
    result <- tryCatch( \
    renv::restore(prompt=FALSE, transactional=FALSE, exclude=skip), \
    error=function(e) e \
    ); \
    if (inherits(result, "error")) { \
    message("renv::restore() failed, falling back to direct CRAN install for missing CRAN packages"); \
    lf <- renv::lockfile_read(); \
    cran_pkgs <- names(Filter(function(p) { \
    src <- p$Source; is.null(src) || src %in% c("Repository", "CRAN") \
    }, lf$Packages)); \
    pkgs <- setdiff(cran_pkgs, skip); \
    missing <- pkgs[!pkgs %in% rownames(installed.packages())]; \
    if (length(missing) > 0) { \
    renv::deactivate(); \
    utils::install.packages(missing, repos=Sys.getenv("RENV_CONFIG_REPOS_OVERRIDE")); \
    } \
    }'

# Install missing transitive deps (yaml, nasapower) not in the lockfile,
# then install the csmTools package itself — all pointing at the renv library.
RUN RENV_LIB=$(R --slave -e 'options(renv.verbose=FALSE); cat(renv::paths$library())' 2>/dev/null | grep "^/") && \
    echo "renv library: $RENV_LIB" && \
    R -e "options(repos=c(CRAN='https://cloud.r-project.org'), renv.verbose=FALSE); \
    pkgs <- c('yaml','nasapower','argparse'); \
    missing <- pkgs[!pkgs %in% rownames(installed.packages(lib.loc='$RENV_LIB'))]; \
    if (length(missing) > 0) install.packages(missing, lib='$RENV_LIB')" && \
    R_LIBS_USER="$RENV_LIB" R CMD INSTALL --library="$RENV_LIB" .
COPY csmtools_cli.R /csmTools/csmtools_cli.R
RUN chmod +x /csmTools/csmtools_cli.R

# Silence the renv "project out-of-sync" advisory at runtime (the image is self-contained)
ENV RENV_CONFIG_SYNCHRONIZED_CHECK=FALSE

CMD ["Rscript", "/csmTools/csmtools_cli.R"]
