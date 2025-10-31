---
id: POL-OPS-BACKUP-MARIADB
estado: vigente
propietario: Oficina de Operaciones
ultima_actualizacion: 2025-03-05
relacionados: [ADR-0006]
---
# Política de respaldos MariaDB para MediaWiki

## Objetivo
Garantizar la continuidad operativa del servicio MediaWiki mediante respaldos consistentes de la base de datos MariaDB, asegurando su almacenamiento, retención y verificación básica.

## Alcance
- Base de datos primaria `mediawiki` alojada en `mediawiki-db01`.
- Ambientes `dev`, `stage` y `prod` administrados por el equipo de Operaciones.

## Lineamientos
1. **Frecuencia**: ejecutar `infrastructure/backups/create_mariadb_backup.sh` cada 6 horas mediante cron en `mediawiki-db01`.
2. **Destino**: almacenar los archivos generados bajo `/opt/backups` (override mediante `BACKUP_BASE_DIR`).
3. **Retención**: conservar respaldos de los últimos 7 días (`RETENTION_DAYS` configurable) y purgar automáticamente archivos más antiguos.
4. **Integridad**: validar cada archivo con `gzip -t` tras su creación (incluido en el script).
5. **Verificación semanal**: descomprimir el respaldo más reciente y cargarlo en una instancia desechable para validar autenticidad de datos críticos (usuarios y páginas recientes).
6. **Credenciales**: mantener `infrastructure/config/secrets.env` actualizado y con permisos `600`. Las credenciales deben rotarse trimestralmente o ante sospecha de exposición.
7. **Alertamiento**: registrar salidas del script en syslog (`logger`) o en `/var/log/mediawiki-setup/backups.log` y configurar monitoreo que notifique fallas.

## Procedimiento resumido
1. Crear directorio de trabajo y garantizar permisos restringidos (`chown root:root`, `chmod 750`).
2. Programar cron con usuario `root`:
   ```cron
   0 */6 * * * /opt/mediawiki/infrastructure/backups/create_mariadb_backup.sh >> /var/log/mediawiki-setup/backups.log 2>&1
   ```
3. Supervisar ejecución revisando el log y el contenido de `/opt/backups`.
4. Ejecutar restauración de prueba semanal siguiendo el runbook `docs/05_operaciones/manual_operaciones_mediawiki.md#6-runbooks-de-incidentes`.

## Métricas de cumplimiento
- ≥ 95% de trabajos de respaldo exitosos por semana.
- 100% de respaldos cuentan con marca de tiempo válida (`YYYYMMDD-HHMMSS`).
- Evidencia de restauración semanal documentada en el registro de operaciones.

## Riesgos y mitigaciones
- **Falta de espacio**: monitorear el uso de disco y escalar almacenamiento cuando la ocupación supere 70%.
- **Credenciales inválidas**: el script aborta con código ≠ 0 si no puede cargar `infrastructure/config/secrets.env`; generar alerta inmediata.
- **Corrupción de archivo**: ante fallo de integridad (`gzip -t`), repetir respaldo inmediatamente y abrir incidente.
