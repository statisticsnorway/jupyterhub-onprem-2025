#!/usr/bin/env bash

set -euo pipefail

REPO="statisticsnorway/kvakk-git-tools"
TAG=$(curl -s "https://api.github.com/repos/$REPO/releases/latest" | jq -r .tag_name)
GITCONFIG_DOWNLOAD_URL="https://raw.githubusercontent.com/$REPO/$TAG/kvakk_git_tools/recommended/gitconfig-dapla-lab"

curl -v -L "$GITCONFIG_DOWNLOAD_URL" -o "$HOME/.gitconfig"
