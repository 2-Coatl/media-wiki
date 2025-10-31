#!/usr/bin/env bats

setup() {
  export SYSTEMCTL_STATE_DIR="$(mktemp -d)"
  export SYSTEMCTL_LOG="$SYSTEMCTL_STATE_DIR/commands.log"

  cat <<'STUB' > "$SYSTEMCTL_STATE_DIR/systemctl"
#!/usr/bin/env bash
set -euo pipefail
STATE_DIR="${SYSTEMCTL_STATE_DIR:?}"
LOG_FILE="${SYSTEMCTL_LOG:-$STATE_DIR/commands.log}"
log() {
  echo "$*" >> "$LOG_FILE"
}

command="$1"
service="${2:-}"

case "$command" in
  is-active)
    log "$command $service"
    if [[ -f "$STATE_DIR/${service}.active" ]]; then
      echo "active"
      exit 0
    fi
    echo "inactive"
    exit 3
    ;;
  stop)
    log "$command $service"
    rm -f "$STATE_DIR/${service}.active"
    exit 0
    ;;
  is-enabled)
    log "$command $service"
    if [[ -f "$STATE_DIR/${service}.masked" ]]; then
      echo "masked"
      exit 0
    fi
    if [[ -f "$STATE_DIR/${service}.enabled" ]]; then
      echo "enabled"
      exit 0
    fi
    echo "disabled"
    exit 1
    ;;
  disable)
    log "$command $service"
    rm -f "$STATE_DIR/${service}.enabled"
    exit 0
    ;;
  mask)
    log "$command $service"
    rm -f "$STATE_DIR/${service}.enabled"
    touch "$STATE_DIR/${service}.masked"
    exit 0
    ;;
  *)
    echo "comando no soportado: $command" >&2
    exit 1
    ;;
esac
STUB
  chmod +x "$SYSTEMCTL_STATE_DIR/systemctl"
  export SYSTEMCTL_BIN="$SYSTEMCTL_STATE_DIR/systemctl"
}

teardown() {
  rm -rf "$SYSTEMCTL_STATE_DIR"
}

establecer_estado_activo_y_habilitado() {
  local servicio="$1"
  touch "$SYSTEMCTL_STATE_DIR/${servicio}.active"
  touch "$SYSTEMCTL_STATE_DIR/${servicio}.enabled"
  rm -f "$SYSTEMCTL_STATE_DIR/${servicio}.masked"
}

establecer_estado_inactivo_y_enmascarado() {
  local servicio="$1"
  rm -f "$SYSTEMCTL_STATE_DIR/${servicio}.active"
  rm -f "$SYSTEMCTL_STATE_DIR/${servicio}.enabled"
  touch "$SYSTEMCTL_STATE_DIR/${servicio}.masked"
}

@test "detiene y enmascara servicios activos" {
  local servicio="telnet.service"
  establecer_estado_activo_y_habilitado "$servicio"

  run infrastructure/security/enforce_service_disabled.sh "$servicio"

  [ "$status" -eq 0 ]
  [ ! -f "$SYSTEMCTL_STATE_DIR/${servicio}.active" ]
  [ ! -f "$SYSTEMCTL_STATE_DIR/${servicio}.enabled" ]
  [ -f "$SYSTEMCTL_STATE_DIR/${servicio}.masked" ]

  run grep -F "stop $servicio" "$SYSTEMCTL_LOG"
  [ "$status" -eq 0 ]

  run grep -F "mask $servicio" "$SYSTEMCTL_LOG"
  [ "$status" -eq 0 ]
}

@test "no ejecuta acciones innecesarias en servicios ya enmascarados" {
  local servicio="rlogin.service"
  establecer_estado_inactivo_y_enmascarado "$servicio"

  run infrastructure/security/enforce_service_disabled.sh "$servicio"

  [ "$status" -eq 0 ]
  [ ! -f "$SYSTEMCTL_STATE_DIR/${servicio}.active" ]
  [ ! -f "$SYSTEMCTL_STATE_DIR/${servicio}.enabled" ]
  [ -f "$SYSTEMCTL_STATE_DIR/${servicio}.masked" ]

  run grep -F "stop $servicio" "$SYSTEMCTL_LOG"
  [ "$status" -ne 0 ]
}

@test "falla cuando no se proporciona el nombre del servicio" {
  run infrastructure/security/enforce_service_disabled.sh
  [ "$status" -ne 0 ]
}
