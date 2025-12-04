#!/usr/bin/env bash
set -euo pipefail

# Use CRAN from env if provided; default to Posit Package Manager.
CRAN_URL="${CRAN:-https://packagemanager.posit.co/cran/__linux__/noble/latest}"
export CRAN="${CRAN_URL}"

echo ">> Using CRAN repo: ${CRAN_URL}"

###############################################################################
# 1) Ensure pak is installed (used for system requirements)
###############################################################################
echo ">> Ensuring 'pak' package is installed"
Rscript --vanilla - <<'RSCRIPT'
cran <- Sys.getenv("CRAN", unset = "https://cloud.r-project.org")
if (!requireNamespace("pak", quietly = TRUE)) {
  install.packages("pak", repos = cran, dependencies = FALSE)
}
RSCRIPT

###############################################################################
# 2) Install system requirements for all packages via pak::pkg_sysreqs()
###############################################################################
echo ">> Resolving and installing system requirements via pak::pkg_sysreqs"

Rscript --vanilla - <<'RSCRIPT' | sh
cran <- Sys.getenv("CRAN", unset = "https://cloud.r-project.org")
options(repos = c(CRAN = cran))

# All CRAN packages you later install
cran_pkgs <- c(
  "tidyfst",
  "configr",
  "DBI",
  "renv",
  "leaflet",
  "getPass",
  "DT",
  "rjwsacruncher",
  "sf",
  "sfarrow",
  "dbplyr",
  "shiny",
  "rstudioapi",
  "httr",
  "readr",
  "knitr",
  "rmarkdown",
  "RCurl",
  "here",
  "esquisse",
  "dcmodify",
  "simputation",
  "SmallCountRounding",
  "klassR",
  "pxwebapidata",
  "gissb",
  "igraph",
  "dggridR",
  "languageserver",
  "lintr",
  "tidyverse",
  "openxlsx",
  "survey",
  "eurostat",
  "easySdcTable"
)

# All GitHub packages you later install
gh_pkgs <- c(
  "statisticsnorway/ssb-pris",
  "statisticsnorway/ssb-GaussSuppression",
  "statisticsnorway/ssb-fellesr",
  "statisticsnorway/ssb-kostra",
  "statisticsnorway/ssb-SdcForetakPerson",
  "statisticsnorway/ssb-struktuR",
  "statisticsnorway/ssb-pxwebapidata",
  "statisticsnorway/ssb-SSBtools",
  "statisticsnorway/ssb-klassr",
  "statisticsnorway/GISSB",
  "statisticsnorway/ReGenesees",
  "statisticsnorway/ssb-pickmdl"
)

pkgs <- c(cran_pkgs, gh_pkgs)

# Ask pak for system requirements (for Ubuntu)
sys <- pak::pkg_sysreqs(pkgs, sysreqs_platform = "ubuntu")

if (!is.null(sys$install_scripts) && length(sys$install_scripts) > 0) {
  cat(sys$install_scripts, sep = "\n")
}
RSCRIPT

###############################################################################
# 3) Java config (same as your original script)
###############################################################################
echo ">> Running R CMD javareconf -e"
R CMD javareconf -e

###############################################################################
# 4) Install R packages from CRAN and GitHub
###############################################################################
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
ip("languageserver",     deps = TRUE)
ip("lintr",              deps = TRUE)
ip("tidyverse",          deps = TRUE)
ip("openxlsx",           deps = TRUE)
ip("survey",             deps = TRUE)
ip("eurostat",           deps = TRUE)
ip("easySdcTable",       deps = TRUE)

# Install ROracle from local tarball if present
local_pkg <- '/tmp/ROracle_1.4-1_R_x86_64-unknown-linux-gnu.tar.gz'
if (file.exists(local_pkg)) {
  install.packages(local_pkg, repos = NULL, type = 'source')
}

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

###############################################################################
# 5) Ensure IRkernel is installed and registered
###############################################################################
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
