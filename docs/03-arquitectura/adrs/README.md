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
- Nombres en `kebab-case` alineados a la decisión.
- Estado visible en el front-matter (`propuesta`, `aceptada`, etc.).

## Listado activo
- [0001 - Estandarizar utilidades de shell](0001-standardizar-utils-shell.md)
- [0002 - Seleccionar framework de pruebas para Bash](0002-framework-pruebas-bash.md)
- [0003 - Convención de módulos para scripts Bash](0003-convencion-modulos-scripts.md)
- [0004 - Estrategia de herramientas de pruebas y cobertura para scripts Bash](0004-estrategia-pruebas-y-cobertura.md)
- [0005 - Política para registrar ADRs ante cambios relevantes](0005-politica-adrs-cambios-relevantes.md)
- [0006 - Plan inicial para reforzar seguridad de servicios y respaldos](0006-plan-inicial-seguridad-y-backups.md)

## Procedimiento
1. Copia `000-template.md` y renómbralo con el siguiente consecutivo.
2. Completa todas las secciones antes de solicitar revisión.
3. Actualiza este índice y el [README de arquitectura](../README.md).
4. Registra impactos en requisitos o runbooks relacionados.

## Validaciones
- 2025-02-17 → Inventario con `find docs -type f -name "000*-*.md"` y `find docs -type f -iname "*-adr*.md"`: solo se encontraron archivos dentro de `docs/03-arquitectura/adrs/`.
