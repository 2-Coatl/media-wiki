#!/usr/bin/env bats

setup() {
  export SCRIPT="${BATS_TEST_DIRNAME}/../../infrastructure/git_hooks/pre-push"
  export TMP_WORKDIR="$(mktemp -d)"
}

teardown() {
  rm -rf "$TMP_WORKDIR"
  unset SCRIPT
  unset TMP_WORKDIR
}

crear_stub() {
  local name="$1"
  local content="$2"
  local path="$TMP_WORKDIR/${name}.sh"
  cat <<SCRIPT > "$path"
#!/usr/bin/env bash
${content}
SCRIPT
  chmod +x "$path"
  echo "$path"
}

@test "pre-push ejecuta validaciones con cobertura suficiente" {
  stub_pipeline=$(crear_stub "pipeline" 'echo "pipeline"')

  export QUALITY_PIPELINE_CMD="$stub_pipeline"
  export PRE_PUSH_MIN_COVERAGE=85

  run "$SCRIPT"

  [ "$status" -eq 0 ]
  [[ "$output" == *"pipeline"* ]]
}

@test "pre-push falla cuando la cobertura es insuficiente" {
  stub_pipeline=$(crear_stub "pipeline" 'echo "Cobertura actual: 70%" >&2
exit 2')

  export QUALITY_PIPELINE_CMD="$stub_pipeline"

  run "$SCRIPT"

  [ "$status" -eq 1 ]
  [[ "$error" == *"Cobertura"* ]]
}
