FROM r-minimal:latest

LABEL maintainer="Statistics Norway"

ARG PYTHON_VERSION="311"
ENV PYTHON_VERSION=${PYTHON_VERSION}

USER root

# Install additional system packages
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
    iputils-ping \
    build-essential \
    libssl-dev \
    libffi-dev \
    python3-dev \
    curl \
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

# Create Python environment and initialize conda
RUN conda create -y -n py311 python=3.11 && \
    conda init bash && \
    echo "conda activate py311" >> ~/.bashrc

# Create and set permissions for user directories
RUN mkdir -p ${HOME}/.local/lib && \
    chown -R ${USERNAME}:${GROUPNAME} ${HOME}/.local

COPY requirements.txt /tmp/requirements.txt

USER root

# Install pipx and ensure it's in PATH
RUN python3 -m pip install pipx && \
    python3 -m pipx ensurepath

# Install Python packages
RUN python3 -m pip install --upgrade pip && \
    python3 -m pip install --upgrade jupyterhub jupyterlab-git==0.44.0 && \
    python3 -m pip install --upgrade nbdime==3.2.1 && \
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
    python3 -m pip install pipx && \
    python3 -m pip cache purge

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

# Copy the kernels. (pre-defined kernels are found at /opt/conda/share/jupyter/kernels)
COPY kernels/ir /opt/conda/share/jupyter/kernels/ir/
COPY kernels/python3 /opt/conda/share/jupyter/kernels/python3/

# Allowing everyone to execute python.sh and r.sh, this is done indirectly by users
RUN chmod +x /opt/conda/share/jupyter/kernels/python3/python.sh
RUN chmod +x /opt/conda/share/jupyter/kernels/ir/r.sh

# Configure pip to use Nexus
RUN pip config set global.index https://pypi.org/pypi --global && \
    pip config set global.index-url https://pypi.org/simple --global && \
    pip config set global.trusted-host pypi.org --global

# Adding pythonForSsb in PYTHONPATH
ENV PYTHONPATH=$PYTHONPATH:/ssb/bruker/felles/pythonForSsb

CMD ["bash"]