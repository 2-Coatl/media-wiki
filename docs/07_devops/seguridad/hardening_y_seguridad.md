---
id: DOC-DEVOPS-011
estado: vigente
propietario: Seguridad
ultima_actualizacion: 2025-02-21
relacionados: [DOC-INDEX-001, DOC-DEVOPS-PLAN-001]
---
# Hardening y Seguridad Integral

Este documento resume las acciones de endurecimiento del sistema operativo y los
servicios críticos del laboratorio MediaWiki. Cada sección referencia los
scripts bajo `scripts/security/` y los validadores en `scripts/validation/` que
sostienen el puntaje de seguridad acordado (>80).

## 1. Endurecimiento del sistema operativo

- **Script central**: `scripts/security/harden-system.sh`.
- **Funciones destacadas**:
  - `disable_unnecessary_services` para desactivar `bluetooth`, `cups`,
    `avahi-daemon` y cualquier servicio no requerido (`systemctl disable --now`).
  - `configure_sysctl` genera `/etc/sysctl.d/99-security.conf` con parámetros
    críticos: `net.ipv4.ip_forward = 0`, `net.ipv4.tcp_syncookies = 1`,
    `net.ipv4.conf.all.accept_redirects = 0`, etc.
  - `configure_limits` y `disable_core_dumps` limitan recursos y evitan volcado
    de memoria no autorizado.
  - `secure_shared_memory` monta `/run/shm` con `noexec,nodev,nosuid`.
- **Validaciones**:
  - `sysctl -a | grep net.ipv4.ip_forward` debe devolver `0`.
  - `systemctl list-unit-files --state=enabled` sin servicios superfluos.
  - `/etc/security/limits.conf` y `/etc/profile` incluyen los cambios.

## 2. Hardening de Apache

- **Automatización**: `scripts/security/harden-apache.sh`.
- **Medidas**:
  - `Options -Indexes` en VirtualHosts o en fragmentos dedicados.
  - `ServerSignature Off`, `ServerTokens Prod` y `TraceEnable Off`.
  - Límites de solicitud (`LimitRequestBody 10485760`), `Timeout 60` y
    `KeepAliveTimeout 5`.
  - Deshabilitar módulos no usados con `a2dismod autoindex status`.
  - Protección de rutas sensibles (`<FilesMatch "\.(git|svn|htaccess)$">`).
- **Comprobaciones**:
  - `apache2ctl -M` confirmando que `security2_module`/`headers_module` están
    presentes y módulos innecesarios deshabilitados.
  - `curl -I https://192.168.1.100` sin cabeceras que revelen versiones.

## 3. Hardening de MariaDB

- **Script**: `scripts/security/harden-database.sh`.
- **Acciones principales**:
  - Verificar `mysql_secure_installation` ejecutado (sin usuarios anónimos ni
    base `test`).
  - `REVOKE FILE ON *.* FROM 'wikiuser'@'10.0.2.%';` para evitar accesos a
    filesystem.
  - `local-infile = 0` y `bind-address = 10.0.2.20` en `config/mysql/security.cnf`.
  - Configurar SSL opcional (`ssl-ca`, `ssl-cert`, `ssl-key`).
  - Auditar usuarios y privilegios (`SELECT User, Host FROM mysql.user`).
  - Asegurar permisos de `/var/lib/mysql` (`chmod 750`, propietario `mysql`).
- **Validaciones**:
  - `SHOW GRANTS FOR 'wikiuser'@'10.0.2.%';` confirmando privilegios mínimos.
  - `ss -tuln | grep 3306` mostrando escucha solo en la IP privada.

## 4. Hardening de SSH

- **Script**: `scripts/security/harden-ssh.sh` ejecutado en cada VM.
- **Puntos clave**:
  - Respaldo de `/etc/ssh/sshd_config`.
  - `PermitRootLogin no`, `PermitEmptyPasswords no`, `Protocol 2`.
  - Autenticación con claves habilitada (`PubkeyAuthentication yes`).
  - Límites de sesiones (`MaxAuthTries 3`, `MaxSessions 2`, `LoginGraceTime 60`).
  - Cifrados y MACs seguros (`aes256-ctr`, `hmac-sha2-512`).
  - `AllowUsers vagrant` para restringir accesos en el laboratorio.
- **Validaciones**:
  - `sshd -t` sin errores.
  - Pruebas de conexión desde el host confirmando credenciales válidas.

## 5. AppArmor

- **Script**: `scripts/security/configure-apparmor.sh`.
- **Actividades**:
  - `apparmor_status` para revisar perfiles cargados.
  - Instalación de utilidades (`apparmor-utils`).
  - Enforzar perfiles `usr.sbin.apache2` y `usr.sbin.mysqld` con `aa-enforce`.
  - Registro de perfiles personalizados si el laboratorio añade servicios
    adicionales.
- **Validaciones**:
  - `aa-status` mostrando los perfiles en modo `enforce`.
  - Confirmar que Apache/MariaDB operan sin denegaciones inesperadas (revisar
    `/var/log/syslog`).

## 6. Auditorías de seguridad

- **Script maestro**: `scripts/security/security-audit.sh`.
- **Cobertura**:
  - Inventario de usuarios y grupos (`getent passwd`, `getent group`).
  - Permisos de archivos críticos (`/etc/passwd`, `/etc/shadow`, `/etc/gshadow`).
  - Búsqueda de binarios SUID (`find / -perm -4000`).
  - Archivos world-writable (`find / -xdev -type f -perm -0002`).
  - Servicios activos (`systemctl list-units --type=service --state=running`).
  - Puertos abiertos (`ss -tuln`).
  - Revisión de parches pendientes (`apt list --upgradable`).
  - Escaneo de rootkits (`rkhunter` o `chkrootkit`).
  - Generación de reporte con clasificación de severidad en
    `/var/log/security-audit.log`.
- **Acciones posteriores**: Remediar hallazgos `CRITICAL`/`HIGH` y documentar
  evidencias antes de cerrar la auditoría.

## 7. Validación integral

- Ejecutar `scripts/validation/validate-group-g.sh` para consolidar:
  - Estado de `sysctl`, `umask` y servicios deshabilitados.
  - Hardening de Apache, MariaDB y SSH.
  - Perfiles de AppArmor y resultados de `security-audit.sh`.
  - Score final (>80) registrado en la bitácora de seguridad.
- Generar evidencias (capturas de comandos, reportes) y anexarlas al repositorio
  de operaciones cuando se cierre el ciclo.

## Referencias

- [Índice de documentación](../../README.md)
- [Plan maestro de tareas](../plan_tareas_mediawiki.md)
