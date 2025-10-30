---
id: DOC-DEVOPS-022
estado: borrador
propietario: Equipo DevOps
ultima_actualizacion: 2025-02-21
relacionados: [DOC-INDEX-001, DOC-DEVOPS-PLAN-001, DOC-DEVOPS-021]
---
# Referencia de configuración MediaWiki

> Este documento amplía la guía de instalación y se enlaza con el [índice general](../../README.md).

## 1. Introducción

Inventario de parámetros críticos aplicados en la plataforma MediaWiki Production Lab. Mantén este documento sincronizado tras cada cambio y crea ADR cuando la decisión sea estructural.

## 2. Apache HTTP Server

| Parámetro | Valor | Comentario |
| --- | --- | --- |
| `ServerName` | `mediawiki.local` | Resuelto vía `/etc/hosts` y DNS interno |
| `Protocols` | `h2 http/1.1` | Obliga HTTP/2 y compatibilidad fallback |
| `SSLCipherSuite` | `TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256` | Endurecimiento TLS 1.2+ |
| `SSLProtocol` | `-all +TLSv1.2 +TLSv1.3` | Bloquea protocolos inseguros |
| `Header always set Content-Security-Policy` | `default-src 'self';` | Minimiza riesgos XSS |

## 3. PHP 8.1

| Parámetro | Valor | Comentario |
| --- | --- | --- |
| `memory_limit` | `256M` | Soporta tareas de mantenimiento intensivas |
| `upload_max_filesize` | `50M` | Ajustado a necesidades de intranet |
| `post_max_size` | `52M` | Consistente con `upload_max_filesize` |
| `opcache.enable` | `1` | Mejora tiempos de respuesta |
| `display_errors` | `Off` | Evita exposición de stack traces en producción |

## 4. MariaDB 10.6

| Parámetro | Valor | Comentario |
| --- | --- | --- |
| `bind-address` | `10.0.2.20` | Limita acceso a red interna |
| `innodb_buffer_pool_size` | `1G` | Ajustado a 16 GB host (6% por VM) |
| `max_connections` | `200` | Equilibra concurrencia con recursos |
| `slow_query_log` | `ON` | Habilita identificación de cuellos de botella |
| `log_bin` | `ON` | Prepara replicación futura |

## 5. MediaWiki (`LocalSettings.php`)

| Parámetro | Valor | Comentario |
| --- | --- | --- |
| `$wgScriptPath` | `/mediawiki` | Define ruta principal |
| `$wgEnableUploads` | `true` | Permite subir archivos |
| `$wgUseInstantCommons` | `false` | Evita dependencias externas |
| `$wgGroupPermissions['*']['read']` | `false` | Requiere autenticación |
| `$wgRateLimits` | Configuración personalizada | Previene abuso de APIs |
| `$wgHooks['SkinAfterContent'][]` | `CustomFooterHooks::addFooter` | Extensión interna |

## 6. Firewall y seguridad de red

| Host | Herramienta | Reglas clave |
| --- | --- | --- |
| `mediawiki-web01` | UFW | Permitir 80/443; restringir SSH a subred operativa |
| `mediawiki-db01` | iptables | Permitir 3306 solo desde `10.0.2.10`; registrar drops |
| `mediawiki-mgmt01` | UFW | Permitir 5666 (NRPE) y 514 (syslog) desde red interna |

## 7. SSL/TLS

| Elemento | Detalle |
| --- | --- |
| Certificados | Emitidos con Certbot en modo standalone; renovación programada vía cron |
| HSTS | `Strict-Transport-Security: max-age=31536000; includeSubDomains` |
| OCSP Stapling | Activado en Apache con `SSLUseStapling on` |

## 8. Tabla de referencia rápida

| Servicio | Archivo | Ruta |
| --- | --- | --- |
| Apache | VirtualHost principal | `/etc/apache2/sites-available/mediawiki.conf` |
| PHP | `php.ini` | `/etc/php/8.1/apache2/php.ini` |
| MariaDB | Configuración principal | `/etc/mysql/mariadb.conf.d/60-mediawiki.cnf` |
| MediaWiki | Ajustes | `/var/www/html/mediawiki/LocalSettings.php` |
| Firewall web | Reglas UFW | `/etc/ufw/applications.d/mediawiki` |

## 9. Configuraciones alternativas

- Habilitar cache de objetos con Redis (ajustar `$wgObjectCaches`).
- Cambiar tamaño máximo de subida a 100 MB para wikis multimedia.
- Integrar autenticación corporativa vía LDAP (`$wgLDAPDomainNames`).

## 10. Proceso de actualización

1. Documenta la modificación en un ADR si afecta arquitectura.
2. Crea rama feature siguiendo TDD (tests primero, objetivo ≥80% coverage).
3. Aplica cambio en entorno de staging (`vagrant up` aislado).
4. Ejecuta `./infrastructure/run-all-tests.sh` y revisa `tests/reports/`.
5. Solicita revisión cruzada y valida despliegue usando `infrastructure/integration/final-integration.sh`.

## Referencias cruzadas

- [Guía de instalación integral](../instalacion/guia_instalacion_mediawiki.md)
- [Hardening y seguridad integral](../seguridad/hardening_y_seguridad.md)
- [Runbooks de configuración](../runbooks)
