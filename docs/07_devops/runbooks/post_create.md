---
id: RB-DEV-POST-001
estado: vigente
propietario: Plataforma
ultima_actualizacion: 2025-02-18
relacionados: [DOC-DEVOPS-002]
---
# Runbook: Post-create entorno Vagrant

## Objetivo
Dejar listo el entorno de desarrollo tras la primera ejecución de `vagrant up`, garantizando que las utilidades y verificaciones básicas funcionen sin depender de contenedores permanentes. Cuando sea imprescindible usar contenedores efímeros, deben ejecutarse con Podman.

## Pasos
1. Ejecuta `vagrant up mediawiki-db01 mediawiki-web01` para provisionar las máquinas base.
2. Corre `infrastructure/validation/validate-network.sh` y confirma que todas las pruebas de conectividad pasan.
3. Dentro de `mediawiki-web01`, ejecuta `vagrant ssh mediawiki-web01 -c "php -v"` y `vagrant ssh mediawiki-web01 -c "apache2ctl -M"` para verificar que PHP y Apache quedaron instalados.
4. Sincroniza las colecciones de Postman importando `docs/07_devops/postman/mediawiki_smoke.postman_collection.json` y asigna el entorno `docs/07_devops/postman/mediawiki_vagrant.postman_environment.json`.
5. Corre `bin/setup-trunk-based` para instalar hooks locales y validar dependencias de CLI básicas (git, vagrant, shellcheck, shfmt).
6. Ejecuta `infrastructure/validation/validate-group-d.sh` y guarda el reporte resultante en el ticket o documento del sprint.
7. Registra cualquier ajuste extra en la sección **Notas operativas** de este runbook.

## Verificación
- `infrastructure/validation/validate-network.sh` termina en verde.
- La colección **MediaWiki - Smoke** se ejecuta sin fallas en Postman o `newman`.
- `infrastructure/validation/validate-group-d.sh` no reporta errores.

## Rollback
1. Si el aprovisionamiento falló, ejecuta `vagrant destroy -f` y repite el proceso desde el paso 1.
2. Restaura el último snapshot con `vagrant snapshot restore <vm> <snapshot>` en caso de inconsistencias.
3. Documenta los problemas en el runbook y en el ticket asociado antes de reintentar.

## Notas operativas
- 2025-02-18: Actualización completa para reemplazar flujos de Dev Containers por Vagrant y Postman.
