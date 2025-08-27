#!/bin/bash
# Script for database upgrade init container
set -e

echo "Checking for database upgrades..."

# Wait for database file to exist (in case it's being created by another process)
timeout=30
while [ ! -f "/data/jupyterhub.sqlite" ] && [ $timeout -gt 0 ]; do
    echo "Waiting for database file to exist..."
    sleep 1
    timeout=$((timeout-1))
done

if [ -f "/data/jupyterhub.sqlite" ]; then
    echo "Running database upgrade..."
    jupyterhub upgrade-db
    echo "Database upgrade completed"
else
    echo "No database file found, skipping upgrade"
fi
