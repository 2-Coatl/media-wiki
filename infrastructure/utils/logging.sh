#!/bin/bash
# Logging system

readonly LOG_FILE="${LOG_FILE:-/var/log/mediawiki-setup.log}"

_red='\033[0;31m'
_green='\033[0;32m'
_yellow='\033[1;33m'
_blue='\033[0;34m'
_nc='\033[0m'

init_logging() {
    local _log_dir
    _log_dir="$(dirname "$LOG_FILE")"

    if [[ -w "$_log_dir" ]] 2>/dev/null; then
        mkdir -p "$_log_dir" 2>/dev/null || true
    fi
}

log_timestamp() {
    date "+%Y-%m-%d %H:%M:%S"
}

log_info() {
    local _msg="$1"
    echo -e "${_blue}[INFO] $(log_timestamp)${_nc} - $_msg" | tee -a "$LOG_FILE" 2>/dev/null || echo -e "${_blue}[INFO] $(log_timestamp)${_nc} - $_msg"
}

log_success() {
    local _msg="$1"
    echo -e "${_green}[OK] $(log_timestamp)${_nc} - $_msg" | tee -a "$LOG_FILE" 2>/dev/null || echo -e "${_green}[OK] $(log_timestamp)${_nc} - $_msg"
}

log_error() {
    local _msg="$1"
    echo -e "${_red}[ERROR] $(log_timestamp)${_nc} - $_msg" | tee -a "$LOG_FILE" 2>/dev/null || echo -e "${_red}[ERROR] $(log_timestamp)${_nc} - $_msg"
}

log_warn() {
    local _msg="$1"
    echo -e "${_yellow}[WARN] $(log_timestamp)${_nc} - $_msg" | tee -a "$LOG_FILE" 2>/dev/null || echo -e "${_yellow}[WARN] $(log_timestamp)${_nc} - $_msg"
}

log_debug() {
    local _msg="$1"

    if [[ "${DEBUG:-0}" == "1" ]]; then
        echo -e "${_blue}[DEBUG] $(log_timestamp)${_nc} - $_msg" | tee -a "$LOG_FILE" 2>/dev/null || echo -e "${_blue}[DEBUG] $(log_timestamp)${_nc} - $_msg"
    fi
}

log_step() {
    local _msg="$1"
    echo "" | tee -a "$LOG_FILE" 2>/dev/null || echo ""
    echo -e "${_blue}==> $_msg${_nc}" | tee -a "$LOG_FILE" 2>/dev/null || echo -e "${_blue}==> $_msg${_nc}"
}