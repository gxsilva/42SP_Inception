#!/bin/sh

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
