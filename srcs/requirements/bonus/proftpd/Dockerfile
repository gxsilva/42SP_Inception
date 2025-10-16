FROM debian:bullseye

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        proftpd-basic \
        proftpd-mod-crypto \
        openssl \
        ca-certificates && \
    rm -rf /var/lib/apt/lists/*

COPY ./conf/proftpd.conf /etc/proftpd/proftpd.conf

RUN mkdir -p /etc/ssl/private /etc/ssl/certs && \
    openssl req -x509 -nodes -newkey rsa:2048 \
        -keyout /etc/ssl/private/proftpd.key \
        -out /etc/ssl/certs/proftpd.crt \
        -days 365 \
        -subj "/C=BR/ST=SP/L=São Paulo/O=42/OU=Student/CN=${NGINX_DOMAIN}" && \
    chmod 600 /etc/ssl/private/proftpd.key && \
    chmod 644 /etc/ssl/certs/proftpd.crt && \
    chown nobody:nogroup /etc/ssl/private/proftpd.key /etc/ssl/certs/proftpd.crt

RUN mkdir -p /home/ftpuser && \
    useradd -d /home/ftpuser -s /usr/sbin/nologin ftpuser && \
    echo "ftpuser:ftppass" | chpasswd && \
    chown -R ftpuser:ftpuser /home/ftpuser

EXPOSE 21 2121 30000-30009

CMD ["proftpd", "-n"]