---
id: ADR-2024-002
estado: aceptada
propietario: Equipo de QA
ultima_actualizacion: 2025-02-15
relacionados: []
---
# 0002 - Selección de framework de pruebas Bash y medición de cobertura

## Estado
Aceptada

## Contexto

Los scripts Bash del repositorio (por ejemplo `scripts/quality/ejecutar_validaciones.sh`) requieren automatizar
su validación siguiendo la metodología TDD con un mínimo de 80 % de cobertura. El directorio `tests/`
contenía únicamente plantillas y no existía una herramienta instalada para ejecutar suites `.bats`
o equivalentes. El entorno actual carece de acceso a paquetes externos (`apt`, `npm` y gemas) lo que impide
instalar dependencias oficiales como `bats-core`, `shunit2`, `kcov` o `bashcov` (ver errores 403 de `apt-get`).

Se evaluaron dos frameworks de pruebas populares (Bats y shunit2) y dos herramientas de cobertura (kcov y bashcov)
mediante prototipos ligeros que pudieran ejecutarse offline.

## Decisión

Adoptar **Bats** como framework principal de pruebas para scripts Bash y posponer la integración de una herramienta
de cobertura dedicada hasta que el entorno permita instalar dependencias externas. Para mantener el flujo TDD
mientras tanto, se documentó un stub ligero (`tests/prototypes/bats/bats_stub.sh`) que transpila los archivos
`.bats` y permite ejecutar los prototipos, con la meta de reemplazarlo por la distribución oficial de `bats-core`
cuando el acceso a paquetes esté disponible.

Las métricas de cobertura se implementarán en una iteración futura; se propone **kcov** como opción preferente
por su madurez y soporte nativo para Bash en entornos Linux. `bashcov` requiere la cadena de herramientas de Ruby,
lo que incrementa la huella operacional del repositorio.

## Consecuencias

- Existe una suite Bats (`tests/quality/ejecutar_validaciones.bats`) que valida el script `scripts/quality/ejecutar_validaciones.sh`
y puede ejecutarse con el stub hasta contar con `bats-core`.
- Se dispone de un prototipo equivalente con shunit2 (`tests/prototypes/shunit2/test_ejecutar_validaciones.sh`) que demuestra
la compatibilidad pero introduce un segundo DSL y mantenimiento adicional, motivo por el que se descarta como opción
principal.
- La falta de cobertura automática se mitiga temporalmente con ejecuciones manuales y el compromiso de integrar `kcov`
cuando el entorno lo permita.
- El equipo debe monitorizar la disponibilidad de `apt`/`npm` para instalar las dependencias oficiales y reemplazar los stubs.

## Alternativas consideradas

### shunit2 como framework principal
- **Ventajas**: Ligero, depende solo de Bash, sintaxis familiar para equipos acostumbrados a xUnit.
- **Desventajas**: Se requirió mantener un stub (`tests/prototypes/shunit2/shunit2_stub.sh`) para ejecutar las pruebas, duplicando
esfuerzo frente a Bats. Las funciones de aserción son menos expresivas que las de Bats para scripts CLI.
- **Motivo del descarte**: Preferencia del repositorio por Bats (plantillas existentes) y necesidad de evitar mantener dos DSL.

### bashcov para cobertura
- **Ventajas**: Reportes simples integrables con Ruby.
- **Desventajas**: Requiere `Ruby` + `gem` en el entorno, lo que aumenta complejidad operativa; sin conectividad externa no pudo
instalarse.
- **Motivo del descarte**: Dependencia adicional de Ruby y bloqueo por falta de acceso a registries.

### kcov diferido
- **Ventajas**: Soporte sólido para Bash, integración con CI y reportes en formatos estándar.
- **Desventajas**: Instalación fallida por restricciones de red (`apt-get` sin firmas válidas).
- **Motivo de la elección diferida**: Se adoptará cuando el entorno permita instalar paquetes.
