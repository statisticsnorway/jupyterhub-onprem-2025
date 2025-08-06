ARG BASE_IMAGE=europe-north1-docker.pkg.dev/artifact-registry-5n/itinfra-bakkesyst-docker/jupyter-onprem-2025/r-minimal:latest
FROM ${BASE_IMAGE}

USER root

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