---
id: DOC-DEVOPS-010
estado: vigente
propietario: Plataforma
ultima_actualizacion: 2025-02-21
relacionados: [DOC-INDEX-001, DOC-DEVOPS-PLAN-001]
---
# Configuración de Servicios Avanzados

Esta guía consolida las actividades para fortalecer los servicios de la
plataforma MediaWiki en el laboratorio de producción. Cada apartado documenta
artefactos en `config/`, `scripts/` y verificaciones operativas indispensables
para cerrar el bloque de configuración avanzada descrito en el plan maestro.

## 1. Apache HTTP Server

- **Archivos de configuración**: mantener los fragmentos bajo `config/apache/`:
  - `security-headers.conf` con cabeceras `X-Content-Type-Options`,
    `X-Frame-Options`, `X-XSS-Protection`, `Referrer-Policy` y
    `Permissions-Policy`.
  - `performance.conf` para compresión `mod_deflate`, cache con `mod_expires` y
    controles con `mod_headers`.
  - `mpm-prefork.conf` para ajustar `StartServers`, `MaxRequestWorkers` y
    `MaxConnectionsPerChild` según la carga objetivo.
- **Script recomendado**: `scripts/configuration/configure-apache-advanced.sh`.
  Implementa funciones para respaldar configuraciones (`backup_apache_config`),
  instalar fragmentos (`install_security_headers`, `install_performance_config`),
  endurecer la huella (`disable_server_tokens`, `configure_timeout`) y validar la
  sintaxis (`test_apache_config`).
- **Validaciones clave**:
  - `apache2ctl configtest` sin errores.
  - `curl -I http://192.168.1.100` para verificar cabeceras de seguridad.
  - `curl -H "Accept-Encoding: gzip" -I http://192.168.1.100` confirmando
    compresión.
- **Criterios de aceptación**: headers aplicados, compresión activa, caché
  diferenciada por tipo de archivo y reinicio exitoso mediante
  `systemctl restart apache2`.

## 2. MariaDB

- **Archivos**: `config/mysql/performance.cnf`, `config/mysql/security.cnf` y
  `config/mysql/logging.cnf` definen los parámetros de rendimiento, seguridad y
  auditoría.
- **Script sugerido**: `scripts/configuration/configure-mariadb-advanced.sh`.
  Prioriza un respaldo inicial (`backup_mysql_config`), copia las plantillas,
  crea archivos de log (`create_log_files`) y prepara la rotación semanal en
  `/etc/logrotate.d/mysql`.
- **Ajustes recomendados**:
  - `innodb_buffer_pool_size = 512M`, `innodb_log_file_size = 128M`,
    `thread_cache_size = 50`, `table_open_cache = 400`, `max_connections = 200`.
  - Seguridad: `local-infile = 0`, `skip-symbolic-links`, `skip-name-resolve`.
  - Logging: slow query log en `/var/log/mysql/slow.log`, error log en
    `/var/log/mysql/error.log`.
- **Validaciones**:
  - `mysql -e "SHOW VARIABLES LIKE 'innodb_buffer_pool_size';"`.
  - Revisión de permisos de log (`ls -l /var/log/mysql`).
  - Servicio activo después de `systemctl restart mariadb`.

## 3. SSL/TLS

- **Artefactos**:
  - Directorio `config/ssl/` para almacenar plantillas de certificados.
  - Script `scripts/security/generate-certificates.sh` que crea claves de 4096
    bits, CSR y certificados autofirmados en `/etc/ssl/mediawiki/`.
  - VirtualHost `config/apache/ssl-vhost.conf` con TLSv1.2+ y HSTS.
- **Despliegue automatizado**: `scripts/configuration/configure-ssl.sh` habilita
  `mod_ssl`, copia el VirtualHost, aplica redirección permanente de HTTP a HTTPS
  y actualiza `LocalSettings.php` (`$wgServer`, `$wgForceHTTPS`).
- **Pruebas**:
  - `apache2ctl configtest`.
  - `curl -k https://192.168.1.100` para confirmar respuesta.
  - `curl -I http://192.168.1.100` comprobando redirección 301 a HTTPS.
  - `openssl x509 -in /etc/ssl/mediawiki/server.crt -text -noout` validando datos.

## 4. Firewalls en todas las VMs

- **Reglas declarativas** bajo `config/firewall/`:
  - `web-server.rules` (HTTP/HTTPS abiertos, SSH restringido).
  - `database.rules` (MySQL expuesto solo hacia la red de aplicación).
  - `management.rules` (acceso Nagios y Syslog desde rangos permitidos).
- **Scripts**:
  - `scripts/security/configure-firewall-web.sh` con UFW (reset, políticas por
    defecto, reglas para SSH/HTTP/HTTPS y validación `ufw status verbose`).
  - `scripts/security/configure-firewall-db.sh` usando `iptables` persistentes
    (`iptables-persistent`).
  - `scripts/security/configure-firewall-mgmt.sh` replicando la lógica de UFW.
- **Validación transversal**: `scripts/validation/validate-firewall.sh` realiza
  pruebas de conectividad (SSH, HTTP(S), MySQL) y confirma bloqueos desde redes
  no autorizadas (p. ej. `nmap -p 3306 192.168.1.100` desde el host).

## 5. Fail2ban

- **Archivos base**:
  - `config/fail2ban/jails.conf` con reglas para `sshd`, `apache-auth`,
    `apache-badbots` y jail personalizada de MediaWiki.
  - `config/fail2ban/filters/mediawiki-auth.conf` para patrones de fallos de
    autenticación.
- **Instalación guiada**: `scripts/security/install-fail2ban.sh` cubre la
  instalación, respaldos (`backup_fail2ban_config`), copia de jails/filters,
  habilitación de servicio y pruebas de bloqueo (`test_ban`).
- **Comprobaciones**:
  - `fail2ban-client status` y `fail2ban-client status sshd`.
  - Verificación de reglas en iptables (`iptables -L -n`).
  - Logs centralizados en syslog para correlación con el servidor de monitoreo.

## 6. ModSecurity

- **Procedimiento**:
  - Instalar `libapache2-mod-security2` y habilitar `mod_security2` con
    `scripts/security/install-modsecurity.sh`.
  - Descargar OWASP CRS en `/etc/modsecurity/`, activar `SecRuleEngine On`,
    configurar `SecAuditLog` y registrar excepciones específicas para MediaWiki.
- **Pruebas**:
  - `apache2ctl configtest`.
  - Intentos controlados de inyección (`curl` con payload `UNION SELECT`) para
    verificar bloqueos.
  - Revisión del log `/var/log/apache2/modsec_audit.log`.

## 7. Validación integral

- Consolidar las comprobaciones con `scripts/validation/validate-group-f.sh`.
  Este script debe agrupar:
  - Headers de Apache, compresión y ajuste de MPM.
  - Variables de MariaDB y estado del slow query log.
  - Certificados activos, redirección a HTTPS y HSTS.
  - Estado de firewalls, Fail2ban y ModSecurity.
- Generar un reporte único que cierre el ciclo y adjuntarlo en la bitácora de
  operaciones.

## Referencias

- [Índice de documentación](../../README.md)
- [Plan maestro de tareas](../plan_tareas_mediawiki.md)
