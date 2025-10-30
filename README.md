# MediaWiki Production Lab v2.0

[![Build](https://img.shields.io/badge/build-passing-brightgreen.svg)](#)
[![Tests](https://img.shields.io/badge/tests-coverage%2080%25-blue.svg)](#)
[![Security](https://img.shields.io/badge/security-hardening%20activo-orange.svg)](#)

Plataforma MediaWiki lista para producción basada en un monolito modular desplegado sobre Vagrant con enfoque DevSecOps.

## Características principales

- Monolito modular MediaWiki 1.43 LTS con extensiones personalizadas.
- Infraestructura reproducible de tres VMs (web, base de datos, gestión).
- Hardening integral (firewall, Fail2ban, ModSecurity, TLS estricto).
- Monitoreo con Nagios y centralización de logs vía Rsyslog.
- Automatizaciones de operaciones, backups y validaciones end-to-end.
- Cultura TDD con cobertura mínima del 80% y Conventional Commits.

## Arquitectura

Consulta la descripción detallada en [ARCHITECTURE.md](ARCHITECTURE.md) y el documento extendido [arquitectura técnica integral](docs/03_arquitectura/arquitectura_general.md).

## Quickstart

```bash
git clone https://example.org/mediawiki/media-wiki.git
cd media-wiki
cp config/variables.ejemplo .env
vagrant up
./scripts/run-all-tests.sh
```

Acceso principal: https://192.168.1.100 (acepta certificados generados por Certbot).

## Servicios y accesos

| Servicio | URL | Credenciales iniciales |
| --- | --- | --- |
| MediaWiki | https://192.168.1.100 | admin / CambiaEsto123 |
| Nagios | http://192.168.56.30/nagios | nagiosadmin / CambiaEsto321 |
| SSH web01 | `vagrant ssh mediawiki-web01` | Clave Vagrant |
| SSH db01 | `vagrant ssh mediawiki-db01` | Clave Vagrant |
| SSH mgmt01 | `vagrant ssh mediawiki-mgmt01` | Clave Vagrant |

> **Nota:** actualiza todas las contraseñas tras la instalación siguiendo el [manual operacional](docs/05_operaciones/manual_operaciones_mediawiki.md).

## Documentación

La documentación se organiza en `docs/` (carpetas numeradas). Accede al [índice maestro](docs/INDEX.md) para navegar por guías y manuales. Destacados:

- [Guía de instalación](docs/07_devops/instalacion/guia_instalacion_mediawiki.md)
- [Referencia de configuración](docs/07_devops/configuracion/referencia_configuracion_mediawiki.md)
- [Manual operacional](docs/05_operaciones/manual_operaciones_mediawiki.md)
- [Hardening y seguridad](docs/07_devops/seguridad/hardening_y_seguridad.md)
- [Desarrollo de extensiones](docs/07_devops/desarrollo/desarrollo_de_extensiones.md)

## Desarrollo y contribución

1. Sigue la guía [CONTRIBUTING.md](CONTRIBUTING.md).
2. Trabaja en ramas feature con Conventional Commits.
3. Escribe tests antes del código (Red → Green → Refactor).
4. Ejecuta `./scripts/development/test-extension.sh` y `./scripts/run-all-tests.sh` antes de abrir PR.
5. Genera documentación asociada y enlázala al índice.

## Troubleshooting rápido

- `vagrant status` para validar estado de VMs.
- `scripts/operations/health-check.sh` para revisar servicios críticos.
- `tests/security/test-hardening.sh` para verificar controles.
- Consulta [runbooks](docs/05_operaciones/manual_operaciones_mediawiki.md#6-runbooks-de-incidentes) ante incidentes.

## Licencia

GPL-2.0-or-later. Ver `LICENSE` para detalles.

## Autores y contacto

- Arquitectura: Equipo de Arquitectura (`arquitectura@example.org`)
- DevOps: Equipo DevOps (`devops@example.org`)
- Seguridad: Equipo de Seguridad (`seguridad@example.org`)

¿Dudas? Abre un issue o escribe a `mediawiki-lab@example.org`.
