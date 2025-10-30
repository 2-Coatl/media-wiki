---
id: TASK-ARQ-001
estado: completado
propietario: Equipo de Arquitectura
ultima_actualizacion: 2025-02-17
relacionados: [DOC-ADR-INDEX-001, DOC-ARQ-INDEX-001, DOC-INDEX-001]
---
# Reubicar ADRs al directorio oficial de arquitectura

## Contexto
Las decisiones arquitectónicas recientes se han almacenado en carpetas generales bajo `docs/` sin seguir la convención oficial.
Esto dificulta localizar el historial de ADRs y provoca referencias rotas en los índices existentes.

## Objetivo
Alinear todos los Architecture Decision Records con la estructura acordada (`docs/03-arquitectura/adrs/`) y mantener los índices actualizados.

## Alcance
- Identificar ADRs ubicados fuera de `docs/03-arquitectura/adrs/`.
- Reubicarlos conservando la numeración correlativa y el formato de nombre (`000X-titulo.md`).
- Actualizar referencias internas (README, enlaces cruzados, índices).
- Verificar que los enlaces en la documentación general sigan funcionando.

## Plan sugerido
1. Ejecutar un inventario (`find docs -name "000*-*.md" -o -name "*-adr*.md"`) para ubicar ADRs dispersos.
2. Crear subcarpetas temporales si es necesario y mover cada archivo al destino `docs/03-arquitectura/adrs/`.
3. Ajustar el front-matter asegurando que `id`, `estado` y `relacionados` estén vigentes.
4. Actualizar los índices (`docs/03-arquitectura/README.md`, `docs/03-arquitectura/adrs/README.md`, `docs/README.md`).
5. Ejecutar una validación de enlaces (por ejemplo con `markdown-link-check`) o revisión manual.

## Criterios de aceptación
- No quedan ADRs fuera de `docs/03-arquitectura/adrs/`.
- Todos los enlaces en los índices de documentación apuntan correctamente a la nueva ubicación.
- Se registra el movimiento mediante un commit documentado y, de ser necesario, una ADR que explique la convención definitiva.
- El equipo de arquitectura valida el cambio y actualiza el estado de esta tarea a `en_progreso` o `completado`.

## Ejecución
- 2025-02-17 → Se ejecutó el inventario (`find docs -type f -name "000*-*.md"` y `find docs -type f -iname "*-adr*.md"`), confirmando que todos los ADR residen en `docs/03-arquitectura/adrs/`.
- 2025-02-17 → Se actualizaron los índices (`docs/README.md`, `docs/03-arquitectura/README.md`, `docs/03-arquitectura/adrs/README.md`) para enlazar la ubicación oficial.
- 2025-02-17 → Se dejó registro en esta tarea y se cambió el estado a `completado` tras validar con documentación sincronizada.
