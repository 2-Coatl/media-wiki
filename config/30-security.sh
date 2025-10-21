#!/bin/bash
# Security configuration

readonly ALLOWED_PORTS_WEB=(22 80 443)
readonly ALLOWED_PORTS_DB=(22 3306)
readonly ALLOWED_PORTS_MGMT=(22 80 443)

readonly FAIL2BAN_BANTIME="3600"
readonly FAIL2BAN_MAXRETRY="5"
readonly FAIL2BAN_FINDTIME="600"

readonly SSL_COUNTRY="US"
readonly SSL_STATE="California"
readonly SSL_CITY="San Francisco"
readonly SSL_ORG="Example Corp"
readonly SSL_CERT_DAYS="365"
readonly SSL_CERT_PATH="/etc/ssl/certs/mediawiki.crt"
readonly SSL_KEY_PATH="/etc/ssl/private/mediawiki.key"