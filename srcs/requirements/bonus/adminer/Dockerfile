FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    apache2 \
    php \
    tini \
    php-mysqli \
    php-pgsql \
    php-sqlite3 \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Download Adminer
RUN rm -f /var/www/html/index.html && \
    wget -O /var/www/html/index.php https://www.adminer.org/latest.php

# Configure Apache to run on port 8080
RUN sed -i 's/80/8080/g' /etc/apache2/sites-available/000-default.conf /etc/apache2/ports.conf

# Set proper permissions
RUN chown -R www-data:www-data /var/www/html

EXPOSE 8080

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["apachectl", "-D", "FOREGROUND"]