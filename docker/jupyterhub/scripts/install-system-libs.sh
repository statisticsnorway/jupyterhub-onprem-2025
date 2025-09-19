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
    bash-completion \
    build-essential \
    ca-certificates \
    curl \
    git \
    gnupg2 \
    jq \
    less \
    locales \
    lsb-release \
    nano \
    openssh-client \
    python3-pip \
    tini \
    unzip \
    vim \
    alien \
    wget \
    tmux
