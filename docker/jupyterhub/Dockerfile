# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.
FROM quay.io/jupyterhub/jupyterhub:4

# Update distro to apply security fixes
RUN apt update && \
    apt-get -y clean all && \
    apt-get -y update && \
    apt-get -y upgrade && \
    apt-get -y dist-upgrade && \
    # # Installing sssd-tools (required for authentication)
    apt-get -y install sssd-tools

# Installing jupyterhub packages
RUN python3 -m pip install dockerspawner>=12.1.0 && \
    python3 -m pip install psycopg2-binary && \
    python3 -m pip install jupyterhub_idle_culler

# copy jupyterhub_config.py to container
COPY jupyterhub_config.py /srv/jupyterhub

ENV SSL_CERT=/srv/jupyterhub/secrets/certificates.pem
ENV SSL_KEY=/srv/jupyterhub/secrets/starssb.key
