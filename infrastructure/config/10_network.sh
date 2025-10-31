#!/bin/bash
# Network configuration

readonly WEB_BRIDGED_IP="${WEB_BRIDGED_IP:-192.168.1.100}"
readonly WEB_BRIDGED_NETMASK="255.255.255.0"
readonly WEB_BRIDGED_GATEWAY="192.168.1.1"

readonly APP_NETWORK="10.0.2.0/24"
readonly WEB_APP_IP="10.0.2.10"
readonly DB_APP_IP="10.0.2.20"

readonly MON_NETWORK="10.0.3.0/24"
readonly WEB_MON_IP="10.0.3.10"
readonly DB_MON_IP="10.0.3.20"
readonly MGMT_MON_IP="10.0.3.30"

readonly MGMT_HOSTONLY_IP="192.168.56.30"