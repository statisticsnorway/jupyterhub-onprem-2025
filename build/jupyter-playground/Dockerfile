FROM oracle:latest

LABEL maintainer="Statistics Norway"

ARG PYTHON_VERSION="311"
ENV PYTHON_VERSION=${PYTHON_VERSION}

USER root

# Install additional system packages
 RUN apt-get update -y && \
     apt-get install -y \
     iputils-ping \
     build-essential \
     pandoc \
#     libffi-dev \
#     python3-dev \
#     curl \
     && apt-get clean \
     && rm -rf /var/lib/apt/lists/*

ARG CONDA_DIR=/opt/conda

# Install miniconda
RUN curl -L https://repo.anaconda.com/miniconda/Miniconda3-py${PYTHON_VERSION}_24.4.0-0-Linux-x86_64.sh -o conda-python.sh && \
    chmod +x conda-python.sh && \
    ./conda-python.sh -b -p $CONDA_DIR && \
    rm -f conda-python.sh

# Add conda to PATH
ENV PATH="${CONDA_DIR}/bin:${PATH}"

RUN sed -i "/^PATH=/c\PATH=$PATH" "$R_HOME/etc/Renviron.site"

# Create and set permissions for user directories
# RUN mkdir -p ${HOME}/.local/lib && \
#     chown -R ${USERNAME}:${GROUPNAME} ${HOME}/.local

COPY requirements.txt /tmp/requirements.txt

# Copy Quarto and pipx install scripts
COPY scripts /opt/scripts/
RUN chmod +x -R /opt/scripts/
RUN chown -R ${USERNAME}:${GROUPNAME} /opt/scripts/ 
RUN chmod -R 700 /opt/scripts/

RUN python -m pip install --user pipx && \
    python -m pipx ensurepath && \
    # Install Quarto latest version
    /opt/scripts/install-quarto.sh && \
    chmod +x /opt/scripts/pipx_install_packages.sh && \
    /opt/scripts/pipx_install_packages.sh

RUN /opt/install-texlive-packages.sh

RUN mkdir -p /etc/jupyter
COPY jupyter_lab_config.py /etc/jupyter

# Install Python packages
RUN python3 -m pip install --upgrade pip && \
    python3 -m pip install --upgrade jupyterhub jupyterlab-git==0.44.0 && \
    python3 -m pip install --upgrade nbdime==3.2.1 && \
    echo "Installing Dapla tools.txt" && \
    python3 -m pip install --no-cache-dir -r /tmp/requirements.txt && \
    python3 -m pip install nbstripout && \
    python3 -m pip install papermill && \
    python3 -m pip install ipywidgets && \
    python3 -m pip install jupyter-server-proxy && \
    python3 -m pip install pyviz_comms==2.3.0 && \
    python3 -m pip install panel==0.13.1rc2 && \
    python3 -m pip install plotly && \
    python3 -m pip install geopandas && \
    python3 -m pip install ipyleaflet && \
    python3 -m pip install descartes && \
    python3 -m pip install jupyter-dash && \
    python3 -m pip install jupyterlab-lsp && \
    python3 -m pip install python-language-server[all] && \
    python3 -m pip install ipysheet && \
    python3 -m pip install fuzzywuzzy[speedup] && \
    python3 -m pip install jupyterlab-system-monitor && \
    python3 -m pip install jupytext==1.15.2 && \
    python3 -m pip uninstall -y ipyparallel && \
    python3 -m pip uninstall -y sympy mpmath && \
    python3 -m pip install poetry && \
    python3 -m pip install sphinx sphinx-autodoc-defaultargs sphinx-autodoc-typehints sphinx-rtd-theme && \
    python3 -m pip install pytest pytest_tornasync pytest-cov pytest-mock pre-commit-hooks jupyterlab-code-formatter black[jupyter] isort && \
    python3 -m pip install pyjstat xmltodict lxml holidays PyGithub pre-commit pyminizip rich openpyxl pyarrow python-dotenv poetry && \
    python3 -m pip install pandas-gbq google-cloud-storage venv-pack nbdev && \
    python3 -m pip install cx-Oracle && \
    python3 -m pip install saspy && \
    python3 -m pip install ipydatagrid && \
    python3 -m pip install pipx && \
    python3 -m pip cache purge && \
    rm /tmp/requirements.txt

# Install and configure pipx packages
RUN pipx install nox && \
    pipx install poetry && \
    pipx install pre-commit && \
    pipx inject nox nox-poetry && \
    pipx inject poetry poetry-plugin-export && \
    pipx inject poetry poetry-plugin-shell

# Set template version for ssb-project-cli
ENV STAT_TEMPLATE_DEFAULT_REFERENCE="1.1.9"

# Configure Python virtual environments
ENV PIP_REQUIRE_VIRTUALENV=true
ENV POETRY_VIRTUALENVS_IN_PROJECT=true

# Setting up environment variables for pip and pipenv
ENV PIP_INDEX=https://pypi.org/pypi
ENV PIP_INDEX_URL=https://pypi.org/simple
ENV PIPENV_PYPI_MIRROR=$PIP_INDEX_URL
ENV PIP_TRUSTED_HOST=pypi.org
RUN pip config set global.index https://pypi.org/pypi --global && \
    pip config set global.index-url https://pypi.org/simple --global && \
    pip config set global.trusted-host pypi.org --global

# Use proxy for https connections
ENV https_proxy=http://proxy.ssb.no:3128
ENV no_proxy=nexus.ssb.no,git-adm.ssb.no,i.test.ssb.no,i.ssb.no,i.qa.ssb.no,data.ssb.no,github.com,api.github.com,codeload.github.com

# Pull and update ca-certificates
RUN mkdir "/usr/local/bin/start-notebook.d" && \
    echo "curl https://nexus.ssb.no/repository/certificate_repo/ssb/cert_Decrypt-CA.crt --output /usr/local/share/ca-certificates/cert_Decrypt-CA.crt" > /usr/local/bin/start-notebook.d/update-certificate.sh && \
    echo "update-ca-certificates" >> /usr/local/bin/start-notebook.d/update-certificate.sh && \
    chmod +x /usr/local/bin/start-notebook.d/update-certificate.sh

# Set Dapla environment variables used to identify the service.
ENV DAPLA_SERVICE=JUPYTERLAB
ENV DAPLA_REGION=ON_PREM

# Adding pythonForSsb in PYTHONPATH
ENV PYTHONPATH=$PYTHONPATH:/ssb/bruker/felles/pythonForSsb

# Set FELLES environment variable
ENV FELLES=/ssb/bruker/felles
ENV ARROW_THIRDPARTY_DEPENDENCY_DIR=$FELLES/R_pakker/arrow
ENV ARROW_GCS=OFF
ENV ARROW_S3=OFF


# Copy the kernels. (pre-defined kernels are found at /opt/conda/share/jupyter/kernels)
COPY kernels/ir /opt/conda/share/jupyter/kernels/ir/
COPY kernels/python3 /opt/conda/share/jupyter/kernels/python3/

# Allowing everyone to execute python.sh and r.sh, this is done indirectly by users
RUN chmod +x /opt/conda/share/jupyter/kernels/python3/python.sh
RUN chmod +x /opt/conda/share/jupyter/kernels/ir/r.sh


USER 1000

CMD ["bash"]