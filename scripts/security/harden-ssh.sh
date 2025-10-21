#!/bin/bash
# SSH hardening

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$PROJECT_ROOT/infrastructure/utils/logging.sh"
source "$PROJECT_ROOT/infrastructure/utils/core.sh"

init_logging
check_root

readonly SSH_CONFIG="/etc/ssh/sshd_config"

configure_ssh_hardening() {
    log_step "Configuring SSH hardening"

    if [[ ! -f "$SSH_CONFIG" ]]; then
        log_error "SSH config not found: $SSH_CONFIG"
        exit 1
    fi

    backup_file "$SSH_CONFIG"

    log_info "Applying SSH hardening settings..."

    local _settings=(
        "PermitRootLogin no"
        "PermitEmptyPasswords no"
        "MaxAuthTries 3"
        "LoginGraceTime 60"
        "X11Forwarding no"
    )

    for _setting in "${_settings[@]}"; do
        local _key="${_setting%% *}"
        local _value="${_setting#* }"

        if grep -q "^#*${_key}" "$SSH_CONFIG"; then
            sed -i "s|^#*${_key}.*|${_setting}|" "$SSH_CONFIG"
            log_info "Updated: $_setting"
        else
            echo "$_setting" >> "$SSH_CONFIG"
            log_info "Added: $_setting"
        fi
    done

    log_success "SSH hardening configured"
}

validate_ssh_config() {
    log_step "Validating SSH configuration"

    if ! sshd -t 2>/dev/null; then
        log_error "SSH configuration is invalid"
        sshd -t
        return 1
    fi

    log_success "SSH configuration is valid"
    return 0
}

restart_ssh() {
    log_step "Restarting SSH service"

    if ! validate_ssh_config; then
        log_error "Cannot restart SSH with invalid config"
        return 1
    fi

    systemctl restart sshd || systemctl restart ssh

    if service_active sshd || service_active ssh; then
        log_success "SSH service restarted"
    else
        log_error "SSH service failed to restart"
        return 1
    fi
}

validate_hardening() {
    log_step "Validating SSH hardening"

    local _errors=0

    local _checks=(
        "PermitRootLogin no"
        "PermitEmptyPasswords no"
        "MaxAuthTries 3"
    )

    for _check in "${_checks[@]}"; do
        local _key="${_check%% *}"
        local _expected="${_check#* }"

        if grep -q "^${_key} ${_expected}" "$SSH_CONFIG"; then
            log_success "Verified: $_check"
        else
            log_error "Not configured: $_check"
            _errors=$((_errors + 1))
        fi
    done

    if service_active sshd || service_active ssh; then
        log_success "SSH service is running"
    else
        log_error "SSH service is not running"
        _errors=$((_errors + 1))
    fi

    if [[ $_errors -eq 0 ]]; then
        log_success "SSH hardening validated"
        return 0
    else
        log_error "SSH hardening validation failed: $_errors error(s)"
        return 1
    fi
}

show_warning() {
    echo ""
    log_warn "IMPORTANT: SSH Hardening Applied"
    echo ""
    echo "Changes made:"
    echo "  - Root login disabled"
    echo "  - Empty passwords disabled"
    echo "  - Max auth attempts: 3"
    echo "  - Login grace time: 60s"
    echo "  - X11 forwarding disabled"
    echo ""
    echo "For Vagrant: PasswordAuthentication is still enabled"
    echo "In production: Disable PasswordAuthentication and use SSH keys"
    echo ""
    echo "Backup created:"
    echo "  ${SSH_CONFIG}.backup.*"
    echo ""
}

main() {
    log_step "SSH Hardening"

    configure_ssh_hardening
    restart_ssh
    validate_hardening
    show_warning

    log_success "SSH hardening complete"
}

main