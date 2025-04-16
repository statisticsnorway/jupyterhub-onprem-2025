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



# Use RStudio's package manager to download packages as binaries
ENV CRAN="https://packagemanager.posit.co/cran/__linux__/noble/latest"

# Install R packages
RUN R CMD javareconf -e && \
    R -e "install.packages('tidyfst', repos='${CRAN}')" && \
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
    R -e "install.packages('klassR', dependencies=TRUE, repos='${CRAN}')" && \
    R -e "install.packages('pxwebapidata', dependencies=TRUE, repos='${CRAN}')" && \
    R -e "install.packages('gissb', dependencies=TRUE, repos='${CRAN}')" && \
    R -e "install.packages('igraph', dependencies=TRUE, repos='${CRAN}')" && \
    R -e "install.packages('dggridR', repos='${CRAN}')" && \
    R -e "install.packages('remotes', repos='${CRAN}')" && \
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
    R -e "remotes::install_github('statisticsnorway/ssb-pickmdl')"

# Install jwsacruncher
COPY jwsacruncher-2.2.4.zip /tmp/jwsacruncher-2.2.4.zip
RUN unzip /tmp/jwsacruncher-2.2.4.zip -d /opt && rm -f /tmp/jwsacruncher-2.2.4.zip
# Create a symlink at /usr/bin so users can call jwsacruncher from anywhere
RUN ln -s /opt/jwsacruncher-2.2.4/bin/jwsacruncher /usr/bin/jwsacruncher


# Fix permissions
RUN chown -R ${USERNAME}:${GROUPNAME} ${HOME} ${R_HOME}

USER ${UID}

CMD ["R"] 