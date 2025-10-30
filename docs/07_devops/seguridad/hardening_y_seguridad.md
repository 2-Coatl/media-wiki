---
id: DOC-DEVOPS-011
estado: vigente
propietario: Seguridad
ultima_actualizacion: 2025-02-21
relacionados: [DOC-INDEX-001, DOC-DEVOPS-PLAN-001, DOC-DEVOPS-022]
---
# Hardening y seguridad integral

> Enlaza con el [índice general](../../README.md) y con los runbooks operativos para seguimiento.

## 1. Resumen ejecutivo

MediaWiki Production Lab mantiene una postura de seguridad defensiva basada en segmentación de red, hardening del sistema operativo y monitoreo continuo. El score objetivo es ≥85/100 en validaciones periódicas.

## 2. Hardening del sistema operativo

- Deshabilitar servicios innecesarios (`telnet`, `rlogin`, `avahi-daemon`).
- Configurar parámetros `sysctl`:
  ```bash
  net.ipv4.ip_forward = 0
  net.ipv4.conf.all.rp_filter = 1
  kernel.randomize_va_space = 2
  ```
- Aplica `unattended-upgrades` para parches automáticos.
- Verifica integridad con `aide --check` semanalmente.

## 3. Seguridad de red

| Elemento | Medida |
| --- | --- |
| Segmentación | Vagrant define redes `public`, `app`, `monitoring`, `host_only` |
| Firewall | UFW/iptables con políticas `deny` por defecto |
| VPN | WireGuard opcional para accesos remotos |
| IDS | Nagios + revisión de logs con alertas Fail2ban |

## 4. Seguridad de aplicaciones

### Apache
- ModSecurity activado con reglas OWASP CRS.
- Cabeceras seguras (`X-Frame-Options`, `X-Content-Type-Options`).
- TLS 1.2+ obligatorio.

### PHP
- `expose_php = Off`.
- `disable_functions = exec,passthru,shell_exec,system`.

### MariaDB
- Usuarios con `GRANT` mínimos.
- Rotación trimestral de contraseñas vía `infrastructure/security/rotate-db-passwords.sh`.

### MediaWiki
- Extensiones revisadas en security review checklist.
- Restricción de lectura anónima y límites de API (`$wgRateLimits`).

## 5. Controles de acceso

- SSH con autenticación de llaves y `PermitRootLogin no`.
- MFA opcional para paneles internos mediante Authelia (planificado).
- Permisos MediaWiki basados en grupos (`sysop`, `bureaucrat`, `ops` personalizados).

## 6. Monitoreo y respuesta a incidentes

1. Nagios supervisa disponibilidad y certificados.
2. Fail2ban protege servicios críticos (`sshd`, `apache-auth`).
3. Rsyslog centraliza eventos; `goaccess` genera reportes diarios.
4. Ante incidente:
   - Identifica alcance.
   - Contén (bloqueo IP/servicio).
   - Erradica y aplica parches.
   - Recupera y valida con `infrastructure/validation/final-validation.sh`.
   - Documenta lecciones aprendidas en `docs/05_operaciones/notas/`.

## 7. Cumplimiento y auditoría

- Bitácoras en `/var/log/central/` retenidas 90 días.
- Revisiones mensuales de accesos privilegiados.
- Auditorías trimestrales alineadas a CIS Benchmark para Debian.

## 8. Checklist de seguridad

- [ ] Actualizar paquetes (`unattended-upgrades` en verde).
- [ ] Revisar reportes de `lynis` y remediar findings.
- [ ] Validar expiración de certificados TLS (>30 días).
- [ ] Ejecutar `tests/security/test-hardening.sh` y asegurar 100% de checks.
- [ ] Confirmar integridad de backups cifrados.

## 9. Gestión de vulnerabilidades

1. Ejecutar `infrastructure/security/vulnerability-scan.sh` semanalmente.
2. Clasificar findings por severidad (CVSS >=7 es crítico).
3. Crear issue en backlog y asignar responsable.
4. Validar remediación con re-scan.

## 10. Contactos y responsabilidades

| Rol | Responsable | Contacto |
| --- | --- | --- |
| CISO | Laura Méndez | seguridad@example.org |
| Líder Seguridad | Andrés Rojas | arojas@example.org |
| Equipo Azul | Turno rotativo | canal `#seguridad-mediawiki` |

## Referencias cruzadas

- [Referencias de configuración](../configuracion/referencia_configuracion_mediawiki.md)
- [Manual operacional](../../05_operaciones/manual_operaciones_mediawiki.md)
- [Plan maestro de tareas](../plan_tareas_mediawiki.md)
