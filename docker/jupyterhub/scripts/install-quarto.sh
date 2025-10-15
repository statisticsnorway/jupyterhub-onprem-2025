#!/bin/bash
set -e

# deps for installer (tar, ca-certs help with HTTPS)
apt-get update
apt-get install -y --no-install-recommends perl wget curl tar ca-certificates
rm -rf /var/lib/apt/lists/*

# Install Quarto (latest .deb from the JSON)
QUARTO_DL_URL=$(wget -qO- https://quarto.org/docs/download/_download.json \
  | grep -oP '(?<="download_url":\s")https.*linux-amd64\.deb')
wget -q "$QUARTO_DL_URL" -O /tmp/quarto.deb
dpkg -i /tmp/quarto.deb
rm -f /tmp/quarto.deb

# TinyTeX system-wide (NOT in $HOME)
TINYTEX_DIR=/opt/TinyTeX
mkdir -p "$TINYTEX_DIR"

# Install TinyTeX into /opt/TinyTeX
curl -fsSL https://yihui.org/tinytex/install-bin-unix.sh \
  | sh -s - --admin --dir="$TINYTEX_DIR"

# Put TeX on PATH for everyone (tlmgr also creates /usr/local/bin symlinks)
"$TINYTEX_DIR/bin/x86_64-linux/tlmgr" path add --system

# Make PATH available to login shells (runtime convenience)
echo 'export PATH=/opt/TinyTeX/bin/x86_64-linux:$PATH' > /etc/profile.d/tinytex.sh
chmod 0755 /etc/profile.d/tinytex.sh