#!/usr/bin/env bash
VALID_GIT_CONFIG="$(python -c 'from kvakk_git_tools import validate_git_config; print(validate_git_config())' 2>&1)"

# If the output of the command is anything else than
# True we should run ssb_gitconfig.py ask the user to run ssb_gitconfig.py
if [ "$VALID_GIT_CONFIG" != "True" ]; then
  cat << EOF
Your Git account is not configured.
To configure:
  run: ssb_gitconfig.py
EOF
fi