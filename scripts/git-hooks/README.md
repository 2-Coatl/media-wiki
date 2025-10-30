# Hooks de Git

Este directorio contiene hooks personalizados para automatizar tareas antes y durante el proceso de commit.

## Instalación

1. Copiar o enlazar cada script al directorio `.git/hooks/` correspondiente.
2. Asegurarse de que los scripts tengan permisos de ejecución.

## Hooks disponibles

- `pre-commit`: valida el estado del repositorio antes de crear un commit.
- `commit-msg`: valida el mensaje del commit y la metadata asociada.

Cada hook incluye mensajes de ayuda (`-h`) y TODOs para completar la lógica futura.
