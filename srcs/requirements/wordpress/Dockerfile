FROM debian:bullseye

#INSTALL THE PACKAGES
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    wget curl ca-certificates gnupg \
    tini \
    ftp \
    mariadb-client \
    php php-fpm php-cli php-mysql php-curl php-gd php-mbstring php-xml php-zip \
    php-redis \
    php-intl php-bcmath php-opcache \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /var/www/html /run/php \
    && chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html /run/php

#INSTALL WORDPRESS CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

#(DEPRECATED BY ME XD)
# COPY ./config/www.conf /etc/php/*/fpm/pool.d/www.conf

RUN sed -i 's/listen = \/run\/php\/php.*\.sock/listen = 0.0.0.0:9000/' /etc/php/*/fpm/pool.d/www.conf \
    && sed -i 's/;listen.owner = www-data/listen.owner = www-data/' /etc/php/*/fpm/pool.d/www.conf \
    && sed -i 's/;listen.group = www-data/listen.group = www-data/' /etc/php/*/fpm/pool.d/www.conf \
    && sed -i 's/;listen.mode = 0660/listen.mode = 0660/' /etc/php/*/fpm/pool.d/www.conf \
    && touch /var/log/php7.4-fpm.log \
    && chown www-data:www-data /var/log/php7.4-fpm.log

WORKDIR /var/www/html

COPY ./tools /usr/local/tools

RUN chmod -R +x /usr/local/tools

#PORT
EXPOSE 9000

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/usr/local/tools/wordpress_entrypoint.sh"]

#OCI METADATAS
LABEL org.opencontainers.image.title="wordpress_image_inception_42" \
      org.opencontainers.image.description="custom debian with WORDPRESS and PHP-FMP" \
      org.opencontainers.image.version="wordpress" \
      org.opencontainers.image.authors="Lucas Gabriel <lssvgabriel@gmail.com>"