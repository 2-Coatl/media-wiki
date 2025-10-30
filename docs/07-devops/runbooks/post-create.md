---
id: RB-DEV-POST-001
estado: vigente
propietario: Plataforma
ultima_actualizacion: 2025-02-15
relacionados: [DOC-DEVOPS-001]
---
# Runbook: Post-create Devcontainer

## Objetivo
Garantizar que el contenedor recién creado quede listo para desarrollo y que los ganchos de calidad estén operativos.

## Pasos
1. Ejecuta `poetry install` para sincronizar dependencias del proyecto.
2. Corre `pre-commit install` para habilitar los ganchos locales.
3. Aplica migraciones con `python manage.py migrate` si existen cambios pendientes.
4. Carga variables locales copiando `.env.example` a `.env` y ajustando secretos requeridos.
5. Ejecuta `pytest -q` y `flake8` para validar el entorno básico.
6. Actualiza `README.md` del módulo correspondiente si se instaló una herramienta adicional.
7. Registra cualquier ajuste extra en la sección **Notas operativas** de este runbook.

## Verificación
- `pytest -q` finaliza en verde.
- `flake8` no muestra errores.
- `poetry check` no arroja advertencias.

## Rollback
1. Ejecuta `git clean -xfd` dentro del contenedor.
2. Reconstruye el contenedor desde VS Code usando **Rebuild Without Cache**.
3. Repite los pasos del procedimiento asegurando que los comandos de verificación concluyen correctamente.

## Notas operativas
- 2025-02-15: Añadido paso para copiar `.env.example` y verificar linting con `flake8`.
