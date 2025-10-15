#!/bin/sh
set -e

#MULTILEVEL LOG
log() {
    level="$1"
    shift
    case "$level" in
        INFO)    echo "ℹ️ [INFO] $*";;
        FILE)    echo "📄 [FILE] $*";;
        SUCCESS) echo "✅ [OK] $*";;
        ERROR)   echo "❌ [ERROR] $*" >&2;;
        DIR)     echo "📁 [DIR] $*";;
        WARN)    echo "⚠️ [WARN] $*";;
        *)       echo "🔍 [UNKNOWN] $*";;
    esac
}
#UNSET SECRETS VARIABLE
unset_secrets()
{
    if [ -z "$MYSQL_ROOT_PASSWORD" ]; then
        unset MYSQL_ROOT_PASSWORD
    fi
    if [ -z "$MYSQL_PASSWORD" ]; then
        unset MYSQL_PASSWORD
    fi
}

#DEBUG CONFIGURATION
if [ "${DEBUG:-}" = "true" ]; then
    set -x
    log INFO "Debug mode ENABLE"
else
    log INFO "Debug mode DISABLE"
fi

#MANAGEMENT SECRETS 
if [ -z "${MYSQL_PASSWORD:-}" ] && [ -f "${MYSQL_SP_PASSWORD:-}" ]; then
    MYSQL_PASSWORD=$(<"${MYSQL_SP_PASSWORD}")
    if [ "${DEBUG:-}" = "true" ]; then
        log DEBUG "MYSQL_PASSWORD: ${MYSQL_PASSWORD}"
    fi
else
    log ERROR "Failed to initialize MYSQL_PASSWORD. File not found or empty at path: ${MYSQL_SP_PASSWORD}"
    false
fi

if [ -z "${MYSQL_ROOT_PASSWORD:-}" ] &&  [ -f "${MYSQL_SP_ROOT_PASSWORD}" ]; then
    MYSQL_ROOT_PASSWORD=$(<"${MYSQL_SP_ROOT_PASSWORD}")
     if [ "${DEBUG:-}" = "true" ]; then
        log DEBUG "MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}"
    fi
else
    log ERROR "Failed to initialize MYSQL_ROOT_PASSWORD. File not found or empty at path: ${MYSQL_SP_ROOT_PASSWORD}"
    false
fi

#MARIADB INSTALL AND CONFIGURATION
if [ ! -f "/var/lib/mysql/.initialized" ]; then
    log INFO "Initialize Data Base..."
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql --rpm --skip-test-db

    log INFO "Start temporary instance for configuration..."

    mysqld --user=mysql --datadir=/var/lib/mysql --skip-networking --socket=/tmp/mysql_init.sock &
    MYSQL_PID="$!"

    until mysqladmin ping --socket=/tmp/mysql_init.sock --silent; do
        log INFO "Database being configured"
        sleep 1
    done

    mysql --socket=/tmp/mysql_init.sock -u root << EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '$MYSQL_USER'@'%';
FLUSH PRIVILEGES;
EOF

    kill "$MYSQL_PID"
    wait "$MYSQL_PID"
    
    touch /var/lib/mysql/.initialized
    log SUCCESS "Data Base initialization completed"
else
    log SUCCESS "Data Base already initialize, skipping bootstrap script..."
fi

unset_secrets

log SUCCESS "Starting mariadb with tini as PID 1..."

exec mysqld --user=mysql --datadir=/var/lib/mysql

#---------------(DEPRECATED BY ME XD)----------------------------------
# if ! MYSQL_ROOT_PASSWORD="$MYSQL_ROOT_PASSWORD" \
#     MYSQL_PASSWORD="$MYSQL_PASSWORD" \
#     MYSQL_DATABASE="$MYSQL_DATABASE" \
#     MYSQL_USER="$MYSQL_USER" \
#     envsubst '$MYSQL_ROOT_PASSWORD $MYSQL_PASSWORD $MYSQL_DATABASE $MYSQL_USER' \
#     < /etc/mysql/mariadb.conf.d/wordpress.sql \
#     | mysql --socket=/tmp/mysql_init.sock -u root
# then
#     echo "⚠️ Failed to initialize the database with wordpress.sql"
#     kill "$MYSQL_PID"
#     wait "$MYSQL_PID"
    
#     # Cleanup sensitive vars if unset or empty
#     [ -z "$MYSQL_ROOT_PASSWORD" ] && unset MYSQL_ROOT_PASSWORD
#     [ -z "$MYSQL_SP_PASSWORD" ] && unset MYSQL_SP_PASSWORD

#     exit 1
# fi
#------------------------------------------------------------