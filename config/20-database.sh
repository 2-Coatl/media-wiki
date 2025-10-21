#!/bin/bash
# Database configuration

readonly DB_NAME="mediawiki"
readonly DB_USER="wikiuser"
readonly DB_PORT="3306"

load_db_credentials() {
    local _secrets="$PROJECT_ROOT/config/secrets.env"

    if [[ ! -f "$_secrets" ]]; then
        echo "ERROR: secrets.env not found"
        echo "Run: ./bin/generate-secrets"
        return 1
    fi

    source "$_secrets"

    if [[ -z "$DB_PASSWORD" ]] || [[ -z "$DB_ROOT_PASSWORD" ]]; then
        echo "ERROR: Database credentials not set in secrets.env"
        return 1
    fi

    return 0
}