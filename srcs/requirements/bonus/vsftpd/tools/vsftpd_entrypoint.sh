#!/bin/sh
set -e

#MACROS FUNCTIONS
log_info()    { echo "ℹ️ [INFO] $*"; }
log_file()    { echo "📄 [FILE] $*"; }
log_success() { echo "✅ [OK] $*"; }
log_error()   { echo "❌ [ERROR] $*" >&2; }
log_dir()     { echo "📁 [DIR] $*"; }
log_warn()    { echo "⚠️ [WARN] $*"; }

#MANAGEMENT SECRETS 
if [ -z "${VSFTPD_USER_PASSWORD:-}" ] &&  [ -f "${VSFTPD_SP_USER_PASSWORD}" ]; then
    VSFTPD_USER_PASSWORD=$(cat "${VSFTPD_SP_USER_PASSWORD}")
    if [ "${DEBUG:-}" = "true" ]; then
        log_debug "VSFTPD_USER_PASSWORD: ${VSFTPD_USER_PASSWORD}"
    fi
else
    log_error "Failed to initialize VSFTPD_USER_PASSWORD. File not found or empty at path: ${VSFTPD_SP_USER_PASSWORD}"
    exit 1
fi

init_vsftpd() {
    log_info "Initialize VSFTPD configuration"

    echo "ftpuser:$VSFTPD_USER_PASSWORD" | chpasswd
}


main () {
    init_vsftpd || exit 1

}
main

log_info "Init VSFTPD as PID 1"

exec /usr/sbin/vsftpd /etc/vsftpd.conf