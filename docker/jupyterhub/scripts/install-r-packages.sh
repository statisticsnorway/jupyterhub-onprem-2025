echo ">> Installing R packages from CRAN and GitHub"
Rscript --vanilla - <<'RSCRIPT'
cran <- Sys.getenv("CRAN", unset = "https://cloud.r-project.org")
options(repos = c(CRAN = cran))

# Helper: install a CRAN package and capture success/failure
ip <- function(pkg, deps = TRUE) {
  tryCatch(
    {
      install.packages(pkg, repos = cran, dependencies = deps)
      list(ok = TRUE, msg = "")
    },
    error = function(e) list(ok = FALSE, msg = conditionMessage(e))
  )
}

# ----------------------------
# 1) Install CRAN packages (explicit list)
# ----------------------------
cran_plan <- list(
  list("tidyfst",            TRUE),
  list("configr",            TRUE),
  list("DBI",                TRUE),
  list("renv",               TRUE),
  list("leaflet",            TRUE),
  list("getPass",            TRUE),
  list("DT",                 TRUE),
  list("rjwsacruncher",      TRUE),
  list("sf",                 TRUE),
  list("sfarrow",            FALSE),
  list("dbplyr",             FALSE),
  list("shiny",              FALSE),
  list("rstudioapi",         TRUE),
  list("httr",               TRUE),
  list("readr",              TRUE),
  list("knitr",              TRUE),
  list("rmarkdown",          TRUE),
  list("RCurl",              TRUE),
  list("here",               TRUE),
  list("esquisse",           TRUE),
  list("dcmodify",           TRUE),
  list("simputation",        TRUE),
  list("SmallCountRounding", TRUE),
  list("klassR",             TRUE),
  list("pxwebapidata",       TRUE),
  list("gissb",              TRUE),
  list("igraph",             TRUE),
  list("dggridR",            TRUE),
  list("languageserver",     TRUE),
  list("lintr",              TRUE),
  list("tidyverse",          TRUE),
  list("openxlsx",           TRUE),
  list("survey",             TRUE),
  list("eurostat",           TRUE),
  list("easySdcTable",       TRUE)
)

cran_results <- data.frame(
  pkg = vapply(cran_plan, `[[`, character(1), 1),
  ok = FALSE,
  message = NA_character_,
  stringsAsFactors = FALSE
)

message(">> Installing CRAN packages")
for (i in seq_along(cran_plan)) {
  pkg  <- cran_plan[[i]][[1]]
  deps <- cran_plan[[i]][[2]]
  message(">> install.packages('", pkg, "', dependencies = ", deps, ")")
  res <- ip(pkg, deps = deps)
  cran_results$ok[i] <- isTRUE(res$ok)
  if (!res$ok) cran_results$message[i] <- res$msg
}

# ----------------------------
# 2) Install ROracle from local tarball if present
# ----------------------------
local_pkg <- "/tmp/ROracle_1.4-1_R_x86_64-unknown-linux-gnu.tar.gz"
roracle_ok <- TRUE
roracle_msg <- ""
if (file.exists(local_pkg)) {
  message(">> Installing local tarball: ", local_pkg)
  tryCatch(
    {
      install.packages(local_pkg, repos = NULL, type = "source")
    },
    error = function(e) {
      roracle_ok <<- FALSE
      roracle_msg <<- conditionMessage(e)
    }
  )
} else {
  message(">> Local ROracle tarball not found: skipping")
}

# ----------------------------
# 3) Ensure 'remotes' present for GitHub installs
# ----------------------------
if (!requireNamespace("remotes", quietly = TRUE)) {
  message(">> Installing 'remotes' from CRAN")
  install.packages("remotes", repos = cran)
}

# ----------------------------
# 4) Install GitHub packages
# ----------------------------
gh_pkgs <- c(
  "statisticsnorway/ssb-pris",
  "statisticsnorway/ssb-GaussSuppression",
  "statisticsnorway/ssb-fellesr",
  "statisticsnorway/ssb-kostra",
  "statisticsnorway/ssb-SdcForetakPerson",
  "statisticsnorway/ssb-struktuR",
  "statisticsnorway/ssb-SSBtools",
  "statisticsnorway/ssb-klassr",
  "statisticsnorway/GISSB",
  "statisticsnorway/ReGenesees",
  "statisticsnorway/ssb-pickmdl"
)

gh_results <- data.frame(
  repo = gh_pkgs,
  ok = FALSE,
  message = NA_character_,
  stringsAsFactors = FALSE
)

message(">> Installing GitHub packages")
for (i in seq_along(gh_pkgs)) {
  repo <- gh_pkgs[[i]]
  message(">> remotes::install_github('", repo, "')")
  tryCatch(
    {
      remotes::install_github(repo, dependencies = TRUE, upgrade = "never")
      gh_results$ok[i] <- TRUE
    },
    error = function(e) {
      gh_results$ok[i] <- FALSE
      gh_results$message[i] <- conditionMessage(e)
    }
  )
}

# ----------------------------
# 5) Summary (CRAN + GitHub + local)
# ----------------------------
cran_total <- nrow(cran_results)
cran_ok_n  <- sum(cran_results$ok)
cran_fail  <- cran_results[!cran_results$ok, , drop = FALSE]

gh_total <- nrow(gh_results)
gh_ok_n  <- sum(gh_results$ok)
gh_fail  <- gh_results[!gh_results$ok, , drop = FALSE]

message("")
message(">> CRAN install summary: ", cran_ok_n, "/", cran_total, " packages installed successfully.")
if (nrow(cran_fail) > 0) {
  message(">> Failed CRAN packages:")
  for (i in seq_len(nrow(cran_fail))) {
    msg <- cran_fail$message[i]
    if (is.na(msg) || !nzchar(msg)) msg <- "(no error message captured)"
    message(" - ", cran_fail$pkg[i], ": ", msg)
  }
}

message("")
message(">> GitHub install summary: ", gh_ok_n, "/", gh_total, " repositories installed successfully.")
if (nrow(gh_fail) > 0) {
  message(">> Failed GitHub repositories:")
  for (i in seq_len(nrow(gh_fail))) {
    msg <- gh_fail$message[i]
    if (is.na(msg) || !nzchar(msg)) msg <- "(no error message captured)"
    message(" - ", gh_fail$repo[i], ": ", msg)
  }
}

message("")
if (file.exists(local_pkg)) {
  if (roracle_ok) {
    message(">> Local install summary: ROracle installed successfully.")
  } else {
    message(">> Local install summary: ROracle FAILED: ", roracle_msg)
  }
} else {
  message(">> Local install summary: ROracle tarball not present (skipped).")
}

# Exit non-zero if anything failed
any_fail <- (nrow(cran_fail) > 0) || (nrow(gh_fail) > 0) || (file.exists(local_pkg) && !roracle_ok)
if (any_fail) quit(status = 1)
RSCRIPT
