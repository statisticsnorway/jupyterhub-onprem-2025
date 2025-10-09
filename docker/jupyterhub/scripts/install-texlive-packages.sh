#!/usr/bin/env bash

set -e

tlmgr update --self

tlmgr install titling

tlmgr install textpos

tlmgr install amsfonts

tlmgr install booktabs