#!/bin/bash
# Validation utilities

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/core.sh"

validate_ip() {
    local _ip="$1"
    [[ "$_ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]
}

validate_port() {
    local _port="$1"
    [[ "$_port" =~ ^[0-9]+$ ]] && [[ $_port -ge 1 ]] && [[ $_port -le 65535 ]]
}

validate_hostname() {
    local _hostname="$1"
    [[ "$_hostname" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$ ]]
}

validate_email() {
    local _email="$1"
    [[ "$_email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]
}

validate_path_writable() {
    local _path="$1"
    [[ -w "$_path" ]]
}

validate_path_readable() {
    local _path="$1"
    [[ -r "$_path" ]]
}

validate_connection() {
    local _host="$1"
    local _port="$2"
    local _timeout="${3:-5}"

    timeout "$_timeout" bash -c "cat < /dev/null > /dev/tcp/$_host/$_port" 2>/dev/null
}

validate_url() {
    local _url="$1"
    local _timeout="${2:-5}"

    if command_exists curl; then
        curl -s -f -m "$_timeout" -o /dev/null "$_url" 2>/dev/null
    elif command_exists wget; then
        wget -q -T "$_timeout" --spider "$_url" 2>/dev/null
    else
        return 1
    fi
}

validate_min_ram() {
    local _required_gb="$1"
    local _total_kb
    local _total_gb

    _total_kb=$(grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}')

    if [[ -z "$_total_kb" ]]; then
        return 1
    fi

    _total_gb=$((_total_kb / 1024 / 1024))

    [[ $_total_gb -ge $_required_gb ]]
}

validate_min_disk() {
    local _path="$1"
    local _required_gb="$2"
    local _available_gb

    _available_gb=$(df -BG "$_path" 2>/dev/null | tail -1 | awk '{print $4}' | tr -d 'G')

    if [[ -z "$_available_gb" ]]; then
        return 1
    fi

    [[ $_available_gb -ge $_required_gb ]]
}

validate_cpu_virtualization() {
    if [[ ! -f /proc/cpuinfo ]]; then
        return 1
    fi

    grep -qE "vmx|svm" /proc/cpuinfo 2>/dev/null
}