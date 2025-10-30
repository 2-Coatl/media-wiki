---
id: NOTE-SEG-001
estado: vigente
propietario: Equipo de Seguridad
ultima_actualizacion: 2025-02-15
relacionados: [ADR-2024-006]
---
# Informe de controles de seguridad

## Alcance y metodología
Se revisaron los scripts de la carpeta `scripts/security` para identificar los controles de endurecimiento actualmente automatizados. Debido a las dependencias sobre servicios del sistema (UFW, Apache, SSH, Fail2ban) y al potencial impacto en el entorno de laboratorio, solo se validó la sintaxis con `bash -n` y se analizó el contenido de cada script, sin ejecutarlos de forma completa.

## Controles identificados
| Control | Script(s) | Implementación | Observaciones |
| --- | --- | --- | --- |
| TLS/HTTPS | `scripts/security/ssl-certificate.sh`, `scripts/security/apache-ssl.sh` | Generación de certificado autofirmado, permisos estrictos y despliegue de un VirtualHost HTTPS con protocolos TLS >=1.2, suites robustas, HSTS y cabeceras de seguridad.| El redireccionamiento HTTP está codificado a `https://192.168.1.100/`, lo que requiere ajustes en otros entornos. 【F:scripts/security/ssl-certificate.sh†L1-L126】【F:scripts/security/apache-ssl.sh†L1-L208】|
| Firewall | `scripts/security/firewall-web.sh`, `scripts/security/firewall-database.sh` | Configuración de UFW con política restrictiva, apertura de puertos mínimos (22/80/443 para web y 22/3306 limitado a la IP de la aplicación) y validaciones básicas de estado.| No se cubren reglas de salida específicas ni listas de control para servicios adicionales. 【F:scripts/security/firewall-web.sh†L1-L124】【F:scripts/security/firewall-database.sh†L1-L124】|
| Fail2ban | `scripts/security/install-fail2ban.sh` | Instalación, habilitación del servicio y jails para SSH y Apache (auth, badbots, noscript, overflows). Incluye parámetros configurables de bantime/findtime/maxretry.| Falta integración con correo real o SIEM, y no hay verificación de estado individual de todos los jails. 【F:scripts/security/install-fail2ban.sh†L1-L188】|
| Endurecimiento SSH | `scripts/security/harden-ssh.sh` | Deshabilita acceso root y contraseñas vacías, limita reintentos, desactiva X11 forwarding y verifica sintaxis antes de reiniciar el servicio.| No deshabilita `PasswordAuthentication`, lo cual se recomienda para producción. 【F:scripts/security/harden-ssh.sh†L1-L152】|
| Logs locales | `scripts/security/apache-ssl.sh`, `scripts/security/install-fail2ban.sh` | El VirtualHost HTTPS define archivos dedicados de error y acceso; Fail2ban vigila `/var/log/auth.log` y registros de Apache.| No existen tareas para centralizar o rotar registros ni para proteger integridad de logs. 【F:scripts/security/apache-ssl.sh†L60-L86】【F:scripts/security/install-fail2ban.sh†L49-L78】|
| IDS | _No disponible_ | _No se identificó ningún script que despliegue o configure un IDS/IPS (por ejemplo, Wazuh, OSSEC, Snort)._ | Brecha completa frente al checklist. |

## Comparación con checklist de hardening
- **TLS:** Cumplido parcialmente. Se habilita HTTPS forzado con configuraciones seguras, pero depende de certificados autofirmados que deben sustituirse en producción.【F:scripts/security/ssl-certificate.sh†L44-L110】【F:scripts/security/apache-ssl.sh†L45-L118】
- **Firewall:** Cumplido. Existen scripts separados para frontend y base de datos con políticas restrictivas y validaciones posteriores.【F:scripts/security/firewall-web.sh†L28-L107】【F:scripts/security/firewall-database.sh†L28-L111】
- **Fail2ban:** Cumplido parcialmente. Se instalan jails críticos, aunque falta monitoreo continuo y alertamiento externo.【F:scripts/security/install-fail2ban.sh†L33-L156】
- **SSH:** Cumplido parcialmente. Se aplican controles básicos, pero queda pendiente endurecer la autenticación con claves y revisar cifrados/ProtocolVersion.【F:scripts/security/harden-ssh.sh†L24-L108】
- **Logs:** No cumplido. No hay automatización para centralización, retención ni monitoreo de logs más allá de los archivos locales configurados por Apache y Fail2ban.【F:scripts/security/apache-ssl.sh†L60-L86】【F:scripts/security/install-fail2ban.sh†L49-L78】
- **IDS:** No cumplido. No existe despliegue ni integración de soluciones de detección de intrusiones.

## Priorización de riesgos
1. **Ausencia de IDS/IPS (Alta).** Deja sin capacidad de detección temprana de compromisos o movimientos laterales. Recomendado evaluar soluciones como Wazuh/OSSEC o Snort y automatizar su instalación.
2. **Gestión de logs limitada (Alta).** Sin centralización ni retención, los eventos críticos pueden perderse o alterarse. Priorizar la integración con un servidor de logs o SIEM y políticas de rotación/retención.
3. **Autenticación SSH basada en contraseña (Media).** Mantener `PasswordAuthentication` activo incrementa el riesgo de fuerza bruta aun con Fail2ban. Configurar autenticación por claves y restringir algoritmos inseguros.
4. **Certificados autofirmados en producción (Media).** Adecuados para entornos de laboratorio, pero deben reemplazarse por certificados válidos o AC interna antes de exponer el servicio.
5. **Cobertura parcial de Fail2ban (Media).** Validar periódicamente el estado de los jails y extender monitoreo a servicios adicionales (ej. PHP-FPM, API). Integrar alertas.
6. **Dependencia de direcciones IP fijas en UFW (Baja).** Cambios de topología requieren ajustes manuales. Se sugiere parametrizar o emplear grupos de seguridad dinámicos.

## Próximos pasos sugeridos
- Definir y automatizar la implantación de un IDS acorde al entorno objetivo.
- Diseñar un plan de logging centralizado con retención y monitoreo (ej. Filebeat + ELK o rsyslog centralizado).
- Extender el endurecimiento de SSH con autenticación por claves, deshabilitando contraseñas, y revisar Kex/Ciphers/HostKeyAlgorithms.
- Sustituir certificados autofirmados por una solución gestionada (ACME/Let's Encrypt o PKI corporativa).
- Ampliar los scripts de Fail2ban para validar todos los jails y generar alertas externas.
- Parametrizar las reglas de firewall para facilitar despliegues en múltiples entornos.
