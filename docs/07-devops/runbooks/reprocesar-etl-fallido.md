---
id: RB-DATA-ETL-001
estado: vigente
propietario: Equipo de Datos
ultima_actualizacion: 2025-02-18
relacionados: [DOC-DEVOPS-002, RB-OPS-VER-001]
---
# Runbook: Reprocesar ETL Fallido

## Objetivo
Recuperar cargas ETL que fallaron y restaurar la consistencia de datos sin duplicados en el entorno gestionado con Vagrant.

## Prerrequisitos
- Acceso a la VM `mediawiki-mgmt01` (o al host que orquesta la ETL) mediante `vagrant ssh`.
- Identificador del lote fallido (`job_id`).
- Último backup válido (`backups/<fecha>_etl.sql`).
- Variables de entorno configuradas en `config/variables.sh`.

## Pasos
1. Suspende programaciones automáticas ejecutando `vagrant ssh mediawiki-mgmt01 -c "sudo systemctl stop etl-scheduler.service"`.
2. Consulta la causa raíz con `vagrant ssh mediawiki-mgmt01 -c "sudo journalctl -u etl-runner.service --since '-15 minutes'"` y adjunta el log al ticket.
3. Limpia artefactos parciales con `vagrant ssh mediawiki-mgmt01 -c "/opt/etl/bin/cleanup.sh --job-id <job_id>"`.
4. Lanza el reproceso usando `vagrant ssh mediawiki-mgmt01 -c "/opt/etl/bin/run.sh --job-id <job_id> --reprocess"`.
5. Monitorea el avance con `vagrant ssh mediawiki-mgmt01 -c "sudo journalctl -u etl-runner.service -f"` hasta ver `PROCESS_COMPLETED`.
6. Ejecuta la validación de integridad: `vagrant ssh mediawiki-mgmt01 -c "/opt/etl/bin/validate.sh --job-id <job_id>"`.
7. Documenta hallazgos y adjunta resultados del validador en el ticket.
8. Reactiva el scheduler con `vagrant ssh mediawiki-mgmt01 -c "sudo systemctl start etl-scheduler.service"`.

## Verificación
- El comando de validación devuelve código 0 y un reporte sin errores.
- Los conteos en `reports.ingestas_diarias` coinciden con la referencia en el ticket (valídalo con `mysql` o la herramienta analítica correspondiente).
- `vagrant ssh mediawiki-mgmt01 -c "sudo systemctl is-active etl-scheduler.service"` retorna `active`.

## Rollback
1. Si el reproceso vuelve a fallar, mantén el scheduler detenido y ejecuta `vagrant ssh mediawiki-mgmt01 -c "/opt/etl/bin/cleanup.sh --job-id <job_id> --force"`.
2. Restaura el último respaldo con `vagrant ssh mediawiki-db01 -c "mysql -uroot -p$DB_ROOT_PASSWORD < /vagrant/backups/<fecha>_etl.sql"`.
3. Registra un ADR con la evidencia si se decide cambiar el flujo operativo.
4. Escala al gerente de datos si se requieren reprocesos manuales adicionales.
