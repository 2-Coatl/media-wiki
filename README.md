# MediaWiki Production Lab

Production-ready MediaWiki deployment with Vagrant, security hardening, and trunk-based development workflow.

## Overview

Automated infrastructure-as-code project for deploying MediaWiki in a secure, production-like environment using Vagrant VMs.

**Features:**
- 2 VMs architecture (web server + database server)
- Ubuntu 20.04 LTS
- Apache 2.4 + PHP 8.1
- MariaDB 10.6
- MediaWiki 1.44 LTS
- 7 layers of security hardening
- Trunk-based development workflow
- Quality pipeline with Git hooks

## Requirements

**Host System:**
- VirtualBox 6.0+
- Vagrant 2.2+
- 8GB RAM minimum
- 50GB disk space available
- Git

**Operating Systems:**
- Windows 10/11
- macOS 10.15+
- Linux (Ubuntu, Debian, Fedora, etc.)

## Quick Start

```bash
# 1. Clone repository
git clone https://github.com/your-username/mediawiki-production-lab.git
cd mediawiki-production-lab

# 2. Validate host requirements
./bin/validate-host

# 3. Setup project
./bin/setup-project

# 4. Setup trunk-based development
./bin/setup-trunk-based

# 5. Deploy
bash scripts/deploy/deploy-vagrant.sh
```

## Registro de configuración inicial

La primera ejecución de `bin/setup-project` en un entorno limpio arrojó las siguientes advertencias:

- `bash: bin/setup-project: Permission denied`: el script carecía de permisos de ejecución. Se resolvió con `chmod +x bin/setup-project`.
- `[WARN] generate-secrets script not found or not executable`: el generador de secretos no tenía permisos. Se habilitó `bin/generate-secrets` con `chmod +x`.

Tras aplicar estos ajustes el comando se ejecuta sin advertencias y produce `config/secrets.env` automáticamente.

## Project Structure

```
mediawiki-production-lab/
├── wiki/                      MediaWiki source files
├── bin/                       Executable scripts
├── config/                    Configuration files
├── scripts/
│   ├── installation/          Installation scripts
│   ├── security/              Security hardening
│   ├── git-hooks/             Git hooks for trunk-based
│   ├── quality/               Quality pipeline
│   └── deploy/                Deployment scripts
├── vagrant/                   Vagrant provisioners
└── docs/                      Documentation
```

## Guía de carpetas y puntos de extensión

