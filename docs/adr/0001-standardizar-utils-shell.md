# ADR 0001: Estandarización de utilidades shell en `infrastructure/utils`

- Estado: Propuesta (pendiente de validación)
- Fecha: 2024-06-06

## Contexto

Los scripts de aprovisionamiento y soporte dependen de utilidades compartidas ubicadas en `infrastructure/utils`. Actualmente las funciones exportadas tienen nombres genéricos, contratos implícitos y no existe un punto único de inicialización. Esta situación dificulta:

- Evitar colisiones con funciones definidas en otros scripts.
- Documentar responsabilidades y dependencias entre módulos (`logging.sh`, `core.sh`, `validation.sh`).
- Adoptar TDD de forma consistente, dado que los contratos de entrada/salida no son explícitos.

## Decisión

Adoptar un layout modular con prefijos por dominio (`mw_log_*`, `mw_sys_*`, `mw_validate_*`, `mw_io_*`) y un loader centralizado que inicialice logging y resuelva dependencias. La propuesta detallada se documenta en `docs/notas/infrastructure-utils-layout.md`.

Puntos clave:

1. Renombrar `core.sh` a `system.sh` y limitarlo a operaciones de sistema.
2. Extraer utilidades de interacción (confirmaciones, backups) a `io.sh`.
3. Crear `loader.sh` como punto de entrada único (`source infrastructure/utils/loader.sh`).
4. Alinear todos los módulos con contratos basados en códigos de salida POSIX y logging centralizado.
5. Mantener aliases temporales durante la transición (`log_info` → `mw_log_info`).

## Consecuencias

- **Positivas**:
  - Interfaces explícitas facilitan la creación de pruebas automatizadas (`bats`) bajo el enfoque TDD.
  - Reducen el riesgo de colisiones y efectos secundarios al importar utilidades.
  - Simplifican la incorporación de nuevos módulos siguiendo la misma convención de prefijos.
- **Negativas**:
  - Se requiere una fase de migración para actualizar scripts existentes.
  - Implica trabajo adicional de documentación y comunicación con el equipo.

## Próximos pasos

1. Presentar la propuesta en la próxima ceremonia del equipo de infraestructura y recoger feedback.
2. Ajustar la ADR con comentarios recibidos antes de marcarla como aceptada.
3. Planificar la migración y definición de pruebas de regresión para los scripts consumidores.
