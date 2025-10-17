#!/bin/sh
set -e

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
if [ -f "${PORTAINER_SP_USER_PASSWORD}" ]; then
    cat ${PORTAINER_SP_USER_PASSWORD} > /tmp/portainer_password
    if [ "${DEBUG:-}" = "true" ]; then
        log_debug "PORTAINER_USER_PASSWORD: $(cat ${PORTAINER_SP_USER_PASSWORD})"
    fi
else
    log_error "Failed to initialize PORTAINER_USER_PASSWORD. File not found or empty at path: ${PORTAINER_SP_USER_PASSWORD}"
    exit 1
fi

exec /opt/portainer/portainer --data "/data" --admin-password-file "/tmp/portainer_password"
