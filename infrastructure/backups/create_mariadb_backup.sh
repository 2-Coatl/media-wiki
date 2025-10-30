#!/bin/bash
# Script de respaldo automatizado para MariaDB utilizado por MediaWiki.
# Genera un dump comprimido con sello de tiempo y elimina respaldos fuera
# de la ventana de retención definida.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

BACKUP_BASE_DIR="${BACKUP_BASE_DIR:-$PROJECT_ROOT/backups}"
RETENTION_DAYS="${RETENTION_DAYS:-7}"
MARIADB_DUMP_BIN="${MARIADB_DUMP_BIN:-mysqldump}"
DB_HOST="${DB_HOST:-localhost}"

mkdir -p "$BACKUP_BASE_DIR"

# Cargar configuración de base de datos y credenciales.
source "$PROJECT_ROOT/config/20-database.sh"
if ! load_db_credentials; then
  echo "[ERROR] No fue posible cargar credenciales desde config/secrets.env" >&2
  exit 1
fi

timestamp="$(date +%Y%m%d-%H%M%S)"
backup_name="mariadb-${DB_NAME}-${timestamp}.sql.gz"
backup_path="$BACKUP_BASE_DIR/$backup_name"

tmp_file="$(mktemp "$BACKUP_BASE_DIR/${backup_name}.XXXXXX")"
trap 'rm -f "$tmp_file"' EXIT

if ! "$MARIADB_DUMP_BIN" \
  --host "$DB_HOST" \
  --port "$DB_PORT" \
  --user "$DB_USER" \
  --password="$DB_PASSWORD" \
  --databases "$DB_NAME" \
  | gzip -c > "$tmp_file"; then
  echo "[ERROR] Falló la ejecución de mysqldump" >&2
  exit 1
fi

mv "$tmp_file" "$backup_path"
trap - EXIT

gzip -t "$backup_path" >/dev/null

echo "[OK] Respaldo completado: $backup_path"

# Purga de respaldos fuera de retención (solo valores numéricos).
if [[ "$RETENTION_DAYS" =~ ^[0-9]+$ ]]; then
  while IFS= read -r old_backup; do
    [[ -z "$old_backup" ]] && continue
    rm -f "$old_backup"
    echo "[INFO] Respaldo eliminado por retención: $old_backup"
  done < <(find "$BACKUP_BASE_DIR" -type f -name "mariadb-${DB_NAME}-*.sql.gz" -mtime +"$RETENTION_DAYS" -print)
else
  echo "[WARN] RETENTION_DAYS debe ser numérico. Se omite purga." >&2
fi
