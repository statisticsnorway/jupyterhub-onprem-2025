import os
import sys

# Configuration file for JupyterHub
c = get_config()

# We rely on environment variables to configure JupyterHub so that we
# avoid having to rebuild the JupyterHub container every time we change a
# configuration parameter.

LOCAL_DEV = os.environ.get("JUPYTERHUB_LOCAL_DEV", "").lower() in {"1", "true", "yes"}

# Spawn single-user servers as Docker containers
if LOCAL_DEV:
    # No PAM/SSSD or host users on a laptop — DummyAuthenticator + DockerSpawner
    c.JupyterHub.spawner_class = "dockerspawner.DockerSpawner"
    c.JupyterHub.authenticator_class = "dummy"
    c.DummyAuthenticator.password = os.environ.get("DUMMY_PASSWORD", "test")
    c.Authenticator.admin_users = {"admin"}
    c.Authenticator.allow_all = True
    c.DockerSpawner.pull_policy = os.environ.get("DOCKER_PULL_POLICY", "ifnotpresent")
else:
    c.JupyterHub.spawner_class = "dockerspawner.SystemUserSpawner"

    c.PAMAuthenticator.service = "login"

    # Normalize username, so if user logs in with domain, username@ssb.no
    # then the domain will be cut out once the users notebook server is spawned
    c.PAMAuthenticator.pam_normalize_username = True
    c.PAMAuthenticator.open_sessions = False

    c.Authenticator.allow_all = True

    c.DockerSpawner.pull_policy = "always"

    # Add admin users
    c.PAMAuthenticator.admin_groups = {"RBAG_jupyterhub_admins@ssb.no"}

    # Remove users that are no longer able to authenticate
    c.Authenticator.delete_invalid_users = True

c.DockerSpawner.http_timeout = 120
c.Spawner.start_timeout = 120

# JupyterHub / DockerSpawner have no profile_list (that is KubeSpawner).
# allowed_images with more than one entry renders the spawn form.
_lab_r440 = os.environ["DOCKER_NOTEBOOK_IMAGE_R440"]
_lab_r460 = os.environ["DOCKER_NOTEBOOK_IMAGE_R460"]
_rstudio_r440 = os.environ["DOCKER_RSTUDIO_IMAGE_R440"]
_rstudio_r460 = os.environ["DOCKER_RSTUDIO_IMAGE_R460"]

# Required default only. Users pick the real image from allowed_images
# (Lab 4.4/4.6 or RStudio 4.4/4.6). Used if the spawn form is skipped.
c.DockerSpawner.image = _lab_r440

# Two fixed slots per username — users never type a server name.
#   /user/<username>/          → JupyterLab (default server)
#   /user/<username>/rstudio/  → RStudio (fixed named server)
_RSTUDIO_SERVER_NAME = "rstudio"
_lab_choices = {
    "JupyterLab Python 3.13 R 4.4.0": _lab_r440,
    "JupyterLab Python 3.13 R 4.6.0": _lab_r460,
}
_rstudio_choices = {
    "RStudio R 4.4.0": _rstudio_r440,
    "RStudio R 4.6.0": _rstudio_r460,
}
_rstudio_images = {_rstudio_r440, _rstudio_r460}


def _spawner_name(spawner):
    return getattr(spawner, "name", "") or ""


def _allowed_images_for(spawner):
    if _spawner_name(spawner) == _RSTUDIO_SERVER_NAME:
        return dict(_rstudio_choices)
    return dict(_lab_choices)


c.DockerSpawner.allowed_images = _allowed_images_for


def _resolve_allowed_map(spawner):
    allowed = getattr(spawner, "allowed_images", None)
    if callable(allowed):
        allowed = allowed(spawner)
    return allowed or {}


