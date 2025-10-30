#!/bin/bash
# Configure MediaWiki post-installation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$PROJECT_ROOT/infrastructure/utils/logging.sh"
source "$PROJECT_ROOT/infrastructure/utils/core.sh"
source "$PROJECT_ROOT/config/00-core.sh"

init_logging
check_root

readonly SETTINGS="$MW_INSTALL_PATH/LocalSettings.php"

configure_mediawiki() {
    log_step "Configuring MediaWiki"

    if [[ ! -f "$SETTINGS" ]]; then
        log_error "LocalSettings.php not found"
        echo "Run MediaWiki installation wizard first"
        exit 1
    fi

    backup_file "$SETTINGS"

    log_info "Adding security settings..."

    if ! file_contains "$SETTINGS" "wgEnableEmail"; then
        cat >> "$SETTINGS" << 'EOF'

# Security settings
$wgEnableEmail = false;
$wgEnableUserEmail = false;
$wgPasswordPolicy['policies']['default']['MinimalPasswordLength'] = 10;
$wgPasswordPolicy['policies']['default']['PasswordCannotMatchUsername'] = true;
EOF
        log_success "Security settings added"
    else
        log_info "Security settings already present"
    fi

    log_info "Adding performance settings..."

    if ! file_contains "$SETTINGS" "wgMainCacheType"; then
        cat >> "$SETTINGS" << 'EOF'

# Performance
$wgMainCacheType = CACHE_ACCEL;
$wgMemCachedServers = [];
EOF
        log_success "Performance settings added"
    else
        log_info "Performance settings already present"
    fi

    log_info "Configuring permissions..."

    if ! file_contains "$SETTINGS" "wgGroupPermissions\['\\*'\]\['edit'\]"; then
        cat >> "$SETTINGS" << 'EOF'

# Disable anonymous editing
$wgGroupPermissions['*']['edit'] = false;
$wgGroupPermissions['*']['createpage'] = false;
EOF
        log_success "Permissions configured"
    else
        log_info "Permissions already configured"
    fi

    log_info "Configuring file uploads..."

    if ! file_contains "$SETTINGS" "wgEnableUploads"; then
        cat >> "$SETTINGS" << 'EOF'

# File uploads
$wgEnableUploads = true;
$wgFileExtensions = array('png', 'gif', 'jpg', 'jpeg', 'pdf', 'svg');
$wgMaxUploadSize = 20 * 1024 * 1024;
EOF
        log_success "File uploads configured"
    else
        log_info "File uploads already configured"
    fi

    log_info "Disabling debugging..."

    if ! file_contains "$SETTINGS" "wgShowExceptionDetails"; then
        cat >> "$SETTINGS" << 'EOF'

# Debugging disabled in production
$wgShowExceptionDetails = false;
$wgShowDBErrorBacktrace = false;
$wgDebugToolbar = false;
EOF
        log_success "Debugging disabled"
    else
        log_info "Debugging settings already present"
    fi

    log_info "Setting permissions on LocalSettings.php..."
    chown "$MW_OWNER:$MW_GROUP" "$SETTINGS"
    chmod 600 "$SETTINGS"

    log_success "MediaWiki configured"
}

validate_configuration() {
    log_step "Validating configuration"

    local _errors=0

    if [[ ! -f "$SETTINGS" ]]; then
        log_error "LocalSettings.php not found"
        _errors=$((_errors + 1))
    else
        log_success "LocalSettings.php exists"
    fi

    if [[ -f "$SETTINGS" ]]; then
        local _perms=$(stat -c %a "$SETTINGS" 2>/dev/null)
        if [[ "$_perms" == "600" ]]; then
            log_success "Permissions correct: $_perms"
        else
            log_warn "Permissions: $_perms (expected 600)"
        fi

        local _owner=$(stat -c %U "$SETTINGS" 2>/dev/null)
        if [[ "$_owner" == "$MW_OWNER" ]]; then
            log_success "Owner correct: $_owner"
        else
            log_warn "Owner: $_owner (expected $MW_OWNER)"
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
    configure_mediawiki
    validate_configuration
}

main