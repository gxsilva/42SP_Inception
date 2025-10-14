#!/bin/sh
set -e

#MACROS FUNCTIONS
log_info()    { echo "ℹ️ [INFO] $*"; }
log_file()    { echo "📄 [FILE] $*"; }
log_success() { echo "✅ [OK] $*"; }
log_error()   { echo "❌ [ERROR] $*" >&2; }
log_dir()     { echo "📁 [DIR] $*"; }
log_warn()    { echo "⚠️ [WARN] $*"; }
log_debug()   { echo "🪲 [DEBUG] $*"; }

#DEBUG CONFIGURATION
if [ "${DEBUG:-}" = "true" ]; then
    set -x
    log_info "Debug mode ENABLE"
else
    log_info "Debug mode DISABLE"
fi

#MANAGEMENT SECRETS 
if [ -z "${MYSQL_PASSWORD:-}" ] &&  [ -f "${MYSQL_SP_PASSWORD}" ]; then
    MYSQL_PASSWORD=$(<"${MYSQL_SP_PASSWORD}")
    if [ "${DEBUG:-}" = "true" ]; then
        log_debug "MYSQL_PASSWORD: ${MYSQL_PASSWORD}"
    fi
else
    log_error "Failed to initialize MYSQL_PASSWORD. File not found or empty at path: ${MYSQL_SP_PASSWORD}"
    false
fi

if [ -z "${WORDPRESS_ADMIN_PASSWORD:-}" ] &&  [ -f "${WORDPRESS_SP_ADMIN_PASSWORD}" ]; then
    WORDPRESS_ADMIN_PASSWORD=$(<"${WORDPRESS_SP_ADMIN_PASSWORD}")
    if [ "${DEBUG:-}" = "true" ]; then
        log_debug "WORDPRESS_ADMIN_PASSWORD: ${WORDPRESS_ADMIN_PASSWORD}"
    fi
else
    log_error "Failed to initialize MYSQL_PASSWORD. File not found or empty at path: ${WORDPRESS_SP_ADMIN_PASSWORD}"
    false
fi

wait_for_mysql() {
   log_info "Waiting for MySQL database to be ready..."
    local max_retries=30
    local count=0
    
    until mysqladmin ping -h"mariadb" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" --silent; do
        count=$((count + 1))
        if [ $count -ge $max_retries ]; then
            log_warn "MySQL connection timeout after $max_retries attempts"
            return 1
        fi
        log_info "Waiting for database connection... (attempt $count/$max_retries)"
        sleep 2
    done
    
    log_success "MySQL database is ready"
    return 0
}

download_wordpress() {
    if [ ! -f "wp-load.php" ]; then
        log_info "Downloading WordPress core files..."
        wp core download --allow-root || {
            log_error "Failed to download WordPress"
            return 1
        }
        log_success "WordPress core files downloaded successfully"
    else
        log_info "WordPress core files already exist"
    fi
    return 0
}

create_wp_config() {
    if [ ! -f "wp-config.php" ]; then
        log_info "Creating WordPress configuration..."
        if [ "${DEBUG:-}" = "true" ]; then
            log_debug "dbname: ${MYSQL_DATABASE:-<not set>}"
            log_debug "dbuser: ${MYSQL_USER:-<not set>}"
            log_debug "dbpass: [REDACTED]"
            log_debug "dbhost: ${WORDPRESS_DB_HOST:-<not set>}"
        fi
        wp config create \
            --dbname="$MYSQL_DATABASE" \
            --dbuser="$MYSQL_USER" \
            --dbpass="$MYSQL_PASSWORD" \
            --dbhost="$WORDPRESS_DB_HOST" \
            --allow-root \
            --skip-check || {
            log_error "Failed to create wp-config.php"
            return 1
        }
        log_success "WordPress configuration created successfully"
    else
        log_info "WordPress configuration already exists"
    fi
    return 0
}

download_wordpress() {
    if [ ! -f "wp-load.php" ]; then
        log_info "Downloading WordPress core files..."
        wp core download --allow-root || {
            echo "Failed to download WordPress"
            return 1
        }
        log_success "WordPress core files downloaded successfully"
    else
        log_info "WordPress core files already exist"
    fi
    return 0
}

install_wordpress() {
    if ! wp core is-installed --allow-root 2>/dev/null; then
        log_info "Installing WordPress..."
        if [ "${DEBUG:-}" = "true" ]; then
            log_debug "url: ${WORDPRESS_URL:-<not set>}"
            log_debug "title: ${WORDPRESS_TITLE:-<not set>}"
            log_debug "admin_user: ${WORDPRESS_ADMIN_USER:-<not set>}"
            log_debug "admin_password: [REDACTED]"
            log_debug "admin_email: [REDACTED]"
        fi
        wp core install \
            --url="$WORDPRESS_URL" \
            --title="$WORDPRESS_TITLE" \
            --admin_user="$WORDPRESS_ADMIN_USER" \
            --admin_password="$WORDPRESS_ADMIN_PASSWORD" \
            --admin_email="$WORDPRESS_ADMIN_EMAIL" \
            --allow-root \
            --skip-email || {
            log_error "Failed to install WordPress"
            return 1
        }
        log_success "WordPress installed successfully"
    else
        log_info "WordPress is already installed"
        
        # Update admin password if it changed
        if wp user get "$WORDPRESS_ADMIN_USER" --allow-root >/dev/null 2>&1; then
            log_warn "Updating admin user password..."
            wp user update "$WORDPRESS_ADMIN_USER" \
                --user_pass="$WORDPRESS_ADMIN_PASSWORD" \
                --allow-root 2>/dev/null
        else
            log_info "Creating admin user..."
            wp user create "$WORDPRESS_ADMIN_USER" "$WORDPRESS_ADMIN_EMAIL" \
                --role=administrator \
                --user_pass="$WORDPRESS_ADMIN_PASSWORD" \
                --allow-root 2>/dev/null || \
                log_error "Admin user already exists or creation failed"
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

    log_success "WordPress initialization completed"
}

main

log_info "Start PHP-FMP"
exec /usr/sbin/php-fpm7.4 -F