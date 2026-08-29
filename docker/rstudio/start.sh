#!/bin/bash
# Legacy hook kept for compatibility. JupyterHub uses start-singleuser.sh as PID 1.
echo "Running RStudio environment hook"

if [ -f /etc/profile.d/stamme_variabel ]; then
    # shellcheck disable=SC1091
    source /etc/profile.d/stamme_variabel
fi

export STATBANK_BASE_URL="${STATBANK_BASE_URL:-}"
export STATBANK_ENCRYPT_URL="${STATBANK_ENCRYPT_URL:-}"
