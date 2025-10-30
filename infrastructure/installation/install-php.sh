#!/bin/bash
# Install PHP 8.1 with extensions

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$PROJECT_ROOT/infrastructure/utils/logging.sh"
source "$PROJECT_ROOT/infrastructure/utils/core.sh"
source "$PROJECT_ROOT/config/00-core.sh"

init_logging
check_root

install_php() {
    log_step "Installing PHP ${PHP_VERSION}"

    if package_installed "php${PHP_VERSION}"; then
        log_info "PHP ${PHP_VERSION} already installed"
        return 0
    fi

    log_info "Updating package lists..."
    apt-get update

    log_info "Installing PHP ${PHP_VERSION} and extensions..."
    apt-get install -y \
        php${PHP_VERSION} \
        php${PHP_VERSION}-cli \
        php${PHP_VERSION}-common \
        php${PHP_VERSION}-mysql \
        php${PHP_VERSION}-xml \
        php${PHP_VERSION}-xmlrpc \
        php${PHP_VERSION}-intl \
        php${PHP_VERSION}-mbstring \
        php${PHP_VERSION}-curl \
        php${PHP_VERSION}-gd \
        php${PHP_VERSION}-zip \
        php${PHP_VERSION}-bcmath \
        php${PHP_VERSION}-soap

    log_success "PHP ${PHP_VERSION} installed"
}

configure_php() {
    log_step "Configuring PHP"

    local _ini_apache="/etc/php/${PHP_VERSION}/apache2/php.ini"
    local _ini_cli="/etc/php/${PHP_VERSION}/cli/php.ini"

    if [[ ! -f "$_ini_apache" ]]; then
        log_error "PHP ini file not found: $_ini_apache"
        return 1
    fi

    log_info "Backing up php.ini..."
    backup_file "$_ini_apache"

    log_info "Configuring PHP settings..."
    sed -i 's/upload_max_filesize = .*/upload_max_filesize = 20M/' "$_ini_apache"
    sed -i 's/post_max_size = .*/post_max_size = 20M/' "$_ini_apache"
    sed -i 's/memory_limit = .*/memory_limit = 256M/' "$_ini_apache"
    sed -i 's/max_execution_time = .*/max_execution_time = 300/' "$_ini_apache"
    sed -i 's/max_input_time = .*/max_input_time = 300/' "$_ini_apache"
    sed -i 's/;date.timezone =.*/date.timezone = America\/Los_Angeles/' "$_ini_apache"

    log_info "Configuring CLI php.ini..."
    sed -i 's/memory_limit = .*/memory_limit = 512M/' "$_ini_cli"

    log_success "PHP configured"
}

restart_apache() {
    log_step "Restarting Apache"

    if ! systemctl restart apache2; then
        log_error "Failed to restart Apache"
        return 1
    fi

    log_success "Apache restarted"
}

validate_php() {
    log_step "Validating PHP installation"

    local _errors=0

    if command_exists php; then
        local _version=$(php -v | head -1 | awk '{print $2}' | cut -d. -f1,2)
        log_success "PHP version: $_version"
    else
        log_error "PHP command not found"
        _errors=$((_errors + 1))
    fi

    local _required_extensions=(
        "mysqli"
        "xml"
        "mbstring"
        "intl"
        "curl"
        "gd"
    )

    log_info "Checking PHP extensions..."
    for _ext in "${_required_extensions[@]}"; do
        if php -m 2>/dev/null | grep -q "^$_ext$"; then
            log_success "Extension loaded: $_ext"
        else
            log_error "Extension not loaded: $_ext"
            _errors=$((_errors + 1))
        fi
    done

    if service_active apache2; then
        log_success "Apache is running with PHP"
    else
        log_error "Apache is not running"
        _errors=$((_errors + 1))
    fi

    if [[ $_errors -eq 0 ]]; then
        log_success "PHP validation passed"
        return 0
    else
        log_error "PHP validation failed: $_errors error(s)"
        return 1
    fi
}

main() {
    install_php
    configure_php
    restart_apache
    validate_php

    log_success "PHP installation complete"
}

main