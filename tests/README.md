# Guía de pruebas

Este directorio alberga las plantillas y suites de pruebas automatizadas. La intención es iniciar con Bats para scripts Bash, aunque pueden agregarse otros frameworks según sea necesario.

## Convenciones

- Colocar los archivos `.bats` dentro de subdirectorios que agrupen las funcionalidades a validar.
- Usar comentarios y TODOs en español para describir los escenarios pendientes.
- Mantener la estructura Red → Green → Refactor del proceso TDD.

## Ejecución

Para ejecutar las pruebas Bats (una vez configuradas):

```bash
bats tests/
```

## Prototipos evaluados

- `tests/quality/ejecutar_validaciones.bats`: suite creada para validar `scripts/quality/ejecutar_validaciones.sh` con sintaxis Bats.
- `tests/prototypes/bats/bats_stub.sh`: intérprete mínimo para ejecutar los `.bats` mientras no exista una instalación oficial.
- `tests/prototypes/shunit2/test_ejecutar_validaciones.sh`: pruebas equivalentes usando el stub de shunit2 ubicado en el mismo directorio.

Para ejecutar los prototipos sin dependencias externas:

```bash
# Bats (via stub)
tests/prototypes/bats/bats_stub.sh tests/quality/ejecutar_validaciones.bats

# shunit2 (via stub)
tests/prototypes/shunit2/test_ejecutar_validaciones.sh
```
