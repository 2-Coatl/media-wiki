#!/bin/bash
# Install and configure Apache web server

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$PROJECT_ROOT/infrastructure/utils/logging.sh"
source "$PROJECT_ROOT/infrastructure/utils/core.sh"
source "$PROJECT_ROOT/config/00-core.sh"

init_logging
check_root

install_apache() {
    log_step "Installing Apache $APACHE_VERSION"

    if package_installed apache2; then
        log_info "Apache already installed"
        return 0
    fi

    log_info "Installing Apache packages..."
    apt-get update
    apt-get install -y apache2

    log_success "Apache installed"
}

enable_apache_modules() {
    log_step "Enabling Apache modules"

    local _modules="rewrite ssl headers expires deflate"
    local _module

    for _module in $_modules; do
        if a2query -m "$_module" >/dev/null 2>&1; then
            log_info "Module already enabled: $_module"
        else
            log_info "Enabling module: $_module"
            a2enmod "$_module" >/dev/null 2>&1
        fi
    done

    log_success "Apache modules enabled"
}

configure_apache() {
    log_step "Configuring Apache"

    local _conf="/etc/apache2/apache2.conf"

    if file_contains "$_conf" "ServerTokens Prod"; then
        log_info "Apache already configured"
        return 0
    fi

    backup_file "$_conf"

    log_info "Setting ServerTokens..."
    if ! grep -q "^ServerTokens" "$_conf"; then
        echo "ServerTokens Prod" >> "$_conf"
    else
        sed -i 's/^ServerTokens.*/ServerTokens Prod/' "$_conf"
    fi

    log_info "Setting ServerSignature..."
    if ! grep -q "^ServerSignature" "$_conf"; then
        echo "ServerSignature Off" >> "$_conf"
    else
        sed -i 's/^ServerSignature.*/ServerSignature Off/' "$_conf"
    fi

    log_success "Apache configured"
}

start_apache() {
    log_step "Starting Apache service"

    if service_active apache2; then
        log_info "Apache already running"
        systemctl reload apache2
    else
        log_info "Starting Apache..."
        systemctl start apache2
    fi

    log_info "Enabling Apache on boot..."
    systemctl enable apache2 >/dev/null 2>&1

    log_success "Apache service started"
}

validate_apache() {
    log_step "Validating Apache installation"

    local _errors=0

    if service_active apache2; then
        log_success "Apache is running"
    else
        log_error "Apache is not running"
        _errors=$((_errors + 1))
    fi

    if port_listening 80; then
        log_success "Port 80 is listening"
    else
        log_error "Port 80 is not listening"
        _errors=$((_errors + 1))
    fi

    if command_exists apache2; then
        local _version=$(apache2 -v | head -1 | awk '{print $3}' | cut -d'/' -f2)
        log_success "Apache version: $_version"
    else
        log_error "Apache command not found"
        _errors=$((_errors + 1))
    fi

    if [[ $_errors -eq 0 ]]; then
        log_success "Apache validation passed"
        return 0
    else
        log_error "Apache validation failed: $_errors error(s)"
        return 1
    fi
}

main() {
    log_step "Apache Installation"

    install_apache
    enable_apache_modules
    configure_apache
    start_apache
    validate_apache

    log_success "Apache installation complete"
}

main