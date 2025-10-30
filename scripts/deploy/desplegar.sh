#!/usr/bin/env bash
set -euo pipefail

mostrar_ayuda() {
  cat <<'AYUDA'
Uso: desplegar.sh [-h]

Script placeholder para gestionar despliegues del proyecto.

Opciones:
  -h    Muestra esta ayuda y termina.
AYUDA
}

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

echo "[deploy] Ejecutando placeholder de despliegue."
# TODO: Implementar flujo de despliegue incluyendo validaciones previas y notificaciones.

exit 0
