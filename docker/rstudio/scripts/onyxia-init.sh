#!/usr/bin/env bash

echo "start of onyxia-init.sh script as user :"
whoami

if sudo true -nv 2>&1; then
  echo "sudo_allowed"
  SUDO=0
else
  echo "no_sudo"
  SUDO=1
fi

# The code related to configuring JupyterLab settings
if command -v jupyter-lab; then
    # Define the JupyterLab settings directory
    JUPYTERLAB_SETTINGS_DIR="$HOME/work/.jupyter/config/lab/user-settings/@jupyterlab"
    mkdir -p "$JUPYTERLAB_SETTINGS_DIR/notebook-extension"
    mkdir -p "$JUPYTERLAB_SETTINGS_DIR/fileeditor-extension"
    mkdir -p "$JUPYTERLAB_SETTINGS_DIR/console-extension"

    # Update or create notebook-extension settings
    NOTEBOOK_SETTINGS_FILE="$JUPYTERLAB_SETTINGS_DIR/notebook-extension/tracker.jupyterlab-settings"
    if [ -f "$NOTEBOOK_SETTINGS_FILE" ]; then
        jq '.codeCellConfig.autoClosingBrackets = true | .markdownCellConfig.autoClosingBrackets = true | .rawCellConfig.autoClosingBrackets = true' \
        "$NOTEBOOK_SETTINGS_FILE" > "${NOTEBOOK_SETTINGS_FILE}.tmp" && mv "${NOTEBOOK_SETTINGS_FILE}.tmp" "$NOTEBOOK_SETTINGS_FILE"
    else
        echo '{
            "codeCellConfig": {"autoClosingBrackets": true},
            "markdownCellConfig": {"autoClosingBrackets": true},
            "rawCellConfig": {"autoClosingBrackets": true}
        }' > "$NOTEBOOK_SETTINGS_FILE"
    fi

    # Update or create fileeditor-extension settings
    FILEEDITOR_SETTINGS_FILE="$JUPYTERLAB_SETTINGS_DIR/fileeditor-extension/plugin.jupyterlab-settings"
    if [ -f "$FILEEDITOR_SETTINGS_FILE" ]; then
        jq '.editorConfig.autoClosingBrackets = true' \
        "$FILEEDITOR_SETTINGS_FILE" > "${FILEEDITOR_SETTINGS_FILE}.tmp" && mv "${FILEEDITOR_SETTINGS_FILE}.tmp" "$FILEEDITOR_SETTINGS_FILE"
    else
        echo '{
            "editorConfig": {"autoClosingBrackets": true}
        }' > "$FILEEDITOR_SETTINGS_FILE"
    fi

    # Update or create console-extension settings
    CONSOLE_SETTINGS_FILE="$JUPYTERLAB_SETTINGS_DIR/console-extension/tracker.jupyterlab-settings"
    if [ -f "$CONSOLE_SETTINGS_FILE" ]; then
        jq '.promptCellConfig.autoClosingBrackets = true' \
        "$CONSOLE_SETTINGS_FILE" > "${CONSOLE_SETTINGS_FILE}.tmp" && mv "${CONSOLE_SETTINGS_FILE}.tmp" "$CONSOLE_SETTINGS_FILE"
    else
        echo '{
            "promptCellConfig": {"autoClosingBrackets": true}
        }' > "$CONSOLE_SETTINGS_FILE"
    fi

    # Enable Resource Usage Indicator by default
    RESOURCE_USAGE_SETTINGS_DIR="$HOME/work/.jupyter/config/lab/user-settings/@jupyter-server/resource-usage"
    mkdir -p "$RESOURCE_USAGE_SETTINGS_DIR"

    RESOURCE_USAGE_SETTINGS_FILE="$RESOURCE_USAGE_SETTINGS_DIR/topbar-item.jupyterlab-settings"
    if [ -f "$RESOURCE_USAGE_SETTINGS_FILE" ]; then
        jq '.enable = true | .refreshRate = 5000 | .memory.label = "| Mem: " | .cpu.label = "CPU: " | .disk.label = "| Disk: "' \
        "$RESOURCE_USAGE_SETTINGS_FILE" > "${RESOURCE_USAGE_SETTINGS_FILE}.tmp" && mv "${RESOURCE_USAGE_SETTINGS_FILE}.tmp" "$RESOURCE_USAGE_SETTINGS_FILE"
    else
        echo '{
            "enable": true,
            "refreshRate": 5000,
            "memory": {
                "label": "| Mem: "
            },
            "cpu": {
                "label": "CPU: "
            },
            "disk": {
                "label": "| Disk: "
            }
        }' > "$RESOURCE_USAGE_SETTINGS_FILE"
    fi
fi

