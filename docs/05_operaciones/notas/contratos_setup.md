---
id: NOTE-INFRA-SETUP
estado: vigente
propietario: Equipo de Infraestructura
ultima_actualizacion: 2025-02-15
relacionados: [ADR-2024-001]
---
# Contratos detectados en scripts de inicialización

## `bin/setup-project`

- **Estructura de directorios obligatoria:**
- Crea o valida la existencia de `bin/`, `config/`, `infrastructure/utils/`, `infrastructure/` con subdirectorios `installation/`, `security/`, `migration/`, `validation/`, `git_hooks/`, `quality/`, `deploy/`, además de `vagrant/provisioners/`, `tests/{unit,integration,smoke}/`, `docs/` y `backups/`.
  - Asume que los comandos tienen permisos para crear carpetas en la raíz del proyecto.
- **Archivos generados o verificados:**
  - `.gitignore` con reglas para secretos, Vagrant, MediaWiki, backups, IDEs, OS y temporales.
  - `README.md` con guía de inicio rápido si no existe.
  - `config/secrets.env`, potencialmente recreado mediante `bin/generate-secrets`.
- **Permisos:**
  - Aplica `chmod +x` a todos los archivos en `bin/` y scripts `.sh` en `infrastructure/`.
- **Dependencias internas:**
  - Depende de `bin/generate-secrets` para rellenar secretos si está disponible y es ejecutable.

## `bin/setup-trunk-based`

- **Archivos esperados/creados:**
- Instala hooks ejecutando `infrastructure/git_hooks/install-hooks.sh` si existe.
  - Crea `.editorconfig` y `.shellcheckrc` con reglas predefinidas cuando no están presentes.
- **Dependencias externas:**
  - Requiere `git`, `vagrant`, `shellcheck` y `shfmt`; en caso de ausencia muestra los comandos de instalación sugeridos.
- **Configuración de Git:**
  - Define `pull.rebase=true` y `init.defaultBranch=main` en la configuración local.
- **Salida esperada:**
  - Mensajes de avance numerados del 1 al 5 y recomendaciones de siguientes pasos.

## `bin/generate-secrets`

- **Archivo gestionado:**
  - Genera `config/secrets.env` con credenciales para bases de datos, MediaWiki y Nagios.
- **Permisos:**
  - Establece `chmod 600` para limitar el acceso al propietario.
- **Dependencias externas:**
  - Requiere `openssl` para crear contraseñas aleatorias.
- **Resguardo:**
  - Si el archivo ya existe, solicita confirmación y crea copias de respaldo con sufijo `backup.<timestamp>`.

## `bin/validate-host`

- **Dependencias internas:**
  - Importa `config/00-core.sh` y requiere que defina variables como `MIN_RAM_GB` y `MIN_DISK_GB`.
- **Validaciones realizadas:**
  - RAM disponible, espacio en disco, presencia de VirtualBox (`vboxmanage`), Vagrant y virtualización por hardware.
- **Expectativas sobre comandos del sistema:**
  - Utiliza `free`, `df`, `vboxmanage`, `vagrant` y lectura de `/proc/cpuinfo`.
- **Resultado:**
  - Termina con `exit 0` si no hay errores; en caso contrario muestra el número de requisitos incumplidos y devuelve `exit 1`.

## Referencias adicionales

- El `README.md` describe la estructura esperada del proyecto (`wiki/`, `bin/`, `config/`, `infrastructure/`, `vagrant/`, `docs/`) y detalla herramientas requeridas (VirtualBox, Vagrant, Git) alineadas con las verificaciones de los scripts.
- Los comentarios en `bin/` refuerzan que la arquitectura es un despliegue de MediaWiki endurecido y con flujo de trunk-based development.

