#!/bin/bash
# Validate database server installation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$PROJECT_ROOT/infrastructure/utils/logging.sh"
source "$PROJECT_ROOT/infrastructure/utils/core.sh"
source "$PROJECT_ROOT/config/00-core.sh"
source "$PROJECT_ROOT/config/10-network.sh"
source "$PROJECT_ROOT/config/20-database.sh"

init_logging

log_step "Database Server Validation"

_errors=0
_warnings=0

validate_db_vm() {
    log_info "Validating database VM..."

    local _vm_status
    _vm_status=$(vagrant status "$VM_DB" 2>/dev/null | grep "$VM_DB" | awk '{print $2}')

    if [[ "$_vm_status" == "running" ]]; then
        log_success "VM $VM_DB is running"
        return 0
    else
        log_error "VM $VM_DB is not running (status: $_vm_status)"
        return 1
    fi
}

validate_web_vm() {
    log_info "Validating web VM..."

    local _vm_status
    _vm_status=$(vagrant status "$VM_WEB" 2>/dev/null | grep "$VM_WEB" | awk '{print $2}')

    if [[ "$_vm_status" == "running" ]]; then
        log_success "VM $VM_WEB is running"
        return 0
    else
        log_error "VM $VM_WEB is not running (status: $_vm_status)"
        return 1
    fi
}

validate_mariadb_service() {
    log_info "Validating MariaDB service..."

    local _service_status
    _service_status=$(vagrant ssh "$VM_DB" -c "systemctl is-active mariadb" 2>/dev/null | tr -d '\r')

    if [[ "$_service_status" == "active" ]]; then
        log_success "MariaDB service is active"
        return 0
    else
        log_error "MariaDB service is not active (status: $_service_status)"
        return 1
    fi
}

validate_network_connectivity() {
    log_info "Validating network connectivity..."

    local _ping_result
    _ping_result=$(vagrant ssh "$VM_WEB" -c "ping -c 1 -W 2 $DB_APP_IP >/dev/null 2>&1 && echo success || echo failed" 2>/dev/null | tr -d '\r')

    if [[ "$_ping_result" == "success" ]]; then
        log_success "Web server can reach database server"
        return 0
    else
        log_error "Web server cannot reach database server"
        return 1
    fi
}

validate_database_connection() {
    log_info "Validating database connection..."

    if load_db_credentials; then
        local _connection_test
        _connection_test=$(vagrant ssh "$VM_WEB" -c "mysql -h $DB_APP_IP -P $DB_PORT -u $DB_USER -p$DB_PASSWORD -e 'SELECT 1' 2>/dev/null && echo success || echo failed" 2>/dev/null | tr -d '\r' | tail -1)

        if [[ "$_connection_test" == "success" ]]; then
            log_success "Database connection successful"
            return 0
        else
            log_error "Database connection failed"
            return 1
        fi
    else
        log_warn "Cannot load credentials, skipping connection test"
        return 2
    fi
}

validate_mediawiki_config() {
    log_info "Validating MediaWiki database configuration..."

    local _db_type
    _db_type=$(vagrant ssh "$VM_WEB" -c "grep '\$wgDBtype' $MW_INSTALL_PATH/LocalSettings.php 2>/dev/null | cut -d'\"' -f2" 2>/dev/null | tr -d '\r')

    if [[ "$_db_type" == "mysql" ]]; then
        log_success "MediaWiki configured for MySQL/MariaDB"
        return 0
    elif [[ "$_db_type" == "sqlite" ]]; then
        log_warn "MediaWiki still using SQLite (migration not run yet)"
        return 2
    else
        log_error "MediaWiki database configuration not found"
        return 1
    fi
}

validate_mediawiki_accessible() {
    log_info "Validating MediaWiki web access..."

    local _http_code
    _http_code=$(curl -k -s -o /dev/null -w "%{http_code}" "http://$WEB_BRIDGED_IP/mediawiki/" 2>/dev/null || echo "000")

    if [[ "$_http_code" =~ ^(200|301|302)$ ]]; then
        log_success "MediaWiki is accessible (HTTP $_http_code)"
        return 0
    else
        log_error "MediaWiki not accessible (HTTP $_http_code)"
        return 1
    fi
}

if ! validate_db_vm; then
    _errors=$((_errors + 1))
fi

if ! validate_web_vm; then
    _errors=$((_errors + 1))
fi

if ! validate_mariadb_service; then
    _errors=$((_errors + 1))
fi

if ! validate_network_connectivity; then
    _errors=$((_errors + 1))
fi

_conn_result=$(validate_database_connection)
_conn_exit=$?
if [[ $_conn_exit -eq 1 ]]; then
    _errors=$((_errors + 1))
elif [[ $_conn_exit -eq 2 ]]; then
    _warnings=$((_warnings + 1))
fi

_mw_result=$(validate_mediawiki_config)
_mw_exit=$?
if [[ $_mw_exit -eq 1 ]]; then
    _errors=$((_errors + 1))
elif [[ $_mw_exit -eq 2 ]]; then
    _warnings=$((_warnings + 1))
fi

if ! validate_mediawiki_accessible; then
    _errors=$((_errors + 1))
fi

echo ""
log_step "Validation Summary"

if [[ $_errors -eq 0 ]] && [[ $_warnings -eq 0 ]]; then
    log_success "All validations passed"
    echo ""
    echo "Database setup complete"
    echo "  Database server: $DB_APP_IP:$DB_PORT"
    echo "  Web access: http://$WEB_BRIDGED_IP/mediawiki/"
    echo ""
    exit 0
elif [[ $_errors -eq 0 ]] && [[ $_warnings -gt 0 ]]; then
    log_warn "Validation passed with $_warnings warning(s)"
    echo ""
    echo "If migration not run yet:"
    echo "  vagrant ssh $VM_WEB"
    echo "  sudo bash /vagrant/scripts/migration/migrate-to-mariadb.sh"
    echo ""
    exit 0
else
    log_error "Validation failed: $_errors error(s), $_warnings warning(s)"
    exit 1
fi