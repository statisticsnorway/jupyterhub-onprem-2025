#!/usr/bin/env bash
set -euo pipefail

# Use CRAN from env if provided; default to cloud CRAN mirror.
CRAN_URL="${CRAN:-https://packagemanager.posit.co/cran/__linux__/noble/latest}"

echo ">> Using CRAN repo: ${CRAN_URL}"
echo ">> Running R CMD javareconf -e"
R CMD javareconf -e

echo ">> Installing R packages from CRAN and GitHub"
Rscript - <<'RSCRIPT'
cran <- Sys.getenv("CRAN", unset = "https://cloud.r-project.org")

ip <- function(pkg, deps = TRUE) install.packages(pkg, repos = cran, dependencies = deps)

# --- CRAN packages ---
ip("tidyfst",            deps = TRUE)
ip("configr",            deps = TRUE)
ip("DBI",                deps = TRUE)
ip("renv",               deps = TRUE)
ip("leaflet",            deps = TRUE)
ip("getPass",            deps = TRUE)
ip("DT",                 deps = TRUE)
ip("rjwsacruncher",      deps = TRUE)
ip("sf",                 deps = TRUE)
ip("sfarrow",            deps = FALSE)
ip("dbplyr",             deps = FALSE)
ip("shiny",              deps = FALSE)
ip("rstudioapi",         deps = TRUE)
ip("httr",               deps = TRUE)
ip("readr",              deps = TRUE)
ip("knitr",              deps = TRUE)
ip("rmarkdown",          deps = TRUE)
ip("RCurl",              deps = TRUE)
ip("here",               deps = TRUE)
ip("esquisse",           deps = TRUE)
ip("dcmodify",           deps = TRUE)
ip("simputation",        deps = TRUE)
ip("SmallCountRounding", deps = TRUE)
ip("klassR",             deps = TRUE)
ip("pxwebapidata",       deps = TRUE)
ip("gissb",              deps = TRUE)
ip("igraph",             deps = TRUE)
ip("dggridR",            deps = TRUE)

# Ensure 'remotes' present for GitHub installs
if (!requireNamespace("remotes", quietly = TRUE)) {
  install.packages("remotes", repos = cran)
}

# --- GitHub packages ---
remotes::install_github("statisticsnorway/ssb-pris")
remotes::install_github("statisticsnorway/ssb-GaussSuppression")
remotes::install_github("statisticsnorway/ssb-fellesr")
remotes::install_github("statisticsnorway/ssb-kostra")
remotes::install_github("statisticsnorway/ssb-SdcForetakPerson")
remotes::install_github("statisticsnorway/ssb-struktuR")
remotes::install_github("statisticsnorway/ssb-pxwebapidata")
remotes::install_github("statisticsnorway/ssb-SSBtools")
remotes::install_github("statisticsnorway/ssb-klassr")
remotes::install_github("statisticsnorway/GISSB")
remotes::install_github("statisticsnorway/ReGenesees")
remotes::install_github("statisticsnorway/ssb-pickmdl")
RSCRIPT

# Ensure IRkernel is installed and registered
echo ">> Installing and registering IRkernel"
Rscript --vanilla - <<'RSCRIPT'
cran <- Sys.getenv("CRAN", unset = "https://cloud.r-project.org")
if (!requireNamespace("IRkernel", quietly = TRUE)) {
  install.packages("IRkernel", repos = cran, dependencies = TRUE)
}
# Register kernel spec in the conda share path used by our image
try({
  IRkernel::installspec(name = "ir", displayname = "R", user = FALSE)
}, silent = TRUE)
RSCRIPT

echo ">> R package installation complete."
