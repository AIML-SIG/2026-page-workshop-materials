# Load the base image with R
FROM rocker/r-ver:4.5.3

RUN useradd -s /bin/bash -m rstudio \
    && usermod -a -G staff rstudio

USER root

# Avoid prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install system packages needed for R, Python, and building some R packages
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       wget curl ca-certificates tar gnupg2 build-essential libcurl4-openssl-dev \
       libssl-dev libxml2-dev libffi-dev libfontconfig1-dev libfreetype6-dev \
       libpng-dev libjpeg-dev libuv1-dev git python3-pip python3-venv \
       cmake pkg-config libgmp-dev libmpfr-dev \
       libharfbuzz-dev libfribidi-dev libcairo2-dev libtiff5-dev libwebp-dev \
    && rm -rf /var/lib/apt/lists/*

# Install R packages from renv.lock using renv package manager
COPY .devcontainer/renv.lock /tmp/renv.lock
RUN R -e "install.packages(c('renv', 'BiocManager', 'languageserver', 'httpgd'), repos='https://cloud.r-project.org/')" \
    && R -e "options(renv.consent=TRUE, timeout=600); options(repos=BiocManager::repositories(version='3.22')); if (!requireNamespace('BiocVersion', quietly=TRUE)) BiocManager::install('BiocVersion', version='3.22', ask=FALSE, update=FALSE); for (i in 1:3) { tryCatch({ renv::restore(project='/tmp', lockfile='/tmp/renv.lock', prompt=FALSE); break }, error=function(e) { if (i == 3) stop(e); message(sprintf('renv::restore attempt %d failed, retrying...', i)) }) }" \
    && rm -rf /root/.cache/R/renv /tmp/renv /tmp/renv.lock

# Install Julia via juliaup
ARG JULIA_VERSION=1.10
ENV JULIA_DEPOT_PATH=/usr/local/share/julia
ENV JULIA_PKG_PRECOMPILE_AUTO=0
ENV JULIA_CPU_TARGET=generic
ENV JULIA_HISTORY=/home/vscode/.julia/logs/repl_history.jl

RUN curl -fsSL https://install.julialang.org | sh -s -- --yes --add-to-path false \
    && /root/.juliaup/bin/juliaup add ${JULIA_VERSION} \
    && /root/.juliaup/bin/juliaup default ${JULIA_VERSION} \
    && mkdir -p /opt/course-julia \
    && JULIA_BIN_DIR="$(/root/.juliaup/bin/julia -e 'print(Sys.BINDIR)')" \
    && cp -a "$(dirname "${JULIA_BIN_DIR}")" /opt/course-julia/julia \
    && chmod -R a+rx /opt/course-julia/julia \
    && mkdir -p ${JULIA_DEPOT_PATH} && chmod -R 0777 ${JULIA_DEPOT_PATH} \
    && mkdir -p /home/vscode/.julia/logs && chmod -R 0777 /home/vscode/.julia

# Install Julia packages, build sysimage, then clean up build-only artifacts
COPY .devcontainer/Project.toml /opt/course-julia/Project.toml
RUN /opt/course-julia/julia/bin/julia --project=/opt/course-julia -e \
        'using Pkg; try Pkg.Registry.add(Pkg.RegistrySpec(url="https://github.com/JuliaRegistries/General.git")) catch end; Pkg.instantiate(); Pkg.add(["PackageCompiler"]); Pkg.precompile()' \
    && /opt/course-julia/julia/bin/julia --project=/opt/course-julia -e \
        'using Pkg, TOML, PackageCompiler; project = TOML.parsefile("/opt/course-julia/Project.toml"); deps = sort!(collect(keys(get(project, "deps", Dict{String, Any}())))); pkgs = Symbol.(deps); if !isempty(pkgs); create_sysimage(pkgs; sysimage_path="/opt/course-julia/course.so", cpu_target="generic"); end' \
    && /opt/course-julia/julia/bin/julia --project=/opt/course-julia -e 'using Pkg; Pkg.rm("PackageCompiler"); Pkg.gc()' \
    && rm -rf ${JULIA_DEPOT_PATH}/registries \
    && rm -rf ${JULIA_DEPOT_PATH}/packages/PackageCompiler \
    && rm -rf ${JULIA_DEPOT_PATH}/compiled \
    && rm -rf ${JULIA_DEPOT_PATH}/logs \
    && rm -rf ${JULIA_DEPOT_PATH}/scratchspaces \
    && printf '%s\n' \
        '#!/usr/bin/env bash' \
        'JULIA_BIN=/opt/course-julia/julia/bin/julia' \
        'PROJECT=/opt/course-julia' \
        'CUSTOM_SYS=/opt/course-julia/course.so' \
        'if [ -f "$CUSTOM_SYS" ] && "$JULIA_BIN" --project="$PROJECT" -J"$CUSTOM_SYS" -e "exit(0)" >/dev/null 2>&1; then' \
        '  exec "$JULIA_BIN" --project="$PROJECT" -J"$CUSTOM_SYS" "$@"' \
        'fi' \
        'exec "$JULIA_BIN" --project="$PROJECT" "$@"' \
        > /usr/local/bin/julia && chmod +x /usr/local/bin/julia \
    && chmod -R a+rwX ${JULIA_DEPOT_PATH} /home/vscode/.julia

# Install Quarto
ARG QUARTO_VERSION=1.8.27
RUN wget -q https://github.com/quarto-dev/quarto-cli/releases/download/v${QUARTO_VERSION}/quarto-${QUARTO_VERSION}-linux-amd64.deb \
    && dpkg -i quarto-${QUARTO_VERSION}-linux-amd64.deb \
    && rm quarto-${QUARTO_VERSION}-linux-amd64.deb

# Create a writable R library directory for non-root users
RUN mkdir -p /home/vscode/R && chmod 0777 /home/vscode/R || true

ENV PATH="/usr/local/bin:${PATH}"
