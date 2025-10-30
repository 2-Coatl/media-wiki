#!/bin/bash
# Configure UFW firewall for database server

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$PROJECT_ROOT/infrastructure/utils/logging.sh"
source "$PROJECT_ROOT/infrastructure/utils/core.sh"
source "$PROJECT_ROOT/config/00-core.sh"
source "$PROJECT_ROOT/config/10-network.sh"

init_logging
check_root

log_step "Configuring firewall for database server"

check_ufw_installed() {
    if ! package_installed ufw; then
        log_info "Installing UFW..."
        apt-get update -qq
        apt-get install -y ufw
        log_success "UFW installed"
    else
        log_info "UFW already installed"
    fi
}

configure_default_policy() {
    log_info "Setting default policies..."

    ufw --force default deny incoming
    ufw --force default allow outgoing

    log_success "Default policies set"
}

allow_ssh() {
    log_info "Allowing SSH (port 22)..."

    if ufw status | grep -q "22/tcp.*ALLOW"; then
        log_info "SSH already allowed"
    else
        ufw allow 22/tcp
        log_success "SSH allowed"
    fi
}

allow_mysql_from_web() {
    log_info "Allowing MySQL from web server only..."

    local _rule="from $WEB_APP_IP to any port 3306"

    if ufw status | grep -q "3306.*$WEB_APP_IP"; then
        log_info "MySQL rule already exists"
    else
        ufw allow from "$WEB_APP_IP" to any port 3306
        log_success "MySQL allowed from $WEB_APP_IP"
    fi
}

enable_firewall() {
    log_info "Enabling firewall..."

    if ufw status | grep -q "Status: active"; then
        log_info "Firewall already active"
        ufw reload
    else
        ufw --force enable
        log_success "Firewall enabled"
    fi
}

validate_firewall() {
    log_step "Validating firewall configuration"

    local _errors=0

    if ! systemctl is-active ufw >/dev/null 2>&1; then
        log_error "UFW service not active"
        _errors=$((_errors + 1))
    else
        log_success "UFW service active"
    fi

    if ! ufw status | grep -q "Status: active"; then
        log_error "Firewall not active"
        _errors=$((_errors + 1))
    else
        log_success "Firewall active"
    fi

    if ! ufw status | grep -q "22/tcp.*ALLOW"; then
        log_error "SSH rule not found"
        _errors=$((_errors + 1))
    else
        log_success "SSH rule configured"
    fi

    if ! ufw status | grep -q "3306.*$WEB_APP_IP"; then
        log_error "MySQL rule not found"
        _errors=$((_errors + 1))
    else
        log_success "MySQL rule configured"
    fi

    if [[ $_errors -eq 0 ]]; then
        log_success "Firewall validation passed"
        return 0
    else
        log_error "Firewall validation failed: $_errors error(s)"
        return 1
    fi
}

main() {
    check_ufw_installed
    configure_default_policy
    allow_ssh
    allow_mysql_from_web
    enable_firewall
    validate_firewall

    log_success "Database firewall configuration complete"

    echo ""
    echo "Firewall rules:"
    ufw status numbered
}

main