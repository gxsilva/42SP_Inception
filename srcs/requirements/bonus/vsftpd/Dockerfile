FROM debian:bullseye

#INSTALL THE PACKAGES
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    vsftpd \
    lftp \
    tini \
    openssl \
    && rm -rf /var/lib/apt/lists/*

# Create FTP user
RUN useradd -m ftpuser

# Create FTP directory
RUN mkdir -p /home/ftpuser/ftp/files && \
    chown nobody:nogroup /home/ftpuser/ftp && \
    chmod a-w /home/ftpuser/ftp && \
    chown ftpuser:ftpuser /home/ftpuser/ftp/files

COPY ./conf/vsftpd.conf /etc/vsftpd.conf
COPY ./tools/vsftpd_entrypoint.sh /usr/local/bin

RUN chmod +x /usr/local/bin/vsftpd_entrypoint.sh

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/usr/local/bin/vsftpd_entrypoint.sh"]

EXPOSE 21 2110-21110

#OCI METADATAS
LABEL org.opencontainers.image.title="vsftpd_image_inception_42" \
      org.opencontainers.image.description="custom debian with VSFTPD and PHP-FMP" \
      org.opencontainers.image.version="vsftpd" \
      org.opencontainers.image.authors="Lucas Gabriel <lssvgabriel@gmail.com>"