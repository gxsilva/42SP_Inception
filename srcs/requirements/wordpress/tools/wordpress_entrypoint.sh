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

#DEBUG CONFIGURATION
if [ "${DEBUG:-}" = "true" ]; then
    set -x
    log INFO "Debug mode ENABLE"
else
    log INFO "Debug mode DISABLE"
fi

#MANAGEMENT SECRETS 
if [ -z "${MYSQL_PASSWORD:-}" ] &&  [ -f "${MYSQL_SP_PASSWORD}" ]; then
    MYSQL_PASSWORD=$(<"${MYSQL_SP_PASSWORD}")
    if [ "${DEBUG:-}" = "true" ]; then
        log DEBUG "MYSQL_PASSWORD: ${MYSQL_PASSWORD}"
    fi
else
    log ERROR "Failed to initialize MYSQL_PASSWORD. File not found or empty at path: ${MYSQL_SP_PASSWORD}"
    false
fi

if [ -z "${WORDPRESS_ADMIN_PASSWORD:-}" ] &&  [ -f "${WORDPRESS_SP_ADMIN_PASSWORD}" ]; then
    WORDPRESS_ADMIN_PASSWORD=$(<"${WORDPRESS_SP_ADMIN_PASSWORD}")
    if [ "${DEBUG:-}" = "true" ]; then
        log DEBUG "WORDPRESS_ADMIN_PASSWORD: ${WORDPRESS_ADMIN_PASSWORD}"
    fi
else
    log ERROR "Failed to initialize MYSQL_PASSWORD. File not found or empty at path: ${WORDPRESS_SP_ADMIN_PASSWORD}"
    false
fi

wait_for_mysql() {
   log INFO "Waiting for MySQL database to be ready..."
    local max_retries=30
    local count=0
    
    until mysqladmin ping -h"mariadb" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" --silent; do
        count=$((count + 1))
        if [ $count -ge $max_retries ]; then
            log WARN "MySQL connection timeout after $max_retries attempts"
            return 1
        fi
        log INFO "Waiting for database connection... (attempt $count/$max_retries)"
        sleep 2
    done
    
    log SUCCESS "MySQL database is ready"
    return 0
}

download_wordpress() {
    if [ ! -f "wp-load.php" ]; then
        log INFO "Downloading WordPress core files..."
        wp core download --allow-root || {
            log ERROR "Failed to download WordPress"
            return 1
        }
        log SUCCESS "WordPress core files downloaded successfully"
    else
        log INFO "WordPress core files already exist"
    fi
    return 0
}

create_wp_config() {
    if [ ! -f "wp-config.php" ]; then
        log INFO "Creating WordPress configuration..."
        if [ "${DEBUG:-}" = "true" ]; then
            log DEBUG "dbname: ${MYSQL_DATABASE:-<not set>}"
            log DEBUG "dbuser: ${MYSQL_USER:-<not set>}"
            log DEBUG "dbpass: [REDACTED]"
            log DEBUG "dbhost: ${WORDPRESS_DB_HOST:-<not set>}"
        fi
        wp config create \
            --dbname="$MYSQL_DATABASE" \
            --dbuser="$MYSQL_USER" \
            --dbpass="$MYSQL_PASSWORD" \
            --dbhost="$WORDPRESS_DB_HOST" \
            --allow-root \
            --skip-check || {
            log ERROR "Failed to create wp-config.php"
            return 1
        }
        log SUCCESS "WordPress configuration created successfully"
    else
        log INFO "WordPress configuration already exists"
    fi
    return 0
}

download_wordpress() {
    if [ ! -f "wp-load.php" ]; then
        log INFO "Downloading WordPress core files..."
        wp core download --allow-root || {
            echo "Failed to download WordPress"
            return 1
        }
        log SUCCESS "WordPress core files downloaded successfully"
    else
        log INFO "WordPress core files already exist"
    fi
    return 0
}

install_wordpress() {
    if ! wp core is-installed --allow-root 2>/dev/null; then
        log INFO "Installing WordPress..."
        if [ "${DEBUG:-}" = "true" ]; then
            log DEBUG "url: ${WORDPRESS_URL:-<not set>}"
            log DEBUG "title: ${WORDPRESS_TITLE:-<not set>}"
            log DEBUG "admin_user: ${WORDPRESS_ADMIN_USER:-<not set>}"
            log DEBUG "admin_password: [REDACTED]"
            log DEBUG "admin_email: [REDACTED]"
        fi
        wp core install \
            --url="$WORDPRESS_URL" \
            --title="$WORDPRESS_TITLE" \
            --admin_user="$WORDPRESS_ADMIN_USER" \
            --admin_password="$WORDPRESS_ADMIN_PASSWORD" \
            --admin_email="$WORDPRESS_ADMIN_EMAIL" \
            --allow-root \
            --skip-email || {
            log ERROR "Failed to install WordPress"
            return 1
        }
        log SUCCESS "WordPress installed successfully"
    else
        log INFO "WordPress is already installed"
        
        # Update admin password if it changed
        if wp user get "$WORDPRESS_ADMIN_USER" --allow-root >/dev/null 2>&1; then
            log WARN "Updating admin user password..."
            wp user update "$WORDPRESS_ADMIN_USER" \
                --user_pass="$WORDPRESS_ADMIN_PASSWORD" \
                --allow-root 2>/dev/null
        else
            log INFO "Creating admin user..."
            wp user create "$WORDPRESS_ADMIN_USER" "$WORDPRESS_ADMIN_EMAIL" \
                --role=administrator \
                --user_pass="$WORDPRESS_ADMIN_PASSWORD" \
                --allow-root 2>/dev/null || \
                log ERROR "Admin user already exists or creation failed"
        fi
    fi
    return 0
}

unset_variables()
{
    if [ -z "$MYSQL_PASSWORD" ]; then
        unset MYSQL_PASSWORD
    fi
    if [ -z "$WORDPRESS_ADMIN_PASSWORD" ]; then
        unset WORDPRESS_ADMIN_PASSWORD
    fi
}

main() {
    wait_for_mysql
    download_wordpress
    create_wp_config
    install_wordpress
    unset_variables

    log SUCCESS "WordPress initialization completed"
}

main

log INFO "Start PHP-FMP"
exec /usr/sbin/php-fpm7.4 -F