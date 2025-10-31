#!/usr/bin/env bash
# Intérprete mínimo compatible con Bats para entornos sin dependencias.
set -euo pipefail

if (( $# == 0 )); then
  echo "Uso: bats_stub.sh archivo.bats [...]" >&2
  exit 1
fi

bats_transpilar() {
  local archivo=$1
  local tmp
  tmp=$(mktemp)
  python3 - "$archivo" <<'PY' > "$tmp"
import re
import sys

archivo = sys.argv[1]
contenido = open(archivo, encoding='utf-8').read().splitlines()
print('set -u')
print('bats_tests=()')
print('bats_names=()')
print('bats_add_test() {')
print('  bats_names+=("$1")')
print('  bats_tests+=("$2")')
print('}')
print('run() {')
print('  local tmp_stdout tmp_stderr')
print('  tmp_stdout=$(mktemp)')
print('  tmp_stderr=$(mktemp)')
print('  status=0')
print('  output=""')
print('  error=""')
print('  if "$@" >"$tmp_stdout" 2>"$tmp_stderr"; then')
print('    status=0')
print('  else')
print('    status=$?')
print('  fi')
print('  output=$(<"$tmp_stdout")')
print('  error=$(<"$tmp_stderr")')
print('  rm -f "$tmp_stdout" "$tmp_stderr"')
print('  return 0')
print('}')
inside_test = False
contador = 0
for linea in contenido:
    if linea.startswith('#!'):
        continue
    if linea.startswith('@test'):
        m = re.match(r'@test\s+"([^"]+)"\s*\{', linea)
        if not m:
            raise SystemExit(f'No se pudo interpretar la línea: {linea}')
        nombre = m.group(1)
        print(f'bats_add_test "{nombre}" bats_test_{contador}')
        print(f'bats_test_{contador}() {{')
        inside_test = True
        contador += 1
        continue
    if linea.strip() == '}' and inside_test:
        inside_test = False
        print('}')
        continue
    print(linea)
print('bats_main() {')
print('  local total=0')
print('  local fallos=0')
print('  local archivo="$1"')
print('  BATS_TEST_FILENAME="$archivo"')
print('  BATS_TEST_DIRNAME=$(dirname "$archivo")')
print('  local idx=0')
print('  for idx in "${!bats_tests[@]}"; do')
print('    local nombre="${bats_names[$idx]}"')
print('    local funcion="${bats_tests[$idx]}"')
print('    ((total++))')
print('    status=0')
print('    output=""')
print('    error=""')
print('    if declare -F setup >/dev/null; then setup; fi')
print('    if "$funcion"; then')
print('      echo "ok - ${nombre}"')
print('    else')
print('      echo "not ok - ${nombre}"')
print('      ((fallos++))')
print('    fi')
print('    if declare -F teardown >/dev/null; then teardown; fi')
print('  done')
print('  echo "Total: ${total}, Fallos: ${fallos}"')
print('  if (( fallos > 0 )); then')
print('    return 1')
print('  fi')
print('  return 0')
print('}')
print('bats_main "$1"')
PY
  echo "$tmp"
}

resultado=0
for archivo in "$@"; do
  script_tmp=$(bats_transpilar "$archivo")
  if ! BATS_SOURCE="$archivo" bash "$script_tmp" "$archivo"; then
    resultado=1
  fi
  rm -f "$script_tmp"
done

exit $resultado
