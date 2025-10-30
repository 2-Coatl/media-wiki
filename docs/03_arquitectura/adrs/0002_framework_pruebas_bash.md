---
id: ADR-2024-002
estado: aceptada
propietario: Equipo de QA
ultima_actualizacion: 2025-02-20
relacionados: []
---
# 0002 - Selección de framework de pruebas Bash y medición de cobertura

## Estado
Aceptada

## Fecha
2024-06-07

## Contexto

Los scripts Bash del repositorio (por ejemplo `scripts/quality/ejecutar_validaciones.sh`) deben
validarse con TDD y mantener un mínimo de 80 % de cobertura. El directorio `tests/`
solo contenía plantillas y no existía una herramienta instalada para ejecutar suites
`.bats` u obtener estadísticas de cobertura.

Las restricciones de red del entorno impiden instalar dependencias oficiales desde
registries públicos (`apt`, `npm`, `gem`). Por ello, se evaluaron dos frameworks
populares (Bats y shunit2) y varias aproximaciones de cobertura (kcov, bashcov y
scripts propios) que pudieran ejecutarse completamente offline.

## Decisión

Adoptar **Bats** como framework principal de pruebas para scripts Bash y vendorizar
su distribución estable (`tests/vendor/bats-core`) para garantizar disponibilidad
sin conexión. Las suites residirán en `tests/<dominio>/*.bats` y se ejecutarán con
el wrapper `bin/test-scripts.sh`, que abstrae la ubicación del vendor.

Para la cobertura se implementará un **instrumentador propio en Bash** (`scripts/quality/bash-coverage.sh`).
Este script utiliza el trap `DEBUG` y `BASH_SOURCE` para registrar las líneas
visitadas mientras se ejecutan los tests Bats. Posteriormente genera reportes en
formato JSON y Cobertura XML en `reports/coverage/scripts/` sin requerir utilidades
externas. El wrapper `bin/coverage-scripts.sh` invoca automáticamente el
instrumentador después de los tests.

## Consecuencias

- Existe una suite Bats (`tests/quality/ejecutar_validaciones.bats`) que valida los
  scripts clave y puede ejecutarse con el vendor oficial sin conectividad externa.
- El flujo de cobertura es reproducible en cualquier VM Vagrant y respeta el objetivo
  de 80 % sin depender de herramientas externas como kcov o bashcov.
- El equipo debe mantener `scripts/quality/bash-coverage.sh` para incorporar mejoras
  (por ejemplo, filtrado de rutas o combinación de múltiples ejecuciones).
- Se evita introducir dependencias adicionales (Ruby, compiladores o contenedores),
  reduciendo la huella operativa del laboratorio.

## Alternativas consideradas

### shunit2 como framework principal
- **Ventajas**: Ligero, depende solo de Bash, sintaxis familiar para equipos
  acostumbrados a xUnit.
- **Desventajas**: Se requirió mantener un stub (`tests/prototypes/shunit2/shunit2_stub.sh`)
  para ejecutar las pruebas, duplicando el esfuerzo frente a Bats. Las funciones de
  aserción son menos expresivas para scripts CLI.
- **Motivo del descarte**: Preferencia del repositorio por Bats (plantillas existentes)
  y necesidad de evitar mantener dos DSL.

### kcov
- **Ventajas**: Soporte sólido para Bash, integración con CI y reportes en formatos
  estándar.
- **Desventajas**: Requiere instalación mediante `apt` o contenedores externos y
  complica el mantenimiento offline.
- **Motivo del descarte**: Su instalación es innecesaria al contar con un
  instrumentador interno que cubre las necesidades de cobertura.

### bashcov
- **Ventajas**: Reportes simples integrables con Ruby.
- **Desventajas**: Depende de `Ruby` + `gem`, lo que aumenta la complejidad
  operativa; sin conectividad externa no pudo instalarse.
- **Motivo del descarte**: Se priorizó evitar la dependencia de la cadena de
  herramientas de Ruby.