def _resolve_selected_image(spawner, user_options=None):
    """Map spawn-form image (display name or tag) to an allowed image."""
    opts = user_options if user_options is not None else (spawner.user_options or {})
    image = opts.get("image") if opts else None
    if isinstance(image, list):
        image = image[0] if image else None
    if not image:
        image = spawner.image
    allowed = _resolve_allowed_map(spawner)
    if isinstance(allowed, dict) and image in allowed:
        return allowed[image]
    return image


def _apply_image_defaults(spawner):
    # DockerSpawner.start() applies user_options.image *after* this hook.
    # Resolve it here so RStudio gets /rstudio and a directory that exists.
    name = _spawner_name(spawner)
    if name and name != _RSTUDIO_SERVER_NAME:
        raise ValueError(
            f"Server name {name!r} is not allowed. "
            "Use the default server for JupyterLab or 'rstudio' for RStudio."
        )

    image = _resolve_selected_image(spawner)
    if name == _RSTUDIO_SERVER_NAME and image not in _rstudio_images:
        image = _rstudio_r440
    elif name != _RSTUDIO_SERVER_NAME and image in _rstudio_images:
        image = _lab_r440
    if image:
        spawner.image = image

    if name == _RSTUDIO_SERVER_NAME:
        rstudio_mem_default = (
            os.environ.get("DOCKER_MEM_LIMIT", "2G") if LOCAL_DEV else "50G"
        )
        spawner.mem_limit = os.environ.get(
            "DOCKER_RSTUDIO_MEM_LIMIT", rstudio_mem_default
        )

    rstudio_url = os.environ.get("RSTUDIO_DEFAULT_URL", "/rstudio")
    if image in _rstudio_images:
        spawner.default_url = rstudio_url
        if LOCAL_DEV:
            spawner.notebook_dir = os.environ.get(
                "DOCKER_RSTUDIO_NOTEBOOK_DIR", "/home/rstudio/work"
            )
            extra = dict(getattr(spawner, "extra_create_kwargs", None) or {})
            extra.setdefault("user", "rstudio")
            spawner.extra_create_kwargs = extra
            env = dict(getattr(spawner, "environment", None) or {})
            env.setdefault("HOME", "/home/rstudio")
            env.setdefault("USER", "rstudio")
            env.setdefault("JUPYTER_RSESSION_PROXY_USE_SOCKET", "no")
            env.setdefault("RSERVER_TIMEOUT", "60")
            spawner.environment = env
            # Default Hub args set log_level=WARN and hide /rstudio/rpc traffic.
            args = [a for a in (spawner.args or []) if not a.startswith("--ServerApp.log_level=")]
            args.append("--ServerApp.log_level=INFO")
            spawner.args = args
    else:
        spawner.default_url = "/lab"
        if LOCAL_DEV:
            spawner.notebook_dir = os.environ.get("DOCKER_NOTEBOOK_DIR", "/home/jovyan")


c.DockerSpawner.pre_spawn_hook = _apply_image_defaults


def _apply_user_options(spawner, user_options):
    """JupyterHub does not apply form values unless this hook is set."""
    image = _resolve_selected_image(spawner, user_options)
    if not image:
        return
    allowed = _resolve_allowed_map(spawner)
    if isinstance(allowed, dict) and image not in allowed and image not in allowed.values():
        raise ValueError(f"Image not allowed: {image}")
    spawner.image = image


c.Spawner.apply_user_options = _apply_user_options
c.DockerSpawner.apply_user_options = _apply_user_options

# JupyterHub requires a single-user instance of the Notebook server, so we
# default to using the `start-singleuser.sh` script included in the
# jupyter/docker-stacks *-notebook images as the Docker run command when
# spawning containers.  Optionally, you can override the Docker run command
# using the DOCKER_SPAWN_CMD environment variable.
# Note: Since ENTRYPOINT is start-singleuser.sh and CMD is ["jupyterhub-singleuser"],
# DOCKER_SPAWN_CMD can override the entire CMD. If it starts with "jupyterhub-singleuser",
# it will be used as-is. Otherwise, it's treated as additional arguments.
# SystemUserSpawner will use CMD from Dockerfile by default: ["jupyterhub-singleuser"]
spawn_cmd = os.environ.get("DOCKER_SPAWN_CMD", None)
if spawn_cmd:
    # Split spawn_cmd into list for DockerSpawner.cmd
    # This will override CMD from Dockerfile
    # ENTRYPOINT (start-singleuser.sh) will receive these as $@ arguments
    # start-singleuser.sh will then run: exec jupyterhub-singleuser "$@"
    cmd_parts = spawn_cmd.split()
    c.DockerSpawner.cmd = cmd_parts

