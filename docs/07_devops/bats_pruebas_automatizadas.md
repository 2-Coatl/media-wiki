---
id: DOC-DEVOPS-TOOLS-002
estado: vigente
propietario: Equipo de QA
ultima_actualizacion: 2025-02-22
relacionados: [DOC-INDEX-001, ADR-2024-002, ADR-2024-004]
---
# Guía operativa de Bats para scripts Bash

[Volver al índice de documentación](../README.md)

Esta guía describe cómo integrar **Bats (Bash Automated Testing System)** en el
laboratorio de MediaWiki siguiendo la metodología TDD. Resume la estructura de
directorios esperada, comandos de instalación offline y patrones de uso comunes
(documentados en los prototipos existentes y en la documentación oficial del
framework).

## 1. Propósito y alcance

- Garantizar que los scripts Bash se desarrollen con el ciclo **Rojo → Verde →
  Refactor** y cobertura mínima del 80 %.
- Centralizar los lineamientos para vendorizar `bats-core` y sus librerías
  (`bats-support`, `bats-assert`) sin depender de Internet.
- Ofrecer ejemplos prácticos reutilizables para nuevas suites ubicadas bajo
  `infrastructure/tests/<dominio>/*.bats`.

## 2. Estructura recomendada del repositorio

```
infrastructure/
  tests/
    vendor/
      bats-core/          <- distribución vendorizada
    test_helper/
      bats-support/       <- librería auxiliar
      bats-assert/        <- librería de aserciones
    calidad/
      ejecutar_validaciones.bats
    ...
  quality/
    ejecutar_validaciones.sh
```

La carpeta `infrastructure/tests/vendor/bats-core` debe contener el runtime oficial. Las
librerías auxiliares se ubican en `infrastructure/tests/test_helper/` para ser cargadas con el
comando `load` dentro de cada suite.

## 3. Instalación rápida (sin conexión)

1. Posicionarse en la raíz del repositorio.
2. Añadir los vendors como submódulos (o sincronizarlos si ya existen):

   ```bash
   git submodule add https://github.com/bats-core/bats-core.git infrastructure/tests/vendor/bats-core
   git submodule add https://github.com/bats-core/bats-support.git infrastructure/tests/test_helper/bats-support
   git submodule add https://github.com/bats-core/bats-assert.git infrastructure/tests/test_helper/bats-assert
   git submodule update --init --recursive
   ```

3. Asegurar permisos de ejecución en `infrastructure/tests/vendor/bats-core/bin/bats`.
4. Documentar la actualización del vendor en un ADR o nota operativa cuando se
   cambie la versión.

Cuando no sea posible clonar submódulos (p. ej. en entornos aislados), se debe
copiar manualmente el contenido de los repositorios mencionados conservando la
misma estructura.

## 4. Primer caso de prueba en TDD

1. Crear la suite `infrastructure/tests/calidad/mi_script.bats` con un caso mínimo:

   ```bash
   #!/usr/bin/env bats

   setup() {
     load 'test_helper/bats-support/load'
     load 'test_helper/bats-assert/load'

    DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
    PATH="$DIR/../../../infrastructure:$PATH"
   }

   @test "puedo ejecutar el script" {
     run quality/mi_script.sh
     assert_success
   }
   ```

2. Ejecutar la suite con `infrastructure/tests/vendor/bats-core/bin/bats infrastructure/tests/calidad/mi_script.bats`
   y verificar el fallo inicial (archivo inexistente).
3. Implementar el script correspondiente bajo `infrastructure/` y repetir la ejecución
   hasta obtener un resultado verde.

## 5. Gestión de rutas y variables

- `BATS_TEST_FILENAME` es la referencia canónica al archivo `.bats` actual; debe
  usarse para resolver rutas absolutas y evitar dependencias del directorio de
  trabajo.
- Agregar la carpeta `infrastructure/` al `PATH` dentro de `setup()` permite invocar los
  ejecutables sin prefijos relativos (`run mi_comando`).
- Utilizar variables de entorno en `setup()` facilita inyectar stubs o comandos
  alternativos durante la ejecución de las pruebas.

## 6. Manejo de salida estándar y errores

- Prefijar los comandos con `run` captura `stdout`, `stderr` y código de salida.
- Validar mensajes usando `assert_output`, `refute_output` o sus variantes con
  `--partial` para coincidencias parciales.
- Para comparar solo una porción de la salida, usar `assert_output --partial` es
  preferible a crear funciones intermedias con `grep`.

## 7. Limpieza y reutilización de fixtures

- Implementar `teardown()` para eliminar archivos temporales, aun cuando las
  pruebas fallen. Ejemplo:

  ```bash
  teardown() {
    rm -f /tmp/mi_script.flag
  }
  ```

- Cuando la prueba dependa del estado previo, utilizar `skip "motivo"` lo antes
  posible para evitar falsos negativos en entornos compartidos.
- Agrupar lógica común en `infrastructure/tests/test_helper/common-setup.bash` y cargarla con
  `load 'test_helper/common-setup'`.

## 8. Suites distribuidas en múltiples archivos

- Crear un archivo `.bats` por dominio o script para facilitar el mantenimiento.
- Ejecutar todo el paquete con `infrastructure/tests/vendor/bats-core/bin/bats infrastructure/tests/`, lo que
  descubrirá automáticamente todos los archivos con extensión `.bats` (sin
  necesidad del flag `-r` si no existen subdirectorios anidados).
- Incluir `setup()` y `teardown()` propios en cada archivo según sus necesidades.

## 9. Setups costosos

- Utilizar `setup_file()` y `teardown_file()` cuando se requiera levantar
  servicios externos (p. ej. un servidor echo con `ncat`).
- Exportar las variables inicializadas en `setup_file()` para que sean visibles en
  los casos de prueba (`export PORT`).
- Asegurar que `teardown_file()` detenga servicios y limpie artefactos incluso si
  una prueba falla.

## 10. Integración con cobertura y CI

- Ejecutar las suites mediante `infrastructure/bin/test_scripts.sh`, que encapsula la ruta al
  vendor de Bats.
- Para cobertura, utilizar `infrastructure/bin/coverage_scripts.sh`, el cual invoca
  `infrastructure/quality/bash-coverage.sh` tras las pruebas.
- Publicar los reportes en `reports/coverage/scripts/` y verificar que el
  porcentaje cumpla con el umbral definido (≥ 80 %).

## 11. Referencias

- [Repositorio oficial de bats-core](https://github.com/bats-core/bats-core)
- [Biblioteca bats-support](https://github.com/bats-core/bats-support)
- [Biblioteca bats-assert](https://github.com/bats-core/bats-assert)
- Plantillas existentes en `infrastructure/tests/quality/` y `infrastructure/tests/prototypes/`
- ADR relacionados: `docs/03_arquitectura/adrs/0002_framework_pruebas_bash.md`
  y `docs/03_arquitectura/adrs/0004_estrategia_pruebas_y_cobertura.md`
