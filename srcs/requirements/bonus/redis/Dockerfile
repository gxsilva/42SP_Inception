FROM debian:bullseye

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    redis-server \
    tini \
    gettext-base \
    redis-tools \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/lib/redis \
    && chown redis:redis /var/lib/redis \
    && chmod 755 /var/lib/redis

ARG ARG_REGIS_CONFIG_PATH=/etc/redis/redis.conf
ENV REDIS_CONFIG_PATH=${ARG_REGIS_CONFIG_PATH}

COPY conf/redis.conf ${ARG_REGIS_CONFIG_PATH}
COPY tools/redis_entrypoint.sh /usr/local/bin

RUN chown redis:redis ${ARG_REGIS_CONFIG_PATH} \
    && chmod +x /usr/local/bin/redis_entrypoint.sh

EXPOSE 6379

USER redis

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/usr/local/bin/redis_entrypoint.sh"]

#OCI METADATAS
LABEL org.opencontainers.image.title="redis_image_inception_42" \
      org.opencontainers.image.description="Custom debian image with REDIS on port 6379" \
      org.opencontainers.image.version="inception" \
      org.opencontainers.image.authors="Lucas Gabriel <lssvgabriel@gmail.com>"