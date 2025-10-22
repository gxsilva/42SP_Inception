#!/bin/sh

# Imports
. /usr/local/tools/common_functions.sh
. /usr/local/tools/wait_services.sh
. /usr/local/tools/wordpress_setup.sh
. /usr/local/tools/redis_setup.sh

debug_log

cd /var/www/html

main() {
    log_info "Starting WordPress entrypoint..."

    # Set secrets as ENV
    set_env || { log_error "Failed to configure ENV"; exit 1; }

    # Wait for essential services
    wait_for_mysql || { log_error "MySQL service unavailable"; exit 1; }
    wait_for_redis || { log_error "Redis service unavailable"; exit 1; }

    # Wordpress download and creating the configuration file
    download_wordpress || { log_error "Failed to download WordPress"; exit 1; }
    create_wp_config || { log_error "Failed to create wp-config.php"; exit 1; }

    # Redis creating the configuration file
    configure_redis || { log_error "Failed to configure Redis"; exit 1; }

    # Consume the configuration file and install the wordpress
    install_wordpress || { log_error "Failed to install WordPress"; exit 1; }

    # Consume the configuration file and set up redis
    setup_redis_plugin || { log_error "Failed to setup Redis plugin"; exit 1; }

    # Redis configuration and set up
    if [ -n "${VSFTPD_USER:-}" ] && [ -n "${VSFTPD_USER_PASSWORD:-}" ]; then
        configure_vsftpd || { log_error "Failed to configure FTP for WordPress"; exit 1; }
    fi

    # Unset local sensitive variables of env
    unset_variables

    log_success "WordPress initialization completed"
}

main

log_info "Start PHP-FMP"
exec /usr/sbin/php-fpm7.4 -F