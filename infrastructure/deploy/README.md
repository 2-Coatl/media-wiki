# Scripts de despliegue

Los scripts de este directorio facilitan la automatización de despliegues en los diferentes entornos.

El comando principal es `desplegar.sh`, que ejecuta las rutinas de seguridad en el orden validado por el equipo.
Puedes sobreescribir el directorio de scripts de seguridad con `DEPLOY_SECURITY_DIR` (útil en pruebas) y registrar
la secuencia ejecutada con `DEPLOY_SECURITY_LOG`.

## Orden oficial de rutinas de seguridad

| Orden | Script                    | Propósito resumido                                 | Dependencias clave | Recuperación sugerida |
|-------|---------------------------|----------------------------------------------------|--------------------|------------------------|
| 1     | `harden-ssh.sh`           | Endurece `sshd_config` y reinicia el servicio SSH. | `systemctl`, `sshd`| Restaurar respaldo `sshd_config.backup.*` y ejecutar `systemctl restart sshd`. |
| 2     | `install-fail2ban.sh`     | Instala y habilita Fail2ban con jails básicos.     | `apt-get`, `systemctl`, `fail2ban-client` | Revisar `systemctl status fail2ban`, restaurar `jail.local.backup.*` y relanzar el script. |
| 3     | `firewall-web.sh`         | Configura UFW para el servidor web.                | `ufw`, `apt-get`   | Consultar `ufw status`, corregir reglas manualmente o ejecutar `ufw --force reset` antes de reintentar. |
| 4     | `firewall-database.sh`    | Ajusta UFW en la base de datos para restringir MySQL al host web. | `ufw`, `apt-get`, variables de `config/10-network.sh` | Validar `ufw status numbered`, reestablecer reglas con `ufw --force reset` y volver a ejecutar. |
| 5     | `ssl-certificate.sh`      | Genera certificado y clave autofirmados.           | `openssl`, permisos en `/etc/ssl/` | Verificar archivos en `/etc/ssl/{certs,private}/`, eliminar artefactos inconsistentes y regenerar. |
| 6     | `apache-ssl.sh`           | Habilita HTTPS en Apache y fuerza redirección HTTP→HTTPS. | `a2enmod`, `a2ensite`, `systemctl`, `curl` | Revisar `apache2ctl configtest`, deshacer cambios con respaldos `mediawiki-ssl.conf.backup.*` y repetir. |
| 7     | `harden-apache.sh`        | Aplica cabeceras y deshabilita módulos innecesarios. | `a2query`, `a2dismod`, `apache2ctl` | Ejecutar `apache2ctl configtest`, restaurar respaldos en `/etc/apache2/` y reiniciar Apache. |

## Dependencias generales

- Acceso privilegiado (root) para modificar servicios del sistema.
- Herramientas de red: `curl`, `nc`, `ufw`, `fail2ban-client`.
- Utilidades de Apache (`a2query`, `a2enmod`, `a2ensite`, `apache2ctl`).
- Paquetes del sistema instalables vía `apt-get`.
- Archivo de log compartido (`/var/log/mediawiki-setup.log`) expuesto por `infrastructure/utils/logging.sh`.

## Recuperación ante fallos

1. Revisar la salida en pantalla o en `/var/log/mediawiki-setup.log` para identificar la rutina fallida.
2. Restaurar los archivos de configuración desde los respaldos que cada script genera automáticamente
   (`*.backup.<timestamp>` en `/etc/ssh/`, `/etc/fail2ban/`, `/etc/apache2/`, etc.).
3. Validar el estado del servicio afectado con `systemctl status <servicio>` y los comandos informativos
   que cada script imprime (por ejemplo `fail2ban-client status`).
4. Reintentar la rutina fallida ejecutando directamente `bash infrastructure/security/<script>.sh` o relanzando
   `infrastructure/deploy/desplegar.sh` tras corregir el problema.
5. En entornos Vagrant, se recomienda realizar un `vagrant snapshot save` previo al despliegue para poder
   volver rápidamente al estado anterior ante errores críticos.
