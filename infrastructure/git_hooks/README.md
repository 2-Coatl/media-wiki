# Hooks de Git

Este directorio contiene hooks personalizados para automatizar tareas antes y durante el proceso de commit.

## Instalación

1. Copiar o enlazar cada script al directorio `.git/hooks/` correspondiente.
2. Asegurarse de que los scripts tengan permisos de ejecución.

## Hooks disponibles

- `pre-commit`: valida el estado del repositorio antes de crear un commit.
- `commit-msg`: valida el mensaje del commit y la metadata asociada.
- `pre-push`: ejecuta linters, pruebas y verificación de cobertura (≥80 % por defecto)
  antes de subir cambios al remoto.

Cada hook incluye mensajes de ayuda (`-h`) y, donde aplica, opciones para ajustar
los umbrales de validación.
