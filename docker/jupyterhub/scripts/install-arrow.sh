#!/usr/bin/env bash
# --------------------------------------------------------------------
# /opt/install_arrow.sh       Ubuntu 24.04  ◇  Apache Arrow (all libs)
#
#   ARROW_VERSION=18.0.0
#     → libarrow* 18.0.0-1   +   arrow 18.0.0   –or– 18.0.0.1, etc.
# --------------------------------------------------------------------
set -euo pipefail
CRAN="${CRAN:-https://packagemanager.posit.co/cran/__linux__/noble/latest}"

: "${ARROW_VERSION:?ARROW_VERSION (e.g. 18.0.0) must be exported}"
echo "▶  Arrow APT target  : $ARROW_VERSION"

############################################################################
# 1)  Add Arrow APT repo (idempotent)
############################################################################
apt-get update -qq
apt-get install -y --no-install-recommends ca-certificates lsb-release wget gnupg
wget -q "https://packages.apache.org/artifactory/arrow/$(lsb_release -is | tr A-Z a-z)/apache-arrow-apt-source-latest-$(lsb_release -cs).deb"
apt-get install -y ./apache-arrow-apt-source-latest-$(lsb_release -cs).deb
rm       ./apache-arrow-apt-source-latest-$(lsb_release -cs).deb
apt-get update -qq

############################################################################
# 2)  Exact Debian revision, e.g. 18.0.0-1
############################################################################
REV=$(apt-cache madison libarrow-dev |
      awk -F'|' -v v="$ARROW_VERSION" '{gsub(/^ +| +$/, "", $2); if($2~("^"v"-")){print $2; exit}}')
[[ -z $REV ]] && { echo "!! libarrow-dev $ARROW_VERSION not in repo"; exit 1; }
echo "    ↪ APT revision    : $REV"

############################################################################
# 3)  Install *all* Arrow dev libs + GIR helpers at that revision
############################################################################
PKGS=(
  libarrow-dev libparquet-dev libarrow-glib-dev gir1.2-arrow-1.0
  libparquet-glib-dev gir1.2-parquet-1.0
  libarrow-dataset-dev libarrow-dataset-glib-dev gir1.2-arrow-dataset-1.0
  libarrow-acero-dev
  libarrow-flight-dev libarrow-flight-glib-dev gir1.2-arrow-flight-1.0
  libarrow-flight-sql-dev libarrow-flight-sql-glib-dev gir1.2-arrow-flight-sql-1.0
  libgandiva-dev libgandiva-glib-dev gir1.2-gandiva-1.0
)
apt-get install -y --allow-downgrades --allow-change-held-packages \
  --no-install-recommends "${PKGS[@]/%/=$REV}"

############################################################################
# 4)  Decide the *exact* R package version
############################################################################
R_ARROW_VERSION=$(Rscript --vanilla - "$ARROW_VERSION" "$CRAN" <<'RS'
req  <- commandArgs(TRUE)[1]          # "18.0.0"
cran <- commandArgs(TRUE)[2]

collect_versions <- function() {
  res <- character()
  # current release
  try(
    res <- c(res, available.packages(repos = cran)["arrow", "Version"]),
    silent = TRUE)
  # archive listing
  html <- tryCatch(readLines(file.path(cran,"src/contrib/Archive/arrow/"), warn = FALSE),
                   error=function(e) character())
  res <- c(res, unique(sub(".*arrow_([0-9.]+)\\.tar\\.gz.*", "\\1",
                           grep("arrow_", html, value = TRUE))))
  unique(res)
}

vers <- collect_versions()

if (req %in% vers) {
  sel <- req                                 # exact match
} else {
  pref <- grep(paste0("^", req, "\\."), vers, value = TRUE)
  if (length(pref)) {
    sel <- as.character(max(package_version(pref)))  # 18.0.0.x
  } else {
    maj  <- sub("(\\d+\\.\\d+).*", "\\1", req)       # 18.0
    cand <- vers[startsWith(vers, maj)]
    stopifnot(length(cand) > 0)                      # abort if none
    sel <- as.character(max(package_version(cand)))  # highest 18.0.*
  }
}
cat(sel)
RS
)
echo "    ↪ R tarball ver  : $R_ARROW_VERSION"

############################################################################
# 5)  Install that exact R version, linking to system libarrow
############################################################################
export LIBARROW_BUILD=FALSE LIBARROW_BINARY=FALSE ARROW_USE_PKG_CONFIG=TRUE
Rscript --vanilla -e "install.packages('remotes', repos='$CRAN', quiet=TRUE)"
Rscript --vanilla -e "remotes::install_version('arrow', version='$R_ARROW_VERSION', repos='$CRAN', dependencies=c('Depends','Imports','LinkingTo'))"

echo "✅  libarrow $REV  +  arrow $R_ARROW_VERSION (R) installed."