#!/usr/bin/env bats

setup() {
  export SCRIPT="${BATS_TEST_DIRNAME}/../../scripts/quality/ejecutar_validaciones.sh"
  export TMP_WORKDIR="$(mktemp -d)"
}

teardown() {
  rm -rf "$TMP_WORKDIR"
  unset SCRIPT
  unset TMP_WORKDIR
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

@test "ejecuta linters, pruebas y cobertura con comandos personalizados" {
  stub_dir="$TMP_WORKDIR/stubs"
  mkdir -p "$stub_dir"

  cat <<'SCRIPT' > "$stub_dir/lint.sh"
#!/usr/bin/env bash
echo "lint ejecutado"
SCRIPT
  chmod +x "$stub_dir/lint.sh"

  cat <<'SCRIPT' > "$stub_dir/tests.sh"
#!/usr/bin/env bash
echo "tests ejecutados"
SCRIPT
  chmod +x "$stub_dir/tests.sh"

  cat <<'SCRIPT' > "$stub_dir/coverage.sh"
#!/usr/bin/env bash
echo "88.4"
SCRIPT
  chmod +x "$stub_dir/coverage.sh"

  export QUALITY_LINT_CMD="$stub_dir/lint.sh"
  export QUALITY_TEST_CMD="$stub_dir/tests.sh"
  export QUALITY_COVERAGE_CMD="$stub_dir/coverage.sh"

  run "$SCRIPT" --min-coverage 80

  [ "$status" -eq 0 ]
  [[ "$output" == *"[quality] Linters completados"* ]]
  [[ "$output" == *"[quality] Pruebas completadas"* ]]
  [[ "$output" == *"[quality] Cobertura actual: 88.4%"* ]]
  [[ "$output" == *"[quality] Validaciones finalizadas"* ]]
}

@test "falla cuando la cobertura está por debajo del umbral" {
  stub_dir="$TMP_WORKDIR/stubs"
  mkdir -p "$stub_dir"

  cat <<'SCRIPT' > "$stub_dir/lint.sh"
#!/usr/bin/env bash
exit 0
SCRIPT
  chmod +x "$stub_dir/lint.sh"

  cat <<'SCRIPT' > "$stub_dir/tests.sh"
#!/usr/bin/env bash
exit 0
SCRIPT
  chmod +x "$stub_dir/tests.sh"

  cat <<'SCRIPT' > "$stub_dir/coverage.sh"
#!/usr/bin/env bash
echo "72.5"
SCRIPT
  chmod +x "$stub_dir/coverage.sh"

  export QUALITY_LINT_CMD="$stub_dir/lint.sh"
  export QUALITY_TEST_CMD="$stub_dir/tests.sh"
  export QUALITY_COVERAGE_CMD="$stub_dir/coverage.sh"

  run "$SCRIPT" --min-coverage 80

  [ "$status" -eq 1 ]
  [[ "$error" == *"Cobertura mínima requerida 80%"* ]]
}
