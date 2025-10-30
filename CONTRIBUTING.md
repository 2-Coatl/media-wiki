# Guía de contribución

Gracias por contribuir a MediaWiki Production Lab.

## Código de conducta

Adoptamos el [Contributor Covenant](https://www.contributor-covenant.org/version/2/1/code_of_conduct/) y esperamos respeto en todas las interacciones. Reporta incidentes a `seguridad@example.org`.

## Requisitos previos

- VirtualBox 7+, Vagrant 2.4+
- PHP 8.1 con Composer
- Node.js 20 + npm
- Git y `make`

## Flujo de contribución

1. **Fork** del repositorio y crea rama feature (`feat/<scope>-<descripcion>`).
2. Asegura que exista un issue vinculado o ADR cuando aplique.
3. Escribe tests antes del código (TDD: Red → Green → Refactor).
4. Ejecuta scripts locales (`./infrastructure/run-all-tests.sh`).
5. Actualiza documentación y enlaza al índice (`docs/INDEX.md`).
6. Abre Pull Request detallando cambios y resultados de pruebas.

## Estilo de commits

Usa Conventional Commits con mensajes en español:

```
feat(instalacion): automatizar verificacion de prerequisitos
fix(db): corregir permisos de replicacion
docs(ops): actualizar runbook de incidentes
```

## Estándares de código y pruebas

- PHP: PSR-12 + type hints.
- JavaScript: ESLint con configuración del proyecto.
- Cobertura mínima 80% (`./infrastructure/development/test-extension.sh`).
- Ejecuta `phpcs`, `phpunit`, `eslint`, `markdownlint` antes de enviar.

## Revisiones y merge

- Requiere al menos 2 aprobaciones.
- CI debe estar en verde.
- Actualiza branch con `git rebase` antes de merge.
- Merge mediante `--no-ff` para mantener historial claro.

## Recursos

- [Índice de documentación](docs/INDEX.md)
- [Manual de desarrollo](docs/07_devops/desarrollo/desarrollo_de_extensiones.md)
- [Hardening y seguridad](docs/07_devops/seguridad/hardening_y_seguridad.md)
