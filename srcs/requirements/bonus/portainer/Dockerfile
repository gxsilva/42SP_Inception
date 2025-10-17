FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    wget \
    ca-certificates \
    tini \
    && rm -rf /var/lib/apt/lists/*

# Download and extract Portainer
RUN wget https://github.com/portainer/portainer/releases/download/2.19.4/portainer-2.19.4-linux-amd64.tar.gz && \
    tar -xzf portainer-2.19.4-linux-amd64.tar.gz && \
    mv portainer /opt/ && \
    rm portainer-2.19.4-linux-amd64.tar.gz


COPY ./tools/portainer_entrypoint.sh /usr/local/bin

RUN mkdir -p /data \
    && chmod +x /usr/local/bin/portainer_entrypoint.sh

EXPOSE 9000 9443

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/usr/local/bin/portainer_entrypoint.sh"]