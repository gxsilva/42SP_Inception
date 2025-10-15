#!/bin/sh

#MACROS FUNCTIONS
log_info()    { echo "ℹ️ [INFO] $*"; }
log_file()    { echo "📄 [FILE] $*"; }
log_success() { echo "✅ [OK] $*"; }
log_error()   { echo "❌ [ERROR] $*" >&2; }
log_dir()     { echo "📁 [DIR] $*"; }
log_warn()    { echo "⚠️ [WARN] $*"; }

#DEBUG CONFIGURATION
if [ "${DEBUG:-}" = "true" ]; then
    set -x
    log_info "Debug mode ENABLE"
else
    log_info "Debug mode DISABLE"
fi

#MANAGEMENT SECRETS 
if [ -z "${MYSQL_PASSWORD:-}" ] &&  [ -f "${MYSQL_SP_PASSWORD}" ]; then
    MYSQL_PASSWORD=$(cat "${MYSQL_SP_PASSWORD}")
    if [ "${DEBUG:-}" = "true" ]; then
        log_debug "MYSQL_PASSWORD: ${MYSQL_PASSWORD}"
    fi
else
    log_error "Failed to initialize MYSQL_PASSWORD. File not found or empty at path: ${MYSQL_SP_PASSWORD}"
    exit 1
fi

if [ -z "${WORDPRESS_ADMIN_PASSWORD:-}" ] &&  [ -f "${WORDPRESS_SP_ADMIN_PASSWORD}" ]; then
    WORDPRESS_ADMIN_PASSWORD=$(cat "${WORDPRESS_SP_ADMIN_PASSWORD}")
    if [ "${DEBUG:-}" = "true" ]; then
        log_debug "WORDPRESS_ADMIN_PASSWORD: ${WORDPRESS_ADMIN_PASSWORD}"
    fi
else
    log_error "Failed to initialize WORDPRESS_ADMIN_PASSWORD. File not found or empty at path: ${WORDPRESS_SP_ADMIN_PASSWORD}"
    exit 1
fi

cd /var/www/html

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

wait_for_redis() {
    log_info "Checking Redis availability..."
    local max_retries=10
    local count=0
    
    while [ $count -lt $max_retries ]; do
        if nc -z redis 6379 2>/dev/null || timeout 1 bash -c "cat < /dev/null > /dev/tcp/redis/6379" 2>/dev/null; then
            log_info "Redis is available"
            return 0
        fi
        count=$((count + 1))
        sleep 1
    done
    
    log_info "Redis not available (optional) - continuing without it"
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

#--allow-root -> Allow WP_CLI to run the command as root user (it pop out an warning by default)
configure_redis() {
    log_info "Configuring Redis cache settings..."

    wp config set WP_REDIS_HOST "$REDIS_HOST" --type=constant --allow-root 2>/dev/null || \
        log_error "Failed to set WP_REDIS_HOST"
    wp config set WP_REDIS_PORT "$REDIS_PORT" --raw --type=constant --allow-root 2>/dev/null || \
        log_error "Failed to set WP_REDIS_PORT"
    wp config set WP_REDIS_DATABASE "$REDIS_WORDPRESS_DATABASE" --raw --type=constant --allow-root 2>/dev/null || \
        log_error "Failed to set WP_REDIS_DATABASE"
    wp config set WP_CACHE true --raw --type=constant --allow-root 2>/dev/null || \
        log_error "Failed to set WP_CACHE"
    log_info "Redis configuration completed"
    return 0
}

setup_redis_plugin() {
    log_info "Setting up Redis cache plugin..."
    
    # Check if plugin is installed
    if ! wp plugin is-installed redis-cache --allow-root 2>/dev/null; then
        log_info "Installing Redis cache plugin..."
        wp plugin install redis-cache --activate --allow-root || {
            log_error "Failed to install Redis cache plugin"
            return 1
        }
    else
        log_info "Redis cache plugin already installed"
        # Activate if not active
        if ! wp plugin is-active redis-cache --allow-root 2>/dev/null; then
            wp plugin activate redis-cache --allow-root || log_error "Failed to activate Redis cache plugin"
        fi
    fi
    
    # Enable Redis object cache
    if ! wp redis status --allow-root 2>/dev/null | grep -q "Connected"; then
        log_info "Enabling Redis object cache..."
        wp redis enable --allow-root 2>/dev/null || log_error "Failed to enable Redis cache"
    else
        log_info "Redis object cache already enabled"
    fi
    
    log_info "Redis plugin setup completed"
    return 0
}

install_wordpress() {
    if ! wp core is-installed --allow-root 2>/dev/null; then
        log_info "Installing WordPress..."
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

unset_variables() {
    if [ -z "$MYSQL_PASSWORD" ]; then
        unset MYSQL_PASSWORD
    fi
    if [ -z "$WORDPRESS_ADMIN_PASSWORD" ]; then
        unset WORDPRESS_ADMIN_PASSWORD
    fi
    return 0
}

main() {
    wait_for_mysql || exit 1
    wait_for_redis || exit 1

    download_wordpress || exit 1
    create_wp_config || exit 1

    configure_redis || exit 1
    
    install_wordpress || exit 1

    setup_redis_plugin || exit 1
    unset_variables || exit 1

    log_success "WordPress initialization completed"
}

main

log_info "Start PHP-FMP"
exec /usr/sbin/php-fpm7.4 -F