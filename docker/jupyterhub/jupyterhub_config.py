import os
import sys

# Configuration file for JupyterHub
c = get_config()

# We rely on environment variables to configure JupyterHub so that we
# avoid having to rebuild the JupyterHub container every time we change a
# configuration parameter.

# Spawn single-user servers as Docker containers
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

# Spawn containers from this image
c.DockerSpawner.image = os.environ["DOCKER_NOTEBOOK_IMAGE"]

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
c.DockerSpawner.mem_guarantee = "5G"
c.DockerSpawner.mem_limit = "50G"

# Mounting /ssb/bruker from the jupyterhub container to the user container
c.DockerSpawner.volumes = {
    "/ssb": "/ssb",
    "/var/lib/sss/pipes": {"bind": "/var/lib/sss/pipes", "mode": "ro,Z"},
    "/var/lib/sss/mc":    {"bind": "/var/lib/sss/mc",    "mode": "rw,Z"},
    "/usr/local/share/ca-certificates/cert_Decrypt-CA.crt": {"bind": "/usr/local/share/ca-certificates/cert_Decrypt-CA.crt", "mode": "ro,Z"},
}
# host_homedir_format_string must be set to map /ssb/bruker/{username} to /home/{username}
c.SystemUserSpawner.host_homedir_format_string = "/ssb/bruker/{username}"
# Allowing users to delete non-empty directories in the jupyterlab file-explorer
c.FileContentsManager.always_delete_dir = True

# Remove containers once they are stopped
c.DockerSpawner.remove = True

# For debugging arguments passed to spawned containers
c.DockerSpawner.debug = True

# Prometheus
c.JupyterHub.authenticate_prometheus = False

# Jupyterhub idle-culler-service
c.JupyterHub.services = [
    {
        "name": "jupyterhub-idle-culler-service",
        "command": [
            sys.executable,
            "-m",
            "jupyterhub_idle_culler",
            "--timeout=3600",
        ],
        "admin": True,
    }
]

# User containers will access hub by container name on the Docker network
c.JupyterHub.hub_ip = "jupyterhub"
c.JupyterHub.hub_port = 8080

# TLS config
c.JupyterHub.port = 443
c.JupyterHub.ssl_key = os.environ["SSL_KEY"]
c.JupyterHub.ssl_cert = os.environ["SSL_CERT"]

# Skip OAuth consent screen for single-user servers
c.JupyterHub.oauth_no_confirm = True
# ---------------------------
# Disable browser caching for Hub pages/assets
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
    # Set the hostname of the server. We use this environment variable to match with the
    # one used in Dapla Jupyterhub.
    "JUPYTERHUB_HTTP_REFERER": os.environ.get("JUPYTERHUB_HTTP_REFERER", "UNKNOWN"),
    "DAPLA_ENVIRONMENT": os.environ.get("DAPLA_ENVIRONMENT", "UNKNOWN"),
}

c.DockerSpawner.environment.update({
    "JUPYTER_RUNTIME_DIR": "/tmp/jupyter-runtime",
    "JUPYTER_PLATFORM_DIRS": "1",
})
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
