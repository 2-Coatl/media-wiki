#!/bin/bash
# Install MediaWiki using symlinks (development mode)

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

install_mediawiki_symlink() {
    log_step "Installing MediaWiki using symlinks (dev mode)"

    if [[ ! -d "$SOURCE_DIR" ]]; then
        log_error "Source directory not found: $SOURCE_DIR"
        echo "Please ensure wiki/ exists in project root"
        exit 1
    fi

    if [[ ! -f "$SOURCE_DIR/index.php" ]]; then
        log_error "Not a valid MediaWiki directory"
        exit 1
    fi

    if [[ -L "$INSTALL_PATH" ]]; then
        local _target
        _target=$(readlink -f "$INSTALL_PATH")
        if [[ "$_target" == "$SOURCE_DIR" ]]; then
            log_info "Symlink already exists and points to correct location"
            return 0
        else
            log_warn "Symlink exists but points to wrong location: $_target"
            log_info "Removing old symlink..."
            rm "$INSTALL_PATH"
        fi
    elif [[ -d "$INSTALL_PATH" ]]; then
        log_warn "Directory exists (not a symlink)"
        log_info "Backing up and removing..."
        mv "$INSTALL_PATH" "${INSTALL_PATH}.backup.$(date +%Y%m%d-%H%M%S)"
    fi

    mkdir -p "$(dirname "$INSTALL_PATH")"

    log_info "Creating symlink..."
    log_info "Source: $SOURCE_DIR"
    log_info "Target: $INSTALL_PATH"

    ln -s "$SOURCE_DIR" "$INSTALL_PATH"

    if [[ -L "$INSTALL_PATH" ]]; then
        log_success "Symlink created successfully"
        log_info "Points to: $(readlink -f "$INSTALL_PATH")"
    else
        log_error "Failed to create symlink"
        exit 1
    fi

    log_info "Creating runtime directories..."

    mkdir -p "$SOURCE_DIR/cache"
    mkdir -p "$SOURCE_DIR/images"

    chmod 755 "$SOURCE_DIR/cache"
    chmod 755 "$SOURCE_DIR/images"

    log_success "MediaWiki installed using symlinks"

    echo ""
    echo "DEVELOPMENT MODE ACTIVE"
    echo "======================="
    echo "Changes in Windows are immediately visible in VM"
    echo ""
    echo "Edit files in:"
    echo "  Windows: wiki/"
    echo "  VM sees: $INSTALL_PATH/ (symlink)"
    echo ""
}

validate_installation() {
    log_step "Validating symlink installation"

    local _errors=0

    if [[ ! -L "$INSTALL_PATH" ]]; then
        log_error "Symlink does not exist"
        _errors=$((_errors + 1))
        return 1
    fi

    log_success "Symlink exists"

    local _target
    _target=$(readlink -f "$INSTALL_PATH")
    if [[ "$_target" == "$SOURCE_DIR" ]]; then
        log_success "Symlink points to correct location"
    else
        log_error "Symlink points to wrong location: $_target"
        _errors=$((_errors + 1))
    fi

    local _files=(
        "index.php"
        "api.php"
        "includes/WebStart.php"
    )

    for _file in "${_files[@]}"; do
        if [[ -f "$INSTALL_PATH/$_file" ]]; then
            log_success "Accessible: $_file"
        else
            log_error "Not accessible: $_file"
            _errors=$((_errors + 1))
        fi
    done

    if [[ $_errors -eq 0 ]]; then
        log_success "Validation passed"
        return 0
    else
        log_error "Validation failed: $_errors error(s)"
        return 1
    fi
}

main() {
    install_mediawiki_symlink
    validate_installation
}

main