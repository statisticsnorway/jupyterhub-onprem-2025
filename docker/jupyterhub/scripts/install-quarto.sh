#!/bin/bash
set -e

# deps
apt-get update
apt-get install -y --no-install-recommends perl wget curl tar xz-utils ca-certificates
rm -rf /var/lib/apt/lists/*

# Install Quarto (latest)
QUARTO_DL_URL=$(wget -qO- https://quarto.org/docs/download/_download.json \
  | grep -oP '(?<="download_url":\s")https.*linux-amd64\.deb')
wget -q "$QUARTO_DL_URL" -O /tmp/quarto.deb
dpkg -i /tmp/quarto.deb
rm -f /tmp/quarto.deb

# -------------------------------
# TinyTeX system-wide in /opt/TinyTeX
# -------------------------------
TINYTEX_DIR=/opt/TinyTeX
mkdir -p "$TINYTEX_DIR"

# Use the stable GitHub URL (no expiring signed URL)
curl -fsSL https://github.com/rstudio/tinytex-releases/releases/download/daily/TinyTeX-1.tar.gz -o /tmp/TinyTeX.tar.gz

# Extract directly into /opt/TinyTeX, stripping the top-level directory name
tar -xzf /tmp/TinyTeX.tar.gz -C "$TINYTEX_DIR" --strip-components=1
rm -f /tmp/TinyTeX.tar.gz
chown -R root:root "$TINYTEX_DIR"

# Detect platform-specific bin dir (e.g., x86_64-linux) and configure tlmgr
PLATFORM_DIR=$(ls -1 "$TINYTEX_DIR/bin" | head -n1)
TLMGR_BIN="$TINYTEX_DIR/bin/$PLATFORM_DIR/tlmgr"
if [ ! -x "$TLMGR_BIN" ]; then
  echo "TinyTeX tlmgr not found at $TLMGR_BIN" >&2
  exit 1
fi

# tlmgr 'path add' system-wide is unnecessary here and may not be supported; skip it

# Make PATH available to login shells (runtime convenience)
echo "export PATH=$TINYTEX_DIR/bin/$PLATFORM_DIR:\$PATH" > /etc/profile.d/tinytex.sh
chmod 0755 /etc/profile.d/tinytex.sh