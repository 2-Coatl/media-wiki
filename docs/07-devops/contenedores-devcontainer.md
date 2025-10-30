---
id: DOC-DEVOPS-001
estado: vigente
propietario: Plataforma
ultima_actualizacion: 2025-02-15
relacionados: [DOC-INDEX-001, RB-OPS-POST-001]
---
# Guía de Contenedores Devcontainer

1. Instala la extensión **Dev Containers** en VS Code y abre la raíz del repositorio.
2. Ejecuta `Dev Containers: Reopen in Container` para construir la imagen base definida en `.devcontainer`.
3. Verifica la construcción revisando los logs hasta ver `All scripts completed.` y valida con `poetry --version` dentro del contenedor.
4. Tras la creación inicial, ejecuta el runbook [`post-create`](runbooks/post-create.md) para instalar dependencias adicionales.
5. Si la construcción falla, elimina el contenedor con `Dev Containers: Rebuild Container` y limpia caché con `docker system prune`.
6. Mantén el contenedor actualizado corriendo `poetry install` cuando se agreguen dependencias nuevas.
7. Documenta overrides locales en `docs/07-devops/runbooks/post-create.md` para que el equipo los replique.
8. Antes de cerrar la sesión, ejecuta `pytest` y `flake8` para asegurar que el entorno permanece consistente.
9. Usa `Dev Containers: Open Folder in Container...` para cambiar de rama sin reconstruir desde cero.
10. Para rollback total, reconstruye con `Dev Containers: Rebuild Without Cache` y vuelve a ejecutar los pasos 3 a 8.
