#!/usr/bin/env bash

set -e

# Ensure tlmgr is on PATH in this non-login build shell (Rocker TeX Live, not TinyTeX)
export PATH="/usr/local/texlive/bin/x86_64-linux:/usr/local/texlive/bin/linux:${PATH}"

if [ -n "${CTAN_REPO:-}" ]; then
    tlmgr option repository "$CTAN_REPO"
fi

tlmgr update --self

tlmgr install titling

tlmgr install textpos

tlmgr install amsfonts

tlmgr install booktabs

tlmgr install tcolorbox

tlmgr install environ

tlmgr install etoolbox

tlmgr install ulem soul

tlmgr install pdfcol

tlmgr install parskip

tlmgr install caption

tlmgr install collection-latexrecommended

tlmgr install collection-latexextra

tlmgr install collection-fontsrecommended

tlmgr install collection-xetex
