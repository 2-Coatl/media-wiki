---
id: NOTE-INFRA-UTILS
estado: vigente
propietario: Equipo de Infraestructura
ultima_actualizacion: 2025-02-15
relacionados: [ADR-2024-001, ADR-2024-003]
---
# Análisis y propuesta de layout para `infrastructure/utils`

## 1. Panorama actual

| Script | Responsabilidades declaradas | Dependencias internas | Patrones de uso | Observaciones |
| --- | --- | --- | --- | --- |
| `logging.sh` | Inicializar y centralizar escritura de logs con diferentes niveles de severidad. | Variables de entorno (`LOG_FILE`, `DEBUG`). | `source` directo desde otros scripts para emitir mensajes enriquecidos. | Define colores ANSI, pero no impone inicialización explícita (`init_logging`) ni prefijos comunes en los nombres. |
| `core.sh` | Funciones base para comprobaciones del sistema y utilidades generales (comandos, servicios, puertos, usuarios). | `logging.sh`. | Se espera que sea incluido en scripts operativos; provee helpers binarios (`true/false`). | Mezcla verificaciones (ej. `check_root`) con funciones de consulta (`port_listening`) sin un contrato de salida común. |
| `validation.sh` | Validaciones sintácticas y de entorno (IP, hostname, URLs, recursos). | `core.sh` → `logging.sh`. | Complementa `core.sh` para validar entradas antes de operar. | Retorna `0/1` como cualquier comando, pero no documenta parámetros ni unidades esperadas (ej. GB). |

### Hallazgos

1. **Jerarquía implícita**: `validation.sh` depende de `core.sh`, que a su vez depende de `logging.sh`, pero no existe un punto de entrada claro para inicializar el stack.
2. **Nombres globales**: Los nombres de funciones son genéricos (`log_info`, `validate_ip`), lo que incrementa el riesgo de colisión al combinar otros scripts.
3. **Contratos heterogéneos**: Algunas utilidades retornan códigos de salida binarios, mientras otras escriben en `stdout` o realizan `exit`. No hay documentación explícita de parámetros.
4. **Configuración contextual**: Se asume la existencia de comandos (`curl`, `wget`, `openssl`) sin exponer requisitos previos ni un mecanismo común de _feature detection_.

## 2. Propuesta de layout objetivo

```
infrastructure/utils/
├── logging.sh          # API de logging (mw_log_*)
├── system.sh           # Reemplaza core.sh, utilidades de entorno/sistema
├── validation.sh       # Validaciones declarativas basadas en system
├── io.sh               # (Opcional) utilidades de interacción (prompt, backups)
└── loader.sh           # Punto único de carga + inicialización
```

### 2.1 Responsabilidades y contratos

#### `logging.sh`
- **Responsabilidad**: Proveer funciones puras de logging (`mw_log_info`, `mw_log_warn`, etc.) y configurar destino.
- **Entradas**:
  - Variable de entorno `MW_LOG_FILE` (opcional, por defecto `/var/log/mediawiki-setup.log`).
  - Texto de mensaje (string).
- **Salidas**:
  - Mensajes en `stdout` con formato consistente.
  - Apéndice al archivo de log configurado.
- **Estándares**:
  - Prefijo `mw_log_` para todas las funciones públicas.
  - Exponer `mw_logging_init` idempotente (no `exit`).

#### `system.sh`
- **Responsabilidad**: Operaciones sobre el sistema (chequeos de permisos, existencia de comandos, servicios, puertos, usuarios).
- **Entradas**:
  - Parámetros específicos (`mw_sys_require_command <cmd> [hint]`).
- **Salidas**:
  - Código de salida `0/1` según éxito.
  - Mensajes a través de `mw_log_*` únicamente.
- **Estándares**:
  - Prefijo `mw_sys_`.
  - No debe abortar el script llamante (`exit`), salvo funciones explícitas `mw_sys_abort_if_not_root` documentadas.

#### `validation.sh`
- **Responsabilidad**: Validar datos de entrada (IPs, hostnames, URLs, recursos).
- **Entradas**:
  - Valores atómicos (`string`, `int`).
- **Salidas**:
  - Código `0/1`. En caso de error, emitir mensaje vía `mw_log_warn` o `mw_log_error`.
- **Estándares**:
  - Prefijo `mw_validate_`.
  - Documentar unidades (GB, segundos) en comentarios.

#### `io.sh` (nuevo opcional)
- **Responsabilidad**: Interacciones con el usuario y operaciones de respaldo (`mw_io_confirm`, `mw_io_backup_file`).
- **Entradas/Salidas**:
  - Mantener API orientada a `stdin/stdout`, retornando `0/1`.
- **Estándares**:
  - Prefijo `mw_io_`.

#### `loader.sh`
- **Responsabilidad**: Punto de entrada único para scripts consumidores (`source infrastructure/utils/loader.sh`).
- **Comportamiento**:
  - Exporta `set -euo pipefail` opcional (configurable).
  - Inicializa logging (`mw_logging_init`).
  - Carga condicional de módulos (`mw_utils_require logging system validation`).

### 2.2 Convenciones transversales

- **Prefijos**: Toda función pública debe comenzar con `mw_<dominio>_` para evitar colisiones.
- **Documentación**: Comentarios en bloque (español) sobre propósito, parámetros y salida.
- **Retornos**: Usar `return` con códigos POSIX; evitar `exit` dentro de utilidades compartidas.
- **Dependencias externas**: Exponer funciones `mw_sys_require_*` para validar comandos antes de utilizarlos.
- **Errores**: Centralizar en `mw_log_error` y permitir que el llamante decida abortar.

## 3. Roadmap de adopción

1. Crear `loader.sh` e introducir prefijos en los scripts existentes manteniendo alias de compatibilidad temporal (`log_info()` → `mw_log_info()`).
2. Actualizar todos los scripts consumidores para `source loader.sh` y utilizar los nuevos nombres.
3. Depurar funciones redundantes y mover utilidades de E/S a `io.sh`.
4. Documentar el uso de `mw_sys_require_command` en README de despliegues.
5. Añadir suite de pruebas shell (`bats`) que cubra los contratos principales con un objetivo de cobertura ≥80%.

## 4. Riesgos y mitigaciones

- **Ruptura de scripts existentes** → Mantener aliases temporales y comunicar la migración mediante ADR.
- **Aumento de complejidad** → `loader.sh` simplifica el punto de entrada y estandariza inicialización.
- **Cobertura de tests** → Adoptar TDD con `bats` o `shunit2` para nuevas funciones antes de refactorizar.

## 5. Próximos pasos de validación

- Revisar la propuesta con el equipo de infraestructura en la próxima sesión de alineación.
- Recoger feedback sobre prefijos y estructura de módulos.
- Ajustar la ADR preliminar con comentarios y decidir si se adopta para scripts de aprovisionamiento generales.
