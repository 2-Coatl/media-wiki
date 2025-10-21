#!/bin/bash
# Apache hardening

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$PROJECT_ROOT/infrastructure/utils/logging.sh"
source "$PROJECT_ROOT/infrastructure/utils/core.sh"

init_logging
check_root

log_step "Apache Hardening"

configure_security_headers() {
    log_info "Configuring security headers..."

    local _conf_file="/etc/apache2/conf-available/security-headers.conf"

    if [[ -f "$_conf_file" ]]; then
        log_info "Security headers already configured"
        return 0
    fi

    cat > "$_conf_file" << 'EOF'
<IfModule mod_headers.c>
    Header always set X-Frame-Options "SAMEORIGIN"
    Header always set X-Content-Type-Options "nosniff"
    Header always set X-XSS-Protection "1; mode=block"
    Header always set Referrer-Policy "strict-origin-when-cross-origin"
    Header always set Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline';"
    Header always set Permissions-Policy "geolocation=(), microphone=(), camera=()"
</IfModule>
EOF

    a2enconf security-headers >/dev/null 2>&1

    log_success "Security headers configured"
}

configure_server_tokens() {
    log_info "Configuring server tokens..."

    local _conf_file="/etc/apache2/conf-available/security.conf"

    if [[ ! -f "$_conf_file" ]]; then
        log_warn "Security config not found, creating..."
        touch "$_conf_file"
    fi

    backup_file "$_conf_file"

    if ! file_contains "$_conf_file" "ServerTokens"; then
        echo "ServerTokens Prod" >> "$_conf_file"
    fi

    if ! file_contains "$_conf_file" "ServerSignature"; then
        echo "ServerSignature Off" >> "$_conf_file"
    fi

    if ! file_contains "$_conf_file" "TraceEnable"; then
        echo "TraceEnable Off" >> "$_conf_file"
    fi

    log_success "Server tokens configured"
}

disable_directory_listing() {
    log_info "Disabling directory listing..."

    local _apache_conf="/etc/apache2/apache2.conf"

    backup_file "$_apache_conf"

    sed -i 's/Options Indexes FollowSymLinks/Options FollowSymLinks/' "$_apache_conf"
    sed -i 's/Options Indexes/Options -Indexes/' "$_apache_conf"

    log_success "Directory listing disabled"
}

configure_timeout() {
    log_info "Configuring timeout..."

    local _apache_conf="/etc/apache2/apache2.conf"

    if ! file_contains "$_apache_conf" "Timeout"; then
        echo "Timeout 60" >> "$_apache_conf"
    else
        sed -i 's/^Timeout .*/Timeout 60/' "$_apache_conf"
    fi

    log_success "Timeout configured to 60 seconds"
}

disable_unnecessary_modules() {
    log_info "Disabling unnecessary modules..."

    local _modules="status autoindex"
    local _disabled=0

    for _mod in $_modules; do
        if a2query -m "$_mod" >/dev/null 2>&1; then
            a2dismod "$_mod" >/dev/null 2>&1
            _disabled=$((_disabled + 1))
            log_info "Disabled module: $_mod"
        fi
    done

    if [[ $_disabled -gt 0 ]]; then
        log_success "Disabled $_disabled unnecessary modules"
    else
        log_info "No unnecessary modules to disable"
    fi
}

restart_apache() {
    log_info "Testing Apache configuration..."

    if ! apache2ctl configtest >/dev/null 2>&1; then
        log_error "Apache configuration test failed"
        apache2ctl configtest
        exit 1
    fi

    log_info "Restarting Apache..."
    systemctl restart apache2

    log_success "Apache restarted"
}

validate_hardening() {
    log_step "Validating hardening"

    local _errors=0

    if service_active apache2; then
        log_success "Apache is running"
    else
        log_error "Apache is not running"
        _errors=$((_errors + 1))
    fi

    if a2query -c security-headers >/dev/null 2>&1; then
        log_success "Security headers enabled"
    else
        log_warn "Security headers not enabled"
    fi

    local _test_url="http://localhost"
    local _headers

    if command_exists curl; then
        _headers=$(curl -I -s "$_test_url" 2>/dev/null || echo "")

        if echo "$_headers" | grep -q "X-Frame-Options"; then
            log_success "X-Frame-Options header present"
        else
            log_warn "X-Frame-Options header missing"
        fi

        if echo "$_headers" | grep -q "X-Content-Type-Options"; then
            log_success "X-Content-Type-Options header present"
        else
            log_warn "X-Content-Type-Options header missing"
        fi
    fi

    if [[ $_errors -eq 0 ]]; then
        log_success "Validation passed"
        return 0
    else
        log_error "Validation failed: $_errors error(s)"
        return 1
    fi
}

main() {
    configure_security_headers
    configure_server_tokens
    disable_directory_listing
    configure_timeout
    disable_unnecessary_modules
    restart_apache
    validate_hardening

    log_success "Apache hardening complete"
}

main