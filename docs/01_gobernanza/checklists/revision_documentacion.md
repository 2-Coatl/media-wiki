---
id: DOC-CHK-DOCS-001
estado: vigente
propietario: PMO
ultima_actualizacion: 2025-02-16
relacionados: [DOC-INDEX-001, DOC-PLT-001]
---
# Checklist para nuevas piezas de documentación

Usa esta lista antes de aprobar un PR etiquetado como `docs`.

## Preparación
- [ ] El archivo vive en la carpeta numerada correcta (`00-`, `01-`, `02-`, etc.).
- [ ] El nombre del archivo está en `kebab-case` y describe el contenido.
- [ ] Se utilizó la plantilla correspondiente (ADR, requisito, UC, TC u otra).

## Front-matter
- [ ] Incluye `id`, `estado`, `propietario`, `ultima_actualizacion` y `relacionados`.
- [ ] El identificador sigue el patrón (`ADR-AAAA-XXX`, `RQ-DOM-XXX`, `UC-<area>-XXX`, etc.).
- [ ] Los campos de `relacionados` apuntan a artefactos existentes.

## Integridad
- [ ] El documento enlaza de regreso al índice relevante (`docs/README.md` o subíndice).
- [ ] Se actualizó la [matriz de trazabilidad](../../02_requisitos/trazabilidad.md) si aplica.
- [ ] Hay pasos de validación/rollback cuando se describen runbooks o guías.

## Control
- [ ] El PR incluye referencia al ticket o ADR si la decisión es arquitectónica.
- [ ] Se solicitó revisión cruzada (arquitectura, QA, operaciones según el tema).
- [ ] Se agregó nota en `docs/README.md` cuando se crea una nueva sección mayor.
