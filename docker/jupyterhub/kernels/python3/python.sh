#!/usr/bin/env bash

# setup user defined environment variables
# .bashrc also calls bashrc.felles
source $HOME/.bashrc

exec /opt/conda/bin/python -m ipykernel $@