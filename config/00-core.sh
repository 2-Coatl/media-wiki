#!/bin/bash
# Core configuration

readonly MEDIAWIKI_VERSION="1.44.0"
readonly PHP_VERSION="8.1"
readonly UBUNTU_VERSION="20.04"
readonly APACHE_VERSION="2.4"
readonly MARIADB_VERSION="10.6"

readonly PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly LOG_DIR="/var/log/mediawiki-setup"
readonly BACKUP_DIR="/opt/backups"

readonly VM_WEB="mediawiki-web01"
readonly VM_DB="mediawiki-db01"
readonly VM_MGMT="mediawiki-mgmt01"

readonly MW_INSTALL_PATH="/var/www/html/mediawiki"
readonly MW_OWNER="www-data"
readonly MW_GROUP="www-data"

readonly MIN_RAM_GB=8
readonly MIN_DISK_GB=50
readonly MIN_VAGRANT_VERSION="2.2.0"
readonly MIN_VBOX_VERSION="6.0.0"

readonly DEPLOYMENT_MODE="${DEPLOYMENT_MODE:-dev}"