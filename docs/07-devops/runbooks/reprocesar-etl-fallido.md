---
id: RB-DATA-ETL-001
estado: vigente
propietario: Equipo de Datos
ultima_actualizacion: 2025-02-15
relacionados: [DOC-DEVOPS-001, RB-OPS-VER-001]
---
# Runbook: Reprocesar ETL Fallido

## Objetivo
Recuperar cargas ETL que fallaron y restaurar la consistencia de datos sin duplicados.

## Prerrequisitos
- Acceso al cluster con permisos de ejecución en `etl-runner`.
- Identificador del lote fallido (`job_id`).
- Último backup válido (`backups/<fecha>_etl.sql`).

## Pasos
1. Congela nuevos disparadores ejecutando `kubectl scale deployment/etl-scheduler --replicas=0`.
2. Consulta la causa raíz con `kubectl logs job/<job_id> --tail=200` y guarda el log en el ticket.
3. Limpia artefactos parciales ejecutando `python scripts/etl/cleanup.py --job-id <job_id>`.
4. Lanza el reproceso con `python scripts/etl/run.py --job-id <job_id> --reprocess`.
5. Monitorea progreso usando `kubectl logs -f job/<job_id>-retry` hasta ver `PROCESS_COMPLETED`.
6. Ejecuta validación de integridad: `python scripts/etl/validate.py --job-id <job_id>`.
7. Documenta hallazgos y adjunta resultados del validador en el ticket.
8. Reactiva el scheduler con `kubectl scale deployment/etl-scheduler --replicas=1`.

## Verificación
- El comando de validación devuelve código 0 y reporte sin errores.
- Los conteos en `reports.ingestas_diarias` coinciden con la referencia en el ticket.
- `docker compose ps` muestra `etl-scheduler` en estado `Up`.

## Rollback
1. Si el reproceso vuelve a fallar, deja el scheduler en 0 y ejecuta `python scripts/etl/cleanup.py --job-id <job_id> --force`.
2. Restaura el último respaldo ejecutando `psql "$REPORTING_URL" -f backups/<fecha>_etl.sql`.
3. Crea un ADR con la evidencia si se decide cambiar el flujo operativo.
4. Escala al gerente de datos si se requieren reprocesos manuales adicionales.
