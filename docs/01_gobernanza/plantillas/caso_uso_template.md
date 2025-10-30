---
id: TPL-UC-001
estado: vigente
propietario: Oficina de Producto
ultima_actualizacion: 2025-02-15
relacionados: [DOC-PLT-001]
---
# Plantilla: Especificación de Caso de Uso Completo

Utiliza el siguiente esquema para documentar casos de uso completos en formato de dos columnas.

```markdown
---
id: UC-<DOMINIO>-XXX
titulo: "<Accion Objeto>"
actor_principal: <rol>
actores_secundarios: [<rol>, <sistema>]
descripcion: |
  <Resumen del objetivo y valor entregado>
desencadenador: <evento que inicia el caso>
precondiciones:
  - <estado previo 1>
  - <estado previo 2>
postcondiciones:
  - <resultado esperado>
frecuencia: diaria
prioridad: alta
reglas_negocio: [RN-015]
requisitos_especiales:
  - tipo: seguridad
    descripcion: <detalle>
datos_clave:
  - nombre: <dato>
    fuente: <sistema>
---

## Flujo principal
| Paso | Actor | Acción |
|------|-------|--------|
| 1 | <Actor> | <Descripción> |
| 2 | Sistema | <Respuesta> |

## Flujos alternos
- **A1 - <Condición>**
  1. <paso>
  2. <paso>

## Excepciones
- **E1 - <Condición crítica>**
  1. <paso>

## Métricas de éxito
- <KPI 1>
- <KPI 2>
```

Mantén los IDs y referencias alineados con la matriz de trazabilidad.
