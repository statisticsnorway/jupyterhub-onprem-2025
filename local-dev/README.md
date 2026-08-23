# Local JupyterHub (laptop)

This folder is a laptop stack for the images and Hub config in this repository. It does not use PAM, TLS, `/ssb`, SSSD, or the Statbank sidecar. AWX does not deploy anything under `local-dev/`.

You get the same five containers CI builds:

| What you start | Image tag | Built from |
|---|---|---|
| Hub | `onprem-jupyterhub:local` | `docker/jupyterhub/Dockerfile.hub` |
| JupyterLab + R 4.4.0 | `onprem-jupyterlab-r440:local` | `docker/jupyterhub/Dockerfile.lab` |
| JupyterLab + R 4.6.0 | `onprem-jupyterlab-r460:local` | `docker/jupyterhub/Dockerfile.lab` |
| RStudio R 4.4.0 | `onprem-rstudio-r440:local` | `docker/rstudio/Dockerfile` |
| RStudio R 4.6.0 | `onprem-rstudio-r460:local` | `docker/rstudio/Dockerfile` |

Compose starts **only the Hub**. Lab and RStudio are created when you click Start on the Control Panel.

## Prerequisites

- Docker Desktop running (Linux containers)
- Enough disk and RAM for full image builds (Lab and RStudio each take a long time and several GB)
- Run all commands from the **repository root**

Windows: PowerShell (`.ps1`). macOS/Linux: bash (`.sh`). If `./local-dev/*.sh` is not executable after clone, run `chmod +x local-dev/*.sh` once.

## 1. Build the repo images

First build is slow (R from source, TeX, Arrow, conda, …). Rebuild only what you changed after that.

**Windows**

```powershell
.\local-dev\build-images.ps1
.\local-dev\build-images.ps1 -Only hub
.\local-dev\build-images.ps1 -Only lab
.\local-dev\build-images.ps1 -Only rstudio
```

**macOS / Linux**

```bash
./local-dev/build-images.sh
./local-dev/build-images.sh hub
./local-dev/build-images.sh lab
./local-dev/build-images.sh rstudio
```

Build-args match CI: `PYTHON_VERSION=313`, `ARROW_VERSION=24.0.0`, `R_VERSION` 4.4.0 or 4.6.0.

## 2. Start Hub

**Windows:** `.\local-dev\up.ps1`  
**macOS / Linux:** `./local-dev/up.sh`

That runs:

```bash
docker compose --env-file local-dev/.env -f local-dev/docker-compose.yml up -d
```

If an image tagged `:local` is missing, the script stops and tells you to run `build-images`.

## 3. Log in and spawn

1. Open http://localhost:8000
2. Log in as `admin` / `test` (any username works; password is `DUMMY_PASSWORD` in `local-dev/.env`)
3. Control Panel shows two cards:
   - **JupyterLab + R** → `/user/<name>/` — pick R 4.4.0 or 4.6.0
   - **RStudio** → `/user/<name>/rstudio/` — pick R 4.4.0 or 4.6.0
4. You can run JupyterLab and RStudio at the same time

Hub config and the home template are bind-mounted from the repo, so edits to `docker/jupyterhub/jupyterhub_config.py` and `docker/jupyterhub/templates/` apply after a Hub recreate (no Hub image rebuild):

```bash
docker compose --env-file local-dev/.env -f local-dev/docker-compose.yml up -d --force-recreate
```

Dockerfile changes still need `build-images` and then a new spawn (Stop the user server, then Start again). `DOCKER_PULL_POLICY=never` so Hub uses the local tags and does not pull from Nexus.

## Stop

```bash
docker compose --env-file local-dev/.env -f local-dev/docker-compose.yml down
```

User containers may remain. Remove them with `docker ps -a` / `docker rm` if needed.

## What to rebuild

| You changed | Rebuild / restart |
|---|---|
| `Dockerfile.hub` or Hub image files | `build-images` hub, then recreate Hub |
| `Dockerfile.lab` or files under `docker/jupyterhub/` used by Lab | `build-images` lab, Stop + Start JupyterLab |
| `docker/rstudio/Dockerfile` or files under `docker/rstudio/` | `build-images` rstudio, Stop + Start RStudio |
| `jupyterhub_config.py` or `templates/` | Recreate Hub only |
| `local-dev/.env` or `local-dev/docker-compose.yml` | Recreate Hub |

## Optional: Hub UI only (stubs)

To check login and the Control Panel without building Lab/RStudio (hours):

**Windows:** `.\local-dev\up.ps1 -Stub`  
**macOS / Linux:** `./local-dev/up.sh --stub`

That builds Hub from this repo and tags `jupyter/base-notebook` as the four spawn images. All four “profiles” then open JupyterLab, not real R or RStudio. Do not use `-Stub` after you have real `:local` images unless you intend to overwrite those tags.

## Logs

```powershell
docker logs -f jupyterhub
docker ps
```

Spawned servers are named like `jupyter-admin` (Lab) and `jupyter-admin-rstudio` (RStudio).

## Layout

- `docker-compose.yml` — Hub only, port 8000, DummyAuthenticator
- `.env` — image tags and local memory/path defaults
- `build-images.ps1` / `build-images.sh` — build the five repo images
- `up.ps1` / `up.sh` — start Hub against those tags
- `Dockerfile.rstudio-mvp` / `build-rstudio*.ps1` — older shortcuts; prefer `build-images` when you want to test this repository
