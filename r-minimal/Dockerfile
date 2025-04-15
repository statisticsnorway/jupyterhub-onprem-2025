FROM base:latest

LABEL maintainer="Statistics Norway"

# R Config
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

# Install required packages
# RUN apt-get update && \
#     apt-get install -y --no-install-recommends \
#     wget \
#     alien \
#     libaio1 \
#     libaio-dev \
#     git \
#     openjdk-${JAVA_VERSION}-jdk \
#     && rm -rf /var/lib/apt/lists/*

COPY scripts /opt/scripts/
RUN chmod +x -R /opt/scripts/
RUN chown -R ${USERNAME}:${GROUPNAME} /opt/scripts/ 
RUN chmod -R 700 /opt/scripts/
RUN ls -la /opt/scripts/
# Clone and prepare R installation scripts
RUN mkdir -p /rocker_scripts && \
    git clone --branch R${R_VERSION} --depth 1 https://github.com/rocker-org/rocker-versioned2.git /tmp/rocker-versioned2 && \
    cp -r /tmp/rocker-versioned2/scripts/* /rocker_scripts/ && \
    rm -rf /tmp/rocker-versioned2 && \
    chown -R ${USERNAME}:${GROUPNAME} /rocker_scripts/ && \
    chmod -R 700 /rocker_scripts/ && \
    ls -la /rocker_scripts/

# Install R from source
RUN bash /rocker_scripts/install_R_source.sh

# Install java
RUN bash /opt/scripts/install-java.sh
# Setting up R with specific version
RUN bash /rocker_scripts/setup_R.sh
# Re-install system libs that may have been removed by autoremove in rocker scripts
RUN bash /opt/scripts/install-system-libs.sh
# Install additional system libs needed by R packages
RUN bash /opt/scripts/install-system-libs-R.sh

# Set up R (RSPM, OpenBLAS, littler, addtional packages)
# RUN bash /rocker_scripts/setup_R.sh && \
#     # Install additional system libs needed by R packages
#     apt-get update && \
#     apt-get install -y --no-install-recommends \
#     libcurl4-openssl-dev \
#     libssl-dev \
#     libxml2-dev \
#     libcairo2-dev \
#     libudunits2-dev \
#     libgdal-dev \
#     libgeos-dev \
#     libproj-dev \
#     libv8-dev \
#     libsodium-dev \
#     libharfbuzz-dev \
#     libfribidi-dev \
#     libfreetype6-dev \
#     libpng-dev \
#     libtiff5-dev \
#     libjpeg-dev \
#     && apt-get clean \
#     && rm -rf /var/lib/apt/lists/*

# # Install curl
# RUN apt-get update && apt-get install -y curl && apt-get install -y alien && apt-get clean && rm -rf /var/lib/apt/lists/*

# Downloading oracle instant-client components and saving to /tmp
RUN curl -L https://download.oracle.com/otn_software/linux/instantclient/216000/oracle-instantclient-basic-21.6.0.0.0-1.x86_64.rpm -o /tmp/oracle-instantclient-basic-21.6.0.0.0-1.x86_64.rpm && \
    curl -L https://download.oracle.com/otn_software/linux/instantclient/216000/oracle-instantclient-devel-21.6.0.0.0-1.x86_64.rpm -o /tmp/oracle-instantclient-devel-21.6.0.0.0-1.x86_64.rpm && \
    curl -L https://download.oracle.com/otn_software/linux/instantclient/216000/oracle-instantclient-sqlplus-21.6.0.0.0-1.x86_64.rpm -o /tmp/oracle-instantclient-sqlplus-21.6.0.0.0-1.x86_64.rpm && \
    curl -L https://download.oracle.com/otn_software/linux/instantclient/216000/oracle-instantclient-odbc-21.6.0.0.0-1.x86_64.rpm -o /tmp/oracle-instantclient-odbc-21.6.0.0.0-1.x86_64.rpm && \
    curl -L https://download.oracle.com/otn_software/linux/instantclient/216000/oracle-instantclient-jdbc-21.6.0.0.0-1.x86_64.rpm -o /tmp/oracle-instantclient-jdbc-21.6.0.0.0-1.x86_64.rpm && \
    curl -L https://download.oracle.com/otn_software/linux/instantclient/216000/oracle-instantclient-tools-21.6.0.0.0-1.x86_64.rpm -o /tmp/oracle-instantclient-tools-21.6.0.0.0-1.x86_64.rpm

# Installing oracle-instantclient components using alien
RUN alien -i /tmp/oracle-instantclient-basic-21.6.0.0.0-1.x86_64.rpm && \
    alien -i /tmp/oracle-instantclient-devel-21.6.0.0.0-1.x86_64.rpm && \
    alien -i /tmp/oracle-instantclient-odbc-21.6.0.0.0-1.x86_64.rpm && \
    alien -i /tmp/oracle-instantclient-jdbc-21.6.0.0.0-1.x86_64.rpm && \
    alien -i /tmp/oracle-instantclient-tools-21.6.0.0.0-1.x86_64.rpm && \
    # Must install sqlplus seperately because of an issue installing using alien
    cd /tmp && \
    rpm2cpio /tmp/oracle-instantclient-sqlplus-21.6.0.0.0-1.x86_64.rpm | cpio -idmv && \
    cp -r /tmp/usr/* /usr/ && \
    rm -rf /tmp/usr && \
    ldconfig && \
    rm -rf /tmp/oracle-instantclient-*

# add tnsnames.ora to oracle path
RUN ln -s /ssb/share/etc/tnsnames.ora /usr/lib/oracle/21/client64/lib/network/tnsnames.ora

# required to build ROracle
ENV OCI_INC=/usr/include/oracle/21/client64
ENV OCI_LIB=/usr/lib/oracle/21/client64/lib
ENV ORACLE_HOME=/usr/lib/oracle/21/client64
ENV TNS_ADMIN=/usr/lib/oracle/21/client64/lib/network
ENV LD_LIBRARY_PATH=/usr/lib/oracle/21/client64/lib

# Use RStudio's package manager to download packages as binaries
ENV CRAN="https://packagemanager.posit.co/cran/__linux__/jammy/latest"

# Install R packages
RUN R CMD javareconf -e && \
    R -e "install.packages('configr', dependencies=TRUE, repos='${CRAN}')" && \
    R -e "install.packages('DBI', dependencies=TRUE, repos='${CRAN}')" && \
    R -e "install.packages('renv', dependencies=TRUE, repos='${CRAN}')" && \
    R -e "install.packages('arrow', dependencies=FALSE, repos='${CRAN}')" && \
    R -e "install.packages('leaflet', dependencies=TRUE, repos='${CRAN}')" && \
    R -e "install.packages('getPass', dependencies=TRUE, repos='${CRAN}')" && \
    R -e "install.packages('googleCloudStorageR', dependencies=TRUE, repos='${CRAN}')" && \
    R -e "install.packages('DT', dependencies=TRUE, repos='${CRAN}')" && \
    R -e "install.packages('rjwsacruncher', dependencies=TRUE, repos='${CRAN}')" && \
    R -e "install.packages('sf', dependencies=TRUE, repos='${CRAN}')" && \
    R -e "install.packages('sfarrow', dependencies=FALSE, repos='${CRAN}')" && \
    R -e "install.packages('dbplyr', dependencies=FALSE, repos='${CRAN}')" && \
    R -e "install.packages('shiny', dependencies=FALSE, repos='${CRAN}')" && \
    R -e "install.packages('rstudioapi', dependencies=TRUE, repos='${CRAN}')" && \
    R -e "install.packages('httr', dependencies=TRUE, repos='${CRAN}')" && \
    R -e "install.packages('readr', dependencies=TRUE, repos='${CRAN}')" && \
    R -e "install.packages('knitr', dependencies=TRUE, repos='${CRAN}')" && \
    R -e "install.packages('rmarkdown', dependencies=TRUE, repos='${CRAN}')" && \
    R -e "install.packages('Rcurl', dependencies=TRUE, repos='${CRAN}')" && \
    R -e "install.packages('here', dependencies=TRUE, repos='${CRAN}')" && \
    R -e "install.packages('esquisse', dependencies=TRUE, repos='${CRAN}')" && \
    R -e "install.packages('dcmodify', dependencies=TRUE, repos='${CRAN}')" && \
    R -e "install.packages('simputation', dependencies=TRUE, repos='${CRAN}')" && \
    R -e "install.packages('SmallCountRounding', dependencies=TRUE, repos='${CRAN}')" && \
    R -e "install.packages('ggplot2', dependencies=TRUE, repos='${CRAN}')" && \
    R -e "install.packages('RCurl', dependencies=TRUE, repos='${CRAN}')" && \
    R -e "install.packages('tidyverse', dependencies=TRUE, repos='${CRAN}')" && \
    R -e "install.packages('docopt', dependencies=TRUE, repos='${CRAN}')" && \
    R -e "install.packages('e1071', dependencies=TRUE, repos='${CRAN}')" && \
    R -e "install.packages('easysdctable', dependencies=TRUE, repos='${CRAN}')" && \
    R -e "install.packages('PxWebApiData', dependencies=TRUE, repos='${CRAN}')" && \
    R -e "install.packages('rglpk', dependencies=TRUE, repos='${CRAN}')" && \
    R -e "install.packages('rjdemetra', dependencies=TRUE, repos='${CRAN}')" && \
    R -e "install.packages('remotes', dependencies=TRUE, repos='${CRAN}')" && \
    R -e "install.packages('devtools', dependencies=TRUE, repos='${CRAN}')" && \
    R -e "install.packages('units', dependencies=TRUE, repos='${CRAN}')" && \
    R -e "install.packages('ggraph', dependencies=TRUE, repos='${CRAN}')" && \
    R -e "install.packages('tidygraph', dependencies=TRUE, repos='${CRAN}')" && \
    R -e "install.packages('nabor', dependencies=TRUE, repos='${CRAN}')" && \
    R -e "install.packages('RcppTOML', dependencies=TRUE, repos='${CRAN}')" && \
    R -e "install.packages('classInt', dependencies=TRUE, repos='${CRAN}')" && \
    R -e "install.packages('s2', dependencies=TRUE, repos='${CRAN}')" && \
    R -e "install.packages('glmnet', dependencies=TRUE, repos='${CRAN}')" && \
    R -e "install.packages('sparseM', dependencies=TRUE, repos='${CRAN}')" && \
    R -e "install.packages('randomForest', dependencies=TRUE, repos='${CRAN}')" && \
    R -e "install.packages('tree', dependencies=TRUE, repos='${CRAN}')" && \
    R -e "install.packages('tm', dependencies=TRUE, repos='${CRAN}')" && \
    R -e "install.packages('ipred', dependencies=TRUE, repos='${CRAN}')" && \
    R -e "install.packages('caTools', dependencies=TRUE, repos='${CRAN}')" && \
    R -e "install.packages('tau', dependencies=TRUE, repos='${CRAN}')" && \
    R -e "install.packages('pdftools', dependencies=TRUE, repos='${CRAN}')" && \
    R -e "install.packages('tesseract', dependencies=TRUE, repos='${CRAN}')" && \
    R -e "install.packages('sp', dependencies=TRUE, repos='${CRAN}')" && \
    R -e "install.packages('validate', dependencies=TRUE, repos='${CRAN}')" && \
    R -e "install.packages('bigrquery', dependencies=TRUE, repos='${CRAN}')" && \
    R -e "install.packages('rio', dependencies=TRUE, repos='${CRAN}')" && \
    R -e "install.packages('janitor', dependencies=TRUE, repos='${CRAN}')" && \
    R -e "install.packages('Hmisc', dependencies=TRUE, repos='${CRAN}')" && \
    R -e "install.packages('arsenal', dependencies=TRUE, repos='${CRAN}')" && \
    R -e "install.packages('summarytools', dependencies=TRUE, repos='${CRAN}')" && \
    R -e "install.packages('plotly', dependencies=TRUE, repos='${CRAN}')" && \
    R -e "install.packages('oecd', dependencies=TRUE, repos='${CRAN}')" && \
    R -e "install.packages('eurostat', dependencies=TRUE, repos='${CRAN}')" && \
    R -e "install.packages('wbstats', dependencies=TRUE, repos='${CRAN}')" && \
    R -e "install.packages('countrycode', dependencies=TRUE, repos='${CRAN}')" && \
    R -e "install.packages('gargle', dependencies=TRUE, repos='${CRAN}')" && \
    R -e "install.packages('lubridate', dependencies=TRUE, repos='${CRAN}')" && \
    R -e "install.packages('haven', dependencies=TRUE, repos='${CRAN}')" && \
    R -e "install.packages('survey', dependencies=TRUE, repos='${CRAN}')" && \
    R -e "remotes::install_github('statisticsnorway/ssb-pris')" && \
    R -e "remotes::install_github('statisticsnorway/ssb-GaussSuppression')" && \
    R -e "remotes::install_github('statisticsnorway/ssb-fellesr')" && \
    R -e "remotes::install_github('statisticsnorway/ssb-kostra')" && \
    R -e "remotes::install_github('statisticsnorway/ssb-SdcForetakPerson')" && \
    R -e "remotes::install_github('statisticsnorway/ssb-struktuR')" && \
    R -e "remotes::install_github('statisticsnorway/ssb-pxwebapidata')" && \
    R -e "remotes::install_github('statisticsnorway/ssb-SSBtools')" && \
    R -e "remotes::install_github('statisticsnorway/ssb-klassr')" && \
    R -e "remotes::install_github('statisticsnorway/GISSB')" && \
    R -e "remotes::install_github('statisticsnorway/ReGenesees')" && \
    R -e "install.packages('igraph', dependencies=TRUE, repos='${CRAN}')" && \
    R -e "remotes::install_github('statisticsnorway/ssb-pickmdl')" && \
    R -e "install.packages('dggridR', repos='${CRAN}')"

# Install jwsacruncher
COPY jwsacruncher-2.2.4.zip /tmp/jwsacruncher-2.2.4.zip
RUN unzip /tmp/jwsacruncher-2.2.4.zip -d /opt && rm -f /tmp/jwsacruncher-2.2.4.zip
# Create a symlink at /usr/bin so users can call jwsacruncher from anywhere
RUN ln -s /opt/jwsacruncher-2.2.4/bin/jwsacruncher /usr/bin/jwsacruncher


# Fix permissions
RUN chown -R ${USERNAME}:${GROUPNAME} ${HOME} ${R_HOME}

USER ${UID}

CMD ["R"] 