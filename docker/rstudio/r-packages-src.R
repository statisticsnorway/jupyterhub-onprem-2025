#!/usr/bin/env Rscript

# Build-time install: manylinux portable first, noble binaries as fallback, CRAN last.
# (GHA cannot rely on Nexus; runtime Rprofile.site points at Nexus mirrors.)
#
# P3M manylinux URL must use major.minor (4.4), not patch (4.4.0).
# Use Depends/Imports/LinkingTo only (not Suggests). That is not enough to
# skip Deriv: doBy Imports it, and simputation → VIM → car → pbkrtest → doBy.
# Deriv 4.3.0 needs R >= 4.5 C API (R_ClosureFormals, Rf_allocLang).

r_ver <- Sys.getenv("R_VERSION", unset = as.character(getRversion()))
r_minor <- sub("^([0-9]+\\.[0-9]+).*", "\\1", r_ver)
manylinux <- sprintf(
  "https://packagemanager.posit.co/cran/latest/bin/linux/manylinux_2_28-x86_64/%s",
  r_minor
)
noble <- sprintf(
  "https://packagemanager.posit.co/cran/latest/bin/linux/noble-x86_64/%s",
  r_minor
)
cran <- "https://cloud.r-project.org"
hard_deps <- c("Depends", "Imports", "LinkingTo")

# --vanilla skips Rprofile; without this User-Agent PPM may fall back to source.
options(HTTPUserAgent = sprintf(
  "R/%s R (%s)",
  getRversion(),
  paste(getRversion(), R.version["platform"], R.version["arch"], R.version["os"])
))

.libPaths(unique(c("/usr/local/lib/R/site-library", .libPaths())))
options(repos = c(P3M = manylinux, CRAN = noble))

# Pin the last pure-R Deriv before later install.packages() pulls 4.3.0 as a
# hard dependency of doBy. Confirmed locally: 4.3.0 fails to compile on R 4.4,
# 4.2.0 installs. R 4.6 can use latest.
if (getRversion() < "4.5") {
  if (!requireNamespace("Deriv", quietly = TRUE) ||
      packageVersion("Deriv") >= "4.3") {
    message("R ", getRversion(), ": installing Deriv 4.2.0 (4.3.0 needs R >= 4.5)")
    install.packages(
      "https://cloud.r-project.org/src/contrib/Archive/Deriv/Deriv_4.2.0.tar.gz",
      repos = NULL,
      type = "source"
    )
  }
  stopifnot(requireNamespace("Deriv", quietly = TRUE))
  stopifnot(packageVersion("Deriv") < "4.3")
}

message("R_VERSION: ", r_ver, " → path: ", r_minor)
message("Repos: ", paste(getOption("repos"), collapse = ", "))
message(".libPaths(): ", paste(.libPaths(), collapse = " | "))

if (!requireNamespace("remotes", quietly = TRUE)) {
  install.packages("remotes", repos = manylinux, dependencies = hard_deps)
}

pkgs <- c(
  "RJDemetra", "SmallCountRounding", "PxWebApiData", "openxlsx", "SSBtools", "GISSB",
  "GaussSuppression", "tinytest", "configr", "DT", "dcmodify", "simputation", "survey",
  "srvyr", "eurostat", "dggridR", "tidyfst", "plotly", "klassR"
)

install_set <- function(p, repos) {
  missing <- setdiff(p, rownames(installed.packages()))
  if (length(missing)) {
    message("Installing: ", paste(missing, collapse = ", "))
    install.packages(
      missing,
      dependencies = hard_deps,
      repos = repos,
      Ncpus = parallel::detectCores()
    )
  } else {
    message("Already installed: ", paste(p, collapse = ", "))
  }
  setdiff(p, rownames(installed.packages()))
}

# 1) Manylinux portable binaries
still_missing <- install_set(pkgs, repos = manylinux)

# 2) Noble binaries for anything still missing
if (length(still_missing)) {
  message("Noble fallback for: ", paste(still_missing, collapse = ", "))
  still_missing <- install_set(still_missing, repos = noble)
}

# 3) CRAN source last resort
if (length(still_missing)) {
  message("CRAN fallback for: ", paste(still_missing, collapse = ", "))
  still_missing <- install_set(still_missing, repos = cran)
}

if (!requireNamespace("simputation", quietly = TRUE)) {
  stop(
    "simputation did not install. Still missing: ",
    paste(setdiff(pkgs, rownames(installed.packages())), collapse = ", "),
    "\nCheck the build log above for the first error."
  )
}
message("simputation installed OK: ", as.character(packageVersion("simputation")))

still_missing <- setdiff(pkgs, rownames(installed.packages()))
if (length(still_missing)) {
  stop(
    "Packages still missing after manylinux/noble/CRAN: ",
    paste(still_missing, collapse = ", ")
  )
}

# 4) ROracle (prebuilt tarball; needs libaio/libnsl already in image)
install.packages("/tmp/ROracle_1.4-1_R_x86_64-unknown-linux-gnu.tar.gz", repos = NULL, type = "source")

# 5) GitHub packages (avoid surprise upgrades of hard deps)
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
for (repo in gh) {
  remotes::install_github(repo, upgrade = "never", dependencies = hard_deps)
}
