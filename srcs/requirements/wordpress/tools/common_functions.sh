#!/bin/sh

# ==================LOGS FUNCTIONS============================
log_info()    { echo "ℹ️ [INFO] $*"; }
log_file()    { echo "📄 [FILE] $*"; }
log_success() { echo "✅ [OK] $*"; }
log_error()   { echo "❌ [ERROR] $*" >&2; }
log_dir()     { echo "📁 [DIR] $*"; }
log_warn()    { echo "⚠️ [WARN] $*"; }

# ==================DEBUG MOD LOG============================
debug_log() {
    if [ "${DEBUG:-}" = "true" ]; then
        set -x
        log_info "Debug mode ENABLE"
    else
        log_info "Debug mode DISABLE"
    fi
}

# ==================SET and UNSET SECRETS AS ENV============================
set_env () {
    # MYSQL PASSWORD
    if [ -z "${MYSQL_PASSWORD:-}" ] &&  [ -f "${MYSQL_SP_PASSWORD}" ]; then
        MYSQL_PASSWORD=$(cat "${MYSQL_SP_PASSWORD}")
        if [ "${DEBUG:-}" = "true" ]; then
            log_debug "MYSQL_PASSWORD: ${MYSQL_PASSWORD}"
        fi
    else
        log_error "Failed to initialize MYSQL_PASSWORD. File not found or empty at path: ${MYSQL_SP_PASSWORD}"
        return 1
    fi

    # WORDPRESS ADMIN PASSWORD
    if [ -z "${WORDPRESS_ADMIN_PASSWORD:-}" ] &&  [ -f "${WORDPRESS_SP_ADMIN_PASSWORD}" ]; then
        WORDPRESS_ADMIN_PASSWORD=$(cat "${WORDPRESS_SP_ADMIN_PASSWORD}")
        if [ "${DEBUG:-}" = "true" ]; then
            log_debug "WORDPRESS_ADMIN_PASSWORD: ${WORDPRESS_ADMIN_PASSWORD}"
        fi
    else
        log_error "Failed to initialize WORDPRESS_ADMIN_PASSWORD. File not found or empty at path: ${WORDPRESS_SP_ADMIN_PASSWORD}"
        return 1
    fi

    # WORDPRESS USER PASSWORD
    if [ -z "${WORDPRESS_USER_PASSWORD:-}" ] &&  [ -f "${WORDPRESS_SP_USER_PASSWORD}" ]; then
        WORDPRESS_USER_PASSWORD=$(cat "${WORDPRESS_SP_USER_PASSWORD}")
        if [ "${DEBUG:-}" = "true" ]; then
            log_debug "WORDPRESS_USER_PASSWORD: ${WORDPRESS_USER_PASSWORD}"
        fi
    else
        log_error "Failed to initialize WORDPRESS_USER_PASSWORD. File not found or empty at path: ${WORDPRESS_SP_USER_PASSWORD}"
        return 1
    fi

    # WORDPRESS USER EMAIL
    if [ -z "${WORDPRESS_USER_EMAIL:-}" ] &&  [ -f "${WORDPRESS_SP_USER_EMAIL}" ]; then
        WORDPRESS_USER_EMAIL=$(cat "${WORDPRESS_SP_USER_EMAIL}")
        if [ "${DEBUG:-}" = "true" ]; then
            log_debug "WORDPRESS_USER_EMAIL: ${WORDPRESS_USER_EMAIL}"
        fi
    else
        log_error "Failed to initialize WORDPRESS_USER_EMAIL. File not found or empty at path: ${WORDPRESS_SP_USER_EMAIL}"
        return 1
    fi

    # WORDPRESS ADMIN EMAIL
    if [ -z "${WORDPRESS_ADMIN_EMAIL:-}" ] &&  [ -f "${WORDPRESS_SP_ADMIN_EMAIL}" ]; then
        WORDPRESS_ADMIN_EMAIL=$(cat "${WORDPRESS_SP_ADMIN_EMAIL}")
        if [ "${DEBUG:-}" = "true" ]; then
            log_debug "WORDPRESS_ADMIN_EMAIL: ${WORDPRESS_ADMIN_EMAIL}"
        fi
    else
        log_error "Failed to initialize WORDPRESS_ADMIN_EMAIL. File not found or empty at path: ${WORDPRESS_SP_ADMIN_EMAIL}"
        return 1
    fi
}

unset_variables() {
    if [ -z "$MYSQL_PASSWORD" ]; then
        unset MYSQL_PASSWORD
    fi
    if [ -z "$WORDPRESS_ADMIN_PASSWORD" ]; then
        unset WORDPRESS_ADMIN_PASSWORD
    fi
    if [ -z "$VSFTPD_USER_PASSWORD" ]; then
        unset VSFTPD_USER_PASSWORD
    fi
    if [ -z "$WORDPRESS_USER_EMAIL" ]; then
        unset WORDPRESS_USER_EMAIL
    fi
    if [ -z "$WORDPRESS_ADMIN_EMAIL" ]; then
        unset WORDPRESS_ADMIN_EMAIL
    fi
    return 0
}

# ==================PROFTPD  (FTP Service)============================

configure_vsftpd() {
    wp config set FS_METHOD ftpext --path="$WORDPRESS_PATH" --allow-root
    wp config set FTP_HOST "172.18.0.4" --path="$WORDPRESS_PATH" --allow-root
    wp config set FTP_USER "$VSFTPD_USER" --path="$WORDPRESS_PATH" --allow-root
    wp config set FTP_PASS "$VSFTPD_USER_PASSWORD" --path="$WORDPRESS_PATH" --allow-root

    log_success "FTP configuration for WordPress set successfully!"
}