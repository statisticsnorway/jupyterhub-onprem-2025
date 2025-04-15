FROM python:latest

LABEL maintainer="Statistics Norway"

ARG PYTHON_VERSION="311"
ENV PYTHON_VERSION=${PYTHON_VERSION}

USER root

# Install system dependencies
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
    iputils-ping \
    pandoc \
    fonts-roboto \
    fonts-open-sans \
    libpcre2-dev \
    libbz2-dev \
    liblzma-dev \
    zlib1g-dev \
    libdeflate-dev \
    libudunits2-dev \
    libproj-dev \
    libgdal-dev \
    build-essential \
    libssl-dev \
    libffi-dev \
    python3-dev \
    nodejs \
    npm \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install additional R packages
RUN R CMD javareconf -e && \
    R -e "install.packages('configr', dependencies=TRUE)" && \
    R -e "install.packages('DBI', dependencies=TRUE)" && \
    R -e "install.packages('renv', dependencies=TRUE)" && \
    R -e "install.packages('arrow', dependencies=FALSE)" && \
    R -e "install.packages('leaflet', dependencies=TRUE)" && \
    R -e "install.packages('getPass', dependencies=TRUE)" && \
    R -e "install.packages('googleCloudStorageR', dependencies=TRUE)" && \
    R -e "install.packages('DT', dependencies=TRUE)" && \
    R -e "install.packages('rjwsacruncher', dependencies=TRUE)" && \
    R -e "install.packages('sf', dependencies=TRUE)" && \
    R -e "install.packages('sfarrow', dependencies=FALSE)" && \
    R -e "install.packages('dbplyr', dependencies=FALSE)" && \
    R -e "install.packages('shiny', dependencies=FALSE)" && \
    R -e "install.packages('rstudioapi', dependencies=TRUE)" && \
    R -e "install.packages('httr', dependencies=TRUE)" && \
    R -e "install.packages('readr', dependencies=TRUE)" && \
    R -e "install.packages('knitr', dependencies=TRUE)" && \
    R -e "install.packages('rmarkdown', dependencies=TRUE)" && \
    R -e "install.packages('Rcurl', dependencies=TRUE)" && \
    R -e "install.packages('here', dependencies=TRUE)" && \
    R -e "install.packages('esquisse', dependencies=TRUE)" && \
    R -e "install.packages('dcmodify', dependencies=TRUE)" && \
    R -e "install.packages('simputation', dependencies=TRUE)" && \
    R -e "install.packages('SmallCountRounding', dependencies=TRUE)" && \
    R -e "install.packages('ggplot2', dependencies=TRUE)" && \
    R -e "install.packages('RCurl', dependencies=TRUE)" && \
    R -e "install.packages('tidyverse', dependencies=TRUE)" && \
    R -e "install.packages('docopt', dependencies=TRUE)" && \
    R -e "install.packages('e1071', dependencies=TRUE)" && \
    R -e "install.packages('easysdctable', dependencies=TRUE)" && \
    R -e "install.packages('PxWebApiData', dependencies=TRUE)" && \
    R -e "install.packages('rglpk', dependencies=TRUE)" && \
    R -e "install.packages('rjdemetra', dependencies=TRUE)" && \
    R -e "install.packages('remotes', dependencies=TRUE)" && \
    R -e "install.packages('devtools', dependencies=TRUE)" && \
    R -e "install.packages('units', dependencies=TRUE)" && \
    R -e "install.packages('ggraph', dependencies=TRUE)" && \
    R -e "install.packages('tidygraph', dependencies=TRUE)" && \
    R -e "install.packages('nabor', dependencies=TRUE)" && \
    R -e "install.packages('RcppTOML', dependencies=TRUE)" && \
    R -e "install.packages('classInt', dependencies=TRUE)" && \
    R -e "install.packages('s2', dependencies=TRUE)" && \
    R -e "install.packages('glmnet', dependencies=TRUE)" && \
    R -e "install.packages('sparseM', dependencies=TRUE)" && \
    R -e "install.packages('randomForest', dependencies=TRUE)" && \
    R -e "install.packages('tree', dependencies=TRUE)" && \
    R -e "install.packages('tm', dependencies=TRUE)" && \
    R -e "install.packages('ipred', dependencies=TRUE)" && \
    R -e "install.packages('caTools', dependencies=TRUE)" && \
    R -e "install.packages('tau', dependencies=TRUE)" && \
    R -e "install.packages('pdftools', dependencies=TRUE)" && \
    R -e "install.packages('tesseract', dependencies=TRUE)" && \
    R -e "install.packages('sp', dependencies=TRUE)" && \
    R -e "install.packages('validate', dependencies=TRUE)" && \
    R -e "install.packages('bigrquery', dependencies=TRUE)" && \
    R -e "install.packages('rio', dependencies=TRUE)" && \
    R -e "install.packages('janitor', dependencies=TRUE)" && \
    R -e "install.packages('Hmisc', dependencies=TRUE)" && \
    R -e "install.packages('arsenal', dependencies=TRUE)" && \
    R -e "install.packages('summarytools', dependencies=TRUE)" && \
    R -e "install.packages('plotly', dependencies=TRUE)" && \
    R -e "install.packages('oecd', dependencies=TRUE)" && \
    R -e "install.packages('eurostat', dependencies=TRUE)" && \
    R -e "install.packages('wbstats', dependencies=TRUE)" && \
    R -e "install.packages('countrycode', dependencies=TRUE)" && \
    R -e "install.packages('gargle', dependencies=TRUE)" && \
    R -e "install.packages('lubridate', dependencies=TRUE)" && \
    R -e "install.packages('haven', dependencies=TRUE)" && \
    R -e "install.packages('survey', dependencies=TRUE)" && \
    R -e "remotes::install_github('statisticsnorway/SSBpris')" && \
    R -e "remotes::install_github('statisticsnorway/GaussSuppression')" && \
    R -e "remotes::install_github('statisticsnorway/fellesr')" && \
    R -e "remotes::install_github('statisticsnorway/Kostra')" && \
    R -e "remotes::install_github('statisticsnorway/SdcForetakPerson')" && \
    R -e "remotes::install_github('statisticsnorway/struktuR')" && \
    R -e "remotes::install_github('statisticsnorway/PxWebApiData')" && \
    R -e "remotes::install_github('statisticsnorway/SSBtools')" && \
    R -e "remotes::install_github('statisticsnorway/klassR')" && \
    R -e "remotes::install_github('statisticsnorway/GISSB')" && \
    R -e "remotes::install_github('statisticsnorway/ReGenesees')" && \
    rm -rf /tmp/downloaded_packages/ /tmp/*.rds

# Install JupyterLab extensions and Python packages
RUN pip3 install jupyterlab-git && \
    pip3 install ipywidgets && \
    pip3 install ipydatagrid && \
    pip3 install plotly && \
    pip3 install dash && \
    pip3 install jupyter-dash && \
    pip3 install jupyterlab-quarto && \
    pip3 install jupytext && \
    pip3 install jupyter-server-proxy && \
    pip3 install anywidget[dev] && \
    pip3 install nbdime && \
    pip3 install nbstripout && \
    pip3 install papermill && \
    pip3 install pyviz_comms && \
    pip3 install panel && \
    pip3 install geopandas && \
    pip3 install ipyleaflet && \
    pip3 install descartes && \
    pip3 install jupyterlab-lsp && \
    pip3 install python-language-server[all] && \
    pip3 install ipysheet && \
    pip3 install fuzzywuzzy[speedup] && \
    pip3 install jupyter-resource-usage && \
    pip3 install ipyparallel && \
    pip3 install sympy mpmath && \
    pip3 install sphinx sphinx-autodoc-defaultargs sphinx-autodoc-typehints sphinx-rtd-theme && \
    pip3 install pytest pytest_tornasync pytest-cov pytest-mock pre-commit-hooks jupyterlab-code-formatter black[jupyter] isort && \
    pip3 install pyjstat xmltodict lxml holidays PyGithub pre-commit pyminizip rich openpyxl pyarrow python-dotenv poetry && \
    pip3 install pandas-gbq google-cloud-storage venv-pack nbdev && \
    jupyter labextension disable @jupyterlab/docmanager-extension:download && \
    jupyter labextension disable @jupyterlab/filebrowser-extension:download && \
    jupyter labextension disable @jupyterlab/extensionmanager-extension && \
    jupyter labextension disable "@jupyterlab/apputils-extension:announcements" && \
    pipx install pre-commit --global && \
    R -e "install.packages('IRkernel'); IRkernel::installspec()" && \
    jupyter server --generate-config && \
    chown -R ${USERNAME}:${GROUPNAME} ${HOME} && \
    jupyter lab clean && \
    rm -rf /var/lib/apt/lists/*

# Set template version for ssb-project-cli
ENV STAT_TEMPLATE_DEFAULT_REFERENCE="1.1.9"

# Configure Python virtual environments
ENV PIP_REQUIRE_VIRTUALENV=true
ENV POETRY_VIRTUALENVS_IN_PROJECT=true

# Fix permissions
RUN chown -R ${USERNAME}:${GROUPNAME} ${HOME}

# Copy the kernels
COPY kernels/ir /opt/conda/share/jupyter/kernels/ir/
COPY kernels/python3 /opt/conda/share/jupyter/kernels/python3/

# Allowing everyone to execute python.sh and r.sh
RUN chmod +x /opt/conda/share/jupyter/kernels/python3/python.sh && \
    chmod +x /opt/conda/share/jupyter/kernels/ir/r.sh

# Copy bashrc.felles
COPY bashrc.felles /usr/local/share/etc/bashrc.felles

# Copy jupyter_notebook_extra_config.py
COPY jupyter_notebook_extra_config.py /tmp/
RUN cat /tmp/jupyter_notebook_extra_config.py >> /etc/jupyter/jupyter_server_config.py && \
    rm /etc/jupyter/jupyter_notebook_config.py && \
    chmod g-w /etc/jupyter/*.py && \
    rm -f /tmp/jupyter_notebook_extra_config.py

# Remove duplicate Python lib
RUN rm /usr/bin/python3 && ln -s /opt/conda/bin/python3 /usr/bin/python3

# Prevent installation of extensions
RUN chmod u-w /opt/conda/share/jupyter/labextensions && \
    chmod u-w /opt/conda/share/jupyter/nbextensions && \
    chmod u-w /opt/conda/share/jupyter/lab/extensions

USER ${UID}

EXPOSE 8888

CMD ["jupyter", "lab", "--no-browser", "--ip", "0.0.0.0"] 