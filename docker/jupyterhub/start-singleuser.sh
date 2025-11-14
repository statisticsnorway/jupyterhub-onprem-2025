#!/bin/bash
set -e

# Determine target user from JupyterHub or fallback to jovyan
TARGET_USER="${JUPYTERHUB_USER:-jovyan}"
CURRENT_UID=$(id -u)
CURRENT_GID=$(id -g)

echo "Entered start-singleuser.sh with args: $@"
echo "Target user: $TARGET_USER, Current UID/GID: $CURRENT_UID / $CURRENT_GID"

# Run start-notebook.d hooks as root (uid/gid 0/0)
if [ -d "/usr/local/bin/start-notebook.d" ]; then
    echo "/usr/local/bin/start-singleuser.sh: running hooks in /usr/local/bin/start-notebook.d as uid / gid: $(id -u) / $(id -g)"
    for hook in /usr/local/bin/start-notebook.d/*; do
        [ -e "$hook" ] || continue
        case "$hook" in
            *.sh)
                echo "/usr/local/bin/start-singleuser.sh: running script $hook"
                . "$hook"
                ;;
            *.py)
                echo "/usr/local/bin/start-singleuser.sh: running script $hook"
                python3 "$hook"
                ;;
            *)
                echo "/usr/local/bin/start-singleuser.sh: running script $hook"
                "$hook"
                ;;
        esac
    done
    echo "/usr/local/bin/start-singleuser.sh: done running hooks in /usr/local/bin/start-notebook.d"
fi

# Update user if JUPYTERHUB_USER is set and we're running as root
if [ "$(id -u)" -eq 0 ] && [ -n "$JUPYTERHUB_USER" ] && [ "$JUPYTERHUB_USER" != "jovyan" ]; then
    if id -u "$JUPYTERHUB_USER" >/dev/null 2>&1; then
        # User exists, get their UID/GID
        TARGET_UID=$(id -u "$JUPYTERHUB_USER")
        TARGET_GID=$(id -g "$JUPYTERHUB_USER")
        CURRENT_USERNAME=$(id -un)
        
        echo "Updated the $CURRENT_USERNAME user:"
        echo "- username: $CURRENT_USERNAME       -> $JUPYTERHUB_USER"
        if [ -n "$HOME" ]; then
            echo "- home dir: $HOME -> /home/$JUPYTERHUB_USER"
        fi
        echo "Update $JUPYTERHUB_USER's UID:GID to $TARGET_UID:$TARGET_GID"
        
        # Update home directory if needed
        if [ -d "/home/$JUPYTERHUB_USER" ]; then
            chown -R "$TARGET_UID:$TARGET_GID" "/home/$JUPYTERHUB_USER" 2>/dev/null || true
        fi
    fi
fi

# Run before-notebook.d hooks as root (uid/gid 0/0)
if [ -d "/usr/local/bin/before-notebook.d" ]; then
    echo "/usr/local/bin/start-singleuser.sh: running hooks in /usr/local/bin/before-notebook.d as uid / gid: $(id -u) / $(id -g)"
    for hook in /usr/local/bin/before-notebook.d/*; do
        [ -e "$hook" ] || continue
        case "$hook" in
            *.sh)
                echo "/usr/local/bin/start-singleuser.sh: running script $hook"
                . "$hook"
                ;;
            *.py)
                echo "/usr/local/bin/start-singleuser.sh: running script $hook"
                python3 "$hook"
                ;;
            *)
                echo "/usr/local/bin/start-singleuser.sh: running script $hook"
                "$hook"
                ;;
        esac
    done
    echo "/usr/local/bin/start-singleuser.sh: done running hooks in /usr/local/bin/before-notebook.d"
fi

# Switch to target user and start jupyterhub-singleuser
if [ "$(id -u)" -eq 0 ] && [ "$TARGET_USER" != "root" ]; then
    # We're root, use su to switch to target user
    echo "Running as $TARGET_USER: jupyterhub-singleuser $@"
    exec su -s /bin/bash -c 'exec jupyterhub-singleuser "$@"' "$TARGET_USER" -- "$@"
elif [ "$(id -un)" = "$TARGET_USER" ]; then
    # Already running as target user
    echo "Running as $TARGET_USER: jupyterhub-singleuser $@"
    exec jupyterhub-singleuser "$@"
else
    # Fallback: try to switch or run as-is
    echo "Running as $(id -un): jupyterhub-singleuser $@"
    exec jupyterhub-singleuser "$@"
fi
