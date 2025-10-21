#!/bin/bash
# Core utilities

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/logging.sh"

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

require_command() {
    local _cmd="$1"
    local _hint="$2"

    if ! command_exists "$_cmd"; then
        log_error "Required command not found: $_cmd"
        [[ -n "$_hint" ]] && echo "  $_hint"
        return 1
    fi
    return 0
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        exit 1
    fi
}

check_not_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "This script must NOT be run as root"
        exit 1
    fi
}

package_installed() {
    dpkg -l "$1" 2>/dev/null | grep -q "^ii"
}

service_active() {
    systemctl is-active "$1" >/dev/null 2>&1
}

service_enabled() {
    systemctl is-enabled "$1" >/dev/null 2>&1
}

port_listening() {
    local _port="$1"
    netstat -tuln 2>/dev/null | grep -q ":$_port " || ss -tuln 2>/dev/null | grep -q ":$_port "
}

user_exists() {
    id "$1" >/dev/null 2>&1
}

group_exists() {
    getent group "$1" >/dev/null 2>&1
}

user_in_group() {
    local _user="$1"
    local _group="$2"
    id -nG "$_user" 2>/dev/null | grep -qw "$_group"
}

file_contains() {
    local _file="$1"
    local _pattern="$2"

    if [[ ! -f "$_file" ]]; then
        return 1
    fi

    grep -q "$_pattern" "$_file" 2>/dev/null
}

backup_file() {
    local _file="$1"
    local _backup="${_file}.backup.$(date +%Y%m%d-%H%M%S)"

    if [[ -f "$_file" ]]; then
        cp "$_file" "$_backup"
        log_info "Backup created: $_backup"
    fi
}

generate_password() {
    local _length="${1:-16}"
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-"$_length"
}

confirm() {
    local _prompt="${1:-Continue?}"
    local _response

    read -p "$_prompt (y/N): " _response

    if [[ "$_response" =~ ^[Yy]$ ]]; then
        return 0
    fi
    return 1
}