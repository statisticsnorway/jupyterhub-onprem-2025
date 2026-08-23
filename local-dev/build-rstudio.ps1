# Build the real RStudio image (rstudio-onprem-ghashr + jupyter-rsession-proxy).
# This takes a long time (R from source, TeX, Oracle, ...).
param(
    [string]$RVersion = "4.4.0",
    [string]$Tag = "onprem-rstudio-r440:local"
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $RepoRoot

Write-Host "Building $Tag with R_VERSION=$RVersion ..."
docker build `
    --build-arg R_VERSION=$RVersion `
    -t $Tag `
    -f docker/rstudio/Dockerfile `
    docker/rstudio
if ($LASTEXITCODE -ne 0) { throw "RStudio image build failed" }

# Until a separate R 4.6.0 image exists locally, reuse this image for that profile too.
if ($Tag -eq "onprem-rstudio-r440:local") {
    docker tag $Tag onprem-rstudio-r460:local
    Write-Host "Also tagged onprem-rstudio-r460:local (same image until R 4.6.0 is built)"
}

Write-Host "Done. Restart Hub: docker compose --env-file local-dev/.env -f local-dev/docker-compose.yml restart"
