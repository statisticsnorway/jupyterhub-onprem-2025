#!/bin/bash
set -e

echo "Starting with NB_USER=$NB_USER, NB_UID=$NB_UID, NB_GID=$NB_GID"

# Create user if environment variables are set and user doesn't exist
if [ -n "$NB_USER" ] && [ -n "$NB_UID" ] && [ -n "$NB_GID" ]; then
    echo "Creating user: $NB_USER with UID: $NB_UID, GID: $NB_GID"
    
    # Create group if it doesn't exist
    if ! getent group "$NB_GID" > /dev/null 2>&1; then
        groupadd -g "$NB_GID" "$NB_USER" || true
    fi
    
    # Create user if it doesn't exist
    if ! id "$NB_USER" > /dev/null 2>&1; then
        useradd -u "$NB_UID" -g "$NB_GID" -s /bin/bash -m "$NB_USER" || true
        # Copy jovyan's environment to new user
        if [ -d "/home/jovyan" ] && [ "$NB_USER" != "jovyan" ]; then
            cp -r /home/jovyan/. "/home/$NB_USER/" 2>/dev/null || true
            chown -R "$NB_UID:$NB_GID" "/home/$NB_USER" || true
        fi
    fi
    
    # Switch to the user and start jupyter
    echo "Switching to user $NB_USER and starting jupyterhub-singleuser"
    exec gosu "$NB_USER" jupyterhub-singleuser "$@"
else
    echo "No user mapping provided, starting as jovyan"
    exec gosu jovyan jupyterhub-singleuser "$@"
fi
