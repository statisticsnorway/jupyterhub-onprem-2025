#!/usr/bin/env bash
# --------------------------------------------------------------------
# /opt/install_arrow.sh       Ubuntu 24.04  ◇  Apache Arrow (all libs)
#
#   ARROW_VERSION=18.0.0
#     → libarrow* 18.0.0-1   +   arrow 18.0.0   –or– 18.0.0.1, etc.
# --------------------------------------------------------------------
set -euo pipefail
CRAN=https://cloud.r-project.org

: "${ARROW_VERSION:?ARROW_VERSION (e.g. 18.0.0) must be exported}"
echo "▶  Arrow APT target  : $ARROW_VERSION"
DISTRO_ID=$(lsb_release -is 2>/dev/null | tr A-Z a-z || true)
CODENAME=$(lsb_release -cs 2>/dev/null || true)
if [[ -z "$DISTRO_ID" || -z "$CODENAME" ]]; then
  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    DISTRO_ID=${ID:-$DISTRO_ID}
    CODENAME=${VERSION_CODENAME:-$CODENAME}
  fi
fi
if [[ "$DISTRO_ID" != "ubuntu" ]]; then
  echo "!! Unsupported distro: ${DISTRO_ID:-unknown} (expected ubuntu)"
  exit 1
fi
echo "    ↪ Ubuntu codename : ${CODENAME:-unknown}"

############################################################################
# 1)  Add Arrow APT repo (idempotent)
############################################################################
apt-get update -qq
apt-get install -y --no-install-recommends ca-certificates lsb-release wget gnupg
wget -q "https://packages.apache.org/artifactory/arrow/${DISTRO_ID}/apache-arrow-apt-source-latest-${CODENAME}.deb"
apt-get install -y ./apache-arrow-apt-source-latest-${CODENAME}.deb
rm       ./apache-arrow-apt-source-latest-${CODENAME}.deb
apt-get update -qq

############################################################################
# 2)  Resolve APT revisions
############################################################################
LATEST_REV=$(apt-cache madison libarrow-dev | awk -F'|' 'NR==1{gsub(/^ +| +$/, "", $2); print $2; exit}')
LATEST_VER=${LATEST_REV%-*}
REQ_SERIES=$(echo "$ARROW_VERSION" | awk -F. '{print $1"."$2}')
LATEST_SERIES=$(echo "$LATEST_VER" | awk -F. '{print $1"."$2}')

REV=$(apt-cache madison libarrow-dev |
      awk -F'|' -v v="$ARROW_VERSION" '{gsub(/^ +| +$/, "", $2); if($2~("^"v"-")){print $2; exit}}')

echo "    ↪ APT latest rev  : $LATEST_REV"
if [[ -n "$REV" ]]; then
  echo "    ↪ APT revision    : $REV"
fi
echo "    ↪ APT series      : $LATEST_SERIES (req $REQ_SERIES)"

############################################################################
# 3)  Install Arrow dev libs (latest uses default apt, older uses pinned)
############################################################################
LATEST_PKGS=(
  libarrow-dev
  libarrow-glib-dev
  libarrow-dataset-dev
  libarrow-dataset-glib-dev
  libarrow-acero-dev
  libarrow-flight-dev
  libarrow-flight-glib-dev
  libarrow-flight-sql-dev
  libarrow-flight-sql-glib-dev
  libgandiva-dev
  libgandiva-glib-dev
  libparquet-dev
  libparquet-glib-dev
)

if [[ "$REQ_SERIES" == "$LATEST_SERIES" ]]; then
  apt-get install -y -V --no-install-recommends "${LATEST_PKGS[@]}"
else
  [[ -z $REV ]] && { echo "!! libarrow-dev $ARROW_VERSION not in repo"; exit 1; }
  REQUIRED_PKGS=(
    libarrow-dev libparquet-dev
    libarrow-dataset-dev libarrow-compute-dev libarrow-acero-dev
    libarrow-flight-dev libarrow-flight-sql-dev
    libgandiva-dev
  )
  OPTIONAL_PKGS=(
    libarrow-glib-dev libparquet-glib-dev
    libarrow-dataset-glib-dev
    libarrow-flight-glib-dev libarrow-flight-sql-glib-dev
    libgandiva-glib-dev
    gir1.2-arrow-1.0 gir1.2-parquet-1.0 gir1.2-arrow-dataset-1.0
    gir1.2-arrow-flight-1.0 gir1.2-arrow-flight-sql-1.0
    gir1.2-gandiva-1.0
  )

  have_rev() {
    apt-cache madison "$1" | awk -F'|' -v v="$REV" '{gsub(/^ +| +$/, "", $2); if($2==v){found=1}} END{exit !found}'
  }

  INSTALL_PKGS=()
  for pkg in "${REQUIRED_PKGS[@]}"; do
    if have_rev "$pkg"; then
      INSTALL_PKGS+=("${pkg}=$REV")
    else
      echo "!! required package missing at $REV: $pkg"
      exit 1
    fi
  done

  SKIPPED_OPTIONAL=()
  for pkg in "${OPTIONAL_PKGS[@]}"; do
    if have_rev "$pkg"; then
      INSTALL_PKGS+=("${pkg}=$REV")
    else
      SKIPPED_OPTIONAL+=("$pkg")
    fi
  done

  apt-get install -y --allow-downgrades --allow-change-held-packages \
    --no-install-recommends "${INSTALL_PKGS[@]}"

  if ((${#SKIPPED_OPTIONAL[@]})); then
    echo "    ↪ Skipped optional packages (not in repo at $REV): ${SKIPPED_OPTIONAL[*]}"
  fi
fi

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