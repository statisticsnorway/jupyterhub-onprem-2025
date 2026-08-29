#!/bin/bash
set -e

function apt_install() {
    if ! dpkg -s "$@" >/dev/null 2>&1; then
        if [ "$(find /var/lib/apt/lists -mindepth 1 2>/dev/null | wc -l)" = "0" ]; then
            apt-get update
        fi
        apt-get install -y --no-install-recommends "$@"
    fi
}

# OpenJDK 17 is in universe on Ubuntu 26.04 (resolute), not main.
if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
fi
if [[ "${VERSION_CODENAME:-}" == "resolute" ]]; then
    apt-get update
    apt-get install -y --no-install-recommends software-properties-common ca-certificates
    add-apt-repository -y universe
    apt-get update
fi

if [[ $* != *--no-jdk* ]]; then
    apt_install openjdk-"${JAVA_VERSION}"-jdk-headless
fi

apt_install \
    ca-certificates-java \
    libbz2-dev \
    openjdk-"${JAVA_VERSION}"-jre-headless

if command -v R; then
    R CMD javareconf
fi
