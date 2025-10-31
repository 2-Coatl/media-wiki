#!/bin/bash
# Install and configure Fail2ban

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$PROJECT_ROOT/infrastructure/utils/logging.sh"
source "$PROJECT_ROOT/infrastructure/utils/core.sh"
source "$PROJECT_ROOT/infrastructure/config/00_core.sh"
source "$PROJECT_ROOT/infrastructure/config/30_security.sh"

init_logging
check_root

install_fail2ban() {
    log_step "Installing Fail2ban"

    if package_installed fail2ban; then
        log_info "Fail2ban already installed"
        return 0
    fi

    log_info "Installing fail2ban package..."
    apt-get update -qq
    apt-get install -y fail2ban

    log_success "Fail2ban installed"
}

create_local_config() {
    log_step "Creating Fail2ban configuration"

    local _jail_local="/etc/fail2ban/jail.local"

    if [[ -f "$_jail_local" ]]; then
        log_info "Configuration already exists"
        backup_file "$_jail_local"
    fi

    log_info "Creating jail.local..."

    cat > "$_jail_local" << EOF
[DEFAULT]
bantime = $FAIL2BAN_BANTIME
findtime = $FAIL2BAN_FINDTIME
maxretry = $FAIL2BAN_MAXRETRY
destemail = root@localhost
sendername = Fail2Ban
action = %(action_mw)s

[sshd]
enabled = true
port = 22
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600

[apache-auth]
enabled = true
port = http,https
logpath = /var/log/apache2/mediawiki_*error.log
maxretry = 5

[apache-badbots]
enabled = true
port = http,https
logpath = /var/log/apache2/mediawiki_*access.log
maxretry = 2

[apache-noscript]
enabled = true
port = http,https
logpath = /var/log/apache2/mediawiki_*error.log

[apache-overflows]
enabled = true
port = http,https
logpath = /var/log/apache2/mediawiki_*error.log
maxretry = 2
EOF

    log_success "Configuration created"
}

start_fail2ban() {
    log_step "Starting Fail2ban"

    log_info "Enabling service..."
    systemctl enable fail2ban

    if service_active fail2ban; then
        log_info "Restarting service..."
        systemctl restart fail2ban
    else
        log_info "Starting service..."
        systemctl start fail2ban
    fi

    sleep 2

    if service_active fail2ban; then
        log_success "Fail2ban is running"
    else
        log_error "Failed to start Fail2ban"
        return 1
    fi
}

validate_fail2ban() {
    log_step "Validating Fail2ban"

    local _errors=0

    if ! service_active fail2ban; then
        log_error "Service not running"
        _errors=$((_errors + 1))
    else
        log_success "Service running"
    fi

    if ! service_enabled fail2ban; then
        log_error "Service not enabled"
        _errors=$((_errors + 1))
    else
        log_success "Service enabled"
    fi

    log_info "Checking jails..."
    local _jail_status
    _jail_status=$(fail2ban-client status 2>/dev/null)

    if echo "$_jail_status" | grep -q "sshd"; then
        log_success "Jail: sshd"
    else
        log_warn "Jail sshd not active"
    fi

    if echo "$_jail_status" | grep -q "apache-auth"; then
        log_success "Jail: apache-auth"
    else
        log_warn "Jail apache-auth not active"
    fi

    if echo "$_jail_status" | grep -q "apache-badbots"; then
        log_success "Jail: apache-badbots"
    else
        log_warn "Jail apache-badbots not active"
    fi

    if [[ $_errors -eq 0 ]]; then
        log_success "Validation passed"
        return 0
    else
        log_error "Validation failed"
        return 1
    fi
}

show_info() {
    log_step "Fail2ban Information"

    echo ""
    echo "Configuration:"
    echo "  Ban time:    $FAIL2BAN_BANTIME seconds"
    echo "  Find time:   $FAIL2BAN_FINDTIME seconds"
    echo "  Max retry:   $FAIL2BAN_MAXRETRY attempts"
    echo ""
    echo "Active jails:"
    fail2ban-client status 2>/dev/null | grep "Jail list" || true
    echo ""
    echo "Useful commands:"
    echo "  Status:      fail2ban-client status"
    echo "  Jail status: fail2ban-client status sshd"
    echo "  Unban IP:    fail2ban-client set sshd unbanip <IP>"
    echo ""
}

main() {
    log_step "Fail2ban Installation"

    install_fail2ban
    create_local_config
    start_fail2ban
    validate_fail2ban
    show_info

    log_success "Fail2ban installation complete"
}

main