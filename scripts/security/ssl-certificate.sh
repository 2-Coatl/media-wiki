#!/bin/bash
# Generate self-signed SSL certificate

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$PROJECT_ROOT/infrastructure/utils/logging.sh"
source "$PROJECT_ROOT/infrastructure/utils/core.sh"
source "$PROJECT_ROOT/config/30-security.sh"

init_logging
check_root

check_openssl() {
    log_step "Checking OpenSSL"

    if command_exists openssl; then
        log_success "OpenSSL installed"
        return 0
    fi

    log_info "Installing OpenSSL..."
    apt-get update -qq
    apt-get install -y openssl

    log_success "OpenSSL installed"
}

create_directories() {
    log_step "Creating SSL directories"

    mkdir -p /etc/ssl/certs
    mkdir -p /etc/ssl/private

    chmod 755 /etc/ssl/certs
    chmod 700 /etc/ssl/private

    log_success "Directories created"
}

generate_certificate() {
    log_step "Generating SSL certificate"

    if [[ -f "$SSL_CERT_PATH" ]] && [[ -f "$SSL_KEY_PATH" ]]; then
        log_info "Certificate already exists"

        local _expiry
        _expiry=$(openssl x509 -enddate -noout -in "$SSL_CERT_PATH" 2>/dev/null | cut -d= -f2)

        if [[ -n "$_expiry" ]]; then
            log_info "Expires: $_expiry"
        fi

        return 0
    fi

    log_info "Creating self-signed certificate..."
    log_info "Valid for: $SSL_CERT_DAYS days"

    openssl req -x509 -nodes \
        -days "$SSL_CERT_DAYS" \
        -newkey rsa:2048 \
        -keyout "$SSL_KEY_PATH" \
        -out "$SSL_CERT_PATH" \
        -subj "/C=$SSL_COUNTRY/ST=$SSL_STATE/L=$SSL_CITY/O=$SSL_ORG/CN=mediawiki.local" \
        2>/dev/null

    log_success "Certificate generated"
}

set_permissions() {
    log_step "Setting permissions"

    chmod 644 "$SSL_CERT_PATH"
    chmod 600 "$SSL_KEY_PATH"

    chown root:root "$SSL_CERT_PATH"
    chown root:root "$SSL_KEY_PATH"

    log_success "Permissions set"
}

validate_certificate() {
    log_step "Validating certificate"

    local _errors=0

    if [[ ! -f "$SSL_CERT_PATH" ]]; then
        log_error "Certificate file not found: $SSL_CERT_PATH"
        _errors=$((_errors + 1))
    else
        log_success "Certificate exists"
    fi

    if [[ ! -f "$SSL_KEY_PATH" ]]; then
        log_error "Key file not found: $SSL_KEY_PATH"
        _errors=$((_errors + 1))
    else
        log_success "Key exists"
    fi

    if [[ -f "$SSL_CERT_PATH" ]]; then
        if openssl x509 -noout -text -in "$SSL_CERT_PATH" >/dev/null 2>&1; then
            log_success "Certificate is valid"

            local _subject
            _subject=$(openssl x509 -noout -subject -in "$SSL_CERT_PATH" 2>/dev/null | sed 's/subject=//')
            log_info "Subject: $_subject"
        else
            log_error "Certificate is invalid"
            _errors=$((_errors + 1))
        fi
    fi

    if [[ -f "$SSL_KEY_PATH" ]]; then
        local _perms
        _perms=$(stat -c %a "$SSL_KEY_PATH")

        if [[ "$_perms" == "600" ]]; then
            log_success "Key permissions correct: $_perms"
        else
            log_warn "Key permissions: $_perms (expected 600)"
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
    log_step "SSL Certificate Generation"

    check_openssl
    create_directories
    generate_certificate
    set_permissions
    validate_certificate

    log_success "SSL certificate setup complete"
    log_info "Certificate: $SSL_CERT_PATH"
    log_info "Key: $SSL_KEY_PATH"
}

main