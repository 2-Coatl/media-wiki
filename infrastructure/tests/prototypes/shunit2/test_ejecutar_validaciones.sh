#!/usr/bin/env bash
# Pruebas rápidas con shunit2 (stub) para validar compatibilidad con scripts existentes.
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
PROYECTO_DIR=$(cd -- "${SCRIPT_DIR}/../../../../" && pwd)
SCRIPT_OBJETIVO="${PROYECTO_DIR}/infrastructure/quality/ejecutar_validaciones.sh"

oneTimeSetUp() {
  export PATH="${PROYECTO_DIR}/infrastructure/quality:${PATH}"
}

setUp() {
  export SHUNIT2_TMPDIR="$(mktemp -d)"
}

tearDown() {
  rm -rf "${SHUNIT2_TMPDIR}"
  unset SHUNIT2_TMPDIR
}

test_mostrar_ayuda() {
  salida=$("${SCRIPT_OBJETIVO}" -h)
  codigo=$?
  assertEquals "la ayuda debe salir con código 0" 0 "$codigo"
  assertContains "la ayuda debe explicar el uso" "$salida" "Uso: ejecutar_validaciones.sh"
}

test_rechaza_argumentos_extra() {
  salida=$("${SCRIPT_OBJETIVO}" argumento_extra 2>&1)
  codigo=$?
  assertEquals "debe devolver 1" 1 "$codigo"
  assertContains "mensaje de error esperado" "$salida" "no acepta argumentos posicionales"
}

test_flujo_feliz() {
  salida=$("${SCRIPT_OBJETIVO}")
  codigo=$?
  assertEquals "flujo feliz en cero" 0 "$codigo"
  assertContains "mensaje principal" "$salida" "[quality] Ejecutando placeholder de validaciones de calidad."
}

# shellcheck disable=SC1091
source "${SCRIPT_DIR}/shunit2_stub.sh"
