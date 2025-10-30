---
id: DOC-DEVOPS-013
estado: vigente
propietario: Equipo de Desarrollo
ultima_actualizacion: 2025-02-21
relacionados: [DOC-INDEX-001, DOC-DEVOPS-PLAN-001]
---
# Desarrollo de Extensiones

Marco de trabajo para crear, desplegar y validar extensiones personalizadas de
MediaWiki dentro del laboratorio. Incluye la plantilla base, scripts de
automatización, ejemplos completos y validaciones de calidad.

## 1. Plantilla de extensión

- **Ubicación**: `development/tools/extension-template-2025/`.
- **Estructura**:
  - `extension.json`, `ExtensionName.php`, `README.md`, `LICENSE`,
    `CHANGELOG.md`, `CODE_OF_CONDUCT.md`.
  - Directorios `src/` (PSR-4), `resources/` (CSS/JS), `i18n/` (en/es/qqq),
    `sql/` (definiciones `tables.json`), `tests/phpunit/`, `maintenance/` y
    configuración `.editorconfig`/`.gitignore`.
- **Buenas prácticas**:
  - JavaScript sin dependencias externas ni uso de `localStorage`.
  - Documentar mensajes i18n y mantener traducciones sincronizadas.
  - Registrar cambios en `CHANGELOG.md` desde la primera iteración.

## 2. Creación automática

- **Script**: `scripts/development/create-extension.sh`.
- **Funciones clave**:
  - `validate_extension_name` (formato PascalCase, sin duplicados).
  - `prompt_extension_info` para capturar descripción, autor, licencia, URL.
  - `copy_template` y `rename_files` adaptando nomenclatura.
  - `replace_placeholders` para actualizar textos (`ExtensionName`,
    `extensionname`, descripción, autor).
  - `initialize_git` para repositorios independientes cuando sea necesario.
- **Salida**: nueva carpeta en `development/extensions/<ExtensionName>/` lista
  para edición.

## 3. Despliegue hacia las VMs

- **Script**: `scripts/development/deploy-extension.sh`.
- **Flujo**:
  1. `validate_extension_exists` y `validate_extension_structure`.
  2. `sync_to_vm` (sincronización directa o vía `rsync`).
  3. `set_permissions` (`chown www-data:www-data`).
  4. `update_localsettings` con `wfLoadExtension` y respaldo previo.
  5. `run_update_script` (`php maintenance/update.php`).
  6. `clear_cache` (`php maintenance/rebuildLocalisationCache.php`).
  7. `verify_deployment` (`curl` a `Special:Version`).
- **Herramienta adicional**: `scripts/development/sync-extensions.sh` para
  sincronización continua usando `inotifywait`.

## 4. Ejemplo EmployeeDirectory

- Generado con el script de creación (`EmployeeDirectory`).
- **Componentes**:
  - Tabla `employee_directory` definida en `sql/tables.json`.
  - `SpecialEmployeeDirectory.php` con permisos dedicados y renderizado de lista.
  - JavaScript (`resources/js/ext.employeeDirectory.js`) con búsqueda en tiempo
    real (filtrado en memoria).
  - CSS (`resources/css/ext.employeeDirectory.css`) con diseño responsivo.
  - Script de mantenimiento `maintenance/importEmployees.php` para cargar datos
    desde CSV.
  - Tests unitarios en `tests/phpunit/unit/` para validar hooks y consultas.
- **Validación**: desplegar, ejecutar `php maintenance/update.php`, importar
  datos, acceder a `Special:EmployeeDirectory` y confirmar funcionamiento.

## 5. Ejemplo ProjectTracker con API

- Extensión creada via script (`ProjectTracker`).
- **API**:
  - `src/Api/ApiProjectTracker.php` con acciones `list`, `get`, `create`,
    `update`, `delete`.
  - Validación estricta de parámetros y respuestas JSON con códigos de error.
  - Control de permisos y autenticación MediaWiki.
- **Interfaz web**:
  - `SpecialProjectTracker.php` consumiendo la API mediante `fetch`.
  - Formularios para CRUD y manejo de errores en la UI.
- **Pruebas**:
  - Curl/postman para cada endpoint.
  - Tests PHP en `tests/phpunit/` cubriendo flujos y seguridad.

## 6. Herramientas de testing

- **Script**: `scripts/development/test-extension.sh`.
- **Cobertura**:
  - Configuración de entorno (`setup_test_environment`).
  - `run_unit_tests` y `run_integration_tests` con PHPUnit.
  - Revisiones de sintaxis (`php -l`), estilo (`phpcs --standard=MediaWiki`) e
    integridad (`validate_extension_json`, `validate_i18n`).
  - Generación de reportes (HTML o consola).
- **Complemento**: `scripts/development/validate-extension.sh` para ganchos
  pre-commit.
- **Requisito**: cobertura mínima del 80% alineada al lineamiento de TDD.

## 7. Validación integral del flujo

- `scripts/validation/validate-group-j.sh` debe:
  - Verificar la existencia e integridad de la plantilla.
  - Probar los scripts de creación, despliegue y testing.
  - Confirmar que `EmployeeDirectory` y `ProjectTracker` aparecen en
    `Special:Version` tras el despliegue.
  - Validar la sincronización de archivos y ejecución de pruebas automatizadas.
  - Emitir un reporte final con hallazgos y recomendaciones.

## Referencias

- [Índice de documentación](../../README.md)
- [Plan maestro de tareas](../plan_tareas_mediawiki.md)
