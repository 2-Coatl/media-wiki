---
id: DOC-DEVOPS-012
estado: vigente
propietario: Observabilidad
ultima_actualizacion: 2025-02-21
relacionados: [DOC-INDEX-001, DOC-DEVOPS-PLAN-001]
---
# Monitoreo y Logging

Guía operativa para desplegar, validar y mantener el stack de monitoreo y
centralización de logs del laboratorio MediaWiki. Cubre Nagios, plugins
personalizados, alertas, logging centralizado y dashboards complementarios.

## 1. Configuración base de Nagios

- **Archivos fuente** en `config/monitoring/`:
  - `nagios-hosts.cfg` con definiciones para `mediawiki-web01` y
    `mediawiki-db01`.
  - `nagios-services.cfg` incluyendo HTTP, HTTPS, SSH, PING, discos, carga y
    procesos monitoreados mediante NRPE.
  - `nagios-contacts.cfg` con el contacto `admin` y grupos de notificación.
- **Automatización**: `infrastructure/configuration/configure-nagios-monitoring.sh`
  copia los archivos, edita `nagios.cfg` para incluirlos, instala NRPE y plugins
  necesarios en cada VM y ejecuta `nagios -v` antes de reiniciar el servicio.
- **Pasos clave**:
  1. Instalar `nagios-nrpe-server` y `nagios-plugins` en `web01`/`db01`.
  2. Definir `allowed_hosts = 127.0.0.1,10.0.3.30` en `/etc/nagios/nrpe.cfg`.
  3. Reiniciar `nagios-nrpe-server` y validar acceso desde `mgmt01` con
     `check_nrpe -H 10.0.3.10`.
  4. En `mgmt01`, ejecutar `/usr/local/nagios/bin/nagios -v` y reiniciar Nagios.
  5. Verificar la UI en `http://192.168.56.30/nagios`.
- **Criterios de aceptación**: hosts en estado `UP`, servicios `OK` y detección
  de alertas cuando se induce una falla controlada.

## 2. Plugins personalizados

- **Ubicación**: `monitoring/plugins/` con scripts como `check_mediawiki.sh`,
  `check_mediawiki_jobs.sh`, `check_apache_workers.sh` y verificadores de espacio
  en disco específicos.
- **Implementación**:
  - Copiar a `/usr/local/nagios/libexec/` en `mgmt01` con permisos ejecutables.
  - Declarar comandos personalizados en `nagios-commands.cfg` (añadir include si
    no existe).
  - Registrar servicios en `nagios-services.cfg` apuntando a los nuevos
    comandos.
- **Validaciones**:
  - Ejecución manual `./check_mediawiki.sh -H 10.0.3.10`.
  - Estado `OK/WARNING/CRITICAL` correcto según thresholds definidos.

## 3. Alertas y notificaciones

- **Lineamientos**:
  - Configurar Postfix (o relay externo) en `mgmt01` para envío de correos.
  - `config/monitoring/alert-rules.conf` documenta umbrales (CPU, memoria, disco)
    y escalaciones.
- **Actualizaciones en Nagios**:
  - Ajustar `contacts.cfg` y `contactgroups` para reflejar destinatarios reales.
  - Definir `notification_period`, `notification_interval` y `notification_options`.
  - Establecer dependencias entre hosts/servicios para evitar ruido.
- **Pruebas**:
  - `nagios -v` tras cualquier cambio.
  - Generar una alerta forzada (`service nagios stop` en un host monitorizado)
    y verificar recepción de notificación.

## 4. Logging centralizado

- **Scripts**: `infrastructure/configuration/enhance-logging.sh` consolida ajustes en
  Apache, MediaWiki, MariaDB y PHP para enriquecer logs y garantizar su
  reenvío hacia `mgmt01` mediante `rsyslog`.
- **Acciones**:
  - Definir `CustomLog` con tiempos de respuesta y user-agent.
  - Configurar `LocalSettings.php` para habilitar `$wgDebugLogFile` y grupos
    (`$wgDebugLogGroups`).
  - Validar slow query log y error log en MariaDB.
  - Establecer `error_log` dedicado para PHP.
  - Confirmar reenvío con `logger` y revisar `/var/log/remote/` en `mgmt01`.
  - Configurar `logwatch` u otra herramienta para resúmenes automáticos.

## 5. Dashboard de monitoreo

- **Recomendación**: instalar Thruk en `mgmt01` para vistas amigables.
- **Pasos**:
  - Instalar paquetes (`thruk`, dependencias de Apache y FastCGI).
  - Integrar con los datos de Nagios (`/etc/thruk/thruk_local.d/`).
  - Crear vistas personalizadas: estado de producción, servicios críticos,
    métricas de rendimiento.
  - Configurar autenticación y refresco automático.
  - Documentar acceso remoto y pruebas en distintos dispositivos.
- **Entregables**: capturas del dashboard y enlaces desde la bitácora de
  operaciones.

## 6. Validación integral

- Ejecutar `infrastructure/validation/validate-group-h.sh` para comprobar:
  - Estado del servicio Nagios y ausencia de errores de configuración.
  - Disponibilidad de NRPE en las VMs.
  - Flujo de logs hacia `mgmt01` y rotación correcta.
  - Alertas disparadas ante caídas simuladas de Apache.
  - Reporte final con hallazgos y recomendaciones.

## Referencias

- [Índice de documentación](../../README.md)
- [Plan maestro de tareas](../plan_tareas_mediawiki.md)
