#!/bin/sh

# Download wordpress
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

# Create wordpress configuration file
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

# Consumes the configuration file and installs wordpress
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
        wp user create "$WORDPRESS_USER" "$WORDPRESS_USER_EMAIL" \
            --role=author \
            --user_pass="$WORDPRESS_USER_PASSWORD" \
            --allow-root 2>/dev/null || \
            log_info "Author user already exists or creation failed"
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