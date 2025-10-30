---
id: ADR-2024-005
estado: aceptada
propietario: Equipo de Arquitectura
ultima_actualizacion: 2025-02-15
relacionados: [ADR-2024-002, ADR-2024-003, ADR-2024-004]
---
# 0005 - Política para registrar ADRs ante cambios relevantes

## Estado
Aceptada

## Fecha
2024-06-07

## Contexto

En ciclos anteriores algunas decisiones significativas (por ejemplo, endurecimiento de seguridad o cambios
en pipelines de despliegue) se implementaron sin una documentación formal. Esto dificulta la trazabilidad
de por qué se eligió una tecnología o configuración específica y afecta la transferencia de conocimiento
entre equipos. Dado que el proyecto sigue un monolito modular con múltiples dominios (infraestructura,
seguridad, calidad) es imprescindible contar con un proceso claro para capturar decisiones.

## Decisión

Establecer la siguiente política obligatoria:

1. Todo cambio que afecte la arquitectura, seguridad, herramientas de pruebas, procesos de despliegue o
   dependencias críticas debe acompañarse de un ADR numerado en `docs/adr/`.
2. El ADR debe describir contexto, alternativas, riesgos y plan de implementación, siguiendo el formato
   utilizado en los registros 0001-0004.
3. Los cambios no podrán marcarse como listos para revisión hasta que el ADR correspondiente esté en estado
   **Propuesta** o **Aceptada**.
4. Las revisiones de seguridad (firewalls, hardening, autenticación) requieren un ADR dedicado que documente
   controles, responsables y fecha de vigencia.
5. Se debe mantener un índice actualizado en `docs/adr/README.md` (o documento equivalente) que liste los ADRs
   aprobados para facilitar su consulta.

## Consecuencias

- **Positivas**
  - Incrementa la transparencia y trazabilidad de decisiones clave, facilitando auditorías y onboarding.
  - Reduce el riesgo de decisiones contradictorias al contar con un repositorio histórico consultable.
  - Alinea al equipo con las buenas prácticas de arquitectura y cumplimiento regulatorio.
- **Negativas**
  - Añade carga administrativa al flujo de desarrollo, especialmente en iteraciones rápidas.
  - Requiere disciplina para mantener el índice y estados de los ADRs actualizados.

## Próximos pasos

1. Crear o actualizar `docs/adr/README.md` con el índice de ADRs existentes.
2. Incorporar la verificación de ADRs en las listas de comprobación de PR y plantillas de issue.
3. Capacitar al equipo sobre la estructura esperada y ejemplos de ADR bien documentados.