# VSCode configuration
if command -v code-server; then
    if [ ! -f "$HOME/work/.local/share/code-server/User/settings.json" ]; then
        echo "User settings.json not found in PVC, copying default settings from container..."
        mkdir -p "$HOME/work/.local/share/code-server/User"
        cp "$HOME/.local/share/code-server/User/settings.json" "$HOME/work/.local/share/code-server/User/settings.json"
    fi

    if [ ! -f "$HOME/work/.local/share/code-server/Machine/settings.json" ]; then
        echo "Machine settings.json not found in PVC, copying default settings from container..."
        mkdir -p "$HOME/work/.local/share/code-server/Machine"
        cp "$HOME/.local/share/code-server/Machine/settings.json" "$HOME/work/.local/share/code-server/Machine/settings.json"
    fi
fi

# RStudio configuration
if command -v /init; then
    : #noqa
    #jq '. + {"editor_theme": "Vibrant Ink"}' "${HOME}"/.config/rstudio/rstudio-prefs.json > "${HOME}"/tmp.settings.json && mv "${HOME}/tmp.settings.json" "${HOME}/.config/rstudio/rstudio-prefs.json"
fi

if [[ -e "$HOME/work" ]]; then
    ## If current directory is not under $HOME/work, change it to $HOME/work.

    ## This puts the user in the correct folder ($HOME/work) when spawning
    ## the initial shell from, for example, the VSCode terminal.

    ## However, the directory does *not* change if a shell is spawned from a
    ## directory where the user saves and runs programs (any folder that
    ## matches the wildcard "$HOME/work/*"). This makes it possible to run
    ## programs that spawns subshells, i.e. "poetry shell" without switching
    ## directory.
    if [[ $(id -u) = 0 ]]; then
        {
            printf "%s\n" "if [[ \$PWD != \$HOME/work/* ]]; then"
            printf "%s\n" "    cd \$HOME/work"
            printf "%s\n" "fi"
        } >> /etc/profile
    else
        {
            printf "%s\n" "if  [[ \$PWD != \$HOME/work/* ]]; then"
            printf "%s\n" "    cd \$HOME/work"
            printf "%s\n" "fi"
        } >> "$HOME/.bashrc"
    fi
fi

NETRC_FILE="$HOME/.netrc"

if [ -n "$GIT_USER_NAME" ] && [ -n "$GIT_PERSONAL_ACCESS_TOKEN" ]; then
    if [ ! -f "$NETRC_FILE" ]; then
        echo "machine github.com login $GIT_USER_NAME password $GIT_PERSONAL_ACCESS_TOKEN" >>"$NETRC_FILE"
    fi
fi

# Configure git
if [ -n "$GIT_USER_NAME" ]; then
    git config --global user.name "$GIT_USER_NAME"
fi

if [ -n "$GIT_USER_MAIL" ]; then
    git config --global user.email "$GIT_USER_MAIL"
fi

if [ -n "$GIT_REPOSITORY" ] && [ -f "$NETRC_FILE" ]; then
    REPO_NAME="$(basename "$GIT_REPOSITORY" .git)"
    REPO_PATH="$HOME/work/$REPO_NAME"
    git clone "$GIT_REPOSITORY" "$REPO_PATH"
    chown -R "$USERNAME:$GROUPNAME" "$REPO_PATH"

    if [ -n "$GIT_BRANCH" ]; then
        if [[ $(id -u) = 0 ]]; then
            # Run git checkout as ${USERNAME} user when running as root
            sudo -u $USERNAME bash -c "cd '$REPO_PATH' && git checkout '$GIT_BRANCH'"
        else
            # Directly run git checkout when running as non-root user
            cd "$REPO_PATH"
            git checkout "$GIT_BRANCH"
            cd -
        fi
    fi

    # if SSB_PROJECT_BUILD is explicitly set to "true", then build the ssb-project
    if [ "$SSB_PROJECT_BUILD_ON_LAUNCH" = "true" ]; then
        cd "$REPO_PATH"
        echo "Building ssb-project..."
        ssb-project build --no-verify
        cd -
    fi
fi

# The commands related to setting the various repositories (R/CRAN, pip, conda)
# are located in specific script
# source /opt/onyxia-set-repositories.sh

# If a PERSONAL_INIT_SCRIPT is set then download and run it. This may be used for customizing an environment
# without the need to build a separate image. Examples of this could be installing particular packages or
# making code or notebooks ready for a course.
if [[ -n "$PERSONAL_INIT_SCRIPT" ]]; then
    PERSONAL_INIT_SCRIPT_SOURCE_URL_PATTERN="^https:\/\/raw\.githubusercontent\.com\/statisticsnorway\/.*\.sh$"
    if [[ $PERSONAL_INIT_SCRIPT =~ $PERSONAL_INIT_SCRIPT_SOURCE_URL_PATTERN ]]; then
        echo "Download and run $PERSONAL_INIT_SCRIPT"
        curl "$PERSONAL_INIT_SCRIPT" | bash -s -- "$PERSONAL_INIT_ARGS"
    else
        echo "Personal init script URL does not match ${PERSONAL_INIT_SCRIPT_SOURCE_URL_PATTERN}. Not running."
    fi
fi

echo "execution of $*"
exec "$@"
