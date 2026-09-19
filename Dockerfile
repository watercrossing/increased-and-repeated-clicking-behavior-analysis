# Reproducible environment for the IEEE S&P 2027 AE submission.
#
# Base pins CRAN to a frozen Posit Package Manager (P3M) snapshot that serves
# prebuilt Ubuntu 24.04 (noble) binaries, so installs here are fast and need
# no compilation from source. The snapshot date is repeated explicitly (as a
# build ARG) rather than left implicit in the base image, so a reader can see
# exactly which CRAN state produced the results, and can override it with
# --build-arg CRAN_SNAPSHOT=YYYY-MM-DD to test against a different one.
FROM rocker/r-ver:4.5.1
ARG CRAN_SNAPSHOT=2025-10-30

# Rebuild Rprofile.site with the snapshot pinned above. All three options
# matter and the file must carry all of them:
#   repos          - the frozen snapshot the results were produced against
#   HTTPUserAgent  - P3M only serves the prebuilt noble binaries when R
#                    identifies itself this way. Drop this line and every
#                    package silently compiles from source instead, turning a
#                    ~3 minute build into a ~45 minute one.
#                    https://docs.posit.co/rspm/admin/serving-binaries/
#   Ncpus          - parallelism for any package that does still build from source
RUN printf '%s\n' \
    "options(repos = c(CRAN = 'https://p3m.dev/cran/__linux__/noble/${CRAN_SNAPSHOT}'), download.file.method = 'libcurl')" \
    'options(HTTPUserAgent = sprintf("R/%s R (%s)", getRversion(), paste(getRversion(), R.version["platform"], R.version["arch"], R.version["os"])))' \
    'options(Ncpus = max(1L, parallel::detectCores()))' \
    > /usr/local/lib/R/etc/Rprofile.site

# System shared libraries needed at runtime by the R packages below, even
# though P3M ships prebuilt binaries (no compilers needed, but the .so files
# they link against still have to exist in the image):
#   - libxml2, libcurl4, libssl3: readxl/xml2, httr-style network+XML deps
#   - libfontconfig1, libfreetype6, libpng16-16, libtiff6, libjpeg-turbo8:
#     ggplot2 / graphics device rendering
#   - libgfortran5, libopenblas0-pthread: lavaan/lme4/car linear algebra
#   - zlib1g: general compression dependency
RUN apt-get update && apt-get install -y --no-install-recommends \
    libxml2 \
    libcurl4 \
    libssl3 \
    libfontconfig1 \
    libfreetype6 \
    libpng16-16 \
    libtiff6 \
    libjpeg-turbo8 \
    libgfortran5 \
    libopenblas0-pthread \
    zlib1g \
    && rm -rf /var/lib/apt/lists/*

# Pandoc is required for rmarkdown::render() to produce HTML output.
# The base image ships a helper script for this rather than relying on the
# (older) apt version.
RUN /rocker_scripts/install_pandoc.sh

# R packages required by Repeat_clicker_analysis.Rmd, plus knitr/rmarkdown
# to knit it. Installed in one call so the P3M binary resolver can plan
# dependencies together; all come from the pinned snapshot above, so this
# layer needs network access only at build time, never at container run time.
RUN Rscript -e "install.packages(c( \
    'readxl', 'dplyr', 'readr', 'lavaan', 'semTools', 'lubridate', 'stringr', \
    'tidyr', 'Hmisc', 'ggplot2', 'moments', 'patchwork', 'mice', 'lmtest', \
    'car', 'lme4', 'miceadds', 'DescTools', 'psych', 'performance', \
    'knitr', 'rmarkdown', \
    'writexl' \
    ))"

# Deliberately no COPY of the .Rmd or the data: this image is independent of
# the analysis content. At run time the repo directory is bind-mounted at
# /work (e.g. `docker run -v $(pwd):/work ...`), so the same image can be
# reused to reproduce the analysis without rebuilding, and the image itself
# stays small and free of the (potentially updated) study data.
WORKDIR /work

CMD ["R"]
