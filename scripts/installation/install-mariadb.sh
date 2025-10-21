#!/bin/bash
# Install MariaDB

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$PROJECT_ROOT/infrastructure/utils/logging.sh"
source "$PROJECT_ROOT/infrastructure/utils/core.sh"
source "$PROJECT_ROOT/config/00-core.sh"
source "$PROJECT_ROOT/config/20-database.sh"

init_logging
check_root

install_mariadb() {
    log_step "Installing MariaDB $MARIADB_VERSION"

    if package_installed mariadb-server; then
        log_info "MariaDB already installed"
        return 0
    fi

    log_info "Installing packages..."
    apt-get update
    apt-get install -y mariadb-server mariadb-client

    log_success "MariaDB installed"
}

start_mariadb() {
    log_step "Starting MariaDB service"

    if service_active mariadb; then
        log_info "MariaDB already running"
        return 0
    fi

    systemctl start mariadb
    systemctl enable mariadb

    log_success "MariaDB service started"
}

secure_installation() {
    log_step "Securing MariaDB installation"

    load_db_credentials

    log_info "Setting root password..."
    mysql -u root <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOF

    log_success "MariaDB secured"
}

configure_performance() {
    log_step "Configuring MariaDB performance"

    local _config_file="/etc/mysql/mariadb.conf.d/99-mediawiki.cnf"

    if [[ -f "$_config_file" ]]; then
        log_info "Configuration already exists"
        return 0
    fi

    log_info "Creating performance configuration..."
    cat > "$_config_file" <<'EOF'
[mysqld]
max_connections = 100
innodb_buffer_pool_size = 256M
innodb_log_file_size = 64M
innodb_flush_log_at_trx_commit = 2
query_cache_size = 32M
query_cache_type = 1
tmp_table_size = 32M
max_heap_table_size = 32M

character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci

bind-address = 0.0.0.0
skip-name-resolve
local-infile = 0

log_error = /var/log/mysql/error.log
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow.log
long_query_time = 2
EOF

    log_info "Restarting MariaDB..."
    systemctl restart mariadb

    log_success "Performance configuration applied"
}

validate_mariadb() {
    log_step "Validating MariaDB installation"

    local _errors=0

    if command_exists mysql; then
        log_success "MySQL command available"
    else
        log_error "MySQL command not found"
        _errors=$((_errors + 1))
    fi

    if service_active mariadb; then
        log_success "MariaDB service running"
    else
        log_error "MariaDB service not running"
        _errors=$((_errors + 1))
    fi

    if service_enabled mariadb; then
        log_success "MariaDB service enabled"
    else
        log_warn "MariaDB service not enabled"
    fi

    if port_listening "$DB_PORT"; then
        log_success "Port $DB_PORT listening"
    else
        log_error "Port $DB_PORT not listening"
        _errors=$((_errors + 1))
    fi

    load_db_credentials

    if mysql -u root -p"${DB_ROOT_PASSWORD}" -e "SELECT 1" >/dev/null 2>&1; then
        log_success "Root authentication working"
    else
        log_error "Root authentication failed"
        _errors=$((_errors + 1))
    fi

    if [[ $_errors -eq 0 ]]; then
        log_success "MariaDB validation passed"
        return 0
    else
        log_error "MariaDB validation failed: $_errors error(s)"
        return 1
    fi
}

main() {
    install_mariadb
    start_mariadb
    secure_installation
    configure_performance
    validate_mariadb

    log_success "MariaDB installation complete"
}

main