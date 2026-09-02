#!/usr/bin/env bash

set -e

# Ensure tlmgr is on PATH in this non-login build shell (Rocker TeX Live, not TinyTeX)
export PATH="/usr/local/texlive/bin/x86_64-linux:/usr/local/texlive/bin/linux:${PATH}"

if [ -n "${CTAN_REPO:-}" ]; then
    tlmgr option repository "$CTAN_REPO"
fi

tlmgr update --self

# Already used by the image before the Lab-collection copy.
tlmgr install amsfonts booktabs titling textpos

# pandoc 3.10.2 pdf_document template (R_test_markdown.Rmd): hard \usepackage{caption,bookmark}
tlmgr install caption bookmark
