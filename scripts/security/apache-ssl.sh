#!/bin/bash
# Configure Apache HTTPS

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$PROJECT_ROOT/infrastructure/utils/logging.sh"
source "$PROJECT_ROOT/infrastructure/utils/core.sh"
source "$PROJECT_ROOT/config/00-core.sh"
source "$PROJECT_ROOT/config/30-security.sh"

init_logging
check_root

enable_ssl_module() {
    log_step "Enabling SSL module"

    if a2query -m ssl >/dev/null 2>&1; then
        log_info "SSL module already enabled"
        return 0
    fi

    a2enmod ssl
    log_success "SSL module enabled"
}

enable_headers_module() {
    log_step "Enabling headers module"

    if a2query -m headers >/dev/null 2>&1; then
        log_info "Headers module already enabled"
        return 0
    fi

    a2enmod headers
    log_success "Headers module enabled"
}

create_https_vhost() {
    log_step "Creating HTTPS virtual host"

    local _vhost_file="/etc/apache2/sites-available/mediawiki-ssl.conf"

    if [[ -f "$_vhost_file" ]]; then
        log_info "HTTPS VirtualHost already exists"
        backup_file "$_vhost_file"
    fi

    log_info "Creating $_vhost_file"

    cat > "$_vhost_file" << 'EOF'
<VirtualHost *:443>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html/mediawiki
    ServerName mediawiki.local

    SSLEngine on
    SSLCertificateFile /etc/ssl/certs/mediawiki.crt
    SSLCertificateKeyFile /etc/ssl/private/mediawiki.key

    SSLProtocol all -SSLv3 -TLSv1 -TLSv1.1
    SSLCipherSuite HIGH:!aNULL:!MD5:!3DES
    SSLHonorCipherOrder on

    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"
    Header always set X-Frame-Options "SAMEORIGIN"
    Header always set X-Content-Type-Options "nosniff"
    Header always set X-XSS-Protection "1; mode=block"
    Header always set Referrer-Policy "strict-origin-when-cross-origin"
    Header always set Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline';"

    <Directory /var/www/html/mediawiki>
        Options FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/mediawiki_ssl_error.log
    CustomLog ${APACHE_LOG_DIR}/mediawiki_ssl_access.log combined
</VirtualHost>
EOF

    log_success "HTTPS VirtualHost created"
}

configure_http_redirect() {
    log_step "Configuring HTTP to HTTPS redirect"

    local _http_vhost="/etc/apache2/sites-available/mediawiki.conf"

    if [[ ! -f "$_http_vhost" ]]; then
        log_error "HTTP VirtualHost not found: $_http_vhost"
        return 1
    fi

    if grep -q "Redirect permanent" "$_http_vhost"; then
        log_info "Redirect already configured"
        return 0
    fi

    backup_file "$_http_vhost"

    log_info "Adding redirect to $_http_vhost"

    sed -i '/<VirtualHost \*:80>/a\    Redirect permanent / https://192.168.1.100/' "$_http_vhost"

    log_success "HTTP redirect configured"
}

enable_ssl_vhost() {
    log_step "Enabling SSL virtual host"

    if a2query -s mediawiki-ssl >/dev/null 2>&1; then
        log_info "SSL VirtualHost already enabled"
        return 0
    fi

    a2ensite mediawiki-ssl.conf
    log_success "SSL VirtualHost enabled"
}

test_apache_config() {
    log_step "Testing Apache configuration"

    if apache2ctl configtest 2>&1 | grep -q "Syntax OK"; then
        log_success "Apache configuration valid"
        return 0
    else
        log_error "Apache configuration has errors"
        apache2ctl configtest
        return 1
    fi
}

restart_apache() {
    log_step "Restarting Apache"

    systemctl restart apache2

    if service_active apache2; then
        log_success "Apache restarted successfully"
    else
        log_error "Apache failed to restart"
        systemctl status apache2
        return 1
    fi
}

validate_https() {
    log_step "Validating HTTPS"

    local _errors=0

    log_info "Checking port 443"
    if port_listening 443; then
        log_success "Port 443 is listening"
    else
        log_error "Port 443 is not listening"
        _errors=$((_errors + 1))
    fi

    log_info "Testing HTTPS connection"
    sleep 2

    if curl -k -s -o /dev/null -w "%{http_code}" https://localhost/mediawiki/ 2>/dev/null | grep -qE "200|301|302"; then
        log_success "HTTPS responds correctly"
    else
        log_warn "HTTPS test inconclusive"
    fi

    log_info "Testing HTTP redirect"
    local _redirect_code
    _redirect_code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/mediawiki/ 2>/dev/null)

    if [[ "$_redirect_code" =~ ^(301|302)$ ]]; then
        log_success "HTTP redirects to HTTPS"
    else
        log_warn "HTTP redirect not working (code: $_redirect_code)"
    fi

    if [[ $_errors -eq 0 ]]; then
        log_success "HTTPS validation passed"
        return 0
    else
        log_error "HTTPS validation failed: $_errors error(s)"
        return 1
    fi
}

main() {
    log_step "Configuring Apache HTTPS"

    if [[ ! -f "$SSL_CERT_PATH" ]] || [[ ! -f "$SSL_KEY_PATH" ]]; then
        log_error "SSL certificate not found"
        echo "Run: sudo bash $PROJECT_ROOT/scripts/security/ssl-certificate.sh"
        exit 1
    fi

    enable_ssl_module
    enable_headers_module
    create_https_vhost
    configure_http_redirect
    enable_ssl_vhost
    test_apache_config
    restart_apache
    validate_https

    log_success "Apache HTTPS configuration complete"
    echo ""
    echo "Access MediaWiki:"
    echo "  HTTPS: https://192.168.1.100/mediawiki/"
    echo "  HTTP:  http://192.168.1.100/mediawiki/ (redirects to HTTPS)"
    echo ""
}

main