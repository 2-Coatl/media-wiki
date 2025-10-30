---
id: DOC-DEVOPS-002
estado: vigente
propietario: Plataforma
ultima_actualizacion: 2025-02-20
relacionados: [DOC-INDEX-001, RB-OPS-VER-001]
---
# Guía de Entorno Local con Vagrant y Postman

Esta guía sustituye los flujos basados en contenedores Docker y Dev Containers.
El laboratorio opera exclusivamente con máquinas virtuales provistas por Vagrant
y las verificaciones funcionales se realizan con colecciones de Postman. Si en
algún momento se requiere un runtime de contenedores puntual para utilidades
específicas, se empleará **Podman** en modo rootless en lugar de Docker.

## Prerrequisitos

1. **Vagrant 2.3 o superior** con el provider VirtualBox.
2. **VirtualBox 7.x** con soporte para redes host-only y bridged.
3. **Postman Desktop** (o la versión CLI `newman` si se automatizan suites).
4. **Podman 4.x** (opcional) para ejecutar contenedores aislados cuando algún
   script de soporte lo requiera.
5. Acceso a este repositorio clonado de forma local.

## Aprovisionamiento con Vagrant

1. Posiciónate en la raíz del repositorio y ejecuta `vagrant status` para validar
   que las máquinas virtuales no estén en ejecución.
2. Levanta la base de datos: `vagrant up mediawiki-db01`.
3. Levanta el servidor web: `vagrant up mediawiki-web01`.
4. (Opcional) Levanta la estación de gestión cuando esté disponible:
   `vagrant up mediawiki-mgmt01`.
5. Verifica conectividad entre nodos con `scripts/validation/validate-network.sh`.
6. Tras las pruebas, detén las máquinas con `vagrant halt` o destrúyelas con
   `vagrant destroy` si requieres un entorno limpio.

## Validaciones con Postman

1. Importa la colección `docs/07-devops/postman/mediawiki-smoke.postman_collection.json`.
2. Configura el entorno `MediaWiki Vagrant` usando la variable `baseUrl` con el
   valor `http://192.168.1.100` (IP expuesta por `mediawiki-web01`).
3. Ejecuta la colección para validar los endpoints críticos (`/api.php`,
   `/index.php`, `/wiki/Main_Page`).
4. Si necesitas automatizarla en CI, usa `newman run docs/07-devops/postman/mediawiki-smoke.postman_collection.json -e docs/07-devops/postman/mediawiki-vagrant.postman_environment.json`.

## Buenas prácticas

- Todo nuevo script debe consumir las utilidades de logging y validación para
  mantener trazabilidad en los aprovisionamientos.
- Documenta cualquier ajuste manual al entorno en `docs/05-operaciones/notas/`.
- Para diagnósticos rápidos, usa `vagrant ssh <vm>` y consulta los logs con
  `journalctl` o los archivos bajo `/var/log/mediawiki`.
- Mantén las colecciones de Postman versionadas dentro del repositorio para
  garantizar que el equipo comparte la misma base de pruebas.

## Uso puntual de Podman

- Ejecuta `podman run` únicamente para utilidades efímeras documentadas en los
  scripts del repositorio (por ejemplo, empaquetar reportes o validar integraciones
  externas) y evita habilitar Docker.
- Mantén los contenedores efímeros y versionados mediante scripts en
  `scripts/operations/` para no desalinear el estado del entorno.
- Cuando se documente una herramienta contenida, agrega las instrucciones precisas
  en `docs/05-operaciones/notas/` para preservar la trazabilidad.

## Próximos pasos

- Migrar los runbooks existentes para que referencien esta guía en lugar de
  instrucciones históricas basadas en Docker.
- Publicar automatizaciones con `newman` integradas a los scripts de validación.
- Documentar casos de uso adicionales de Postman (por ejemplo, pruebas de carga
  ligeras usando iteraciones).
