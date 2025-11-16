#!/bin/bash
set -e

echo "Entered start-singleuser.sh with args: $@"

# Run start-notebook.d hooks in background (as the authenticated user, set by SystemUserSpawner --user flag)
if [ -d "/usr/local/bin/start-notebook.d" ]; then
    echo "/usr/local/bin/start-singleuser.sh: starting hooks in /usr/local/bin/start-notebook.d in background as uid / gid: $(id -u) / $(id -g)"
    for hook in /usr/local/bin/start-notebook.d/*; do
        [ -e "$hook" ] || continue
        case "$hook" in
            *.sh)
                echo "/usr/local/bin/start-singleuser.sh: starting script $hook in background"
                nohup bash -c ". \"$hook\"" > "/tmp/$(basename $hook).log" 2>&1 &
                ;;
            *.py)
                echo "/usr/local/bin/start-singleuser.sh: starting script $hook in background"
                nohup python3 "$hook" > "/tmp/$(basename $hook).log" 2>&1 &
                ;;
            *)
                echo "/usr/local/bin/start-singleuser.sh: starting script $hook in background"
                nohup "$hook" > "/tmp/$(basename $hook).log" 2>&1 &
                ;;
        esac
    done
    echo "/usr/local/bin/start-singleuser.sh: started all hooks in /usr/local/bin/start-notebook.d in background"
fi

# Run before-notebook.d hooks (as the authenticated user, set by SystemUserSpawner --user flag)
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

# Start jupyterhub-singleuser
echo "Starting jupyterhub-singleuser $@"
exec jupyterhub-singleuser "$@"
