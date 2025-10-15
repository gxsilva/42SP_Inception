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

#NGINX CONFIGURATION
if [ -f /etc/nginx/nginx.conf ]; then
    log INFO "Configuration Process..."

    log FILE "Generating /etc/nginx/nginx.conf from ./config/nginx.conf..."
    envsubst '\$NGINX_URL \$NGINX_USER \$NGINX_ROOT_FOLDER  \$NGINX_HTTPS_PORT \$OPENSSL_PATH \$OPENSSL_PVKEY_PATH \$OPENSSL_CA' \
                < /etc/nginx/nginx.conf > /tmp/nginx.conf &&  \
    mv /tmp/nginx.conf /etc/nginx/nginx.conf
else
  log ERROR "Unable to generate /etc/nginx/nginx.conf from from ./config/nginx.conf"
  false
fi

if ! nginx -t; then
    log ERROR "Nginx configuration file is incorrect"
    false
fi

echo "Starting nginx with tini as PID 1..."
exec /usr/bin/tini -- "$@"
