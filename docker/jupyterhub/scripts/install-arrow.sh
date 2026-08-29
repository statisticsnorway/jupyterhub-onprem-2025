#!/usr/bin/env bash
# --------------------------------------------------------------------
# Install R arrow as a Posit portable (manylinux_2_28) binary.
# No APT / system libarrow. Runtime users install via Nexus (Rprofile.site).
# --------------------------------------------------------------------
set -euo pipefail

: "${ARROW_VERSION:?ARROW_VERSION (e.g. 24.0.0) must be exported}"
: "${R_VERSION:?R_VERSION (e.g. 4.4.0) must be exported}"

# P3M manylinux path must be major.minor (4.4), NOT patch (4.4.0).
R_MINOR="${R_VERSION%.*}"
REPOS="https://packagemanager.posit.co/cran/latest/bin/linux/manylinux_2_28-x86_64/${R_MINOR}"

echo "▶  Arrow portable binary : ${ARROW_VERSION}"
echo "    ↪ R_VERSION         : ${R_VERSION} → path ${R_MINOR}"
echo "    ↪ repos             : ${REPOS}"

Rscript --vanilla -e "install.packages('remotes', repos='${REPOS}', quiet=TRUE)"
Rscript --vanilla -e "remotes::install_version('arrow', version='${ARROW_VERSION}', repos='${REPOS}', dependencies=c('Depends','Imports','LinkingTo'), upgrade='never')"

Rscript --vanilla -e "caps <- arrow::arrow_info()\$capabilities; print(caps); if (is.null(caps) || !any(unlist(caps))) stop('arrow capabilities all FALSE'); message('arrow ', as.character(packageVersion('arrow')), ' OK')"

echo "✅  arrow ${ARROW_VERSION} (portable manylinux) installed."
