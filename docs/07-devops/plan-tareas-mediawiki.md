---
id: DOC-DEVOPS-PLAN-001
estado: vigente
propietario: PMO Técnica
ultima_actualizacion: 2025-02-18
relacionados: [DOC-INDEX-001]
---
# Plan maestro de tareas - MediaWiki Production Lab v2.0

[Volver al índice de documentación](../README.md)

Este plan consolida todas las tareas necesarias para ejecutar el roadmap del MediaWiki Production Lab v2.0. Cada grupo mantiene la dependencia indicada y debe seguir la metodología **TDD** (Red → Green → Refactor) con cobertura mínima del 80 %. Incluye hitos de documentación y creación de ADR cuando aplique.

## Convenciones generales

- **Metodología:** Iterativo e incremental con énfasis en TDD.
- **Commits:** formato Conventional Commits.
- **Documentación:** cada decisión relevante en ADR (directorio `docs/03-arquitectura/adrs/`).
- **Validaciones:** scripts en `scripts/validation/` y pruebas Bats/ PHPUnit según el artefacto.
- **Snapshots:** capturar puntos de control de Vagrant tras cada grupo mayor.
- **Arquitectura:** mantener un **monolito modular**; queda descartado adoptar Kubernetes u orquestadores
  equivalentes. Evitar “interfaces gordas” descomponiendo responsabilidades siguiendo el principio de
  segregación de interfaces.
- **Contenedores:** solo se utilizará **Podman** para casos puntuales (p. ej. herramientas de cobertura);
  Docker no forma parte del stack soportado.

## Grupo A – Fundamentos del proyecto

- [ ] Inicializar repositorio Git, ramas `main` y `develop`, y configuración de usuario.
- [ ] Crear README, LICENSE (GPL-2.0-or-later), `.gitignore`, `.editorconfig` y hooks básicos.
- [ ] Generar estructura de directorios (`bin/`, `config/`, `docs/`, `scripts/`, `tests/`, `vagrant/`).
- [ ] Definir variables globales (`config/variables.sh`) con comentarios y `readonly`.
- [ ] Publicar documentación base (`docs/00-vision-y-alcance`, `docs/01-gobernanza`, etc.).
- [ ] Implementar `scripts/validation/validate-phase-a.sh` con chequeos de estructura y documentación.
- [ ] Registrar tag `group-a-complete` tras validación exitosa.

## Grupo B – Sistema de utilidades

- [ ] Implementar `infrastructure/utils/loader.sh` con protección de carga múltiple.
- [ ] Añadir `logging.sh`, `validation.sh`, `service.sh`, `network.sh`, `database.sh` con pruebas unitarias Bats.
- [ ] Configurar logs centralizados (`/var/log/mediawiki-setup.log`).
- [ ] Documentar uso en `docs/06-qa/utilities.md`.
- [ ] Crear `scripts/validation/validate-group-b.sh` y suite `tests/unit/test-all-utils.bats`.
- [ ] Emitir tag `group-b-complete` tras 100 % de pruebas verdes.

## Grupo C – Infraestructura Vagrant

- [ ] Redactar `Vagrantfile` para web y db (y futura VM de monitoreo) con redes privadas y bridged.
- [ ] Escribir provisioners base y específicos en `vagrant/provisioners/` usando utilidades del Grupo B.
- [ ] Levantar VMs con `vagrant up` y verificar `hostname`, `/etc/hosts` y directorios clave.
- [ ] Desarrollar `scripts/validation/validate-network.sh` y `validate-group-c.sh`.
- [ ] Documentar infraestructura en `docs/02-requisitos` y `docs/03-arquitectura`.
- [ ] Crear snapshot `baseline` y tag `group-c-complete`.

## Grupo D – Instalación de software base

- [ ] Automatizar instalación de PHP, Apache y MariaDB (scripts en `scripts/installation/`).
- [ ] Ajustar configuraciones (`php.ini`, módulos Apache, `mariadb.conf.d`).
- [ ] Implementar `scripts/validation/validate-{php,apache,mariadb}.sh` y pruebas de integración.
- [ ] Desplegar monitoreo base (Nagios) y logging central (rsyslog) opcional o preparar host dedicado.
- [ ] Configurar clientes rsyslog y validar flujo de logs.
- [ ] Documentar en `docs/05-operaciones` y etiquetar `group-d-complete`; snapshot `post-software-installation`.

## Grupo E – Instalación de MediaWiki

