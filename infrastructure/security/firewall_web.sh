#!/bin/bash
# Configure UFW firewall for web server

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$PROJECT_ROOT/infrastructure/utils/logging.sh"
source "$PROJECT_ROOT/infrastructure/utils/core.sh"
source "$PROJECT_ROOT/infrastructure/config/00_core.sh"
source "$PROJECT_ROOT/infrastructure/config/30_security.sh"

init_logging
check_root

log_step "Configuring web server firewall"

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

allow_web_ports() {
    log_info "Allowing web server ports..."

    for _port in "${ALLOWED_PORTS_WEB[@]}"; do
        if ufw status | grep -q "$_port"; then
            log_info "Port $_port already allowed"
        else
            ufw allow "$_port"/tcp
            log_success "Allowed port $_port/tcp"
        fi
    done
}

allow_internal_network() {
    log_info "Allowing internal network..."

    if ufw status | grep -q "10.0.2.0/24"; then
        log_info "Internal network already allowed"
    else
        ufw allow from 10.0.2.0/24
        log_success "Allowed internal network 10.0.2.0/24"
    fi
}

enable_firewall() {
    log_info "Enabling firewall..."

    if ufw status | grep -q "Status: active"; then
        log_info "Firewall already active"
    else
        ufw --force enable
        log_success "Firewall enabled"
    fi
}

validate_firewall() {
    log_step "Validating firewall configuration"

    local _errors=0

    if ! ufw status | grep -q "Status: active"; then
        log_error "Firewall is not active"
        _errors=$((_errors + 1))
    else
        log_success "Firewall is active"
    fi

    for _port in "${ALLOWED_PORTS_WEB[@]}"; do
        if ufw status | grep -q "$_port"; then
            log_success "Port $_port is allowed"
        else
            log_error "Port $_port is not allowed"
            _errors=$((_errors + 1))
        fi
    done

    if ufw status | grep -q "10.0.2.0/24"; then
        log_success "Internal network is allowed"
    else
        log_warn "Internal network not explicitly allowed"
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
    allow_web_ports
    allow_internal_network
    enable_firewall
    validate_firewall

    log_success "Web server firewall configured"

    echo ""
    echo "Firewall rules:"
    ufw status numbered
    echo ""
}

main