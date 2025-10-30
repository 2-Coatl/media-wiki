#!/bin/bash
# Install MediaWiki using copy (production mode)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$PROJECT_ROOT/infrastructure/utils/logging.sh"
source "$PROJECT_ROOT/infrastructure/utils/core.sh"
source "$PROJECT_ROOT/config/00-core.sh"

init_logging
check_root

readonly SOURCE_DIR="/vagrant/wiki"
readonly INSTALL_PATH="$MW_INSTALL_PATH"

install_mediawiki_copy() {
    log_step "Installing MediaWiki using copy (production mode)"

    if [[ ! -d "$SOURCE_DIR" ]]; then
        log_error "Source directory not found: $SOURCE_DIR"
        exit 1
    fi

    if [[ ! -f "$SOURCE_DIR/index.php" ]]; then
        log_error "Not a valid MediaWiki directory"
        exit 1
    fi

    if [[ -d "$INSTALL_PATH" ]] && [[ ! -L "$INSTALL_PATH" ]]; then
        log_info "MediaWiki already installed (directory exists)"

        if [[ "$SOURCE_DIR/index.php" -nt "$INSTALL_PATH/index.php" ]]; then
            log_info "Source is newer, updating..."
        else
            log_info "Installation is up to date"
            return 0
        fi
    elif [[ -L "$INSTALL_PATH" ]]; then
        log_warn "Symlink exists (dev mode), removing for production mode..."
        rm "$INSTALL_PATH"
    fi

    mkdir -p "$(dirname "$INSTALL_PATH")"

    if [[ -d "$INSTALL_PATH" ]]; then
        log_info "Backing up existing installation..."
        mv "$INSTALL_PATH" "${INSTALL_PATH}.backup.$(date +%Y%m%d-%H%M%S)"
    fi

    log_info "Copying MediaWiki files..."
    log_info "This creates an independent copy (production mode)"

    cp -r "$SOURCE_DIR" "$INSTALL_PATH"

    log_info "Setting ownership to $MW_OWNER:$MW_GROUP..."
    chown -R "$MW_OWNER:$MW_GROUP" "$INSTALL_PATH"

    log_info "Setting permissions..."
    find "$INSTALL_PATH" -type d -exec chmod 755 {} \;
    find "$INSTALL_PATH" -type f -exec chmod 644 {} \;

    if [[ -d "$INSTALL_PATH/maintenance" ]]; then
        chmod +x "$INSTALL_PATH/maintenance/"*.php 2>/dev/null || true
    fi

    log_info "Creating runtime directories..."
    mkdir -p "$INSTALL_PATH/cache"
    mkdir -p "$INSTALL_PATH/images"

    chmod 755 "$INSTALL_PATH/cache"
    chmod 755 "$INSTALL_PATH/images"

    chown -R "$MW_OWNER:$MW_GROUP" "$INSTALL_PATH/cache"
    chown -R "$MW_OWNER:$MW_GROUP" "$INSTALL_PATH/images"

    if [[ -d "$INSTALL_PATH/.git" ]]; then
        rm -rf "$INSTALL_PATH/.git"
    fi

    log_success "MediaWiki installed (production copy)"

    echo ""
    echo "PRODUCTION MODE ACTIVE"
    echo "====================="
    echo "Independent copy created"
    echo ""
    echo "Location: $INSTALL_PATH"
    echo ""
}

validate_installation() {
    log_step "Validating copy installation"

    local _errors=0

    if [[ -L "$INSTALL_PATH" ]]; then
        log_error "Installation is a symlink (should be directory in prod mode)"
        _errors=$((_errors + 1))
        return 1
    fi

    if [[ ! -d "$INSTALL_PATH" ]]; then
        log_error "Installation directory does not exist"
        _errors=$((_errors + 1))
        return 1
    fi

    log_success "Installation is a directory (correct for production)"

    local _files=(
        "index.php"
        "api.php"
        "includes/WebStart.php"
        "maintenance/install.php"
    )

    for _file in "${_files[@]}"; do
        if [[ -f "$INSTALL_PATH/$_file" ]]; then
            log_success "Found: $_file"
        else
            log_error "Missing: $_file"
            _errors=$((_errors + 1))
        fi
    done

    local _owner
    _owner=$(stat -c %U "$INSTALL_PATH/index.php" 2>/dev/null)
    if [[ "$_owner" == "$MW_OWNER" ]]; then
        log_success "Ownership correct: $_owner"
    else
        log_warn "Ownership: $_owner (expected $MW_OWNER)"
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
    install_mediawiki_copy
    validate_installation
}

main