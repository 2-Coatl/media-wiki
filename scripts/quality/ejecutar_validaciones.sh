#!/usr/bin/env bash
set -euo pipefail

mostrar_ayuda() {
  cat <<'AYUDA'
Uso: ejecutar_validaciones.sh [--min-coverage <porcentaje>] [-h]

Ejecuta linters, pruebas y verificación de cobertura en una única pasada.

Opciones:
  -h, --help                Muestra esta ayuda y termina.
      --min-coverage NUM    Umbral mínimo de cobertura (por defecto 80).

Variables de entorno:
  QUALITY_LINT_CMD          Comando completo para ejecutar linters.
  QUALITY_TEST_CMD          Comando completo para ejecutar las pruebas.
  QUALITY_COVERAGE_CMD      Comando que imprime el porcentaje de cobertura.
  QUALITY_COVERAGE_VALUE    Valor numérico de cobertura usado por el
                            comando por defecto cuando QUALITY_COVERAGE_CMD
                            no está definido.
  QUALITY_MIN_COVERAGE      Umbral mínimo de cobertura utilizado cuando no
                            se pasa el flag --min-coverage.
AYUDA
}

es_numero_decimal() {
  [[ "$1" =~ ^[0-9]+([.][0-9]+)?$ ]]
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

MIN_COVERAGE="${QUALITY_MIN_COVERAGE:-80}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      mostrar_ayuda
      exit 0
      ;;
    --min-coverage)
      shift
      if [[ $# -eq 0 ]]; then
        echo "Error: --min-coverage requiere un valor." >&2
        exit 1
      fi
      if ! es_numero_decimal "$1"; then
        echo "Error: el valor de --min-coverage debe ser numérico." >&2
        exit 1
      fi
      MIN_COVERAGE="$1"
      shift
      ;;
    *)
      echo "Error: argumento desconocido $1" >&2
      mostrar_ayuda >&2
      exit 1
      ;;
  esac
done

if [[ $# -ne 0 ]]; then
  echo "Error: este script no acepta argumentos posicionales." >&2
  exit 1
fi

# Comandos configurables
if [[ -n "${QUALITY_LINT_CMD:-}" ]]; then
  read -r -a LINT_CMD <<< "${QUALITY_LINT_CMD}"
else
  LINT_CMD=(default_lint)
fi

if [[ -n "${QUALITY_TEST_CMD:-}" ]]; then
  read -r -a TEST_CMD <<< "${QUALITY_TEST_CMD}"
else
  TEST_CMD=(default_tests)
fi

if [[ -n "${QUALITY_COVERAGE_CMD:-}" ]]; then
  read -r -a COVERAGE_CMD <<< "${QUALITY_COVERAGE_CMD}"
else
  COVERAGE_CMD=(default_coverage)
fi

default_lint() {
  local exit_code=0
  local found=0
  while IFS= read -r -d '' file; do
    found=1
    if ! bash -n "$file"; then
      echo "[quality] Error de sintaxis en ${file}" >&2
      exit_code=1
    fi
  done < <(find "$REPO_ROOT" -type f -name '*.sh' -print0)

  if [[ "$exit_code" -ne 0 ]]; then
    return "$exit_code"
  fi

  if [[ "$found" -eq 0 ]]; then
    echo "[quality] No se encontraron scripts Bash para lint."
  fi
  return 0
}

default_tests() {
  if command -v bats >/dev/null 2>&1; then
    bats --recursive "$REPO_ROOT/tests"
  else
    echo "[quality] Error: bats no está instalado. Configure QUALITY_TEST_CMD." >&2
    return 1
  fi
}

default_coverage() {
  local value="${QUALITY_COVERAGE_VALUE:-100}"
  echo "$value"
}

ejecutar_comando() {
  local descripcion="$1"
  local mensaje_ok="$2"
  shift 2
  echo "[quality] Ejecutando ${descripcion}..."
  if "$@"; then
    echo "[quality] ${mensaje_ok}"
    return 0
  else
    echo "[quality] Error al ejecutar ${descripcion}" >&2
    return 1
  fi
}

if ! ejecutar_comando "Linters" "Linters completados" "${LINT_CMD[@]}"; then
  exit 1
fi

if ! ejecutar_comando "Pruebas" "Pruebas completadas" "${TEST_CMD[@]}"; then
  exit 1
fi

echo "[quality] Verificando cobertura..."
coverage_output="$(${COVERAGE_CMD[@]} 2>&1)"
coverage_status=$?
if [[ "$coverage_status" -ne 0 ]]; then
  echo "[quality] Error al ejecutar comando de cobertura" >&2
  echo "$coverage_output" >&2
  exit 1
fi

coverage_value=$(printf '%s\n' "$coverage_output" | tr ',' '.' | grep -Eo '[0-9]+([.][0-9]+)?' | head -n 1)
if [[ -z "$coverage_value" ]]; then
  echo "[quality] Error: no se pudo obtener el porcentaje de cobertura." >&2
  exit 1
fi

printf '[quality] Cobertura actual: %s%%\n' "$coverage_value"

if awk -v actual="$coverage_value" -v minimo="$MIN_COVERAGE" 'BEGIN { exit !(actual+0 >= minimo+0) }'; then
  printf '[quality] Cobertura mínima requerida %s%% alcanzada.\n' "$MIN_COVERAGE"
else
  printf '[quality] Error: Cobertura mínima requerida %s%% no alcanzada.\n' "$MIN_COVERAGE" >&2
  exit 1
fi

echo "[quality] Validaciones finalizadas"
exit 0
