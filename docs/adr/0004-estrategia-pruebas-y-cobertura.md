---
id: ADR-2024-004
estado: aceptada
propietario: Equipo de QA
ultima_actualizacion: 2025-02-15
relacionados: [ADR-2024-002]
---
# 0004 - Estrategia de herramientas de pruebas y cobertura para scripts Bash

## Estado
Aceptada

## Fecha
2024-06-07

## Contexto

El equipo acordó adoptar TDD para todos los scripts Bash con un objetivo mínimo de 80 % de cobertura.
Las restricciones de red del entorno impiden instalar dependencias desde registries públicos, lo que
complica el uso directo de `bats-core`, `kcov` u otras herramientas estándar. A pesar de esas limitaciones,
se requiere un flujo repetible que permita ejecutar pruebas de forma local y en CI, midiendo cobertura cuando
sea factible.

## Decisión

1. **Framework de pruebas**: Vendorizar la versión estable de `bats-core` dentro del repositorio
   (`tests/vendor/bats-core`) para garantizar disponibilidad offline. Las suites se ubicarán en `tests/<dominio>/*.bats`
   y deberán ejecutarse mediante el wrapper `bin/test-scripts.sh` que abstrae la ruta del vendor.
2. **Cobertura**: Construir una imagen Docker declarada en `infrastructure/docker/coverage/Dockerfile`
   que empaquete `kcov` desde fuentes. El comando `bin/coverage-scripts.sh` ejecutará las suites Bats dentro de
   dicha imagen y publicará reportes en `reports/coverage/scripts/` en formato HTML y cobertura Cobertura XML.
3. **Política de aceptación**: Todo cambio en scripts debe acompañarse de una suite Bats y demostrar al menos
   80 % de cobertura por módulo. Las pipelines de CI bloquearán merges cuando la cobertura caiga por debajo del
   umbral definido.
4. **Mantenimiento**: Documentar en `docs/05-operaciones/notas/testing-bash.md` el procedimiento para actualizar la versión
   vendorizada de `bats-core` y los pasos para reconstruir la imagen de `kcov` cuando exista una nueva liberación.

## Consecuencias

- **Positivas**
  - El repositorio incluye todas las dependencias necesarias para ejecutar pruebas sin acceso a Internet.
  - La cobertura se calcula de forma consistente en local y CI, habilitando la métrica objetivo del 80 %.
  - El wrapper de pruebas estandariza la ejecución y reduce la curva de aprendizaje para contribuyentes.
- **Negativas**
  - Vendorizar `bats-core` incrementa el tamaño del repositorio y requiere actualizaciones manuales.
  - Construir la imagen con `kcov` puede aumentar el tiempo de las pipelines de CI y necesita almacenamiento
    adicional para los reportes.

## Alternativas consideradas

### Mantener stubs locales para Bats
- **Ventajas**: Configuración ligera sin dependencias externas.
- **Desventajas**: Falta de paridad con la herramienta oficial y ausencia de características recientes.
- **Motivo del descarte**: La vendorización de `bats-core` ofrece la versión completa sin depender de la red.

### `bashcov` + Ruby
- **Ventajas**: Reportes sencillos.
- **Desventajas**: Requiere la cadena de herramientas de Ruby y gems adicionales que no están disponibles offline.
- **Motivo del descarte**: Incremento de superficie operativa y dependencia de registries.

### Sin cobertura obligatoria en CI
- **Ventajas**: Pipeline más corta.
- **Desventajas**: No se cumple el estándar de calidad de 80 % y se pierde visibilidad de regresiones.
- **Motivo del descarte**: La cobertura es un requisito explícito de la metodología definida por el equipo.

## Próximos pasos

1. Añadir `bats-core` vendorizado y actualizar los wrappers de ejecución.
2. Construir y versionar la imagen de cobertura en el repositorio.
3. Configurar la pipeline de CI para consumir `bin/test-scripts.sh` y `bin/coverage-scripts.sh`.