# Enable SystemUserSpawner features

# Connect containers to this Docker network
network_name = os.environ["DOCKER_NETWORK_NAME"]

c.DockerSpawner.use_internal_ip = True
c.DockerSpawner.network_name = network_name

# Pass the network name as argument to spawned containers
c.DockerSpawner.extra_host_config = {"network_mode": network_name}

# Memory limits
# Documentation https://jupyterhub-dockerspawner.readthedocs.io/en/latest/api/index.html
if LOCAL_DEV:
    c.DockerSpawner.mem_guarantee = os.environ.get("DOCKER_MEM_GUARANTEE", "256M")
    c.DockerSpawner.mem_limit = os.environ.get("DOCKER_MEM_LIMIT", "2G")
    c.DockerSpawner.volumes = {}
    c.DockerSpawner.notebook_dir = os.environ.get("DOCKER_NOTEBOOK_DIR", "/home/jovyan")
else:
    c.DockerSpawner.mem_guarantee = "5G"
    c.DockerSpawner.mem_limit = "50G"

    # /ssb comes from Hub compose; user files live under /ssb/bruker/<username>.
    c.DockerSpawner.volumes = {
        "/ssb": "/ssb",
        "/var/lib/sss/pipes": {"bind": "/var/lib/sss/pipes", "mode": "ro,Z"},
        "/var/lib/sss/mc":    {"bind": "/var/lib/sss/mc",    "mode": "rw,Z"},
    }
    # Jupyter/RStudio start here (SSSD user). DockerSpawner 14 expands
    # {username} to the escaped container name (admin-paf → admin-2dpaf).
    # NFS homes use the real AD name, so notebook_dir must use {raw_username}.
    # host_homedir_format_string formats with user.name (unescaped) already.
    c.DockerSpawner.notebook_dir = "/ssb/bruker/{raw_username}"
    # Also bind that share to /home/{username} ($HOME for the AD user).
    c.SystemUserSpawner.host_homedir_format_string = "/ssb/bruker/{username}"
# Allowing users to delete non-empty directories in the jupyterlab file-explorer
c.FileContentsManager.always_delete_dir = True

# Remove containers once they are stopped
c.DockerSpawner.remove = True

# For debugging arguments passed to spawned containers
c.DockerSpawner.debug = True

# Prometheus
c.JupyterHub.authenticate_prometheus = False

# JupyterHub idle-culler (RBAC scopes; admin: True is JupyterHub < 2)
c.JupyterHub.services = [
    {
        "name": "jupyterhub-idle-culler-service",
        "command": [
            sys.executable,
            "-m",
            "jupyterhub_idle_culler",
            "--timeout=3600",
        ],
    }
]
c.JupyterHub.load_roles = [
    {
        "name": "jupyterhub-idle-culler",
        "description": "Cull idle servers",
        "scopes": [
            "list:users",
            "read:users:activity",
            "admin:servers",
        ],
        "services": ["jupyterhub-idle-culler-service"],
    }
]

# User containers will access hub by container name on the Docker network
c.JupyterHub.hub_port = 8080
if LOCAL_DEV:
    c.JupyterHub.bind_url = "http://:8000"
    c.JupyterHub.hub_bind_url = "http://0.0.0.0:8080"
    c.JupyterHub.hub_connect_url = "http://jupyterhub:8080"
