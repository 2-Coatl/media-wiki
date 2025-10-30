---
id: ADR-2024-004
estado: aceptada
propietario: Equipo de QA
ultima_actualizacion: 2025-02-20
relacionados: [ADR-2024-002]
---
# 0004 - Estrategia de herramientas de pruebas y cobertura para scripts Bash

## Estado
Aceptada

## Fecha
2024-06-07

## Contexto

El equipo acordó adoptar TDD para todos los scripts Bash con un objetivo mínimo
de 80 % de cobertura. Las restricciones de red impiden instalar dependencias desde
registries públicos, por lo que se requiere un flujo reproducible completamente
offline que ejecute pruebas y calcule cobertura.

## Decisión

1. **Framework de pruebas**: Vendorizar la versión estable de `bats-core`
   (`tests/vendor/bats-core`) para garantizar disponibilidad offline. Las suites se
   ubicarán en `tests/<dominio>/*.bats` y se ejecutarán mediante el wrapper
   `bin/test-scripts.sh`.
2. **Cobertura**: Utilizar el instrumentador interno `scripts/quality/bash-coverage.sh`,
   que intercepta el trap `DEBUG` para registrar líneas ejecutadas y genera reportes
   Cobertura XML y JSON en `reports/coverage/scripts/`. El comando
   `bin/coverage-scripts.sh` ejecuta primero las suites Bats y luego el
   instrumentador para consolidar métricas.
3. **Política de aceptación**: Todo cambio en scripts debe incluir suites Bats y
   demostrar al menos 80 % de cobertura por módulo. Las pipelines de CI consumirán
   los reportes generados por el instrumentador y fallarán si el umbral se incumple.
4. **Mantenimiento**: Documentar en `docs/05_operaciones/notas/testing_bash.md` el
   procedimiento para actualizar el vendor de Bats, regenerar reportes y combinar
   múltiples ejecuciones cuando existan suites segmentadas.

## Consecuencias

- El repositorio incluye todas las dependencias necesarias para ejecutar pruebas y
  medir cobertura sin acceso a Internet.
- La cobertura se calcula de forma consistente en local y CI sin depender de
  herramientas externas como kcov o bashcov.
- El wrapper de pruebas estandariza la ejecución y reduce la curva de aprendizaje
  para contribuyentes.
- Mantener el instrumentador requiere ajustar filtros de rutas o exclusiones cuando
  se añadan nuevos directorios de scripts.

## Alternativas consideradas

### Instrumentar cobertura con kcov
- **Ventajas**: Reportes listos en HTML y Cobertura XML.
- **Desventajas**: Requiere paquetes externos o contenedores, lo que contradice la
  restricción de operar offline.
- **Motivo del descarte**: El instrumentador interno cubre la necesidad sin depender
  de software adicional.

### Utilizar bashcov (Ruby)
- **Ventajas**: Flujo conocido en la comunidad de Bash.
- **Desventajas**: Depende de Ruby y gemas externas que no pueden descargarse en el
  entorno actual.
- **Motivo del descarte**: Se priorizó una solución 100 % Bash.

## Próximos pasos

1. Añadir `bats-core` vendorizado y actualizar los wrappers de ejecución.
2. Incorporar `scripts/quality/bash-coverage.sh` y `bin/coverage-scripts.sh` al flujo
   de desarrollo.
3. Configurar la pipeline de CI para consumir ambos wrappers usando Vagrant.
