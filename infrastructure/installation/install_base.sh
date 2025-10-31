#!/bin/bash
# Base system installation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$PROJECT_ROOT/infrastructure/utils/logging.sh"
source "$PROJECT_ROOT/infrastructure/utils/core.sh"
source "$PROJECT_ROOT/infrastructure/config/00_core.sh"

init_logging
check_root

install_base_packages() {
    log_step "Installing base packages"

    local _packages=(
        "apt-transport-https"
        "ca-certificates"
        "curl"
        "wget"
        "vim"
        "nano"
        "net-tools"
        "htop"
        "iotop"
        "unzip"
        "zip"
        "git"
        "rsync"
        "software-properties-common"
        "gnupg"
        "lsb-release"
    )

    if package_installed curl && package_installed vim && package_installed git; then
        log_info "Base packages already installed"
        return 0
    fi

    log_info "Updating package lists..."
    apt-get update -qq

    log_info "Installing base packages..."
    apt-get install -y -qq "${_packages[@]}"

    log_success "Base packages installed"
}

configure_locale() {
    log_step "Configuring locale"

    local _locale="en_US.UTF-8"

    if locale | grep -q "LANG=$_locale"; then
        log_info "Locale already configured"
        return 0
    fi

    log_info "Setting locale to $_locale..."
    locale-gen "$_locale"
    update-locale LANG="$_locale"

    log_success "Locale configured"
}

configure_timezone() {
    log_step "Configuring timezone"

    local _timezone="America/Los_Angeles"

    if [[ "$(timedatectl show -p Timezone --value)" == "$_timezone" ]]; then
        log_info "Timezone already configured"
        return 0
    fi

    log_info "Setting timezone to $_timezone..."
    timedatectl set-timezone "$_timezone"

    log_success "Timezone configured"
}

disable_unnecessary_services() {
    log_step "Disabling unnecessary services"

    local _services=(
        "snapd"
        "bluetooth"
    )

    local _disabled=0

    for _service in "${_services[@]}"; do
        if systemctl list-unit-files 2>/dev/null | grep -q "^$_service"; then
            if systemctl is-enabled "$_service" >/dev/null 2>&1; then
                log_info "Disabling $_service..."
                systemctl disable "$_service" >/dev/null 2>&1 || true
                systemctl stop "$_service" >/dev/null 2>&1 || true
                _disabled=$((_disabled + 1))
            fi
        fi
    done

    if [[ $_disabled -gt 0 ]]; then
        log_success "Disabled $_disabled service(s)"
    else
        log_info "No services to disable"
    fi
}

upgrade_system() {
    log_step "Upgrading system packages"

    log_info "This may take several minutes..."

    apt-get upgrade -y -qq

    log_success "System upgraded"
}

main() {
    log_step "Base system installation"

    install_base_packages
    configure_locale
    configure_timezone
    disable_unnecessary_services
    upgrade_system

    log_success "Base system installation complete"
}

main