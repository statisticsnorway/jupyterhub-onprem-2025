# Override marimo proxy to use "python3 -m marimo" so it works when the
# marimo script has permission issues (e.g. SystemUserSpawner with host UID).
# See: PermissionError: [Errno 13] Permission denied: 'marimo'
c.ServerProxy.servers["marimo"] = {
    "command": [
        "python3",
        "-m",
        "marimo",
        "edit",
        "--port",
        "{port}",
        "--base-url",
        "{base_url}marimo/",
    ],
    "timeout": 30,
}
