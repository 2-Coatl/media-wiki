#!/bin/bash
# Validate web server installation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$PROJECT_ROOT/infrastructure/utils/logging.sh"
source "$PROJECT_ROOT/infrastructure/utils/core.sh"
source "$PROJECT_ROOT/infrastructure/config/00_core.sh"
source "$PROJECT_ROOT/infrastructure/config/10_network.sh"

init_logging

_errors=0

validate_vm_running() {
    log_step "Validating VM status"

    local _vm_status
    _vm_status=$(cd "$PROJECT_ROOT" && vagrant status "$VM_WEB" 2>/dev/null | grep "$VM_WEB")

    if echo "$_vm_status" | grep -q "running"; then
        log_success "VM $VM_WEB is running"
        return 0
    else
        log_error "VM $VM_WEB is not running"
        return 1
    fi
}

validate_apache_service() {
    log_step "Validating Apache service"

    local _apache_status
    _apache_status=$(cd "$PROJECT_ROOT" && vagrant ssh "$VM_WEB" -c "systemctl is-active apache2" 2>/dev/null)

    if [[ "$_apache_status" == "active" ]]; then
        log_success "Apache is active"
        return 0
    else
        log_error "Apache is not active"
        return 1
    fi
}

validate_php_installed() {
    log_step "Validating PHP installation"

    local _php_version
    _php_version=$(cd "$PROJECT_ROOT" && vagrant ssh "$VM_WEB" -c "php -v 2>/dev/null | head -1" 2>/dev/null)

    if echo "$_php_version" | grep -q "PHP $PHP_VERSION"; then
        log_success "PHP $PHP_VERSION installed"
        return 0
    else
        log_error "PHP $PHP_VERSION not found"
        return 1
    fi
}

validate_mediawiki_accessible() {
    log_step "Validating MediaWiki accessibility"

    local _http_code
    _http_code=$(curl -s -o /dev/null -w "%{http_code}" "http://$WEB_BRIDGED_IP/mediawiki/" 2>/dev/null)

    if [[ "$_http_code" =~ ^(200|301|302)$ ]]; then
        log_success "MediaWiki accessible (HTTP $http_code)"
        return 0
    else
        log_error "MediaWiki not accessible (HTTP $_http_code)"
        return 1
    fi
}

validate_ports() {
    log_step "Validating ports"

    local _port_check
    _port_check=$(cd "$PROJECT_ROOT" && vagrant ssh "$VM_WEB" -c "netstat -tuln 2>/dev/null | grep ':80 '" 2>/dev/null)

    if [[ -n "$_port_check" ]]; then
        log_success "Port 80 listening"
        return 0
    else
        log_error "Port 80 not listening"
        return 1
    fi
}

validate_permissions() {
    log_step "Validating file permissions"

    local _owner
    _owner=$(cd "$PROJECT_ROOT" && vagrant ssh "$VM_WEB" -c "stat -c %U $MW_INSTALL_PATH/index.php 2>/dev/null" 2>/dev/null)

    if [[ "$_owner" == "$MW_OWNER" ]]; then
        log_success "File ownership correct: $_owner"
        return 0
    else
        log_warn "File ownership: $_owner (expected $MW_OWNER)"
        return 0
    fi
}

main() {
    log_step "WEB SERVER VALIDATION"

    validate_vm_running || _errors=$((_errors + 1))
    validate_apache_service || _errors=$((_errors + 1))
    validate_php_installed || _errors=$((_errors + 1))
    validate_mediawiki_accessible || _errors=$((_errors + 1))
    validate_ports || _errors=$((_errors + 1))
    validate_permissions || _errors=$((_errors + 1))

    echo ""

    if [[ $_errors -eq 0 ]]; then
        log_success "All validations passed"
        echo ""
        echo "Next steps:"
        echo "  1. Open browser: http://$WEB_BRIDGED_IP/mediawiki/"
        echo "  2. Complete MediaWiki installation wizard"
        echo "  3. Select SQLite as database"
        echo "  4. Proceed to Database setup"
        echo ""
        exit 0
    else
        log_error "Validation failed with $_errors error(s)"
        exit 1
    fi
}

main