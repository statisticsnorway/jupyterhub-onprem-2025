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

# Extract under /opt and normalize the directory name
tar -xzf /tmp/TinyTeX.tar.gz -C /opt
rm -f /tmp/TinyTeX.tar.gz
if [ ! -d /opt/TinyTeX ]; then
  # the tar expands to TinyTeX or TinyTeX-<version>
  mv /opt/TinyTeX* "$TINYTEX_DIR"
fi
chown -R root:root "$TINYTEX_DIR"

# Create system-wide PATH symlinks and set mirror
"$TINYTEX_DIR/bin/x86_64-linux/tlmgr" path add --system

# Make PATH available to login shells (runtime convenience)
echo 'export PATH=/opt/TinyTeX/bin/x86_64-linux:$PATH' > /etc/profile.d/tinytex.sh
chmod 0755 /etc/profile.d/tinytex.sh