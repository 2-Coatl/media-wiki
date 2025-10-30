---
id: DOC-INDEX-001
estado: vigente
propietario: Equipo de Arquitectura
ultima_actualizacion: 2025-02-21
relacionados: []
---
## Panorama
Carpetas numeradas para visión, gobernanza, requisitos, arquitectura, QA y DevOps.

## Convenciones generales
- Todos los nombres de carpetas y archivos usan `snake_case` para evitar enlaces rotos y facilitar la navegación.

Usa 00_vision_y_alcance para estrategia y glosario.
01_gobernanza guarda plantillas, lineamientos y acuerdos transversales.
02_requisitos contiene trazabilidad, catálogo de reglas (`reglas_de_negocio/`) y casos de uso (`casos_de_uso/`).
03_arquitectura consolida ADR numerados en [`adrs/`](03_arquitectura/adrs/README.md), diagramas C4 y contratos de integración.
05_operaciones conserva bitácoras tácticas y acuerdos de soporte.
06_qa documenta estrategia de validación, métricas y casos de prueba.
07_devops centraliza guías, runbooks y automatización: consulta la [guía de entorno Vagrant](07_devops/entorno_vagrant.md), la [validación con Postman](07_devops/postman_validacion.md), las [utilidades auxiliares con Podman](07_devops/podman_utilidades_auxiliares.md) y la [guía operativa de Bats](07_devops/bats_pruebas_automatizadas.md).
Consulta el [plan maestro de tareas](07_devops/plan_tareas_mediawiki.md) para la ejecución integral del roadmap.
Falta documentar arquitectura técnica, planes QA detallados y contratos API.
Cada doc nuevo debe enlazar de vuelta a este índice e incluir front-matter mínimo.
## Próximas etapas

- Preparar `docs/08_testing_integral/testing_integral.md` para consolidar el plan de pruebas end-to-end y resultados del bloque K.
- Documentar `docs/09_documentacion/documentacion_centralizada.md` con lineamientos editoriales y trazabilidad del bloque L.
- Diseñar `docs/10_integracion_final/integracion_final.md` que describa el cierre operativo y entregables del bloque M.

Cada nuevo archivo debe respetar el front-matter descrito arriba, enlazar a este índice y mantener la convención de nombres en `snake_case`.
