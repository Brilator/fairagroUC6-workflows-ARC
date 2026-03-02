# =============================================================================
# Stage 1 — builder
# Has git, all -dev headers and compilation toolchain; discarded afterwards.
# =============================================================================
FROM rocker/r-ver:4.4.3 AS builder

# Install build-time deps (git for clone; *-dev for compiling R packages)
RUN apt-get update && apt-get -y install --no-install-recommends \
    sudo git ca-certificates curl \
    libcurl4-openssl-dev libssl-dev && \
    update-ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Install renv and argparse BEFORE entering the csmTools project directory,
# so renv does not auto-activate and intercept install.packages with GitHub remotes.
RUN R -e 'install.packages(c("renv","argparse"), repos="https://cloud.r-project.org/")'

# Clone csmtools repository and move to /csmTools directory, make it WORKDIR
RUN git clone https://github.com/joemureithi/uc6_csmTools.git /csmTools
WORKDIR /csmTools

# Install system dependencies (using scripts from the cloned repo).
# This typically pulls in libgdal-dev, libudunits2-dev, libgeos-dev, libproj-dev, etc.
RUN chmod +x ./install_requirements.sh && ./install_requirements.sh

# Install DSSAT (using scripts from the cloned repo — installs to /DSSAT48 by default)
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

# =============================================================================
# Stage 2 — runtime
# Lean image: no git, no *-dev headers, no apt cache.
# =============================================================================
FROM rocker/r-ver:4.4.3 AS runtime

# Install only the shared-library runtime counterparts of the build-time -dev
# packages.  No git, no headers needed.
# NOTE: package names are Ubuntu-24.04 (Noble) specific.  If install_requirements.sh
# pulls in additional system libs, add their runtime counterparts here.
RUN apt-get update && apt-get -y install --no-install-recommends \
    sudo ca-certificates curl \
    libcurl4t64 libssl3 \
    libgdal34t64 libudunits2-0 libgeos-c1t64 libproj25 \
    libsqlite3-0 libspatialite8t64 libnetcdf19t64 \
    libhdf5-103-1t64 \
    libxml2 libpng16-16t64 libjpeg62 libtiff6 \
    python3 \
    && rm -rf /var/lib/apt/lists/*

# Copy compiled R packages (default library: renv + argparse installed before renv init)
COPY --from=builder /usr/local/lib/R/library /usr/local/lib/R/library

# Copy the renv package cache (contains the project-specific library restored by renv)
COPY --from=builder /root/.cache/R/renv /root/.cache/R/renv

# Copy the entire csmTools project directory, which contains:
#   - R source / renv lockfile
#   - renv private library (compiled packages)
#   - csmtools_cli.R
COPY --from=builder /csmTools /csmTools

# Copy DSSAT data directory (install_dssat.sh places it at /root/dssat;
# path is hardcoded in DSSATPRO.L48 so it must stay the same).
COPY --from=builder /root/dssat /root/dssat

# Copy the DSSAT model binary
COPY --from=builder /root/dssat-csm-os/build/bin/dscsm048 /root/dssat-csm-os/build/bin/dscsm048

# Silence the renv "project out-of-sync" advisory at runtime (the image is self-contained)
ENV RENV_CONFIG_SYNCHRONIZED_CHECK=FALSE

WORKDIR /csmTools
CMD ["Rscript", "/csmTools/csmtools_cli.R"]
