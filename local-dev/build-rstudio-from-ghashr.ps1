# Wrap the published rstudio-onprem image with JupyterHub single-user bits.
param(
    [string]$From = "europe-north1-docker.pkg.dev/artifact-registry-5n/itinfra-bakkesyst-docker/rstudio-onprem:0.3.7",
    [string]$Tag = "onprem-rstudio-r440:local"
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $RepoRoot

Write-Host "Wrapping $From -> $Tag ..."
docker build `
    --build-arg GHASHR_IMAGE=$From `
    -t $Tag `
    -f local-dev/Dockerfile.rstudio-from-ghashr `
    .
if ($LASTEXITCODE -ne 0) { throw "ghashr Hub wrapper build failed" }

Write-Host "Done. Spawn RStudio R 4.4.0 from http://localhost:8000/hub/home"
