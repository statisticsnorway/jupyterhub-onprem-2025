# Build the real RStudio image (rstudio-onprem-ghashr + jupyter-rsession-proxy).
# This takes a long time (R from source, TeX, Oracle, ...).
param(
    [string]$RVersion = "4.4.0",
    [string]$Tag = "onprem-rstudio-r440:local",
    [string]$JavaVersion = "17",
    [string]$CranDistro = "noble"
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $RepoRoot

Write-Host "Building $Tag with R_VERSION=$RVersion JAVA_VERSION=$JavaVersion CRAN_DISTRO=$CranDistro ..."
docker build `
    --build-arg R_VERSION=$RVersion `
    --build-arg JAVA_VERSION=$JavaVersion `
    --build-arg CRAN_DISTRO=$CranDistro `
    --build-arg ARROW_VERSION=24.0.0 `
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
