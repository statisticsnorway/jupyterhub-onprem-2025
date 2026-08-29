# Build the Hub, JupyterLab, and RStudio images from this repository
# (same Dockerfiles and build-args as CI). Tag them *:local for local-dev/.env.
param(
    [ValidateSet("all", "hub", "lab", "rstudio")]
    [string[]]$Only = @("all")
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $RepoRoot

$PythonVersion = "313"
$ArrowVersion = "24.0.0"
$JavaVersion = "17"
$CranDistro = "noble"
$BuildAll = $Only -contains "all"

function Invoke-RepoBuild {
    param(
        [Parameter(Mandatory = $true)][string]$Tag,
        [Parameter(Mandatory = $true)][string]$File,
        [Parameter(Mandatory = $true)][string]$Context,
        [string]$RVersion = "",
        [string]$PyVersion = "",
        [string]$Arrow = "",
        [string]$Java = "",
        [string]$Cran = ""
    )

    Write-Host ""
    Write-Host "=== Building $Tag ==="
    $args = @("build", "-t", $Tag, "-f", $File)
    if ($RVersion) { $args += @("--build-arg", "R_VERSION=$RVersion") }
    if ($PyVersion) { $args += @("--build-arg", "PYTHON_VERSION=$PyVersion") }
    if ($Arrow) { $args += @("--build-arg", "ARROW_VERSION=$Arrow") }
    if ($Java) { $args += @("--build-arg", "JAVA_VERSION=$Java") }
    if ($Cran) { $args += @("--build-arg", "CRAN_DISTRO=$Cran") }
    $args += $Context

    docker @args
    if ($LASTEXITCODE -ne 0) { throw "Build failed: $Tag" }
}

if ($BuildAll -or ($Only -contains "hub")) {
    Invoke-RepoBuild -Tag "onprem-jupyterhub:local" `
        -File "docker/jupyterhub/Dockerfile.hub" `
        -Context "docker/jupyterhub"
}

if ($BuildAll -or ($Only -contains "lab")) {
    Invoke-RepoBuild -Tag "onprem-jupyterlab-r440:local" `
        -File "docker/jupyterhub/Dockerfile.lab" `
        -Context "docker/jupyterhub" `
        -RVersion "4.4.0" -PyVersion $PythonVersion -Arrow $ArrowVersion -Java $JavaVersion -Cran $CranDistro
    Invoke-RepoBuild -Tag "onprem-jupyterlab-r460:local" `
        -File "docker/jupyterhub/Dockerfile.lab" `
        -Context "docker/jupyterhub" `
        -RVersion "4.6.0" -PyVersion $PythonVersion -Arrow $ArrowVersion -Java $JavaVersion -Cran $CranDistro
}

if ($BuildAll -or ($Only -contains "rstudio")) {
    Invoke-RepoBuild -Tag "onprem-rstudio-r440:local" `
        -File "docker/rstudio/Dockerfile" `
        -Context "docker/rstudio" `
        -RVersion "4.4.0" -Arrow $ArrowVersion -Java $JavaVersion -Cran $CranDistro
    Invoke-RepoBuild -Tag "onprem-rstudio-r460:local" `
        -File "docker/rstudio/Dockerfile" `
        -Context "docker/rstudio" `
        -RVersion "4.6.0" -Arrow $ArrowVersion -Java $JavaVersion -Cran $CranDistro
}

Write-Host ""
Write-Host "Done. Start Hub with: .\local-dev\up.ps1  (macOS/Linux: ./local-dev/up.sh)"
