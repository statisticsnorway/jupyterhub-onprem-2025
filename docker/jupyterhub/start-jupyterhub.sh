#!/bin/bash
set -e

# Ensure data directory exists
mkdir -p /data

# Run the database upgrade script
echo "Running database upgrade script..."
/tmp/upgrade-db.sh

# Start JupyterHub
exec jupyterhub "$@"
