FROM docker.io/library/ubuntu:24.04

# Spawned by JupyterHub (jupyter-rsession-proxy), not as a standalone RStudio compose stack.
# CI builds this image twice: R_VERSION=4.4.0 and R_VERSION=4.6.0.

# System-wide configuration
SHELL ["/bin/bash", "-c"]
ENV SHELL="/bin/bash"
ENV DEBIAN_FRONTEND="noninteractive"

# Setup user & workspace
ENV USERNAME="rstudio"
ENV UID="1000"
ENV GROUPNAME="users"
ENV GID="100"
ENV HOME="/home/${USERNAME}"
ENV WORKSPACE_DIR="${HOME}/work"
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

COPY scripts/ /opt/

RUN chmod -R +x /opt/ && \
    # Install essential system libraries
    /opt/install-system-libs.sh && \
    apt-get upgrade -y && \
    # Generate locales
    locale-gen nb_NO.UTF-8 && \
    # Update default locale to Norwegian
    update-locale LANG=nb_NO.UTF-8 && \
    # Make sudo passwordless
    echo '${USERNAME} ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers && \
    # Fix permissions
    chown -R ${USERNAME}:${GROUPNAME} ${HOME} && \
    chmod +x /opt/onyxia-init.sh && \
    # Clean up
    rm -rf /var/lib/apt/lists/*

ENV PATH="${PATH}:${HOME}/.local/bin:${HOME}/.krew/bin:${HOME}/work/.local/pipx/bin"

# Download git completion and git prompt scripts (sjekke om dete er nødvendig mtp at vi kopierer inn bashrc fra L219)
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

USER 1000

# Install gitconfig file from kvakk-git-tools
# RUN /opt/install-gitconfig.sh

# R Config (overridden at build time: 4.4.0 / 4.6.0)
ARG R_VERSION="4.4.0"
ENV R_VERSION=${R_VERSION}
ENV R_HOME="/usr/local/lib/R"
ENV DEFAULT_USER="${USERNAME}"

# Java configuration
ARG JAVA_VERSION="17"
ENV JAVA_VERSION=${JAVA_VERSION}
ENV JAVA_HOME="/usr/lib/jvm/java-$JAVA_VERSION-openjdk-amd64"
ENV PATH="${JAVA_HOME}/bin:${PATH}"

USER root

RUN apt-get upgrade --fix-missing -y

# Install R using rocker's install scripts for the selected R_VERSION
RUN git clone --branch R${R_VERSION} --depth 1 https://github.com/rocker-org/rocker-versioned2.git /tmp/rocker-versioned2 && \
    cp -r /tmp/rocker-versioned2/scripts/ /rocker_scripts/ && \
    chown -R ${USERNAME}:${GROUPNAME} /rocker_scripts/ && \
    chmod -R 700 /rocker_scripts/ && \
    /rocker_scripts/install_R_source.sh

ENV CRAN="https://p3m.dev/cran/__linux__/noble/latest"

# RStudio ENVs
ENV S6_VERSION=v2.1.0.2
ENV RSTUDIO_VERSION=stable
ENV DEFAULT_USER=rstudio
# Pin a concrete pandoc release. PANDOC_VERSION=default becomes "latest" when
# RStudio is not installed yet, and rocker then scrapes api.github.com for a
# .deb URL. That fails instantly (empty URL) on GitHub Actions rate limits.
ENV PANDOC_VERSION=3.10.2
ENV QUARTO_VERSION=default

# LaTeX ENVs
ENV CTAN_REPO=https://ctan.uib.no/systems/texlive/tlnet
ENV PATH=$PATH:/usr/local/texlive/bin/linux

COPY jwsacruncher-2.2.4.zip /tmp/jwsacruncher-2.2.4.zip

# Set up R (RSPM, OpenBLAS, littler, addtional packages)
RUN /opt/install-java.sh
# Install R
RUN /rocker_scripts/setup_R.sh
# Install RStudio
RUN /rocker_scripts/install_quarto.sh 
# Install geospatial packages
RUN /rocker_scripts/install_tidyverse.sh
# RUN /rocker_scripts/install_verse.sh
RUN /rocker_scripts/install_geospatial.sh
# R4.4.0 rocker scripts still apt-get python-setuptools (Python 2), which is gone on Ubuntu Noble.
# Install RStudio before pandoc so PANDOC_VERSION=default can use the bundled binary.
RUN sed -i -E 's/(^|[^[:alnum:]])python-setuptools/\1python3-setuptools/g' /rocker_scripts/*.sh
RUN /rocker_scripts/install_rstudio.sh
RUN /rocker_scripts/install_pandoc.sh

# Re-install system libs that may have been removed by autoremove in rocker scripts
RUN /opt/install-system-libs.sh && \
    # Install additional system libs needed by R packages
    /opt/install-system-libs-R.sh && \
    # arrow >= 21 requires cmake >= 3.26 when users install into renv projects
    CMAKE_VERSION="$(cmake --version | awk 'NR == 1 { print $3 }')" && \
    if ! dpkg --compare-versions "$CMAKE_VERSION" ge "3.26"; then \
    echo "cmake >= 3.26 is required for arrow; found $CMAKE_VERSION"; \
    exit 1; \
    fi && \
    # Configure R for CUDA if parent image has CUDA
    if ! [[ -z "${CUDA_VERSION}" ]]; then /rocker_scripts/config_R_cuda.sh; fi && \
    # Install useful additional packages
    install2.r --error \
    devtools \
    DBI \
    lintr \
    quarto \
    renv \
    styler && \
    unzip /tmp/jwsacruncher-2.2.4.zip -d /opt && rm -f /tmp/jwsacruncher-2.2.4.zip && \
    # Create a symlink at /usr/bin so users can call jwsacruncher from anywhere
    ln -s /opt/jwsacruncher-2.2.4/bin/jwsacruncher /usr/bin/jwsacruncher && \
    # Fix permissions
    chown -R ${USERNAME}:${GROUPNAME} ${HOME} ${R_HOME} && \
    # Clean
    rm -rf /var/lib/apt/lists/*


# Install Arrow, og sjekk https://cran.r-project.org/src/contrib/Archive/arrow/ om R-versjonen ligger der. Slik at du treffer riktig versjon. Bruk også "apt-cache madison libarrow-dev"
ARG ARROW_VERSION="24.0.0"
ENV ARROW_VERSION=${ARROW_VERSION}
RUN /opt/install-arrow.sh

ENV ARROW_HOME="/usr"
ENV ARROW_USE_PKG_CONFIG="TRUE"
ENV LIBARROW_BINARY="FALSE"
ENV LIBARROW_BUILD="FALSE"
ENV PKG_CONFIG_PATH="/usr/lib/x86_64-linux-gnu/pkgconfig:/usr/lib/pkgconfig:/usr/share/pkgconfig"

# Setting up environment variables for Oracle
ENV OCI_INC=/usr/include/oracle/21/client64
ENV OCI_LIB=/usr/lib/oracle/21/client64/lib
ENV ORACLE_HOME=/usr/lib/oracle/21/client64
ENV TNS_ADMIN=/usr/lib/oracle/21/client64/lib/network
ENV LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/usr/lib/oracle/21/client64/lib

# Downloading oracle instant-client components and saving to /tmp
RUN wget https://download.oracle.com/otn_software/linux/instantclient/216000/oracle-instantclient-basic-21.6.0.0.0-1.x86_64.rpm -P /tmp/ && \
    wget https://download.oracle.com/otn_software/linux/instantclient/216000/oracle-instantclient-devel-21.6.0.0.0-1.x86_64.rpm -P /tmp/ && \
    wget https://download.oracle.com/otn_software/linux/instantclient/216000/oracle-instantclient-sqlplus-21.6.0.0.0-1.x86_64.rpm -P /tmp/ && \
    wget https://download.oracle.com/otn_software/linux/instantclient/216000/oracle-instantclient-odbc-21.6.0.0.0-1.x86_64.rpm -P /tmp/ && \
    wget https://download.oracle.com/otn_software/linux/instantclient/216000/oracle-instantclient-jdbc-21.6.0.0.0-1.x86_64.rpm -P /tmp/ && \
    wget https://download.oracle.com/otn_software/linux/instantclient/216000/oracle-instantclient-tools-21.6.0.0.0-1.x86_64.rpm -P /tmp/

# Installing oracle-instantclient components using alien
RUN alien -i /tmp/oracle-instantclient-basic-21.6.0.0.0-1.x86_64.rpm && \
    alien -i /tmp/oracle-instantclient-devel-21.6.0.0.0-1.x86_64.rpm && \
    alien -i /tmp/oracle-instantclient-odbc-21.6.0.0.0-1.x86_64.rpm && \
    alien -i /tmp/oracle-instantclient-jdbc-21.6.0.0.0-1.x86_64.rpm && \
    alien -i /tmp/oracle-instantclient-tools-21.6.0.0.0-1.x86_64.rpm && \
    alien -i /tmp/oracle-instantclient-sqlplus-21.6.0.0.0-1.x86_64.rpm

# Copy the ROracle installation file into the container
COPY ROracle_1.4-1_R_x86_64-unknown-linux-gnu.tar.gz /tmp/ROracle_1.4-1_R_x86_64-unknown-linux-gnu.tar.gz

RUN /rocker_scripts/install_verse.sh

RUN /rocker_scripts/install_texlive.sh

COPY r-packages-src.R /tmp/r-packages-src.R

# Install additional packages from source
RUN Rscript --vanilla /tmp/r-packages-src.R && \
    rm -rf /tmp/downloaded_packages/ /tmp/*.rds

RUN R --no-echo -e 'cat(Sys.getenv("R_HOME"), Sys.getenv("R_LIBS_USER"),"\n");cat(.libPaths(),"\n"); print(installed.packages()[,c("Package", "Version")])'


# NSS/SSSD client so SystemUserSpawner can run as the AD user
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    openssh-client \
    wget \
    python3 \
    python3-pip \
    python3-dev \
    python3-venv \
    libpam-sss \
    libnss-sss \
    sssd-common \
    sssd-tools \
    libnss3-tools && \
    apt-mark manual libpam-sss libnss-sss sssd-common sssd-tools libnss3-tools || true && \
    sed -i 's/^passwd:.*/passwd:     files sss systemd/' /etc/nsswitch.conf && \
    sed -i 's/^group:.*/group:      files sss systemd/'  /etc/nsswitch.conf && \
    sed -i 's/^shadow:.*/shadow:     files/'             /etc/nsswitch.conf && \
    rm -rf /var/lib/apt/lists/*


