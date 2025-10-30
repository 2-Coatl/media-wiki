---
id: DOC-ADR-INDEX-001
estado: vigente
propietario: Equipo de Arquitectura
ultima_actualizacion: 2025-02-17
relacionados: [DOC-ARQ-INDEX-001, DOC-PLT-001]
---
# Índice de ADRs

## Cómo se organiza
- Numeración secuencial (`0001`, `0002`, ...).
- Nombres en `snake_case` alineados a la decisión.
- Estado visible en el front-matter (`propuesta`, `aceptada`, etc.).

## Listado activo
- [0001 - Estandarizar utilidades de shell](0001_standardizar_utils_shell.md)
- [0002 - Seleccionar framework de pruebas para Bash](0002_framework_pruebas_bash.md)
- [0003 - Convención de módulos para scripts Bash](0003_convencion_modulos_scripts.md)
- [0004 - Estrategia de herramientas de pruebas y cobertura para scripts Bash](0004_estrategia_pruebas_y_cobertura.md)
- [0005 - Política para registrar ADRs ante cambios relevantes](0005_politica_adrs_cambios_relevantes.md)
- [0006 - Plan inicial para reforzar seguridad de servicios y respaldos](0006_plan_inicial_seguridad_y_backups.md)

## Procedimiento
1. Copia `000_template.md` y renómbralo con el siguiente consecutivo.
2. Completa todas las secciones antes de solicitar revisión.
3. Actualiza este índice y el [README de arquitectura](../README.md).
4. Registra impactos en requisitos o runbooks relacionados.

## Validaciones
- 2025-02-17 → Inventario con `find docs -type f -name "000*_*.md"` y `find docs -type f -iname "*-adr*.md"`: solo se encontraron archivos dentro de `docs/03_arquitectura/adrs/`.
