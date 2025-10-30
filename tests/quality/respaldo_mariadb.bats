#!/usr/bin/env bats

setup() {
  export REPO_ROOT="${BATS_TEST_DIRNAME}/../.."
  export TMP_WORKDIR="$(mktemp -d)"
  export BACKUP_BASE_DIR="$TMP_WORKDIR/backups"
  mkdir -p "$BACKUP_BASE_DIR"

  stub_dump="$TMP_WORKDIR/mysqldump_stub.sh"
  cat <<'STUB' > "$stub_dump"
#!/bin/bash
# Stub que imita mysqldump para las pruebas
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --host|--port|--user)
      shift 2
      ;;
    --password=*)
      shift 1
      ;;
    --databases)
      shift 1
      break
      ;;
    *)
      break
      ;;
  esac
done
cat <<'DUMP'
-- Dump generado por stub
CREATE DATABASE /*!32312 IF NOT EXISTS*/ `mediawiki`;
DUMP
STUB
  chmod +x "$stub_dump"
  export MARIADB_DUMP_BIN="$stub_dump"

  secrets_file="$REPO_ROOT/config/secrets.env"
  export TEST_SECRETS_FILE="$secrets_file"
  if [[ -f "$secrets_file" ]]; then
    cp "$secrets_file" "$TMP_WORKDIR/secrets.env.backup"
    export RESTORE_ORIGINAL_SECRETS=1
  else
    export RESTORE_ORIGINAL_SECRETS=0
  fi

  cat <<'SECRETS' > "$secrets_file"
DB_PASSWORD='dummy-pass'
DB_ROOT_PASSWORD='dummy-root'
SECRETS
}

teardown() {
  if [[ "$RESTORE_ORIGINAL_SECRETS" -eq 1 ]]; then
    mv "$TMP_WORKDIR/secrets.env.backup" "$TEST_SECRETS_FILE"
  else
    rm -f "$TEST_SECRETS_FILE"
  fi
  rm -rf "$TMP_WORKDIR"
  unset REPO_ROOT
  unset TMP_WORKDIR
  unset BACKUP_BASE_DIR
  unset MARIADB_DUMP_BIN
  unset TEST_SECRETS_FILE
  unset RESTORE_ORIGINAL_SECRETS
}

@test "create-mariadb-backup: genera un respaldo comprimido" {
  run "$REPO_ROOT/infrastructure/backups/create_mariadb_backup.sh"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Respaldo completado"* ]]

  archivos=("$BACKUP_BASE_DIR"/mariadb-mediawiki-*.sql.gz)
  [ -f "${archivos[0]}" ]

  gzip -t "${archivos[0]}"
  gzip -cd "${archivos[0]}" | grep -q "CREATE DATABASE"
}

@test "create-mariadb-backup: purga respaldos fuera de retencion" {
  antiguo="$BACKUP_BASE_DIR/mariadb-mediawiki-20000101-000000.sql.gz"
  printf "stub" | gzip -c > "$antiguo"
  touch -d "10 days ago" "$antiguo"

  export RETENTION_DAYS=1

  run "$REPO_ROOT/infrastructure/backups/create_mariadb_backup.sh"

  [ "$status" -eq 0 ]
  [[ ! -f "$antiguo" ]]
}
