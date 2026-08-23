# Start the local JupyterHub stack against images tagged *:local.
# Build those images first with .\local-dev\build-images.ps1
# (or pass -Stub to test Hub UI only, without the real Lab/RStudio images).
param(
    [switch]$Stub
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $RepoRoot

$Required = @(
    "onprem-jupyterhub:local",
    "onprem-jupyterlab-r440:local",
    "onprem-jupyterlab-r460:local",
    "onprem-rstudio-r440:local",
    "onprem-rstudio-r460:local"
)

if ($Stub) {
    Write-Host "Building Hub image (onprem-jupyterhub:local)..."
    docker build -t onprem-jupyterhub:local -f docker/jupyterhub/Dockerfile.hub docker/jupyterhub
    if ($LASTEXITCODE -ne 0) { throw "Hub image build failed" }

    Write-Host "Pulling jupyter/base-notebook (stub for all four spawn images)..."
    docker pull jupyter/base-notebook:latest
    if ($LASTEXITCODE -ne 0) { throw "Failed to pull jupyter/base-notebook" }

    foreach ($tag in @(
            "onprem-jupyterlab-r440:local",
            "onprem-jupyterlab-r460:local",
            "onprem-rstudio-r440:local",
            "onprem-rstudio-r460:local"
        )) {
        docker tag jupyter/base-notebook:latest $tag
        Write-Host "Tagged stub $tag"
    }
}
else {
    $missing = @()
    foreach ($tag in $Required) {
        $id = docker images -q $tag
        if (-not $id) { $missing += $tag }
    }
    if ($missing.Count -gt 0) {
        Write-Host "Missing local images:"
        $missing | ForEach-Object { Write-Host "  $_" }
        Write-Host ""
        Write-Host "Build them from this repo first:"
        Write-Host "  .\local-dev\build-images.ps1"
        Write-Host ""
        Write-Host "Or start Hub UI only (not the real Lab/RStudio images):"
        Write-Host "  .\local-dev\up.ps1 -Stub"
        throw "Local images are missing"
    }
}

Write-Host "Starting local Hub on http://localhost:8000 ..."
docker compose --env-file local-dev/.env -f local-dev/docker-compose.yml up -d
if ($LASTEXITCODE -ne 0) { throw "docker compose up failed" }

Write-Host ""
Write-Host "Hub is up:  http://localhost:8000"
Write-Host "Login:      admin  /  password: test"
Write-Host "            (any username works; password is DUMMY_PASSWORD in local-dev/.env)"
Write-Host "Then start JupyterLab + R and/or RStudio from the Control Panel."
Write-Host "Logs:       docker logs -f jupyterhub"
Write-Host "Stop:       docker compose --env-file local-dev/.env -f local-dev/docker-compose.yml down"
