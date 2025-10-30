---
id: DOC-PLT-001
estado: vigente
propietario: PMO
ultima_actualizacion: 2025-02-16
relacionados: [DOC-INDEX-001]
---
# Plantillas Express

Centraliza aquí los formatos oficiales para decisiones, requisitos y artefactos de trazabilidad. Copia la sección requerida y reemplaza los valores marcados con `<>`.

## Índice de plantillas
- [ADR](plantillas/adr-template.md)
- [Requisito funcional](plantillas/requisito-template.md)
- [Caso de uso completo](plantillas/caso-uso-template.md)
- [Caso de prueba](plantillas/caso-prueba-template.md)
- [Checklist de verificación](checklists/revision-documentacion.md)

## Bloques rápidos

### ADR inline
```yaml
---
id: ADR-2025-XXX
titulo: "<decisión>"
contexto: <resumen>
decision: <alternativa seleccionada>
consecuencias: <impactos>
estado: propuesta
propietario: <responsable>
fecha: AAAA-MM-DD
relacionados: [RQ-ANL-001, UC-DASH-003]
---
```

### Requisito funcional inline
```yaml
---
id: RQ-<DOMINIO>-XXX
titulo: "<resultado esperado>"
descripcion: <detalle>
rol: <actor>
necesidad: <necesidad>
beneficio: <valor>
criterios_aceptacion:
  - Dado <condicion> cuando <accion> entonces <resultado>
reglas_negocio: [RN-015]
trazabilidad: [UC-DASH-003, TC-USR-010]
estado: propuesto
propietario: <responsable>
fecha: AAAA-MM-DD
---
```

### Uso recomendado
1. Crea el archivo en la carpeta del dominio (requisitos, arquitectura, QA, etc.).
2. Pega la plantilla completa y actualiza los metadatos antes de agregar contenido.
3. Registra la relación en `docs/02-requisitos/trazabilidad.md` para mantener cobertura.
4. Adjunta evidencia o enlaces desde el documento origen hacia la plantilla utilizada.
5. Solicita revisión cruzada (producto, QA, arquitectura) antes de mover el estado a `aprobado`.
