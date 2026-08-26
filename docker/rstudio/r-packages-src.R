#!/usr/bin/env Rscript

# Be explicit about repos (Ubuntu 24.04 "noble" binary path) with CRAN fallback
ppn <- c(CRAN = "https://packagemanager.posit.co/cran/__linux__/noble/latest")
cran <- c(CRAN = "https://cloud.r-project.org")

# --vanilla skips Rprofile; without this User-Agent PPM falls back to source.
options(HTTPUserAgent = sprintf(
  "R/%s R (%s)",
  getRversion(),
  paste(getRversion(), R.version["platform"], R.version["arch"], R.version["os"])
))

# Use a sane library path (avoid writing into R_HOME/lib)
.libPaths(unique(c("/usr/local/lib/R/site-library", .libPaths())))
options(repos = ppn)

# Deriv 4.3.0 compiles against R 4.5 C API (R_ClosureFormals, Rf_allocLang).
# On R 4.4.0 install the last pure-R release first so later dependencies=TRUE
# does not try to compile 4.3.0 from source.
if (getRversion() < "4.5") {
  if (!requireNamespace("Deriv", quietly = TRUE) ||
      packageVersion("Deriv") >= "4.3") {
    message("R ", getRversion(), ": installing Deriv 4.2 (4.3.0 needs R >= 4.5)")
    install.packages(
      "https://cloud.r-project.org/src/contrib/Archive/Deriv/Deriv_4.2.tar.gz",
      repos = NULL,
      type = "source"
    )
  }
}

message("Repos: ", paste(getOption("repos"), collapse = ", "))
message(".libPaths(): ", paste(.libPaths(), collapse = " | "))

pkgs <- c(
  "RJDemetra","SmallCountRounding","PxWebApiData","openxlsx","SSBtools","GISSB",
  "GaussSuppression","tinytest","configr","DT","dcmodify","simputation","survey",
  "srvyr","eurostat","dggridR","tidyfst","plotly","klassR"
)

# Helper to install a set and report missing
install_set <- function(p, repos = getOption("repos")) {
  missing <- setdiff(p, rownames(installed.packages()))
  if (length(missing)) {
    message("Installing: ", paste(missing, collapse = ", "))
    install.packages(missing, dependencies = TRUE, repos = repos, Ncpus = parallel::detectCores())
  } else {
    message("Already installed: ", paste(p, collapse = ", "))
  }
  setdiff(p, rownames(installed.packages()))
}

# 1) Try PPM first
still_missing <- install_set(pkgs, repos = ppn)

# 2) If simputation is still missing, force a CRAN fallback just for that pkg
if ("simputation" %in% still_missing) {
  message("Forcing CRAN fallback for simputation…")
  install.packages("simputation", dependencies = TRUE, repos = cran, Ncpus = parallel::detectCores())
}

# 3) Verify simputation really installed, or stop with a loud error
if (!requireNamespace("simputation", quietly = TRUE)) {
  ip <- setdiff("simputation", rownames(installed.packages()))
  stop("simputation did not install. Still missing: ", paste(ip, collapse = ", "),
       "\nCheck the build log above for the first error.")
} else {
  message("simputation installed OK: ", as.character(packageVersion("simputation")))
}

# 4) ROracle (you already fixed libaio/libnsl)
install.packages("/tmp/ROracle_1.4-1_R_x86_64-unknown-linux-gnu.tar.gz", repos = NULL, type = "source")

# 5) GitHub packages (avoid surprise upgrades of deps)
if (!requireNamespace("remotes", quietly = TRUE)) install.packages("remotes", repos = cran)
gh <- c(
  "statisticsnorway/ssb-pris",
  "statisticsnorway/ssb-kostra",
  "statisticsnorway/ssb-sdcforetakperson",
  "statisticsnorway/ssb-struktur",
  "statisticsnorway/ssb-pickmdl",
  "statisticsnorway/ssb-fellesr",
  "statisticsnorway/ssb-easysdctable",
  "statisticsnorway/ReGenesees"
)
for (repo in gh) remotes::install_github(repo, upgrade = "never", dependencies = TRUE)
