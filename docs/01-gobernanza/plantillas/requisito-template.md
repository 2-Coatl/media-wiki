---
id: TPL-RQ-001
estado: vigente
propietario: Oficina de Producto
ultima_actualizacion: 2025-02-15
relacionados: [DOC-PLT-001]
---
# Plantilla: Requisito Funcional

El bloque YAML define la estructura mínima para cada nuevo RQ.

```yaml
---
id: RQ-<DOMINIO>-XXX
titulo: "<resultado esperado>"
descripcion: |
  <Detalle completo del requerimiento, contexto y usuarios>
rol: <actor principal>
necesidad: <necesidad específica>
beneficio: <impacto esperado>
criterios_aceptacion:
  - Dado <condición> cuando <acción> entonces <resultado>
  - Dado <condición alternativa> cuando <acción> entonces <resultado>
reglas_negocio: [RN-015, RN-028]
trazabilidad:
  casos_uso: [UC-DASH-003]
  casos_prueba: [TC-USR-010]
  decisiones: [ADR-2025-001]
estado: propuesto # opciones: propuesto|en_validacion|aprobado
propietario: <responsable de negocio>
fecha: AAAA-MM-DD
version: 1.0
historial:
  - fecha: AAAA-MM-DD
    cambio: <Descripción breve>
---
```

## Checklist de captura
- Asegura que el `DOMINIO` corresponde al área (ANL, SEG, INT, etc.).
- Describe criterios de aceptación en formato BDD.
- Incluye vínculos de trazabilidad desde la creación.
- Incrementa `version` y agrega una entrada al `historial` por cada ajuste relevante.
