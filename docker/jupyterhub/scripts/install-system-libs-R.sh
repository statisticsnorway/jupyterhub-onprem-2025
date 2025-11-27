#!/bin/bash
set -e

function apt_install() {
    if ! dpkg -s "$@" >/dev/null 2>&1; then
        if [ "$(find /var/lib/apt/lists/ -mindepth 1 | wc -l)" = "0" ]; then
            apt-get update
        fi
        apt-get install -y --no-install-recommends "$@"
    fi
}

apt_install \
    libglpk40 \
    libpq-dev \
    libzmq3-dev \
    libgit2-dev \
    libfontconfig1-dev \
    libglpk-dev \
    libgmp-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libgdal-dev \
    libproj-dev \
    libgeos-dev \
    libnode-dev \
    unixodbc-dev \
    gdal-bin \
    libdeflate-dev \
    liblzma-dev \
    libreadline-dev \
    libudunits2-dev \
    libx11-dev