- **bin/**: scripts de orquestación ejecutables. Aquí viven `setup-project`, `validate-host`, `setup-trunk-based` y `generate-secrets`. Puedes añadir nuevas utilidades siguiendo el mismo patrón Bash y habilitándolas con `chmod +x`.
- **config/**: parámetros sensibles y plantillas de configuración. `config/secrets.env` se genera con `bin/generate-secrets`; extiende esta carpeta creando archivos `*.env` adicionales o agregando parámetros consumidos por los scripts de instalación.
- **docs/**: documentación funcional y técnica. Usa este directorio para ADRs, guías operativas y diagramas.
- **infrastructure/**: componentes reutilizables para aprovisionamiento (por ejemplo utilidades de Ansible o Terraform). Añade nuevos módulos sin mezclar lógica de scripts.
- **scripts/**: núcleo del aprovisionamiento dividido por etapas. Cada subcarpeta es un punto de extensión natural:
  - `installation/`: instala dependencias del sistema; agrega nuevos paquetes creando scripts `install-<componente>.sh`.
  - `security/`: endurecimiento de servicios; extiende con scripts para nuevas políticas de seguridad.
  - `migration/`: tareas de migración y mantenimiento de datos.
  - `validation/`: verificaciones posteriores a la instalación; añade validaciones adicionales reutilizando utilidades compartidas.
  - `git-hooks/` y `quality/`: pipelines de control de calidad y hooks de Git; puedes incorporar nuevas comprobaciones o herramientas de linting.
  - `deploy/`: automatización de despliegue y rollback; crea scripts que encapsulen nuevos flujos de entrega.
- **tests/**: pruebas automatizadas separadas en `unit/`, `integration/` y `smoke/`. Coloca aquí nuevos casos siguiendo el enfoque TDD y asegurando ≥80 % de cobertura.
- **vagrant/**: definiciones y provisioners específicos de Vagrant. Extiende la topología añadiendo provisioners o configuraciones por VM.
- **backups/**: destino para respaldos generados; excluido de Git por diseño.

## Configuration

Edit `config/00-core.sh` to configure deployment mode:

```bash
# Development mode (symlinks, fast iteration)
DEPLOYMENT_MODE="dev"

# Production mode (copy, independent)
DEPLOYMENT_MODE="prod"
```

## Deployment Modes

**Development Mode (symlinks):**
- MediaWiki sources symlinked from `wiki/`
- Edit files on host, changes reflected immediately
- Fast iteration, no re-provisioning needed

**Production Mode (copy):**
- MediaWiki sources copied to VM
- Independent from host
- Better performance and security

## Architecture

**Network Topology:**
- Web Server: 192.168.1.100 (bridged) + 10.0.2.10 (internal)
- Database Server: 10.0.2.20 (internal only)

**Security Layers:**
- Application: MediaWiki secure configuration
- Web Server: Apache hardening + ModSecurity
- Transport: TLS 1.2+, HSTS
- Network: UFW firewalls, network segmentation
- Access: Fail2ban, SSH hardening
- Database: Least privilege, IP-restricted access
- System: Ubuntu hardening, minimal services

## Trunk-Based Development

Git hooks automatically enforce:
- Pre-commit: Syntax validation, sensitive file check
- Commit-msg: Conventional commits format
- Pre-push: Full quality pipeline

**Commit format:**
```
<type>(<scope>): <subject>

Types: feat, fix, docs, security, refactor, test, chore
Scopes: web, db, security, network, vagrant, provision
```

**Examples:**
```bash
git commit -m "feat(security): add fail2ban configuration"
git commit -m "fix(db): resolve connection timeout"
git commit -m "docs: update architecture diagram"
```

## Common Commands

**Vagrant Operations:**
```bash
vagrant status                 # Check VMs status
vagrant up                     # Start all VMs
vagrant halt                   # Stop all VMs
vagrant ssh mediawiki-web01    # SSH to web server
vagrant ssh mediawiki-db01     # SSH to database server
```

**Deployment:**
```bash
bash scripts/deploy/deploy-vagrant.sh    # Full deployment
bash scripts/deploy/smoke-tests.sh       # Run smoke tests
bash scripts/deploy/snapshot-create.sh   # Create VM snapshot
bash scripts/deploy/rollback.sh <name>   # Rollback to snapshot
```

**Quality:**
```bash
# Ejecuta linters, pruebas y cobertura en una sola pasada
bash scripts/quality/ejecutar_validaciones.sh --min-coverage 85

# Sobrescribe comandos por defecto (útil en CI/CD)
QUALITY_TEST_CMD="pytest" \
QUALITY_COVERAGE_CMD="coverage report --fail-under=90" \
bash scripts/quality/ejecutar_validaciones.sh
```

El script `scripts/quality/ejecutar_validaciones.sh` expone las siguientes
variables para personalizar el flujo:

- `QUALITY_LINT_CMD`: comando completo para linters.
- `QUALITY_TEST_CMD`: comando que ejecuta las pruebas automatizadas.
- `QUALITY_COVERAGE_CMD`: comando que imprime el porcentaje de cobertura.
- `QUALITY_COVERAGE_VALUE`: valor numérico usado por el comando de cobertura
  por defecto (100 si no se define).
- `QUALITY_MIN_COVERAGE`: umbral mínimo utilizado cuando no se pasa el flag
  `--min-coverage`.

El hook `scripts/git-hooks/pre-push` reutiliza este job y garantiza que antes
de cada `git push` se ejecuten las pruebas y que la cobertura sea igual o
superior al 80 % (configurable con `--min-coverage` o la variable de entorno
`PRE_PUSH_MIN_COVERAGE`).

### Integración en CI/CD

Para adoptar el mismo flujo en pipelines remotas basta con invocar el script
de calidad dentro del job correspondiente. Ejemplo en GitHub Actions:

```yaml
- name: Validaciones de calidad
  run: |
    QUALITY_LINT_CMD="shellcheck scripts/**/*.sh" \
    QUALITY_TEST_CMD="bats --recursive tests" \
    QUALITY_COVERAGE_CMD="coverage report --fail-under=85" \
    bash scripts/quality/ejecutar_validaciones.sh --min-coverage 85
```

Esto mantiene alineados los hooks locales y el pipeline central, evitando
desviaciones entre ambientes.

## Accessing MediaWiki

After successful deployment:
- URL: https://192.168.1.100/mediawiki/
- Admin credentials: See `config/secrets.env`

## Troubleshooting

**VMs not starting:**
```bash
# Check VirtualBox
vboxmanage list vms

# Check Vagrant status
vagrant status

# View logs
vagrant ssh mediawiki-web01 -c "sudo tail -f /var/log/mediawiki-setup.log"
```

**Network issues:**
```bash
# Test connectivity
vagrant ssh mediawiki-web01 -c "ping -c 3 10.0.2.20"

# Check firewall
vagrant ssh mediawiki-web01 -c "sudo ufw status"
```

**MediaWiki issues:**
```bash
# Check Apache
vagrant ssh mediawiki-web01 -c "sudo systemctl status apache2"

# Check PHP
vagrant ssh mediawiki-web01 -c "php -v"

# Check logs
vagrant ssh mediawiki-web01 -c "sudo tail -f /var/log/apache2/mediawiki_error.log"
```

## Security

**IMPORTANT:** This project uses self-signed SSL certificates suitable for development/lab environments only. For production deployments:
- Use valid SSL certificates (Let's Encrypt, commercial CA)
- Review and update security configurations
- Change all default passwords
- Enable additional security measures as needed

## License

MIT License - See LICENSE file for details

## Contributing

1. Fork the repository
2. Create feature branch
3. Follow trunk-based workflow
4. Ensure all quality checks pass
5. Submit pull request

## Support

For issues and questions:
- GitHub Issues: https://github.com/your-username/mediawiki-production-lab/issues
- Documentation: docs/ directory

## Acknowledgments

- MediaWiki: https://www.mediawiki.org
- Vagrant: https://www.vagrantup.com
- VirtualBox: https://www.virtualbox.org