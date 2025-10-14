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

#NGINX CONFIGURATION
if [ -f /etc/nginx/nginx.conf ]; then
    log_info "Configuration Process..."

    log_file "Generating /etc/nginx/nginx.conf from ./config/nginx.conf..."
    envsubst '\$NGINX_URL \$NGINX_USER \$NGINX_ROOT_FOLDER  \$NGINX_HTTPS_PORT \$OPENSSL_PATH \$OPENSSL_PVKEY_PATH \$OPENSSL_CA' \
                < /etc/nginx/nginx.conf > /tmp/nginx.conf &&  \
    mv /tmp/nginx.conf /etc/nginx/nginx.conf
else
  log_error "Unable to generate /etc/nginx/nginx.conf from from ./config/nginx.conf"
  false
fi

if ! nginx -t; then
    log_error "Nginx configuration file is incorrect"
    false
fi

echo "Starting nginx with tini as PID 1..."
exec /usr/bin/tini -- "$@"