- [ ] Descargar y verificar MediaWiki 1.43 LTS (`download-mediawiki.sh`).
- [ ] Extraer y mover archivos a `/var/www/html/mediawiki` con permisos adecuados (`extract-mediawiki.sh`).
- [ ] Configurar VirtualHost de Apache (`config/apache/mediawiki-vhost.conf`, script de despliegue).
- [ ] Ejecutar instalador web, almacenar `LocalSettings.php` en `config/mediawiki/` y aplicar hardening.
- [ ] Correr scripts post-instalación (`maintenance/update.php`, cron de `runJobs.php`, habilitar extensiones básicas).
- [ ] Validar con `scripts/validation/validate-group-e.sh`, pruebas funcionales y documentar en `docs/04-mediawiki-installation.md`.
- [ ] Crear snapshot `post-mediawiki-installation` y tag `group-e-complete`.

## Grupo F – Configuración de servicios

- [ ] Afinar Apache (HTTP/2 opcional, `mpm_prefork`), PHP (opcache) y MariaDB (buffers, usuarios adicionales).
- [ ] Automatizar orquestación en `scripts/configuration/` y `scripts/deploy/desplegar.sh`.
- [ ] Configurar tareas programadas (jobs MediaWiki, limpieza de logs, backups rápidos).
- [ ] Documentar runbooks de despliegue y rollback en `docs/07-devops/runbooks/`.
- [ ] Validar cada servicio tras aplicar cambios y registrar resultados.

## Grupo G – Seguridad del sistema

- [ ] Ejecutar scripts de hardening existentes (`harden-ssh.sh`, `install-fail2ban.sh`, `firewall-*.sh`, `apache-ssl.sh`).
- [ ] Emitir o renovar certificados TLS, configurar headers de seguridad y revisar permisos.
- [ ] Documentar controles aplicados, riesgos y excepciones en ADRs y `docs/03-arquitectura/adrs/`.
- [ ] Crear pruebas de seguridad (`tests/security/`) y reportes de escaneo (nmap, lynis).
- [ ] Actualizar checklist de auditoría en `docs/05-operaciones`.

## Grupo H – Monitoreo y logging

- [ ] Desplegar servidor de monitoreo (Nagios/Zabbix/Prometheus) o extender host dedicado.
- [ ] Centralizar logs (`/var/log/remote/<host>/`) y configurar alertas (email/Slack).
- [ ] Crear dashboards y runbooks de incidentes (`docs/05-operaciones/runbooks/`).
- [ ] Validar alertas generando fallos controlados.

## Grupo I – Operaciones y backups

- [ ] Definir política de backups (BD, `LocalSettings.php`, `images/`) con retenciones y encriptación.
- [ ] Implementar scripts de respaldo y restauración en `scripts/operations/`.
- [ ] Documentar runbooks de DRP, RTO/RPO y ejercicios de recuperación.
- [ ] Automatizar pruebas de restauración periódicas.

## Grupo J – Desarrollo de extensiones

- [ ] Crear plantilla de extensión y ejemplos en `development/extensions/`.
- [ ] Configurar pipelines de QA (lint, PHPUnit, QUnit) integrados a hooks.
- [ ] Documentar guías de estilo y publicación en `docs/03-arquitectura` y `docs/06-qa`.
- [ ] Asegurar entorno dev/prod consistente con carpetas sincronizadas.

## Grupo K – Testing integral

- [ ] Consolidar estrategia QA en `docs/06-qa/estrategia-qa.md` (matriz de pruebas y cobertura ≥ 80 %).
- [ ] Automatizar suites unitarias, integrales, seguridad y performance.
- [ ] Integrar métricas de cobertura y reportes en pipeline CI.
- [ ] Definir criterios de salida para releases y checklist de aprobación QA.

## Grupo L – Documentación

- [ ] Mantener README, CHANGELOG y glosario actualizados tras cada grupo.
- [ ] Completar diagramas C4 y contratos API pendientes en `docs/03-arquitectura`.
- [ ] Redactar manual de administración y guía de usuario final del wiki.
- [ ] Revisar consistencia lingüística y enlaces cruzados; registrar actualizaciones en índice.

## Grupo M – Integración final

- [ ] Ejecutar despliegue completo en entorno limpio (`bin/setup-project`, `scripts/deploy/desplegar.sh`).
- [ ] Correr smoke tests, validaciones de seguridad y monitoreo integrados.
- [ ] Generar release notes, actualizar CHANGELOG y crear tag final.
- [ ] Capturar snapshot final y preparar plan de soporte post-lanzamiento.

## Seguimiento

- Registrar avance de cada tarea en la herramienta de gestión (Jira/Trello) enlazando commits y ADRs.
- Revisar semanalmente los pendientes críticos en comité de gobierno técnico.
- Actualizar este documento cuando se aprueben cambios al roadmap.

