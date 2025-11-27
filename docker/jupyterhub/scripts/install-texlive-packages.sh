#!/usr/bin/env bash

set -e

# Ensure tlmgr is on PATH in this non-login build shell
TINYTEX_DIR=/opt/TinyTeX
PLATFORM_DIR=$(ls -1 "$TINYTEX_DIR/bin" | head -n1)
export PATH="$TINYTEX_DIR/bin/$PLATFORM_DIR:$PATH"

tlmgr update --self

tlmgr install titling

tlmgr install textpos

tlmgr install amsfonts

tlmgr install booktabs