# Added repository for libpoppler-cpp-dev, and installed dependencies for tesseract
RUN apt-get update -y && \
    apt-get install -y software-properties-common && \
    apt-get install -y libpoppler-cpp-dev libtesseract-dev tesseract-ocr-eng tesseract-ocr-nor && \
    apt-get install -y libmagick++-dev

# Added dependencies for ProtoBuf
RUN apt-get update -y && \
    apt-get install -y libprotoc-dev libprotobuf-dev protobuf-compiler

# add tnsnames.ora to oracle path
RUN ln -s /ssb/share/etc/tnsnames.ora /usr/lib/oracle/21/client64/lib/network/tnsnames.ora

# symlink to /ssb/share/etc/stamme_variabel
RUN ln -s /ssb/share/etc/stamme_variabel /etc/profile.d/stamme_variabel

RUN mkdir -p /usr/local/share/etc/
COPY bashrc.felles /usr/local/share/etc/bashrc.felles

ENV FELLES=/ssb/bruker/felles

# adding a custom bashrc with git branch in PS1
COPY default-bashrc /etc/skel/.bashrc

COPY check-git-config.bash /usr/local/bin/check-git-config.sh
RUN chmod +x /usr/local/bin/check-git-config.sh

# Install ssb-gitconfig.py script
RUN wget -O /usr/local/bin/ssb-gitconfig.py https://raw.githubusercontent.com/statisticsnorway/kvakk-git-tools/main/src/kvakk_git_tools/ssb_gitconfig.py
RUN chmod +x /usr/local/bin/ssb-gitconfig.py

