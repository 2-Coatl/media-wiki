#!/bin/bash
# Install MediaWiki - Auto-detect mode

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$PROJECT_ROOT/infrastructure/utils/logging.sh"
source "$PROJECT_ROOT/config/00-core.sh"

init_logging

log_step "MediaWiki Installation"
log_info "Deployment mode: $DEPLOYMENT_MODE"

case "$DEPLOYMENT_MODE" in
    dev|development)
        log_info "Using SYMLINK strategy (development)"
        bash "$SCRIPT_DIR/install-mediawiki-symlink.sh"
        ;;

    prod|production)
        log_info "Using COPY strategy (production)"
        bash "$SCRIPT_DIR/install-mediawiki-copy.sh"
        ;;

    *)
        log_error "Invalid DEPLOYMENT_MODE: $DEPLOYMENT_MODE"
        echo "Valid values: dev, development, prod, production"
        exit 1
        ;;
esac

log_success "MediaWiki installation complete"