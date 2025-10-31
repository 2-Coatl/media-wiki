#!/bin/bash
# Migrate MediaWiki from SQLite to MariaDB

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$PROJECT_ROOT/infrastructure/utils/logging.sh"
source "$PROJECT_ROOT/infrastructure/utils/core.sh"
source "$PROJECT_ROOT/infrastructure/config/00_core.sh"
source "$PROJECT_ROOT/infrastructure/config/10_network.sh"
source "$PROJECT_ROOT/infrastructure/config/20_database.sh"

init_logging
check_root

readonly BACKUP_BASE="/tmp/mediawiki-backup-$(date +%Y%m%d-%H%M%S)"

check_prerequisites() {
    log_step "Checking prerequisites"

    local _errors=0

    if [[ ! -d "$MW_INSTALL_PATH" ]]; then
        log_error "MediaWiki not found at $MW_INSTALL_PATH"
        _errors=$((_errors + 1))
    fi

    if [[ ! -f "$MW_INSTALL_PATH/LocalSettings.php" ]]; then
        log_error "LocalSettings.php not found"
        _errors=$((_errors + 1))
    fi

    if ! command_exists mysql; then
        log_error "MySQL client not installed"
        _errors=$((_errors + 1))
    fi

    if [[ $_errors -gt 0 ]]; then
        log_error "Prerequisites check failed"
        exit 1
    fi

    log_success "Prerequisites check passed"
}

test_database_connection() {
    log_step "Testing database connection"

    load_db_credentials

    log_info "Testing connection to $DB_APP_IP:$DB_PORT"

    if ! validate_connection "$DB_APP_IP" "$DB_PORT" 5; then
        log_error "Cannot reach database server"
        exit 1
    fi

    log_info "Testing authentication"

    if ! mysql -h "$DB_APP_IP" -u "$DB_USER" -p"$DB_PASSWORD" -e "SELECT 1" >/dev/null 2>&1; then
        log_error "Authentication failed"
        exit 1
    fi

    log_success "Database connection successful"
}

backup_existing_data() {
    log_step "Backing up existing data"

    mkdir -p "$BACKUP_BASE"

    log_info "Backing up LocalSettings.php"
    cp "$MW_INSTALL_PATH/LocalSettings.php" "$BACKUP_BASE/"

    if [[ -d "$MW_INSTALL_PATH/data" ]]; then
        log_info "Backing up SQLite database"
        cp -r "$MW_INSTALL_PATH/data" "$BACKUP_BASE/"
    fi

    if [[ -d "$MW_INSTALL_PATH/images" ]]; then
        log_info "Backing up images"
        cp -r "$MW_INSTALL_PATH/images" "$BACKUP_BASE/"
    fi

    log_success "Backup created at $BACKUP_BASE"
}

export_sqlite_data() {
    log_step "Exporting SQLite data"

    local _db_type
    _db_type=$(grep 'wgDBtype' "$MW_INSTALL_PATH/LocalSettings.php" 2>/dev/null | grep -o '"[^"]*"' | tr -d '"' | head -1)

    if [[ "$_db_type" != "sqlite" ]]; then
        log_info "Database is not SQLite (type: $_db_type), skipping export"
        return 0
    fi

    log_info "Exporting data using dumpBackup.php"

    cd "$MW_INSTALL_PATH"

    if ! php maintenance/dumpBackup.php --full > "$BACKUP_BASE/wiki-dump.xml" 2>/dev/null; then
        log_warn "Export may have failed, check backup"
    fi

    log_success "Data exported to $BACKUP_BASE/wiki-dump.xml"
}

