#!/usr/bin/env bats

setup() {
  export SCRIPT="${BATS_TEST_DIRNAME}/../../scripts/quality/ejecutar_validaciones.sh"
}

teardown() {
  unset SCRIPT
}

@test "muestra el mensaje de ayuda con -h" {
  run "$SCRIPT" -h
  [ "$status" -eq 0 ]
  [[ "$output" == *"Uso: ejecutar_validaciones.sh"* ]]
}

@test "falla si recibe argumentos posicionales" {
  run "$SCRIPT" argumento_extra
  [ "$status" -eq 1 ]
  [[ "$error" == *"no acepta argumentos posicionales"* ]]
}

@test "ejecuta el flujo feliz sin argumentos" {
  run "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"[quality] Ejecutando placeholder de validaciones de calidad."* ]]
}