else:
    c.JupyterHub.hub_ip = "jupyterhub"
    # TLS config
    c.JupyterHub.port = 443
    c.JupyterHub.ssl_key = os.environ["SSL_KEY"]
    c.JupyterHub.ssl_cert = os.environ["SSL_CERT"]

# Two containers per user, both keyed off the login name — no user-chosen names.
# After login, land on Control Panel so both JupyterLab and RStudio are visible.
c.JupyterHub.allow_named_servers = True
c.JupyterHub.named_server_limit_per_user = 1
c.JupyterHub.redirect_to_server = False
c.JupyterHub.default_url = "/hub/home"
c.JupyterHub.template_paths = ["/srv/jupyterhub/templates"]

# Skip OAuth consent screen for single-user servers (removed in JupyterHub 6).
from jupyterhub.app import JupyterHub as _JupyterHubApp

if "oauth_no_confirm" in _JupyterHubApp.class_traits():
    c.JupyterHub.oauth_no_confirm = True
# ---------------------------
# Disable browser caching for Hub pages/assets (removed in JupyterHub 6).
if "extra_headers" in _JupyterHubApp.class_traits():
    c.JupyterHub.extra_headers = {
        "Cache-Control": "no-store, no-cache, must-revalidate, max-age=0",
        "Pragma": "no-cache",
        "Expires": "0",
    }
# Also prevent long-lived caching of Hub static files
c.JupyterHub.tornado_settings = {"static_cache_max_age": 0}
# ---------------------------

# Persist hub data on volume mounted inside container
data_dir = os.environ.get("DATA_VOLUME_CONTAINER", "/data")

c.JupyterHub.cookie_secret_file = os.path.join(data_dir, "jupyterhub_cookie_secret")

c.JupyterHub.db_url = f"sqlite:///{data_dir}/jupyterhub.sqlite"

# Combine both environment configurations
c.DockerSpawner.environment = {
    # Keep application-specific variables
    "STATBANK_ENCRYPT_URL": os.environ.get("STATBANK_ENCRYPT_URL", "UNKNOWN"),
    "STATBANK_BASE_URL": os.environ.get("STATBANK_BASE_URL", "UNKNOWN"),
    "STATBANK_TEST_BASE_URL": os.environ.get("STATBANK_TEST_BASE_URL", "UNKNOWN"),
    # Set the hostname of the server. We use this environment variable to match with the
    # one used in Dapla Jupyterhub.
    "JUPYTERHUB_HTTP_REFERER": os.environ.get("JUPYTERHUB_HTTP_REFERER", "UNKNOWN"),
    "DAPLA_ENVIRONMENT": os.environ.get("DAPLA_ENVIRONMENT", "UNKNOWN"),
}

c.DockerSpawner.environment.update({
    "JUPYTER_RUNTIME_DIR": "/tmp/jupyter-runtime",
    "JUPYTER_PLATFORM_DIRS": "1",
})

# marimo-jupyter-extension runtime configuration:
# - Use a wrapper that selects Poetry venv when available in the current project.
# - This keeps marimo imports aligned with packages added via `poetry add`.
c.MarimoProxyConfig.marimo_path = "/usr/local/bin/marimo-launch"
c.MarimoProxyConfig.timeout = 120
# -------------------------------------------------------------------
# Extra args to enforce single-user server config across all spawns
# -------------------------------------------------------------------
c.Spawner.args = [
    "--ServerApp.shutdown_no_activity_timeout=28800",
    '--ServerApp.tornado_settings={"static_cache_max_age":0}',
    "--ServerApp.log_level=WARN",
    "--MappingKernelManager.cull_idle_timeout=3600",
    "--MappingKernelManager.cull_interval=120",
    "--MappingKernelManager.cull_connected=False",
    "--MappingKernelManager.cull_busy=False",
    "--TerminalManager.cull_inactive_timeout=3600",
    "--TerminalManager.cull_interval=120",
    "--FileContentsManager.always_delete_dir=True",
    "--ContentsManager.allow_hidden=True",
]