reconfigure_mediawiki() {
    log_step "Reconfiguring MediaWiki for MariaDB"

    load_db_credentials

    local _settings="$MW_INSTALL_PATH/LocalSettings.php"

    backup_file "$_settings"

    log_info "Updating database configuration"

    sed -i "s/\$wgDBtype = \"sqlite\";/\$wgDBtype = \"mysql\";/" "$_settings"
    sed -i "s/\$wgDBserver = \"localhost\";/\$wgDBserver = \"$DB_APP_IP\";/" "$_settings"

    if ! grep -q "^\$wgDBname" "$_settings"; then
        sed -i "/\$wgDBtype/a \$wgDBname = \"$DB_NAME\";" "$_settings"
    else
        sed -i "s/\$wgDBname = \"[^\"]*\";/\$wgDBname = \"$DB_NAME\";/" "$_settings"
    fi

    if ! grep -q "^\$wgDBuser" "$_settings"; then
        sed -i "/\$wgDBname/a \$wgDBuser = \"$DB_USER\";" "$_settings"
    else
        sed -i "s/\$wgDBuser = \"[^\"]*\";/\$wgDBuser = \"$DB_USER\";/" "$_settings"
    fi

    if ! grep -q "^\$wgDBpassword" "$_settings"; then
        sed -i "/\$wgDBuser/a \$wgDBpassword = \"$DB_PASSWORD\";" "$_settings"
    else
        sed -i "s/\$wgDBpassword = \"[^\"]*\";/\$wgDBpassword = \"$DB_PASSWORD\";/" "$_settings"
    fi

    log_success "LocalSettings.php reconfigured"
}

update_database_schema() {
    log_step "Updating database schema"

    cd "$MW_INSTALL_PATH"

    log_info "Running update.php"

    if ! php maintenance/update.php --quick 2>&1 | tee -a "$LOG_FILE"; then
        log_error "Database update failed"
        exit 1
    fi

    log_success "Database schema updated"
}

import_existing_data() {
    log_step "Importing existing data"

    local _dump="$BACKUP_BASE/wiki-dump.xml"

    if [[ ! -f "$_dump" ]]; then
        log_info "No dump file found, skipping import"
        return 0
    fi

    cd "$MW_INSTALL_PATH"

    log_info "Importing data from dump"

    if ! php maintenance/importDump.php < "$_dump" 2>&1 | tee -a "$LOG_FILE"; then
        log_warn "Import may have failed, check logs"
    fi

    log_info "Rebuilding recent changes"
    php maintenance/rebuildrecentchanges.php 2>&1 | tee -a "$LOG_FILE" || true

    log_success "Data import complete"
}

validate_migration() {
    log_step "Validating migration"

    local _errors=0

    if [[ ! -f "$MW_INSTALL_PATH/LocalSettings.php" ]]; then
        log_error "LocalSettings.php missing"
        _errors=$((_errors + 1))
    fi

    local _db_type
    _db_type=$(grep 'wgDBtype' "$MW_INSTALL_PATH/LocalSettings.php" 2>/dev/null | grep -o '"[^"]*"' | tr -d '"' | head -1)

    if [[ "$_db_type" == "mysql" ]]; then
        log_success "Database type is mysql"
    else
        log_error "Database type is not mysql: $_db_type"
        _errors=$((_errors + 1))
    fi

    load_db_credentials

    local _table_count
    _table_count=$(mysql -h "$DB_APP_IP" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" -e "SHOW TABLES" 2>/dev/null | wc -l)

    if [[ $_table_count -gt 10 ]]; then
        log_success "Database has $_table_count tables"
    else
        log_error "Database has too few tables: $_table_count"
        _errors=$((_errors + 1))
    fi

    if curl -s -f "http://localhost/mediawiki/" >/dev/null 2>&1; then
        log_success "MediaWiki is accessible"
    else
        log_warn "MediaWiki may not be accessible via HTTP"
    fi

    if [[ $_errors -eq 0 ]]; then
        log_success "Migration validation passed"
        return 0
    else
        log_error "Migration validation failed: $_errors error(s)"
        return 1
    fi
}

print_summary() {
    echo ""
    log_step "Migration Summary"
    echo ""
    echo "Migration completed successfully"
    echo ""
    echo "Backup location: $BACKUP_BASE"
    echo "Database server: $DB_APP_IP"
    echo "Database name: $DB_NAME"
    echo ""
    echo "Next steps:"
    echo "  1. Test MediaWiki: http://192.168.1.100/mediawiki/"
    echo "  2. Verify all pages are accessible"
    echo "  3. Check uploaded files"
    echo "  4. Remove SQLite data directory if everything works:"
    echo "     rm -rf $MW_INSTALL_PATH/data"
    echo ""
}

main() {
    log_step "MediaWiki Migration: SQLite to MariaDB"

    check_prerequisites
    test_database_connection
    backup_existing_data
    export_sqlite_data
    reconfigure_mediawiki
    update_database_schema
    import_existing_data
    validate_migration
    print_summary

    log_success "Migration complete"
}

main