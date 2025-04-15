ARG BASE_IMAGE=ubuntu:24.04
FROM $BASE_IMAGE

LABEL maintainer="Statistics Norway"

# System-wide configuration
SHELL ["/bin/bash", "-c"]
ENV SHELL="/bin/bash"
ENV DEBIAN_FRONTEND="noninteractive"

# Setup user & workspace
ENV USERNAME="jovyan"
ENV UID="1000"
ENV GROUPNAME="users"
ENV GID="100"
ENV HOME="/home/${USERNAME}"
ENV WORKSPACE_DIR="${HOME}/work"
ENV TZ=Europe/Oslo

# Create user and setup workspace
RUN groupmod -g ${GID} ${GROUPNAME} && \
    # If user by ID 1000 already exists, remove it so we can re-create it
    if id -u ${UID} >/dev/null 2>&1; then userdel -r $(getent passwd ${UID} | cut -d: -f1); fi && \
    # Setup custom user with sudo rights
    useradd ${USERNAME} --uid=${UID} -g ${GROUPNAME} --groups sudo -r --no-log-init --create-home && \
    # Create workspace
    mkdir -p ${WORKSPACE_DIR} && \
    # Disable default sudo message when opening shell
    touch ${HOME}/.sudo_as_admin_successful

WORKDIR ${WORKSPACE_DIR}

USER root

# Install basic packages
RUN apt-get update && \
    apt-get install -y \
    wget \
    bzip2 \
    ca-certificates \
    sudo \
    locales \
    fonts-liberation \
    run-one \
    curl \
    git \
    gnupg \
    lsb-release \
    software-properties-common \
    alien \
    # libaio1 \
    libaio-dev \
    libgit2-dev \
    libbz2-dev \
    libfontconfig1-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libopenblas-dev \
    libglpk-dev \
    libpoppler-cpp-dev \
    libv8-dev \
    libnode-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set timezone to Oslo
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Configure locale
RUN locale-gen nb_NO.UTF-8 && \
    update-locale LANG=nb_NO.UTF-8 && \
    echo "nb_NO.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen

# Make sudo passwordless
RUN echo '${USERNAME} ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

# Set up PATH
ENV PATH="${PATH}:${HOME}/.local/bin:${HOME}/.krew/bin:${HOME}/work/.local/pipx/bin"

# Download git completion and git prompt scripts
RUN curl -o ${HOME}/.git-completion.bash https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash && \
    curl -o ${HOME}/.git-prompt.sh https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh && \
    chown ${USERNAME}:${GROUPNAME} ${HOME}/.git-completion.bash ${HOME}/.git-prompt.sh && \
    echo "source ~/.git-completion.bash" >> ${HOME}/.bashrc && \
    echo "source ~/.git-prompt.sh" >> ${HOME}/.bashrc && \
    echo 'export PS1="\[\e[1;32m\]\u@\h:\[\e[1;34m\]\w\[\e[1;31m\]\$(__git_ps1 \" (%s)\")\[\e[0m\]\$ "' >> ${HOME}/.bashrc

# Set locales
ENV LANG=nb_NO.UTF-8
ENV LANGUAGE=nb_NO:nb
ENV LC_ALL=nb_NO.UTF-8

# adding a custom bashrc with git branch in PS1
COPY common-bashrc /etc/skel/.bashrc
# Set common codestyle settings and update old users with possible new files from /etc/skel
RUN mkdir /etc/skel/.config && \
    mkdir -p /usr/local/bin/before-notebook.d && \
    echo 'tar -cf - -C /etc/skel . | tar --skip-old-files --directory /home/jovyan -xf -' \
    >  /usr/local/bin/before-notebook.d/sync-skel.sh && \
    chmod +x /usr/local/bin/before-notebook.d/sync-skel.sh

COPY common-pycodestyle /etc/skel/.config/pycodestyle

# Install ssb_gitconfig.py script
RUN wget -O /usr/local/bin/ssb_gitconfig.py https://raw.githubusercontent.com/statisticsnorway/kvakk-git-tools/main/kvakk_git_tools/ssb_gitconfig.py
RUN chmod +x /usr/local/bin/ssb_gitconfig.py

COPY check-git-config.bash /usr/local/bin/check-git-config.sh
RUN chmod +x /usr/local/bin/check-git-config.sh


# # Set up proxy configuration
# ENV https_proxy=http://proxy.ssb.no:3128
# ENV no_proxy=nexus.ssb.no,git-adm.ssb.no,i.test.ssb.no,i.ssb.no,i.qa.ssb.no,data.ssb.no,github.com,api.github.com,codeload.github.com

# # Set up certificate update script
# RUN mkdir "/usr/local/bin/start-notebook.d" && \
#     echo "curl https://nexus.ssb.no/repository/certificate_repo/ssb/cert_Decrypt-CA.crt --output /usr/local/share/ca-certificates/cert_Decrypt-CA.crt" > /usr/local/bin/start-notebook.d/update-certificate.sh && \
#     echo "update-ca-certificates" >> /usr/local/bin/start-notebook.d/update-certificate.sh && \
#     chmod +x /usr/local/bin/start-notebook.d/update-certificate.sh


# required by dapla team cli
ENV DAPLA_TEAM_API_BASE_URL="http://dapla-team-api.dapla.svc.cluster.local/"

# Fix permissions
RUN chown -R ${USERNAME}:${GROUPNAME} ${HOME}

USER ${UID}

CMD ["/bin/bash"] 