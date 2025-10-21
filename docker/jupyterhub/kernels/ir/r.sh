#!/usr/bin/env bash

# setup user defined environment variables
# .bashrc also calls bashrc.felles
source $HOME/.bashrc

export PATH="/opt/TinyTeX/bin/x86_64-linux:${PATH}"
export R_PROFILE_USER="/opt/conda/share/jupyter/kernels/ir/Rstartup"
export R_LIBS_USER="/usr/local/lib/R/library"

# Run IRkernel
exec /usr/local/bin/R --slave -e "IRkernel::main()" $@