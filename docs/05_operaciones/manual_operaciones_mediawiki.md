---
id: DOC-OPS-010
estado: borrador
propietario: Oficina de Operaciones
ultima_actualizacion: 2025-02-21
relacionados: [DOC-INDEX-001, DOC-DEVOPS-021, DOC-DEVOPS-022]
---
# Manual operacional MediaWiki Production Lab

> Conecta este manual con el [índice general](../README.md) y el [inventario de notas operativas](notas/operaciones_y_respaldos.md).

## 1. Introducción y alcance

Describe procedimientos diarios, mantenimientos planificados y respuesta a incidentes para garantizar disponibilidad ≥99.5% del entorno MediaWiki.

## 2. Operaciones diarias

1. Verificar dashboard de Nagios (`http://192.168.56.30/nagios`).
2. Revisar logs críticos via Rsyslog (`/var/log/central/mediawiki-web01/*.log`).
3. Ejecutar `infrastructure/operations/health-check.sh` y registrar resultados en la bitácora.
4. Confirmar que los jobs diferidos (`runJobs.php`) estén procesándose sin rezago.

## 3. Mantenimiento preventivo

| Frecuencia | Actividad |
| --- | --- |
| Semanal | Limpiar cache (`php maintenance/purgeList.php`). |
| Quincenal | Optimizar tablas MariaDB (`mysqlcheck -o wikidb`). |
| Mensual | Revisar espacio en disco y rotación de logs. |
| Trimestral | Actualizar extensiones y aplicar parches de seguridad. |

## 4. Procedimientos de backup

1. Ejecuta `infrastructure/operations/backup-database.sh` y verifica checksum.
2. Ejecuta `infrastructure/operations/backup-files.sh` para `images/`, `extensions/` y `LocalSettings.php`.
3. Transfiere artefactos a almacenamiento externo cifrado.
4. Documenta en la bitácora la fecha, tamaño y ubicación.

## 5. Procedimientos de restore

1. Notifica al líder de Operaciones y Seguridad.
2. Restaura base de datos:
   ```bash
   mysql -u root -p < backups/wikidb-YYYYMMDD.sql
   ```
3. Restaura archivos:
   ```bash
   rsync -av backups/files-YYYYMMDD/ /var/www/html/mediawiki/
   ```
4. Ejecuta `php maintenance/update.php` y valida integridad con `tests/functional/test-mediawiki.sh`.

## 6. Runbooks de incidentes

### 6.1 Wiki no responde

1. Confirmar estado de Apache (`systemctl status apache2`).
2. Revisar `journalctl -u apache2` y aplicar `apache2ctl configtest`.
3. Si falla TLS, renovar certificados y reiniciar servicio.
4. Escalar a Seguridad si se detecta compromiso.

### 6.2 Base de datos saturada

1. Ejecutar `mysqladmin processlist`.
2. Identificar queries lentas y revisar `slow_query_log`.
3. Aplicar plan de contingencia (kill query, añadir índice temporal).
4. Escalar a Arquitectura para tuning permanente.

### 6.3 Ataque de fuerza bruta

1. Revisar `fail2ban-client status sshd`.
2. Incrementar ban temporal (`bantime.increment`).
3. Bloquear IP en firewall y registrar incidente.
4. Coordinar análisis forense con Seguridad.

## 7. Escalamiento y SLAs

| Severidad | SLA respuesta | Escalamiento |
| --- | --- | --- |
| Crítica | 15 min | Líder Operaciones → Seguridad → Dirección |
| Alta | 1 h | Operaciones → Arquitectura |
| Media | 4 h | Operaciones |
| Baja | 8 h | Backlog semanal |

## 8. Calendario de mantenimiento

| Frecuencia | Responsables | Actividades |
| --- | --- | --- |
| Diario | Operaciones | Health check, revisión de logs |
| Semanal | Operaciones + DevOps | Limpieza de cache, verificación de backups |
| Mensual | Operaciones + Seguridad | Auditoría de accesos, revisión de parches |
| Trimestral | Arquitectura + DevOps | Revisión de capacidad y roadmap |

## 9. Procedimientos de cambio

1. Registrar RFC en herramienta de gestión.
2. Ejecutar análisis de impacto y plan de rollback.
3. Implementar en staging con TDD (Red → Green → Refactor).
4. Programar ventana de cambio y comunicar.
5. Ejecutar cambio en producción y documentar resultados.

## 10. Scripts y comandos útiles

- `./infrastructure/operations/health-check.sh`
- `./infrastructure/operations/backup-database.sh`
- `./infrastructure/operations/restore-database.sh`
- `./infrastructure/operations/maintenance-tasks.sh`

## Matriz RACI

| Actividad | R (Responsable) | A (Aprobador) | C (Consultado) | I (Informado) |
| --- | --- | --- | --- | --- |
| Backups diarios | Operaciones | Líder Operaciones | Seguridad | Dirección |
| Actualización de extensiones | DevOps | Arquitectura | Operaciones | Usuarios clave |
| Respuesta a incidentes críticos | Seguridad | Dirección | Operaciones | Toda la organización |

## Referencias cruzadas

- [Guía de instalación](../07_devops/instalacion/guia_instalacion_mediawiki.md)
- [Referencia de configuración](../07_devops/configuracion/referencia_configuracion_mediawiki.md)
- [Hardening y seguridad integral](../07_devops/seguridad/hardening_y_seguridad.md)
