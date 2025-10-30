---
id: RB-OPS-VER-001
estado: vigente
propietario: SRE
ultima_actualizacion: 2025-02-15
relacionados: [DOC-DEVOPS-001, RB-DEV-POST-001]
---
# Runbook: Verificar Servicios

## Objetivo
Confirmar que los servicios críticos de la plataforma operan correctamente tras despliegues o incidentes.

## Pasos
1. Ejecuta `docker compose ps` para revisar que todos los contenedores estén en estado `Up`.
2. Corre `curl -f http://localhost:8000/healthz` y `curl -f http://localhost:8000/metrics`.
3. Valida la base de datos con `psql "$DATABASE_URL" -c "SELECT 1;"`.
4. Revisa logs en vivo mediante `docker compose logs -f web` durante dos minutos buscando errores 5xx.
5. Ejecuta `pytest -k smoke --maxfail=1` para confirmar flujos críticos.
6. Notifica al canal `#ops` con un resumen de estatus, tiempos y tickets relacionados.

## Verificación
- Todos los comandos devuelven códigos de salida 0.
- `pytest` finaliza sin fallas ni xfails inesperados.
- No se detectan errores críticos en los logs durante la ventana de observación.

## Rollback
1. Si algún servicio falla, ejecuta `docker compose restart <servicio>` y repite las verificaciones.
2. Si persiste la falla, dispara el runbook de [`reprocesar-etl-fallido`](reprocesar-etl-fallido.md) y escala a guardia SRE.
3. Documenta los hallazgos en el ticket asociado antes de cerrar el incidente.
