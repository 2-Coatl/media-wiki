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
