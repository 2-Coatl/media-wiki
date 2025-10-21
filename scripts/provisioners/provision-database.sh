#!/bin/bash
# Database server provisioner

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$PROJECT_ROOT/infrastructure/utils/logging.sh"
source "$PROJECT_ROOT/infrastructure/utils/core.sh"
source "$PROJECT_ROOT/config/00-core.sh"
source "$PROJECT_ROOT/config/10-network.sh"
source "$PROJECT_ROOT/config/20-database.sh"

init_logging

readonly LOCK_FILE="/var/lock/mediawiki-database.lock"

check_provisioned() {
    [[ -f "$LOCK_FILE" ]]
}

if check_provisioned; then
    log_info "System already provisioned"
fi

install_base_system() {
    log_step "[1/7] Installing base system"
    bash "$PROJECT_ROOT/scripts/installation/install-base.sh"
}

configure_timezone() {
    log_step "[2/7] Configuring timezone"

    local _timezone="America/Los_Angeles"

    if timedatectl list-timezones | grep -q "$_timezone"; then
        timedatectl set-timezone "$_timezone"
        log_success "Timezone set to $_timezone"
    else
        log_warn "Timezone $_timezone not found, keeping default"
    fi
}

configure_network() {
    log_step "[3/7] Configuring network"

    local _app_ip="$DB_APP_IP"
    local _web_ip="$WEB_APP_IP"

    log_info "Database IP: $_app_ip"
    log_info "Web server IP: $_web_ip"

    if ip addr show | grep -q "$_app_ip"; then
        log_success "IP address configured: $_app_ip"
    else
        log_error "IP address not configured: $_app_ip"
        return 1
    fi

    log_info "Testing connectivity to web server..."
    if ping -c 1 -W 2 "$_web_ip" >/dev/null 2>&1; then
        log_success "Can reach web server: $_web_ip"
    else
        log_warn "Cannot reach web server yet: $_web_ip"
    fi
}

install_mariadb() {
    log_step "[4/7] Installing MariaDB"
    bash "$PROJECT_ROOT/scripts/installation/install-mariadb.sh"
}

secure_mariadb() {
    log_step "[5/7] Securing MariaDB"

    load_db_credentials

    log_info "Running mysql_secure_installation equivalent..."

    mysql -u root << EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOF

    log_success "MariaDB secured"
}

configure_remote_access() {
    log_step "[6/7] Configuring remote access"

    local _config="/etc/mysql/mariadb.conf.d/50-server.cnf"

    if [[ ! -f "$_config" ]]; then
        log_error "MariaDB config not found: $_config"
        return 1
    fi

    backup_file "$_config"

    log_info "Setting bind-address to 0.0.0.0"
    sed -i 's/^bind-address.*/bind-address = 0.0.0.0/' "$_config"

    systemctl restart mariadb

    log_success "Remote access configured"
}

create_mediawiki_database() {
    log_step "[7/7] Creating MediaWiki database"

    load_db_credentials

    local _web_ip="$WEB_APP_IP"

    log_info "Creating database: $DB_NAME"
    log_info "Creating user: $DB_USER@$_web_ip"

    mysql -u root -p"${DB_ROOT_PASSWORD}" << EOF
CREATE DATABASE IF NOT EXISTS ${DB_NAME}
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS '${DB_USER}'@'${_web_ip}'
    IDENTIFIED BY '${DB_PASSWORD}';

GRANT ALL PRIVILEGES ON ${DB_NAME}.*
    TO '${DB_USER}'@'${_web_ip}';

FLUSH PRIVILEGES;
EOF

    log_success "Database created: $DB_NAME"
    log_success "User created: $DB_USER@$_web_ip"
}

validate_installation() {
    log_step "Validating installation"

    local _errors=0

    if service_active mariadb; then
        log_success "MariaDB is running"
    else
        log_error "MariaDB is not running"
        _errors=$((_errors + 1))
    fi

    if port_listening 3306; then
        log_success "Port 3306 listening"
    else
        log_error "Port 3306 not listening"
        _errors=$((_errors + 1))
    fi

    load_db_credentials

    if mysql -u root -p"${DB_ROOT_PASSWORD}" -e "SELECT 1" >/dev/null 2>&1; then
        log_success "Root authentication works"
    else
        log_error "Root authentication failed"
        _errors=$((_errors + 1))
    fi

    if mysql -u root -p"${DB_ROOT_PASSWORD}" -e "USE ${DB_NAME}" >/dev/null 2>&1; then
        log_success "Database $DB_NAME exists"
    else
        log_error "Database $DB_NAME not found"
        _errors=$((_errors + 1))
    fi

    if [[ $_errors -eq 0 ]]; then
        log_success "All validations passed"
        return 0
    else
        log_error "$_errors validation(s) failed"
        return 1
    fi
}

print_summary() {
    log_step "Database Server Installation Complete"

    echo ""
    echo "========================================"
    echo "  DATABASE SERVER READY"
    echo "========================================"
    echo ""
    echo "Connection details:"
    echo "  Host: $DB_APP_IP"
    echo "  Port: 3306"
    echo "  Database: $DB_NAME"
    echo "  User: $DB_USER"
    echo "  Password: (see config/secrets.env)"
    echo ""
    echo "Next steps:"
    echo "  1. Ensure web01 is running"
    echo "  2. Run migration script on web01:"
    echo "     vagrant ssh mediawiki-web01"
    echo "     sudo bash /vagrant/scripts/migration/migrate-to-mariadb.sh"
    echo ""
    echo "========================================"
    echo ""
}

main() {
    log_step "Starting Database Server Provisioning"

    install_base_system
    configure_timezone
    configure_network
    install_mariadb
    secure_mariadb
    configure_remote_access
    create_mediawiki_database
    validate_installation

    touch "$LOCK_FILE"

    print_summary

    log_success "Database server provisioning complete"
}

main