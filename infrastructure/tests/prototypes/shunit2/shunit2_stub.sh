#!/usr/bin/env bash
# Stub minimal de shunit2 para prototipos offline.
set -u

__shunit_failures=0
__shunit_total=0

fail() {
  local mensaje=${1:-"Fallo sin mensaje"}
  echo "not ok - ${__shunit_test_actual}: ${mensaje}"
  return 1
}

assertEquals() {
  local mensaje=${1:-""}
  local esperado=${2:-""}
  local obtenido=${3:-""}
  if [[ "$esperado" != "$obtenido" ]]; then
    fail "${mensaje} (esperado='${esperado}' obtenido='${obtenido}')"
  fi
}

assertContains() {
  local mensaje=${1:-""}
  local texto=${2:-""}
  local subcadena=${3:-""}
  if [[ "$texto" != *"$subcadena"* ]]; then
    fail "${mensaje} (no se encontró '${subcadena}')"
  fi
}

__shunit_ejecutar_test() {
  local test_funcion=$1
  __shunit_test_actual=$test_funcion
  ((__shunit_total++))

  if declare -F setUp >/dev/null; then
    setUp
  fi

  if "$test_funcion"; then
    echo "ok - ${test_funcion}"
  else
    ((__shunit_failures++))
  fi

  if declare -F tearDown >/dev/null; then
    tearDown
  fi
}

__shunit_main() {
  if declare -F oneTimeSetUp >/dev/null; then
    oneTimeSetUp
  fi

  local prueba
  while IFS= read -r prueba; do
    __shunit_ejecutar_test "$prueba"
  done < <(compgen -A function | grep '^test')

  if declare -F oneTimeTearDown >/dev/null; then
    oneTimeTearDown
  fi

  echo "Total: ${__shunit_total}, Fallos: ${__shunit_failures}"
  if (( __shunit_failures > 0 )); then
    exit 1
  fi
}

__shunit_main
