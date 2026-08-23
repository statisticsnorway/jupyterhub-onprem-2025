#!/bin/bash
set -e

echo "Entered rstudio start-singleuser.sh with args: $@"

# SSB shared environment (symlink created at image build)
if [ -f /etc/profile.d/stamme_variabel ]; then
    # shellcheck disable=SC1091
    source /etc/profile.d/stamme_variabel
fi

export STATBANK_BASE_URL="${STATBANK_BASE_URL:-}"
export STATBANK_ENCRYPT_URL="${STATBANK_ENCRYPT_URL:-}"

# TeX Live must be on PATH for non-login subprocesses (RMarkdown/Quarto PDF)
if [ -d /usr/local/texlive/bin/x86_64-linux ]; then
    export PATH="/usr/local/texlive/bin/x86_64-linux:${PATH}"
fi
if [ -d /usr/lib/rstudio-server/bin ]; then
    export PATH="/usr/lib/rstudio-server/bin:${PATH}"
fi

# Run start-notebook.d hooks in background (authenticated user from SystemUserSpawner)
if [ -d "/usr/local/bin/start-notebook.d" ]; then
    echo "start-singleuser.sh: starting hooks in /usr/local/bin/start-notebook.d as uid/gid $(id -u)/$(id -g)"
    for hook in /usr/local/bin/start-notebook.d/*; do
        [ -e "$hook" ] || continue
        case "$hook" in
            *.sh) nohup bash -c ". \"$hook\"" > "/tmp/$(basename "$hook").log" 2>&1 & ;;
            *.py) nohup python3 "$hook" > "/tmp/$(basename "$hook").log" 2>&1 & ;;
            *)    nohup "$hook" > "/tmp/$(basename "$hook").log" 2>&1 & ;;
        esac
    done
fi

# Run before-notebook.d hooks synchronously
if [ -d "/usr/local/bin/before-notebook.d" ]; then
    echo "start-singleuser.sh: running hooks in /usr/local/bin/before-notebook.d as uid/gid $(id -u)/$(id -g)"
    for hook in /usr/local/bin/before-notebook.d/*; do
        [ -e "$hook" ] || continue
        case "$hook" in
            *.sh) . "$hook" ;;
            *.py) python3 "$hook" ;;
            *)    "$hook" ;;
        esac
    done
fi

if [ "$1" = "jupyterhub-singleuser" ]; then
    shift
fi
# Local DockerSpawner may start this image as root
if [ "$(id -u)" = "0" ]; then
    set -- --allow-root "$@"
fi
echo "Starting jupyterhub-singleuser $@"
exec jupyterhub-singleuser "$@"
