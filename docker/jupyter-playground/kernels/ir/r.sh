#!/usr/bin/env bash

# setup user defined environment variables
# .bashrc also calls bashrc.felles
source $HOME/.bashrc

export R_PROFILE_USER="/opt/conda/share/jupyter/kernels/ir/Rstartup"
export R_LIBS_USER="/usr/lib/R/library"

# Run IRkernel
exec /usr/bin/R --slave -e "IRkernel::main()" $@