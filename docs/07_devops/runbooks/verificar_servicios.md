---
id: RB-OPS-VER-001
estado: vigente
propietario: SRE
ultima_actualizacion: 2025-02-18
relacionados: [DOC-DEVOPS-002, RB-DEV-POST-001]
---
# Runbook: Verificar Servicios

## Objetivo
Confirmar que los servicios críticos de la plataforma operan correctamente tras despliegues o incidentes en el entorno basado en Vagrant.

## Pasos
1. Ejecuta `vagrant status` desde la raíz del repositorio y asegúrate de que `mediawiki-web01` y `mediawiki-db01` se encuentran en estado `running`.
2. Valida el servidor web con `vagrant ssh mediawiki-web01 -c "sudo systemctl is-active apache2"` y confirma que devuelve `active`.
3. Comprueba la API ejecutando `vagrant ssh mediawiki-web01 -c "curl -fsS http://localhost/api.php?action=query&meta=siteinfo&format=json"`.
4. Ejecuta la colección de Postman **MediaWiki - Smoke** (`docs/07_devops/postman/mediawiki_smoke.postman_collection.json`) usando el entorno `MediaWiki Vagrant`. Verifica que todas las solicitudes devuelven código 200.
5. Valida la base de datos con `vagrant ssh mediawiki-db01 -c "mysql -uwikiuser -p$DB_PASSWORD -e 'SELECT 1;'"` (obtén la contraseña desde `infrastructure/config/variables.sh`).
6. Revisa los logs de Apache con `vagrant ssh mediawiki-web01 -c "sudo journalctl -u apache2 --since '-10 minutes'"` y confirma que no hay errores 5xx.
7. Ejecuta `infrastructure/validation/validate-group-d.sh` para correr las verificaciones automatizadas del stack base.
8. Notifica al canal `#ops` con un resumen de estado, tiempos y tickets relacionados.

## Verificación
- Todos los comandos devuelven código de salida 0.
- La colección de Postman finaliza sin fallas.
- No se detectan errores críticos en los logs revisados.

## Rollback
1. Si un servicio falla, corre `vagrant ssh <vm> -c "sudo systemctl restart <servicio>"` y repite las verificaciones.
2. Si persiste la falla en la base de datos, restaura el último snapshot con `vagrant snapshot restore mediawiki-db01 <snapshot>`.
3. Documenta los hallazgos en el ticket asociado antes de cerrar el incidente.
