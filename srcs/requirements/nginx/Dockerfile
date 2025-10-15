FROM debian:bullseye

#NGINX ENV
ENV OPENSSL_PATH=/etc/nginx/ssl
ENV NGINX_DOMAIN=lsilva-x.42.fr

#INSTALL THE PACKAGES
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    nginx \
    openssl \
    ca-certificates \
    gettext-base \
    curl \
    tini \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /var/log/nginx /var/cache/nginx /etc/nginx/ssl \
    && chown -R www-data:www-data /var/log/nginx /var/cache/nginx

#NGINX CONFIGURATION FILE
COPY ./conf/nginx.conf /etc/nginx/nginx.conf
RUN chmod +x /etc/nginx/nginx.conf

#NGINX SCRIPT ENTRYPOINT
COPY ./tools/nginx_entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/nginx_entrypoint.sh

#CREAT RSA PRIVATE KEY (TO SIGN CA)
RUN mkdir -p ${OPENSSL_PATH} && \
    openssl genpkey -algorithm RSA -out ${OPENSSL_PATH}/nginx-selfsigned.key -pkeyopt rsa_keygen_bits:2048 && \
    openssl req -x509 -new -nodes \
        -key ${OPENSSL_PATH}/nginx-selfsigned.key -sha256 -days 3650 \
        -out ${OPENSSL_PATH}/nginx-selfsigned.crt \
        -subj "/C=BR/ST=SP/L=São Paulo/O=42/OU=Student/CN=${NGINX_DOMAIN}"

ENTRYPOINT ["/usr/local/bin/nginx_entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]

#OCI METADATAS
LABEL org.opencontainers.image.title="nginx_image_inception_42" \
      org.opencontainers.image.description="Custom debian image with NGINX and SSL/TLS" \
      org.opencontainers.image.version="inception" \
      org.opencontainers.image.authors="Lucas Gabriel <lssvgabriel@gmail.com>"