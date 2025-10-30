---
id: DOC-OPS-005
estado: vigente
propietario: Oficina de Operaciones
ultima_actualizacion: 2025-03-05
relacionados: [DOC-INDEX-001, DOC-DEVOPS-PLAN-001, POL-OPS-BACKUP-MARIADB]
---
# Operaciones y Respaldos

Compendio de políticas, scripts y validaciones necesarios para garantizar la
continuidad operativa de MediaWiki. Incluye estrategias de respaldo,
procedimientos de restauración, automatización con `cron` y chequeos de salud.

## 1. Política de respaldos

- Documento maestro: `docs/05_operaciones/politicas/politica_respaldo_mariadb.md`.
- Cobertura mínima: base de datos `mediawiki`, archivos de aplicación, imágenes,
  `LocalSettings.php`, configuraciones de Apache/MariaDB y extensiones
  personalizadas.
- Frecuencias sugeridas:
  - Base de datos: full cada 6 horas mediante `create_mariadb_backup.sh`.
  - Archivos: full diario a las 03:00 e incrementales cada 12 horas.
  - Configuraciones: semanal.
- Retención: diarios 7 días, semanales 4 semanas, mensuales 12 meses.
- Ventanas de ejecución: 02:00-04:00 (full), intervalos configurables para
  incrementales.
- Pruebas de restauración mensuales obligatorias.

## 2. Respaldos de base de datos

- **Script**: `scripts/backups/create_mariadb_backup.sh`.
- **Flujo implementado**:
  1. Carga credenciales desde `config/secrets.env`.
  2. Genera dump con `mysqldump --databases mediawiki` y lo comprime (`.sql.gz`).
  3. Aplica retención automática (`RETENTION_DAYS`, valor predeterminado 7).
  4. Valida integridad mediante `gzip -t` y reporta en stdout.
- **Parámetros**:
  - `BACKUP_BASE_DIR`: redefine el destino (default: `<repo>/backups`).
  - `RETENTION_DAYS`: número de días a conservar.
  - `DB_HOST`: host de MariaDB (default: `localhost`).
  - `MARIADB_DUMP_BIN`: ruta alternativa al binario `mysqldump`.
- **Verificación**:
  - `gzip -t respaldo.sql.gz`.
  - `mysql --user wikiuser --password --host ... < respaldo.sql` en entorno de
    pruebas temporal.

## 3. Respaldos de archivos

- **Script**: `scripts/operations/backup-mediawiki.sh`.
- **Consideraciones**:
  - Crear `/var/backups/mediawiki/files/` con subcarpetas diarias.
  - Incluir `images/`, `extensions/`, `LocalSettings.php` y exclusiones (`cache/`, `.git`).
  - Usar `tar -czf` y generar checksum.
  - Guardar bitácora en `/var/log/backup-mediawiki.log`.
- **Validaciones**:
  - `tar -tzf` para listar contenido y comprobar archivos críticos.
  - Uso de `stat` para confirmar tamaños esperados.

## 4. Procedimientos de restauración

- **Scripts**: `scripts/operations/restore-database.sh` y
  `scripts/operations/restore-mediawiki.sh`.
- **Buenas prácticas**:
  - Listar respaldos disponibles (`list_available_backups`) mostrando fecha/tamaño.
  - Validar integridad (`verify_backup_integrity`) antes de aplicar cambios.
  - Realizar respaldo de seguridad previo (`backup_current_database` o copia de
    archivos) antes de sobrescribir datos.
  - Poner la wiki en modo mantenimiento o detener Apache durante la restauración.
  - Ejecutar `php maintenance/update.php` y validar con `curl` tras finalizar.
- **Pruebas**: simular pérdida controlada en un entorno aislado, ejecutar
  restauración completa y documentar resultados.

## 5. Automatización con cron

- **Script**: `scripts/operations/setup-backup-cron.sh`.
- **Entradas recomendadas**:
  - `0 */6 * * * /opt/mediawiki/scripts/backups/create_mariadb_backup.sh`.
  - `0 3 * * * /path/backup-mediawiki.sh`.
  - `0 4 * * 0 /path/cleanup-old-backups.sh` (si se utiliza script dedicado).
- **Validación**: `crontab -l` y revisión de logs en `/var/log/syslog` o
  archivos específicos.

## 6. Health checks y mantenimiento

- **Script**: `scripts/operations/health-check.sh`.
- **Cobertura**:
  - `df -h` con alertas >80%.
  - Estado de servicios (`systemctl status apache2`, `mariadb`).
  - `mysql -e "SELECT 1"` para conectividad.
  - `curl -o /dev/null -s -w "%{http_code}" https://192.168.1.100` verificando
    respuesta 200 y tiempo de respuesta.
  - Validación de certificados (`openssl s_client -connect 192.168.1.100:443`).
  - Chequeo de actualizaciones (`apt list --upgradable`).
  - Confirmación de respaldos recientes (timestamp <24h).
  - Reporte consolidado en `/var/log/health-check.log`.
- **Mantenimiento**: `scripts/operations/maintenance-tasks.sh` para limpieza de
  cache, optimización de tablas y purga de temporales.

## 7. Validación integral

- Ejecutar `scripts/validation/validate-group-i.sh` para corroborar:
  - Existencia del documento de políticas y directorios de respaldo.
  - Generación exitosa de respaldos de base de datos y archivos (incluidos
    checksums).
  - Integridad de scripts de restauración.
  - Programación de `cron` correcta.
  - Health check sin hallazgos críticos.
  - Prueba end-to-end (backup -> restauración -> verificación de datos).

## Referencias

- [Índice de documentación](../../README.md)
- [Plan maestro de tareas](../../07_devops/plan_tareas_mediawiki.md)