# Appends ssh-rsa as the accepted algorithm to /etc/ssh/ssh_config
RUN printf "    PubkeyAcceptedAlgorithms +ssh-rsa\n    HostkeyAlgorithms +ssh-rsa" >> /etc/ssh/ssh_config

# Set Dapla environment variables used to identify the service.
ENV DAPLA_SERVICE=R_STUDIO
ENV DAPLA_REGION=ON_PREM

# ghashr standalone hook (s6 /init). Hub PID 1 is start-singleuser.sh.
COPY start.sh /start.sh
RUN chmod +x /start.sh && \
    mkdir -p /usr/local/bin/before-notebook.d && \
    cp /start.sh /usr/local/bin/before-notebook.d/00-rstudio-env.sh


# Install Oracle client libraries for ROracle
RUN apt-get update && \
    apt-get install -y --no-install-recommends libaio1t64 libnsl2 && \
    # allow old loaders/binaries to find time64 libaio
    ln -sf /lib/x86_64-linux-gnu/libaio.so.1t64 /lib/x86_64-linux-gnu/libaio.so.1 && \
    # (optional but nice) include t64 dir in default paths
    echo '/usr/lib/x86_64-linux-gnu/t64' > /etc/ld.so.conf.d/t64.conf && \
    # (optional) expose Oracle client libs without LD_LIBRARY_PATH
    echo '/usr/lib/oracle/21/client64/lib' > /etc/ld.so.conf.d/oracle.conf && \
    ldconfig && \
    rm -rf /var/lib/apt/lists/*



ENV PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/texlive/bin/linux:/usr/lib/rstudio-server/bin:/usr/lib/rstudio-server/bin/quarto/bin:/usr/lib/rstudio-server/bin/postback:/usr/local/texlive/bin/x86_64-linux:${PATH}"

# Install the LaTeX packages you need
RUN set -eux; \
    /usr/local/texlive/bin/x86_64-linux/tlmgr option repository "$CTAN_REPO"; \
    # /usr/local/texlive/bin/x86_64-linux/tlmgr update --self; \
    /usr/local/texlive/bin/x86_64-linux/tlmgr install amsfonts booktabs; \
    # optional: clean up TL backup cache to keep the layer smaller
    rm -rf /usr/local/texlive/*/tlpkg/backups

