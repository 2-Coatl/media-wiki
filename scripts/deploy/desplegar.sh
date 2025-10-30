#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$PROJECT_ROOT/infrastructure/utils/core.sh"

SECURITY_DIR="${DEPLOY_SECURITY_DIR:-$PROJECT_ROOT/scripts/security}"

readonly SECURITY_STEPS=(
  "harden-ssh.sh"
  "install-fail2ban.sh"
  "firewall-web.sh"
  "firewall-database.sh"
  "ssl-certificate.sh"
  "apache-ssl.sh"
  "harden-apache.sh"
)

mostrar_ayuda() {
  cat <<'AYUDA'
Uso: desplegar.sh [-h]

Orquesta el despliegue ejecutando las rutinas de seguridad en la secuencia establecida.

Opciones:
  -h    Muestra esta ayuda y termina.
AYUDA
}

parse_args() {
  while getopts ":h" opcion; do
    case "${opcion}" in
      h)
        mostrar_ayuda
        exit 0
        ;;
      ?)
        echo "Opción desconocida: -${OPTARG}" >&2
        mostrar_ayuda >&2
        exit 1
        ;;
    esac
  done

  shift $((OPTIND - 1))

  if [ "$#" -ne 0 ]; then
    echo "Error: este script no acepta argumentos posicionales." >&2
    exit 1
  fi
}

validar_directorio_seguridad() {
  if [[ ! -d "$SECURITY_DIR" ]]; then
    log_error "Directorio de rutinas de seguridad no encontrado: $SECURITY_DIR"
    exit 1
  fi
}

preparar_bitacora_seguridad() {
  if [[ -n "${DEPLOY_SECURITY_LOG:-}" ]]; then
    local _log_dir
    _log_dir="$(dirname "$DEPLOY_SECURITY_LOG")"
    mkdir -p "$_log_dir" 2>/dev/null || true
    : > "$DEPLOY_SECURITY_LOG"
  fi
}

ejecutar_rutina_seguridad() {
  local _script="$1"
  local _indice="$2"
  local _total="$3"
  local _ruta="$SECURITY_DIR/$_script"

  if [[ ! -x "$_ruta" ]]; then
    log_error "Rutina de seguridad no disponible: $_ruta"
    return 1
  fi

  log_step "[${_indice}/${_total}] Ejecutando $_script"
  log_info "Lanzando $_ruta"

  if [[ -n "${DEPLOY_SECURITY_LOG:-}" ]]; then
    echo "$_script" >> "$DEPLOY_SECURITY_LOG"
  fi

  if bash "$_ruta"; then
    log_success "Rutina completada: $_script"
    return 0
  fi

  log_error "Fallo en la rutina: $_script"
  return 1
}

ejecutar_rutinas_seguridad() {
  local _total="${#SECURITY_STEPS[@]}"
  local _indice=1

  for _script in "${SECURITY_STEPS[@]}"; do
    ejecutar_rutina_seguridad "$_script" "$_indice" "$_total"
    _indice=$((_indice + 1))
  done
}

main() {
  parse_args "$@"
  init_logging

  log_step "Inicio de despliegue"
  log_info "Directorio de seguridad: $SECURITY_DIR"

  validar_directorio_seguridad
  preparar_bitacora_seguridad
  ejecutar_rutinas_seguridad

  log_success "Fase de seguridad completada"
  log_info "Continúa integrando otros pasos de despliegue (pendiente)."
}

main "$@"
