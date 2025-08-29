#!/usr/bin/env bash

# setup user defined environment variables
# .bashrc also calls bashrc.felles
source $HOME/.bashrc

export R_PROFILE_USER="/opt/conda/share/jupyter/kernels/ir/Rstartup"
R_BIN="$(command -v R || true)"
[ -z "$R_BIN" ] && [ -x /usr/local/bin/R ] && R_BIN=/usr/local/bin/R
exec "$R_BIN" --slave -e "IRkernel::main()" "$@"