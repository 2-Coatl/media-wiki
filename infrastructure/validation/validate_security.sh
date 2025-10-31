#!/bin/bash
# Validate security configuration

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$PROJECT_ROOT/infrastructure/utils/logging.sh"
source "$PROJECT_ROOT/infrastructure/utils/core.sh"
source "$PROJECT_ROOT/infrastructure/config/00_core.sh"
source "$PROJECT_ROOT/infrastructure/config/10_network.sh"

init_logging

log_step "Security Validation"

_errors=0
_warnings=0

validate_web_firewall() {
    log_info "Validating web server firewall..."

    local _ufw_status
    _ufw_status=$(vagrant ssh "$VM_WEB" -c "sudo ufw status" 2>/dev/null || echo "failed")

    if echo "$_ufw_status" | grep -q "Status: active"; then
        log_success "Web firewall active"
        return 0
    else
        log_error "Web firewall not active"
        return 1
    fi
}

validate_db_firewall() {
    log_info "Validating database firewall..."

    local _ufw_status
    _ufw_status=$(vagrant ssh "$VM_DB" -c "sudo ufw status" 2>/dev/null || echo "failed")

    if echo "$_ufw_status" | grep -q "Status: active"; then
        log_success "Database firewall active"
        return 0
    else
        log_error "Database firewall not active"
        return 1
    fi
}

validate_ssl_certificate() {
    log_info "Validating SSL certificate..."

    local _cert_exists
    _cert_exists=$(vagrant ssh "$VM_WEB" -c "test -f /etc/ssl/certs/mediawiki.crt && echo yes || echo no" 2>/dev/null)

    local _key_exists
    _key_exists=$(vagrant ssh "$VM_WEB" -c "test -f /etc/ssl/private/mediawiki.key && echo yes || echo no" 2>/dev/null)

    if [[ "$_cert_exists" == "yes" ]] && [[ "$_key_exists" == "yes" ]]; then
        log_success "SSL certificate exists"
        return 0
    else
        log_error "SSL certificate missing"
        return 1
    fi
}

validate_https_access() {
    log_info "Validating HTTPS access..."

    local _https_code
    _https_code=$(curl -k -s -o /dev/null -w "%{http_code}" "https://$WEB_BRIDGED_IP/mediawiki/" 2>/dev/null || echo "000")

    if [[ "$_https_code" =~ ^(200|301|302)$ ]]; then
        log_success "HTTPS accessible (code: $_https_code)"
        return 0
    else
        log_error "HTTPS not accessible (code: $_https_code)"
        return 1
    fi
}

validate_http_redirect() {
    log_info "Validating HTTP to HTTPS redirect..."

    local _http_code
    _http_code=$(curl -s -o /dev/null -w "%{http_code}" "http://$WEB_BRIDGED_IP/mediawiki/" 2>/dev/null || echo "000")

    if [[ "$_http_code" =~ ^(301|302)$ ]]; then
        log_success "HTTP redirects to HTTPS (code: $_http_code)"
        return 0
    else
        log_warn "HTTP does not redirect (code: $_http_code)"
        return 1
    fi
}

validate_fail2ban() {
    log_info "Validating Fail2ban..."

    local _f2b_status
    _f2b_status=$(vagrant ssh "$VM_WEB" -c "sudo systemctl is-active fail2ban" 2>/dev/null || echo "failed")

    if [[ "$_f2b_status" == "active" ]]; then
        log_success "Fail2ban active"
        return 0
    else
        log_warn "Fail2ban not active"
        return 1
    fi
}

validate_security_headers() {
    log_info "Validating security headers..."

    local _headers
    _headers=$(curl -k -s -I "https://$WEB_BRIDGED_IP/mediawiki/" 2>/dev/null)

    local _headers_found=0

    if echo "$_headers" | grep -qi "X-Frame-Options"; then
        _headers_found=$((_headers_found + 1))
    fi

    if echo "$_headers" | grep -qi "X-Content-Type-Options"; then
        _headers_found=$((_headers_found + 1))
    fi

    if echo "$_headers" | grep -qi "X-XSS-Protection"; then
        _headers_found=$((_headers_found + 1))
    fi

    if [[ $_headers_found -ge 2 ]]; then
        log_success "Security headers present ($_headers_found/3)"
        return 0
    else
        log_warn "Security headers missing ($_headers_found/3)"
        return 1
    fi
}

validate_ports() {
    log_info "Validating port access..."

    local _port_errors=0

    if nc -zv -w3 "$WEB_BRIDGED_IP" 443 2>/dev/null; then
        log_success "Port 443 accessible"
    else
        log_error "Port 443 not accessible"
        _port_errors=$((_port_errors + 1))
    fi

    if nc -zv -w3 "$WEB_BRIDGED_IP" 3306 2>/dev/null; then
        log_warn "Port 3306 exposed (should be blocked)"
        _warnings=$((_warnings + 1))
    else
        log_success "Port 3306 blocked (correct)"
    fi

    [[ $_port_errors -eq 0 ]]
}

validate_web_firewall || _errors=$((_errors + 1))
echo ""

validate_db_firewall || _errors=$((_errors + 1))
echo ""

validate_ssl_certificate || _errors=$((_errors + 1))
echo ""

validate_https_access || _errors=$((_errors + 1))
echo ""

validate_http_redirect || _warnings=$((_warnings + 1))
echo ""

validate_fail2ban || _warnings=$((_warnings + 1))
echo ""

validate_security_headers || _warnings=$((_warnings + 1))
echo ""

validate_ports || _errors=$((_errors + 1))
echo ""

log_step "Security Validation Summary"

if [[ $_errors -eq 0 ]] && [[ $_warnings -eq 0 ]]; then
    log_success "All security validations passed"
    exit 0
elif [[ $_errors -eq 0 ]]; then
    log_warn "Validation passed with $_warnings warning(s)"
    exit 0
else
    log_error "Validation failed: $_errors error(s), $_warnings warning(s)"
    exit 1
fi