---
id: TPL-TC-001
estado: vigente
propietario: QA
ultima_actualizacion: 2025-02-15
relacionados: [DOC-PLT-001]
---
# Plantilla: Caso de Prueba

```markdown
---
id: TC-<DOMINIO>-XXX
titulo: "<verbo objeto>"
objetivo: |
  <Qué validamos>
prioridad: alta
criticidad: bloqueante
precondiciones:
  - <estado inicial>
datos_prueba:
  - nombre: <dato>
    valor: <valor>
    fuente: <origen>
ambiente: staging
trazabilidad:
  requisitos: [RQ-ANL-001]
  casos_uso: [UC-DASH-003]
  reglas_negocio: [RN-015]
---

## Pasos
| Paso | Acción | Resultado esperado |
|------|--------|--------------------|
| 1 | <Acción> | <Resultado> |
| 2 | <Acción> | <Resultado> |

## Validaciones
- [ ] Logs sin errores
- [ ] Respuesta HTTP 200
- [ ] Datos persistidos en tabla `<tabla>`

## Evidencias
- Screenshot: `<ruta>`
- Archivo: `<ruta>`
```

Actualiza `ambiente` y `datos_prueba` según corresponda al ciclo de QA.
