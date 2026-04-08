#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -qq -y \
  ca-certificates curl pandoc python3 python3-pip \
  texlive-fonts-recommended texlive-latex-extra texlive-latex-recommended texlive-xetex \
  >/dev/null
pip3 install --break-system-packages --no-cache-dir "jupyterlab>=4" "nbconvert>=7" >/dev/null
echo "kpsewhich ulem: $(kpsewhich ulem.sty)"
python3 <<'PY'
import json
nb = {
    "nbformat": 4,
    "nbformat_minor": 5,
    "metadata": {
        "kernelspec": {
            "display_name": "Python 3",
            "language": "python",
            "name": "python3",
        },
        "language_info": {"name": "python"},
    },
    "cells": [{"cell_type": "markdown", "metadata": {}, "source": ["# t"]}],
}
open("/tmp/s.ipynb", "w", encoding="utf-8").write(json.dumps(nb))
PY
jupyter nbconvert --to pdf /tmp/s.ipynb --output /tmp/s.pdf
test -s /tmp/s.pdf
echo OK
