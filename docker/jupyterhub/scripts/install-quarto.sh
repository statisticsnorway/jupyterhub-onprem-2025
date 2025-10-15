#!/bin/bash
set -e

# deps for installer
apt-get update
apt-get install -y --no-install-recommends perl wget
rm -rf /var/lib/apt/lists/*

# Install Quarto
QUARTO_DL_URL=$(wget -qO- https://quarto.org/docs/download/_download.json \
  | grep -oP '(?<="download_url":\s")https.*linux-amd64\.deb')
wget -q "$QUARTO_DL_URL" -O /tmp/quarto.deb
dpkg -i /tmp/quarto.deb
rm -f /tmp/quarto.deb

# TinyTeX system-wide (NOT in $HOME)
export TINYTEX_DIR=/opt/TinyTeX
wget -qO- https://yihui.org/tinytex/install-bin-unix.sh \
  | sh -s - --admin --dir="$TINYTEX_DIR"

# Put TeX on PATH for everyone
"$TINYTEX_DIR/bin/x86_64-linux/tlmgr" path add --system

# Make PATH available to login shells
echo 'export PATH=/opt/TinyTeX/bin/x86_64-linux:$PATH' > /etc/profile.d/tinytex.sh
chmod 0755 /etc/profile.d/tinytex.sh