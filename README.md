## JupyterHub On‑Prem 2025

Production‑ready JupyterHub (Hub) and JupyterLab single‑user (Lab) images for an on‑prem RHEL environment. The Lab image is based on Ubuntu Noble and includes PAM/SSSD integration, an R kernel, and a minimal JupyterLab extension that opens the Hub Control Panel in the same browser tab.

### Contents
- Hub image: `docker/jupyterhub/Dockerfile.hub`
- Lab image: `docker/jupyterhub/Dockerfile.lab`
- Docker Compose: `docker/jupyterhub/docker-compose.yml`
- JupyterHub config: `docker/jupyterhub/jupyterhub_config.py`
- Lab extension: `docker/jupyterhub/labextensions/hub-control-panel-same-tab`

## Getting Started

### 1) Build images (from repository root)

```bash
# Build Lab (single‑user)
docker build -t jupyterhub-onprem-lab -f docker/jupyterhub/Dockerfile.lab docker/jupyterhub

# Build Hub
docker build -t jupyterhub-onprem-hub -f docker/jupyterhub/Dockerfile.hub docker/jupyterhub
```

### 2) Run with Docker Compose
Set the images you want to run and bring the stack up:

```bash
set -a
DOCKER_NOTEBOOK_IMAGE=jupyterhub-onprem-lab
DOCKER_HUB_IMAGE=jupyterhub-onprem-hub
# Optional, if you run a custom authenticator:
# STATBANK_AUTHENTICATOR_IMAGE=<your_statbank_authenticator_image>
set +a

docker compose -f docker/jupyterhub/docker-compose.yml up -d
```

The Hub exposes ports 443 and 8080 (see `docker/jupyterhub/docker-compose.yml`).

## Key Configuration

### Authentication and Spawner
- Spawner: `dockerspawner.SystemUserSpawner`.
- PAM via `PAMAuthenticator` with SSSD. The Compose file mounts:
  - `/var/lib/sss` and `/run/sssd` in the Hub container for lookups.
- Single‑user containers join the `jupyterhub-network` and reach the Hub at `jupyterhub:8080`.

### Volumes and Paths
- The NFS share `/ssb` is mounted into both Hub and single‑user containers.
- The single‑user runtime directory is `/tmp/jupyter-runtime` to avoid NFS latency and improve first‑terminal startup time.

### Jupyter Server / Lab Behavior
- Hidden files are shown and culling is enabled via `c.Spawner.args` in `jupyterhub_config.py`.
- Alternatively, you can place equivalent settings as JSON in the Lab image under `/opt/conda/etc/jupyter/jupyter_server_config.d/` if you prefer fewer runtime arguments.

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

## R Kernel
- IRkernel and required system libraries are installed in the Lab image.
- The kernel launcher script lives in `docker/jupyterhub/kernels/ir/r.sh`.

## Troubleshooting

### Terminal prompt shows "I have no name!"
- Ensure SSSD/PAM lookups are functioning in the relevant containers.
- Do not mount `/etc/shadow` from the host; it may break authentication.

### First terminal is slow to open
- Server runtime directory is `/tmp/jupyter-runtime` to avoid NFS latency.
- Shell initialization is optimized; set `FAST_SHELL=1` for extra‑fast init if needed.

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
- Pull Requests: build the Hub and Lab images and publish them as CI artifacts (no deployment).
- Push to main: trigger CD and deploy the latest images to the test environment.
- Release tag on main (e.g., `vX.Y.Z`): trigger CD and deploy the tagged images to the production environment.

This ensures changes are validated in CI, promoted automatically to test on merge, and released to production only on an explicit version tag.

To learn how the CD trigger works read more about it here:
* [AWX playbook CD trigger](https://github.com/statisticsnorway/itinfra_ansible_linux/blob/e022c17e48a98a00b8c8646606526eaf88eab809/playbooks/ghashr_cd.yml)

## Repository Structure
- JupyterHub configuration lives in `docker/jupyterhub/jupyterhub_config.py`.
- `docker/jupyterhub/docker-compose.yml` controls ports, volumes, and networking.
- Customize the Lab image (`Dockerfile.lab`) as needed for additional packages and extensions.