RUN apt-get update && apt-get install -y --no-install-recommends default-jdk

RUN locale-gen nb_NO.UTF-8 && update-locale LANG=nb_NO.UTF-8 LC_ALL=nb_NO.UTF-8

# Change default R repo (used by renv)
COPY Rprofile.site /etc/R/Rprofile.site
COPY Rprofile.site /usr/local/lib/R/etc/Rprofile.site

# RStudio IDE (system defaults, XDG system config — se Posit «Customizing Session Settings»)
COPY rstudio-prefs.json /etc/rstudio/rstudio-prefs.json

# JupyterHub layer (from local-dev/Dockerfile.rstudio-from-ghashr).
# GHA context is docker/rstudio — COPY paths below are relative to that folder.
# Must run before https_proxy so GitHub Actions can reach PyPI.
COPY rserver.conf /etc/rstudio/rserver.conf
COPY start-singleuser.sh /usr/local/bin/start-singleuser.sh
COPY jupyter_server_config.py /usr/etc/jupyter/jupyter_server_config.py

RUN python3 -m pip install --break-system-packages --no-cache-dir \
        jupyterhub==5.3.0 \
        jupyter_server \
        jupyterlab \
        jupyter-server-proxy \
        jupyter-rsession-proxy && \
    command -v jupyterhub-singleuser && \
    python3 -c "import jupyterhub; assert jupyterhub.__version__.startswith('5.3')" && \
    chmod 0755 /usr/local/bin/start-singleuser.sh && \
    mkdir -p \
        /tmp/jupyter-runtime \
        /usr/etc/jupyter/jupyter_server_config.d \
        /etc/xdg/jupyter/jupyter_server_config.d && \
    chmod 1777 /tmp/jupyter-runtime && \
    printf '%s\n' '{"ServerApp":{"jpserver_extensions":{"jupyter_server_proxy":true}}}' \
      > /usr/etc/jupyter/jupyter_server_config.d/jupyter-server-proxy.json && \
    cp /usr/etc/jupyter/jupyter_server_config.py /etc/xdg/jupyter/jupyter_server_config.py && \
    cp /usr/etc/jupyter/jupyter_server_config.d/jupyter-server-proxy.json \
       /etc/xdg/jupyter/jupyter_server_config.d/jupyter-server-proxy.json

ENV JUPYTER_RUNTIME_DIR=/tmp/jupyter-runtime
ENV JUPYTER_PLATFORM_DIRS=1
ENV JUPYTER_RSESSION_PROXY_USE_SOCKET=no
ENV RSERVER_TIMEOUT=60
ENV PATH="/usr/local/bin:/usr/lib/rstudio-server/bin:${PATH}"

RUN git config --system --add safe.directory '*'

# Use proxy for https connections, this must happen last
ENV https_proxy=http://proxy.ssb.no:3128
ENV no_proxy=nexus.ssb.no,git-adm.ssb.no,i.test.ssb.no,i.ssb.no,data.ssb.no,github.com,api.github.com,codeload.github.com,www.ssb.no

# Hub talks to jupyterhub-singleuser on :8888, not ghashr s6 on :8787.
# Do not WORKDIR /home/rstudio — SystemUserSpawner runs as the SSSD user
# and notebook_dir is /ssb/bruker/{username} (see jupyterhub_config.py).
EXPOSE 8888
WORKDIR /tmp
ENTRYPOINT ["/usr/local/bin/start-singleuser.sh"]
CMD ["jupyterhub-singleuser"]
