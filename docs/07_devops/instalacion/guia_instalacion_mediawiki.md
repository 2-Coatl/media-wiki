---
id: DOC-DEVOPS-021
estado: borrador
propietario: Equipo DevOps
ultima_actualizacion: 2025-02-21
relacionados: [DOC-INDEX-001, DOC-DEVOPS-PLAN-001]
---
# Guía de instalación integral

> Refiérete al [índice general de documentación](../../README.md) para más referencias y contexto.

## 1. Prerrequisitos

| Categoría | Requisito |
| --- | --- |
| Hardware | CPU con virtualización habilitada, 16 GB RAM, 80 GB libres |
| Software | VirtualBox 7+, Vagrant 2.4+, Git, Python 3.11+, `make` |
| Conocimientos | Terminal Linux, fundamentos de redes, nociones de TDD |

> **Nota:** valida que el BIOS tenga activada la virtualización Intel VT-x o AMD-V.

## 2. Preparación del entorno

1. Clona el repositorio:
   ```bash
   git clone https://example.org/mediawiki/media-wiki.git
   cd media-wiki
   ```
2. Crea un archivo `.env` a partir de la plantilla en `config/variables.ejemplo`.
3. Exporta variables sensibles para Vagrant:
   ```bash
   export MEDIAWIKI_ADMIN_PASS="CambiaEsto123"
   export MEDIAWIKI_DB_PASS="CambiaEsto321"
   ```
4. Instala dependencias auxiliares:
   ```bash
   pip install -r requirements-dev.txt
   ```

## 3. Instalación paso a paso

1. **Provisiona la infraestructura:**
   ```bash
   vagrant up
   ```
2. **Aplica configuraciones post-provisioning:**
   ```bash
   make provision-post
   ```
3. **Ejecuta migraciones y tareas de MediaWiki:**
   ```bash
   vagrant ssh mediawiki-web01 -- 'cd /var/www/html/mediawiki && php maintenance/update.php'
   ```
4. **Habilita extensiones personalizadas:**
   ```bash
   vagrant ssh mediawiki-web01 -- 'sudo -i /usr/local/bin/habilitar_extensiones.sh'
   ```
5. **Configura certificados TLS de prueba:**
   ```bash
   vagrant ssh mediawiki-web01 -- 'sudo certbot certonly --standalone -d mediawiki.local'
   ```

## 4. Verificación de instalación

| Check | Comando | Resultado esperado |
| --- | --- | --- |
| Estado de VMs | `vagrant status` | Tres VMs en `running` |
| Servicio web | `curl -I https://192.168.1.100` | Código 200 y redirección HTTPS |
| Acceso a DB | `vagrant ssh mediawiki-db01 -- 'mysql -u wikiuser -p -e "SHOW DATABASES;"'` | Base `wikidb` disponible |
| Monitoreo | `open http://192.168.56.30/nagios` | Dashboard sin alertas críticas |

## 5. Troubleshooting común

- **VM no arranca:**
  > **Nota:** ejecuta `vagrant up --debug` y revisa logs en `infrastructure/logs/`.
- **Fallo de red interna:** valida adaptadores host-only en VirtualBox y reinicia `vagrant reload`.
- **Certificados inválidos:** renueva con `certbot renew --dry-run` y revisa `/etc/letsencrypt/renewal/`.
- **Jobs en cola:** ejecuta `php maintenance/runJobs.php --maxjobs 500` desde `mediawiki-web01`.

## 6. Checklist post-instalación

- [ ] Actualizar contraseñas por defecto de admin y usuarios técnicos.
- [ ] Configurar backups automáticos (`infrastructure/operations/configurar_backups.sh`).
- [ ] Registrar las VMs en el inventario de activos.
- [ ] Ejecutar `./infrastructure/run-all-tests.sh` para validar la instalación.

## 7. Apéndice: salidas esperadas

```
==> mediawiki-web01: Machine booted and ready!
==> mediawiki-db01: Machine booted and ready!
==> mediawiki-mgmt01: Machine booted and ready!
```

```
HTTP/2 200 
server: Apache/2.4.58 (Debian)
content-type: text/html; charset=UTF-8
```

## Referencias cruzadas

- [Plan maestro de tareas](../plan_tareas_mediawiki.md)
- [Referencia de configuración](../configuracion/referencia_configuracion_mediawiki.md)
- [Runbooks de DevOps](../runbooks)
