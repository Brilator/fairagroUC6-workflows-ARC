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

# Patch .Rprofile to use absolute path for renv/activate.R so it works
# when R is invoked from any working directory (e.g. s4n temp dirs).
RUN sed -i 's|source("renv/activate.R")|source("/csmTools/renv/activate.R")|g' /csmTools/.Rprofile

# NOTE: The runtime .Rprofile is replaced with renv::load() so activate.R bootstrap
# is never called.  This sed is kept verbatim to preserve the Docker layer cache from
# the previous build; the pattern may or may not match — it is harmless either way.
RUN sed -i 's/renv_bootstrap_initialize()/invisible(NULL) # bootstrap disabled in Docker/g' /csmTools/renv/activate.R

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

# Write the renv library path to a temp file, then install extra packages and
# csmTools using --no-init-file to bypass renv GitHub remote resolution.
RUN Rscript --quiet -e "writeLines(renv::paths\$library(), '/tmp/renv_lib')" && \
    lib=$(cat /tmp/renv_lib) && \
    Rscript --no-init-file -e "install.packages(c('yaml','nasapower','argparse'), repos='https://cloud.r-project.org', lib='${lib}')" && \
    R CMD INSTALL --library="${lib}" .

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

# Copy compiled R packages from the builder's site-library (where install.packages()
# installs to by default in rocker images: /usr/local/lib/R/site-library).
# This includes renv, argparse, and any other system-level installs.
COPY --from=builder /usr/local/lib/R/site-library /usr/local/lib/R/site-library

# Copy the renv package cache (contains the project-specific library restored by renv)
COPY --from=builder /root/.cache/R/renv /root/.cache/R/renv

# Copy the entire csmTools project directory, which contains:
#   - R source / renv lockfile
#   - renv private library (compiled packages)
#   - csmtools_cli.R
COPY --from=builder /csmTools /csmTools

# Replace .Rprofile with a minimal version that directly prepends the renv project
# library to .libPaths().  This bypasses renv::load() / activate.R entirely, which
# avoids all bootstrap and HOME-path issues under s4n's --net=none and --user constraints.
# The library path is deterministic for this platform (linux-ubuntu-noble / R-4.4 / x86_64).
RUN printf '.libPaths(c("/root/.cache/R/renv/library/csmTools-099ce2ab/linux-ubuntu-noble/R-4.4/x86_64-pc-linux-gnu/", .libPaths()))\n' > /csmTools/.Rprofile

# Copy DSSAT data directory (install_dssat.sh places it at /root/dssat;
# path is hardcoded in DSSATPRO.L48 so it must stay the same).
COPY --from=builder /root/dssat /root/dssat

# Copy the DSSAT model binary
COPY --from=builder /root/dssat-csm-os/build/bin/dscsm048 /root/dssat-csm-os/build/bin/dscsm048

# s4n runs the container with --user=1000:1000, but all our runtime data lives
# under /root/ (mode 700 by default → permission denied for non-root users).
# Make /root and everything below it world-readable+executable.
RUN chmod -R a+rx /root

# Silence the renv "project out-of-sync" advisory at runtime (the image is self-contained)
# Pin renv cache and profile so s4n's --workdir and --env=HOME overrides don't break package discovery.
ENV RENV_CONFIG_SYNCHRONIZED_CHECK=FALSE
ENV RENV_CONFIG_SANDBOX_ENABLED=FALSE
ENV RENV_PATHS_CACHE=/root/.cache/R/renv
ENV R_PROFILE_USER=/csmTools/.Rprofile
ENV RENV_CONFIG_BOOTSTRAP_ENABLED=FALSE

WORKDIR /csmTools
ENTRYPOINT ["Rscript", "/csmTools/csmtools_cli.R"]