## JupyterHub On‑Prem 2025

Production‑ready JupyterHub (Hub), JupyterLab, and RStudio single‑user images for an on‑prem RHEL environment. After login, users land on the Control Panel and can run JupyterLab and RStudio at the same time. Both URLs are derived from the username (`/user/<name>/` and `/user/<name>/rstudio/`); users do not name servers. Lab images are based on Ubuntu Noble and include PAM/SSSD integration, an R kernel, and a minimal JupyterLab extension that opens the Hub Control Panel in the same browser tab. RStudio images are spawned through JupyterHub via jupyter-rsession-proxy (not as a standalone RStudio compose stack on the Hub host).

### Contents
- Hub image: `docker/jupyterhub/Dockerfile.hub`
- Lab image: `docker/jupyterhub/Dockerfile.lab` (built twice: R 4.4.0 and R 4.6.0)
- RStudio image: `docker/rstudio/Dockerfile` (built twice: R 4.4.0 and R 4.6.0)
- Docker Compose: `docker/jupyterhub/docker-compose.yml`
- JupyterHub config: `docker/jupyterhub/jupyterhub_config.py`
- Lab extension: `docker/jupyterhub/labextensions/hub-control-panel-same-tab`

### Spawner profiles

| Profile | Image (Nexus) |
|---|---|
| JupyterLab Python 3.13 R 4.4.0 (default) | `onprem-jupyterlab-r440` |
| JupyterLab Python 3.13 R 4.6.0 | `onprem-jupyterlab-r460` |
| RStudio R 4.4.0 | `onprem-rstudio-r440` |
| RStudio R 4.6.0 | `onprem-rstudio-r460` |

Images are pulled via Nexus: `nexus.ssb.no:8439/artifact-registry-5n/itinfra-bakkesyst-docker/<image>:<TAG>`.

## Getting Started

### 1) Build images (from repository root)

```bash
# Hub
docker build -t onprem-jupyterhub -f docker/jupyterhub/Dockerfile.hub docker/jupyterhub

# JupyterLab (R 4.4.0 and R 4.6.0)
docker build -t onprem-jupyterlab-r440 --build-arg R_VERSION=4.4.0 -f docker/jupyterhub/Dockerfile.lab docker/jupyterhub
docker build -t onprem-jupyterlab-r460 --build-arg R_VERSION=4.6.0 -f docker/jupyterhub/Dockerfile.lab docker/jupyterhub

# RStudio (R 4.4.0 and R 4.6.0)
docker build -t onprem-rstudio-r440 --build-arg R_VERSION=4.4.0 -f docker/rstudio/Dockerfile docker/rstudio
docker build -t onprem-rstudio-r460 --build-arg R_VERSION=4.6.0 -f docker/rstudio/Dockerfile docker/rstudio
```

### 2) Run with Docker Compose
Set the Hub image and the four spawner images, then bring the stack up:

```bash
set -a
DOCKER_HUB_IMAGE=onprem-jupyterhub
DOCKER_NOTEBOOK_IMAGE_R440=onprem-jupyterlab-r440
DOCKER_NOTEBOOK_IMAGE_R460=onprem-jupyterlab-r460
DOCKER_RSTUDIO_IMAGE_R440=onprem-rstudio-r440
DOCKER_RSTUDIO_IMAGE_R460=onprem-rstudio-r460
# Optional, if you run a custom authenticator:
# STATBANK_AUTHENTICATOR_IMAGE=<your_statbank_authenticator_image>
set +a

docker compose -f docker/jupyterhub/docker-compose.yml up -d
```

The Hub exposes ports 443 and 8080 (see `docker/jupyterhub/docker-compose.yml`).

### 3) Local testing of Hub + spawner profiles

Production compose needs PAM/SSSD, TLS, `/ssb` and the Statbank sidecar. For a laptop, follow **[local-dev/README.md](local-dev/README.md)**: build the five repo images, start Hub, log in at http://localhost:8000 (`admin` / `test`). AWX ignores `local-dev/`.

### 4) Local testing of JupyterLab (image only)
If you want to run a Lab image by itself:
```bash
docker run -it --rm -p 8888:8888 --entrypoint="" onprem-jupyterlab-r440 jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root
```
## Key Configuration

