#!/bin/bash
# Web server provisioner

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$PROJECT_ROOT/infrastructure/utils/logging.sh"
source "$PROJECT_ROOT/infrastructure/utils/core.sh"
source "$PROJECT_ROOT/config/00-core.sh"

init_logging

readonly LOCK_FILE="/var/lock/mediawiki-web-server.lock"

check_provisioned() {
    [[ -f "$LOCK_FILE" ]]
}

if check_provisioned; then
    log_info "System already provisioned (idempotent mode)"
    log_info "Running validation checks only"
fi

install_base_system() {
    log_step "[1/8] Installing base system"
    bash "$PROJECT_ROOT/scripts/installation/install-base.sh"
}

configure_timezone() {
    log_step "[2/8] Configuring timezone"

    if timedatectl status | grep -q "America/Los_Angeles"; then
        log_info "Timezone already configured"
        return 0
    fi

    log_info "Setting timezone to America/Los_Angeles"
    timedatectl set-timezone America/Los_Angeles

    log_success "Timezone configured"
}

configure_network() {
    log_step "[3/8] Configuring network"

    source "$PROJECT_ROOT/config/10-network.sh"

    local _bridged_ip
    _bridged_ip=$(ip addr show eth1 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d'/' -f1 || echo "")

    if [[ "$_bridged_ip" == "$WEB_BRIDGED_IP" ]]; then
        log_success "Bridged network configured: $_bridged_ip"
    else
        log_warn "Bridged IP mismatch. Expected: $WEB_BRIDGED_IP, Got: $_bridged_ip"
    fi

    local _app_ip
    _app_ip=$(ip addr show eth2 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d'/' -f1 || echo "")

    if [[ "$_app_ip" == "$WEB_APP_IP" ]]; then
        log_success "Internal network configured: $_app_ip"
    else
        log_warn "Internal IP mismatch. Expected: $WEB_APP_IP, Got: $_app_ip"
    fi
}

install_apache() {
    log_step "[4/8] Installing Apache"
    bash "$PROJECT_ROOT/scripts/installation/install-apache.sh"
}

install_php() {
    log_step "[5/8] Installing PHP"
    bash "$PROJECT_ROOT/scripts/installation/install-php.sh"
}

install_mediawiki() {
    log_step "[6/8] Installing MediaWiki"
    bash "$PROJECT_ROOT/scripts/installation/install-mediawiki.sh"
}

configure_apache_vhost() {
    log_step "[7/8] Configuring Apache VirtualHost"

    local _vhost_file="/etc/apache2/sites-available/mediawiki.conf"

    if [[ -f "$_vhost_file" ]]; then
        log_info "VirtualHost already configured"
        return 0
    fi

    cat > "$_vhost_file" << 'EOF'
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html/mediawiki
    ServerName mediawiki.local

    <Directory /var/www/html/mediawiki>
        Options FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/mediawiki_error.log
    CustomLog ${APACHE_LOG_DIR}/mediawiki_access.log combined
</VirtualHost>
EOF

    a2ensite mediawiki.conf
    a2dissite 000-default.conf 2>/dev/null || true
    systemctl reload apache2

    log_success "Apache VirtualHost configured"
}

validate_installation() {
    log_step "[8/8] Validating installation"

    local _errors=0

    if service_active apache2; then
        log_success "Apache is running"
    else
        log_error "Apache is not running"
        _errors=$((_errors + 1))
    fi

    if command_exists php; then
        local _php_version
        _php_version=$(php -v | head -1 | awk '{print $2}' | cut -d. -f1,2)
        log_success "PHP $_php_version installed"
    else
        log_error "PHP not installed"
        _errors=$((_errors + 1))
    fi

    if [[ -d "$MW_INSTALL_PATH" ]]; then
        log_success "MediaWiki files present"
    else
        log_error "MediaWiki files not found"
        _errors=$((_errors + 1))
    fi

    if port_listening 80; then
        log_success "Port 80 listening"
    else
        log_error "Port 80 not listening"
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

show_completion_message() {
    echo ""
    echo "========================================"
    echo "  Web Server Installation Complete"
    echo "========================================"
    echo ""
    echo "Access MediaWiki:"
    echo "  URL: http://$WEB_BRIDGED_IP/mediawiki/"
    echo ""
    echo "Next steps:"
    echo "  1. Open URL in browser"
    echo "  2. Follow installation wizard"
    echo "  3. Select SQLite (for now)"
    echo "  4. Complete setup"
    echo ""
    echo "After database server is ready:"
    echo "  vagrant ssh $VM_WEB"
    echo "  sudo bash /vagrant/scripts/migration/migrate-to-mariadb.sh"
    echo ""
    echo "========================================"
    echo ""
}

main() {
    log_step "Starting Web Server Provisioning"
    log_info "Deployment mode: $DEPLOYMENT_MODE"

    check_root

    install_base_system
    configure_timezone
    configure_network
    install_apache
    install_php
    install_mediawiki
    configure_apache_vhost
    validate_installation

    touch "$LOCK_FILE"

    show_completion_message

    log_success "Web server provisioning complete"
}

main