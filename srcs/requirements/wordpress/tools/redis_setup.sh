#!/bin/sh

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