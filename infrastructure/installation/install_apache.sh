#!/bin/bash
# Instala y configura Apache con soporte para modo de simulación y pruebas

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$PROJECT_ROOT/infrastructure/utils/core.sh"
source "$PROJECT_ROOT/infrastructure/config/00_core.sh"

if [[ -n "${INSTALL_APACHE_HELPERS:-}" ]]; then
    # Permite inyectar dependencias durante pruebas
    source "$INSTALL_APACHE_HELPERS"
fi

DRY_RUN=0
APACHE_CONF_FILE="${APACHE_CONF_FILE:-/etc/apache2/apache2.conf}"

usage() {
    cat <<'EOF'
Uso: install_apache.sh [opciones]

Opciones:
  --dry-run    Simula los pasos sin aplicar cambios.
  -h, --help   Muestra esta ayuda.
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                DRY_RUN=1
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                log_error "Opción desconocida: $1"
                usage
                exit 1
                ;;
        esac
    done
}

install_apache() {
    log_step "Installing Apache $APACHE_VERSION"

    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "[DRY-RUN] Se omite la instalación de paquetes apache2"
        return 0
    fi

    if package_installed apache2; then
        log_info "Apache already installed"
        return 0
    fi

    log_info "Installing Apache packages..."
    apt-get update
    apt-get install -y apache2

    log_success "Apache installed"
}

enable_apache_modules() {
    log_step "Enabling Apache modules"

    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "[DRY-RUN] Se omite la habilitación de módulos"
        return 0
    fi

    local _modules="rewrite ssl headers expires deflate"
    local _module

    for _module in $_modules; do
        if a2query -m "$_module" >/dev/null 2>&1; then
            log_info "Module already enabled: $_module"
        else
            log_info "Enabling module: $_module"
            a2enmod "$_module" >/dev/null 2>&1
        fi
    done

    log_success "Apache modules enabled"
}

configure_apache() {
    log_step "Configuring Apache"

    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "[DRY-RUN] Se omite la edición de apache2.conf"
        return 0
    fi

    local _conf="$APACHE_CONF_FILE"

    if file_contains "$_conf" "ServerTokens Prod"; then
        log_info "Apache already configured"
        return 0
    fi

    backup_file "$_conf"

    log_info "Setting ServerTokens..."
    if ! grep -q "^ServerTokens" "$_conf"; then
        echo "ServerTokens Prod" >> "$_conf"
    else
        sed -i 's/^ServerTokens.*/ServerTokens Prod/' "$_conf"
    fi

    log_info "Setting ServerSignature..."
    if ! grep -q "^ServerSignature" "$_conf"; then
        echo "ServerSignature Off" >> "$_conf"
    else
        sed -i 's/^ServerSignature.*/ServerSignature Off/' "$_conf"
    fi

    log_success "Apache configured"
}

start_apache() {
    log_step "Starting Apache service"

    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "[DRY-RUN] Se omite la interacción con systemctl"
        return 0
    fi

    if service_active apache2; then
        log_info "Apache already running"
        systemctl reload apache2
    else
        log_info "Starting Apache..."
        systemctl start apache2
    fi

    log_info "Enabling Apache on boot..."
    systemctl enable apache2 >/dev/null 2>&1

    log_success "Apache service started"
}

validate_apache() {
    log_step "Validating Apache installation"

    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "[DRY-RUN] Validación simulada sin comprobar servicios"
        return 0
    fi

    local _errors=0

    if service_active apache2; then
        log_success "Apache is running"
    else
        log_error "Apache is not running"
        _errors=$((_errors + 1))
    fi

    if port_listening 80; then
        log_success "Port 80 is listening"
    else
        log_error "Port 80 is not listening"
        _errors=$((_errors + 1))
    fi

    if command_exists apache2; then
        local _version
        _version=$(apache2 -v | head -1 | awk '{print $3}' | cut -d'/' -f2)
        log_success "Apache version: $_version"
    else
        log_error "Apache command not found"
        _errors=$((_errors + 1))
    fi

    if [[ $_errors -eq 0 ]]; then
        log_success "Apache validation passed"
        return 0
    else
        log_error "Apache validation failed: $_errors error(s)"
        return 1
    fi
}

main() {
    parse_args "$@"

    init_logging

    if [[ $DRY_RUN -eq 1 ]]; then
        log_warn "[DRY-RUN] Ejecución sin privilegios de superusuario"
    else
        check_root
    fi

    log_step "Apache Installation"

    install_apache
    enable_apache_modules
    configure_apache
    start_apache
    validate_apache

    if [[ $DRY_RUN -eq 1 ]]; then
        log_success "[DRY-RUN] Instalación de Apache completada"
    else
        log_success "Apache installation complete"
    fi
}

main "$@"