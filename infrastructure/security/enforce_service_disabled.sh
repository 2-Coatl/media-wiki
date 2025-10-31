#!/usr/bin/env bash
# Enforce que un servicio de systemd permanezca detenido, deshabilitado y enmascarado.
#
# Este script detiene el servicio indicado (si está activo), lo deshabilita para evitar
# futuros arranques automáticos y lo enmascara para impedir que sea iniciado de forma
# manual o indirecta. Está pensado como una medida de refuerzo de seguridad para
# servicios que no deben exponerse en un servidor endurecido.

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Uso: $0 <servicio>" >&2
  exit 1
fi

SERVICE="$1"
SYSTEMCTL_BIN="${SYSTEMCTL_BIN:-systemctl}"

# Detener el servicio solo si está activo para evitar errores innecesarios.
if "$SYSTEMCTL_BIN" is-active "$SERVICE" > /dev/null 2>&1; then
  "$SYSTEMCTL_BIN" stop "$SERVICE"
  echo "Servicio $SERVICE detenido."
else
  echo "Servicio $SERVICE ya se encontraba detenido."
fi

# El estado de habilitación puede devolver códigos de salida distintos, por lo que se
# capturan y manejan manualmente.
enabled_state="$("$SYSTEMCTL_BIN" is-enabled "$SERVICE" 2>/dev/null || true)"

case "$enabled_state" in
  masked)
    echo "Servicio $SERVICE ya estaba enmascarado."
    ;;
  enabled|alias*)
    "$SYSTEMCTL_BIN" disable "$SERVICE"
    "$SYSTEMCTL_BIN" mask "$SERVICE"
    echo "Servicio $SERVICE deshabilitado y enmascarado."
    ;;
  disabled|static|'')
    "$SYSTEMCTL_BIN" mask "$SERVICE"
    echo "Servicio $SERVICE enmascarado."
    ;;
  *)
    # Estados inesperados también se enmascaran para mantener una postura segura.
    "$SYSTEMCTL_BIN" mask "$SERVICE"
    echo "Servicio $SERVICE enmascarado (estado previo: $enabled_state)."
    ;;
esac
