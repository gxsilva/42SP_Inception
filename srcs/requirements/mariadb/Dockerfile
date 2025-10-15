FROM debian:bullseye

#INSTALL THE PACKAGES
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    mariadb-server \
    mariadb-client \
    gettext \
    tini \
    && rm -rf /var/lib/apt/lists/* 

#FOLDER AND USER PERMISSIONS
RUN mkdir -p /var/run/mysqld /var/lib/mysql \
    && chown -R mysql:mysql /var/run/mysqld /var/lib/mysql \
    && chmod 755 /var/run/mysqld /var/lib/mysql

#CONFIGURATION FILE AND PERMISSIONS
COPY ./conf/mariadb.conf /etc/mysql/mariadb.conf.d/50-server.cnf

#MARIADB SCRIPT ENTRYPOINT
COPY ./tools/mariadb_entrypoint.sh ./usr/local/bin

RUN chmod 644 /etc/mysql/mariadb.conf.d/50-server.cnf \
    && chmod +x /usr/local/bin/mariadb_entrypoint.sh

# DATABASE SCHEMA (DEPRECATED BY ME XD)
# COPY ./tools/wordpress.sql /etc/mysql/mariadb.conf.d/wordpress.sql

#PORT
EXPOSE 3306

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/usr/local/bin/mariadb_entrypoint.sh"]

#OCI METADATAS
LABEL org.opencontainers.image.title="mariadb_image_inception_42" \
      org.opencontainers.image.description="custom debian with MARIADB" \
      org.opencontainers.image.version="mariadb" \
      org.opencontainers.image.authors="Lucas Gabriel <lssvgabriel@gmail.com>"