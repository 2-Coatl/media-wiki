---
id: DOC-DEVOPS-002
estado: vigente
propietario: Plataforma
ultima_actualizacion: 2025-02-21
relacionados: [DOC-INDEX-001, RB-OPS-VER-001, DOC-DEVOPS-004]
---
# Guía de Entorno Local con Vagrant

## Objetivo
Definir el flujo oficial para aprovisionar, operar y cerrar el entorno local de
MediaWiki empleando Vagrant como capa de infraestructura reproducible. El
propósito es garantizar que todos los equipos levanten las mismas máquinas y
configuraciones antes de ejecutar pruebas funcionales o actividades de soporte.

## Alcance
- Equipos de plataforma y desarrollo que deben contar con un entorno MediaWiki
  local completamente funcional.
- Incluye la preparación de máquinas virtuales, validaciones básicas de red y
  pautas de operación cotidiana dentro del laboratorio Vagrant.
- No cubre pruebas funcionales ni herramientas de contenedores, las cuales se
  documentan en guías específicas de Postman y Podman.

## Requisitos previos
1. **Vagrant 2.3 o superior** con el provider VirtualBox instalado.
2. **VirtualBox 7.x** con redes host-only y bridged habilitadas.
3. Acceso local a este repositorio clonado y permisos para ejecutar scripts.
4. Recursos mínimos: 8 GB de RAM disponibles y 30 GB libres en disco.

## Componentes del entorno
### Máquinas virtuales declaradas en el `Vagrantfile`
- `mediawiki-db01`: base de datos MariaDB con datos de prueba iniciales.
- `mediawiki-web01`: servidor Apache/PHP configurado con la aplicación MediaWiki.
- `mediawiki-mgmt01`: estación opcional para herramientas administrativas.

### Scripts y artefactos de apoyo
- Scripts de validación bajo `infrastructure/validation/` para comprobar conectividad y
  dependencias entre máquinas.
- Plantillas de configuración compartidas dentro de `config/vagrant/`.

## Flujo de aprovisionamiento
1. Ejecuta `vagrant status` en la raíz del repositorio para confirmar que no hay
   máquinas en ejecución.
2. Levanta la base de datos con `vagrant up mediawiki-db01` y espera a que
   finalice la provisión.
3. Levanta el servidor web con `vagrant up mediawiki-web01`.
4. (Opcional) Provisiona la estación de gestión con
   `vagrant up mediawiki-mgmt01` cuando esté disponible.
5. Valida la red interna con `infrastructure/validation/validate-network.sh`.
6. Documenta cualquier desviación o error encontrado en los runbooks
   correspondientes.

## Operación diaria y diagnósticos
- Usa `vagrant ssh <vm>` para conectarte a cada máquina virtual y ejecutar
  diagnósticos locales (`journalctl`, `/var/log/mediawiki`, etc.).
- Aplica los scripts de logging y validación provistos para mantener trazabilidad
  y detectar cambios de configuración no autorizados.
- Mantén sincronizados los archivos compartidos montados desde el host y evita
  modificar configuraciones de sistema directamente en las máquinas si no se
  registran en control de versiones.

## Cierre del entorno
1. Confirma que no existan procesos `vagrant` activos antes de apagar el equipo.
2. Detén los servicios con `vagrant halt` para un cierre ordenado.
3. Elimina snapshots obsoletos con `vagrant snapshot delete` y libera disco con
   `vagrant destroy` cuando necesites un estado limpio.
4. Actualiza el runbook post-create con incidencias o aprendizajes relevantes.

## Buenas prácticas y consideraciones
- Versiona los cambios al `Vagrantfile` y a los scripts de validación dentro del
  repositorio; evita modificaciones locales no documentadas.
- Coordina con Operaciones antes de ajustar recursos de las máquinas virtuales
  (CPU, RAM) para mantener paridad entre equipos.
- Mantén la red host-only `192.168.1.0/24` reservada exclusivamente para el
  laboratorio y revisa colisiones en caso de usar otras herramientas de
  virtualización.

## Glosario rápido
- **Vagrant:** Herramienta para crear y administrar entornos virtuales
  reproducibles mediante un `Vagrantfile` versionado.
- **VirtualBox:** Provider utilizado para ejecutar las máquinas virtuales
  declaradas en Vagrant.

## Referencias
- [Índice general de documentación](../README.md)
- [Runbook post-create de entorno Vagrant](runbooks/post_create.md)
- [Guía de validación funcional con Postman](postman_validacion.md)
- [Utilidades auxiliares con Podman](podman_utilidades_auxiliares.md)
