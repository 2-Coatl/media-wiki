---
id: TPL-ADR-001
estado: vigente
propietario: PMO
ultima_actualizacion: 2025-02-15
relacionados: [DOC-PLT-001]
---
# Plantilla: Architecture Decision Record

Usa este bloque como base para nuevos ADR. Copia el contenido del bloque YAML y actualiza cada campo.

```yaml
---
id: ADR-2025-XXX
titulo: "<decisión resumida>"
contexto: |
  <Antecedentes, problema y fuerzas en conflicto>
decision: |
  <Descripción de la opción elegida y justificación>
consecuencias: |
  <Impactos positivos, riesgos y planes de mitigación>
estado: propuesta # opciones: propuesta|aprobada|rechazada
propietario: <nombre del responsable>
fecha: AAAA-MM-DD
relacionados:
  requisitos: [RQ-ANL-001]
  casos_uso: [UC-DASH-003]
  reglas_negocio: [RN-015]
  tickets: [JIRA-123]
seguimiento:
  proximos_pasos:
    - <acción 1>
    - <acción 2>
  fecha_revision: AAAA-MM-DD
---
```

## Guía rápida
- **Contexto**: explica el problema y criterios evaluados.
- **Decisión**: detalla la alternativa seleccionada y por qué.
- **Consecuencias**: incluye beneficios, riesgos y tareas pendientes.
- Actualiza `fecha_revision` cada que se revalide la decisión.
