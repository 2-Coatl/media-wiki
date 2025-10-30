---
id: DOC-PRESENT-001
estado: borrador
propietario: Oficina de Proyecto
ultima_actualizacion: 2025-02-21
relacionados: [DOC-INDEX-001, DOC-ARQ-002]
---
# Presentación: MediaWiki Production Lab v2.0

> Vínculo al [índice general](../README.md) y a la [arquitectura técnica](../03_arquitectura/arquitectura_general.md).

## Slide 1 · Portada

- Título: "MediaWiki Production Lab v2.0"
- Subtítulo: "Monolito modular listo para producción"
- Logo MediaWiki / Organización

## Slide 2 · Resumen del proyecto

- Objetivo: plataforma colaborativa segura y automatizada.
- Alcance: infraestructura Vagrant, hardening, extensiones internas, testing.
- Stakeholders: Arquitectura, DevOps, Operaciones, Seguridad.

## Slide 3 · Arquitectura

- Diagrama mermaid (copiar desde documentación técnica).
- Tres VMs + redes `public`, `app`, `monitoring`, `host_only`.
- Módulos clave: MediaWiki núcleo + extensiones.

## Slide 4 · Características principales

- Hardening integral (TLS, ModSecurity, Fail2ban).
- Monitoreo Nagios + Rsyslog centralizado.
- Extensiones `EmployeeDirectory` y `ProjectTracker`.
- Automatizaciones de backup y validación.

## Slide 5 · Estrategia de testing

- TDD (Red → Green → Refactor) con cobertura ≥80%.
- Suites: infraestructura, seguridad, funcional, E2E, performance.
- Script maestro `scripts/run-all-tests.sh`.

## Slide 6 · Demo plan

1. Login admin → vista de portada.
2. Creación de página de proyecto con `ProjectTracker`.
3. Consulta de `EmployeeDirectory`.
4. Visualización de alertas en Nagios.

## Slide 7 · Resultados clave

- Score seguridad: 85/100.
- Cobertura tests: 82%.
- Tiempo aprox. de despliegue: 15 min.

## Slide 8 · Próximos pasos

- Preparar replicación de base de datos.
- Integrar pipelines CI/CD externos.
- Investigar contenedores LXC.

## Slide 9 · Contacto

- Arquitectura: arquitectura@example.org
- DevOps: devops@example.org
- Seguridad: seguridad@example.org

## Notas

- Exporta a PDF usando `marp` o `pandoc` si se requiere entrega formal.
- Adjunta la presentación en la carpeta `docs/presentations/entregables/` cuando esté lista.