### Authentication and Spawner
- Spawner: `dockerspawner.SystemUserSpawner` with `allowed_images` (JupyterLab and RStudio, two R versions each).
- Two fixed servers per user: JupyterLab at `/user/<name>/` and RStudio at `/user/<name>/rstudio/` (`named_server_limit_per_user = 1`, no user-chosen names).
- PAM via `PAMAuthenticator` with SSSD. The Compose file mounts:
  - `/var/lib/sss` and `/run/sssd` in the Hub container for lookups.
- Single‑user containers join the `jupyterhub-network` and reach the Hub at `jupyterhub:8080`.
- RStudio profiles set `default_url=/rstudio` so the session opens in the RStudio UI.

### Volumes and Paths
- The NFS share `/ssb` is mounted into both Hub and single‑user containers.
- The single‑user runtime directory is `/tmp/jupyter-runtime` to avoid NFS latency and improve first‑terminal startup time.

### Jupyter Server / Lab Behavior
- Hidden files are shown and culling is enabled via `c.Spawner.args` in `jupyterhub_config.py`.

## JupyterLab Customization

### Hub Control Panel in the same tab
The `hub-control-panel-same-tab` extension replaces the default behavior so the Hub Control Panel opens in the current tab.
- Source: `docker/jupyterhub/labextensions/hub-control-panel-same-tab`
- Built and installed by `Dockerfile.lab`.

### Extension Manager disabled
The Extension Manager is disabled as part of the image build (`jupyter labextension disable @jupyterlab/extensionmanager-extension`).
- Recommended alternative: disable via `page_config.json` for a declarative setup:
  - Path: `/opt/conda/etc/jupyter/labconfig/page_config.json`
  - Example:
    ```json
    {
      "workspacesDisabled": true,
      "disabledExtensions": {
        "@jupyterlab/apputils-extension:layout": true,
        "@jupyterlab/extensionmanager-extension": true
      }
    }
    ```

## Kernels
- IRkernel and required system libraries are installed in the Lab image.
- The kernel launcher script lives in `docker/jupyterhub/kernels/`

## Troubleshooting

### First terminal is slow to open
- Server runtime directory is `/tmp/jupyter-runtime` to avoid NFS latency.

### Building Lab extensions
- The custom extension builds with TypeScript only (no bundler) and targets JupyterLab 4.4.x. Ensure peer/dev dependencies line up with your Lab version.

## Common Commands

```bash
# List running containers
docker ps

# Tail Hub logs
docker logs jupyterhub

# Tail Lab logs (xxx is referenced as initialer)
docker logs jupyter-xxx 

# Restart Hub (look inside of the jupyterhub.service file)
systemctl restart jupyterhub-onprem-2025

# Tear down the stack (look inside of the jupyterhub.service file)
systemctl stop jupyterhub-onprem-2025
```

## CI/CD Pipeline (Github Actions + AWX playbook)

The pipeline follows a simple promotion flow:
- Pull Requests: build Hub, two JupyterLab images, and two RStudio images and publish them to Artifact Registry (no deployment).
- Push to main: build all five images, tag them `latest`, trigger CD, and deploy to the test environment (`sl-jupyter-t1.ssb.no`).
- Release tag (e.g., `vX.Y.Z`): build all five images with semver tags, trigger CD, and deploy to production (`sl-jupyter-p1.ssb.no`).

Nexus (`nexus.ssb.no:8439`) proxies Artifact Registry. AWX still deploys only the Hub compose stack; user images are pulled on spawn (`pull_policy = always`).

This ensures changes are validated in CI, promoted automatically to test on merge, and released to production only on an explicit version tag.

To learn how the CD trigger works read more about it here:
* [AWX playbook CD trigger](https://github.com/statisticsnorway/itinfra_ansible_linux/blob/e022c17e48a98a00b8c8646606526eaf88eab809/playbooks/ghashr_cd.yml)

## Repository Structure
- JupyterHub configuration lives in `docker/jupyterhub/jupyterhub_config.py`.
- `docker/jupyterhub/docker-compose.yml` controls ports, volumes, and networking.
- Customize the Lab image (`docker/jupyterhub/Dockerfile.lab`) as needed for additional packages and extensions.
- Customize the RStudio image (`docker/rstudio/Dockerfile`) as needed. Do not add `.env`, `.service`, or `docker-compose.yml` under `docker/rstudio/` (AWX would pick them up).
