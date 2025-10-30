---
id: DOC-DEVOPS-003
estado: vigente
propietario: Plataforma
ultima_actualizacion: 2025-02-24
relacionados: [DOC-INDEX-001, DOC-DEVOPS-002, DOC-DEVOPS-004, RB-OPS-VER-001]
---
# Utilidades auxiliares con Podman

## Objetivo
Proporcionar lineamientos para ejecutar herramientas auxiliares en contenedores
Podman cuando se requieran tareas de soporte puntuales para el entorno MediaWiki.
Esta guía complementa a las guías de Vagrant y Postman, evitando mezclar las
instrucciones principales de aprovisionamiento con el uso de contenedores
específicos.

## ¿Qué es Podman?
Podman es una herramienta nativa de Linux, de código abierto y sin demonio que
facilita encontrar, ejecutar, construir, compartir y desplegar aplicaciones
mediante contenedores e imágenes compatibles con OCI. Su interfaz de línea de
comandos es familiar para quienes han utilizado Docker; en la mayoría de los
casos basta con definir `alias docker=podman` para operar con equivalencia.

Al igual que otros motores de contenedores (Docker, CRI-O, containerd), Podman
depende de un runtime OCI (por ejemplo, `runc`, `crun`, `runv`) para interactuar
con el sistema operativo y crear contenedores. Esto hace que los contenedores
creados por Podman sean prácticamente indistinguibles de los generados por otras
herramientas comunes. Los contenedores bajo Podman pueden ejecutarse como root o
como usuarios sin privilegios y se gestionan mediante la biblioteca `libpod`,
que administra pods, contenedores, imágenes y volúmenes.

Podman ofrece una API REST para administrar contenedores y un cliente remoto
disponible en Linux, macOS y Windows. La API REST se soporta únicamente sobre
Linux. Para profundizar, se recomienda revisar la introducción oficial, los
tutoriales para usuarios avanzados y la referencia de comandos y API.

### Comandos principales
La CLI de Podman cubre desde la gestión del ciclo de vida de contenedores hasta
operaciones de red y artefactos. A continuación, se listan los subcomandos más
utilizados:

- `artifact`, `image`, `manifest`, `save`, `load`, `push`, `pull`, `search`,
  `tag` y `untag` para gestionar imágenes y artefactos OCI.
- `container`, `run`, `create`, `start`, `stop`, `restart`, `rm`, `exec`,
  `attach`, `logs`, `top`, `commit`, `diff`, `export`, `import`, `mount`,
  `unmount`, `wait` para operar contenedores individuales.
- `pod` y `kube` para agrupar contenedores y reproducir definiciones desde
  manifiestos Kubernetes o Quadlets.
- `auto-update`, `healthcheck`, `events`, `stats`, `system`, `info`, `version`
  para observabilidad y mantenimiento.
- `network`, `port`, `pause`, `unpause`, `machine`, `login`, `logout`, `rename`,
  `update`, `secret`, `farm`, `generate` para capacidades avanzadas y
  administración general.

Consulta `podman help <subcomando>` para obtener la descripción completa, las
opciones soportadas y los códigos de salida.

## Alcance
- Equipos que necesitan correr utilidades de diagnóstico, cobertura o linters sin
  instalarlas en las máquinas virtuales de Vagrant.
- Casos documentados en scripts bajo `scripts/operations/` o notas en
  `docs/05-operaciones/notas/`.
- No cubre la ejecución de Postman/Newman ni el aprovisionamiento del entorno
  principal.

## Requisitos previos
1. **Podman 4.x** instalado localmente con soporte para rootless containers.
2. Acceso al repositorio para reutilizar los scripts oficializados.
3. Conectividad a los registros internos autorizados cuando se requiera descargar
   imágenes privadas.

## Componentes y artefactos
- **Imágenes base** listadas en `docs/05-operaciones/notas/`.
- **Scripts de orquestación** dentro de `scripts/operations/` que invocan Podman.
- **Variables de entorno** definidas en cada script; revisar comentarios antes de
  ejecutar.
- **Cliente remoto** cuando se necesite operar contra la API REST desde estaciones
  macOS o Windows.

## Flujo general de uso
1. Revisa el script recomendado en `scripts/operations/` y valida parámetros.
2. Ejecuta el script o la instrucción `podman run` indicada para lanzar el
   contenedor efímero.
3. Realiza la tarea puntual (por ejemplo, generar un reporte de cobertura).
4. Detén el contenedor con `podman stop <nombre>` si el script no lo hace.
5. Elimina recursos temporales con `podman rm` y `podman rmi` cuando proceda.

## Buenas prácticas
- Documenta cualquier nueva imagen o parámetro en `docs/05-operaciones/notas/`.
- Evita privilegiar contenedores; usa `--userns=keep-id` y volúmenes de solo
  lectura cuando sea posible.
- Mantén el principio de contenedores efímeros: no guardes estado persistente ni
  dejes procesos activos tras finalizar la tarea.
- Registra en el runbook correspondiente cualquier desviación del flujo oficial.

## Guía de rendimiento
- **Runtime**: valida con `podman info --format={{.Host.OCIRuntime.Name}}` que se
  esté utilizando `crun`, generalmente el runtime más veloz.
- **Driver de almacenamiento**: prioriza `native overlayfs`; como alternativas,
  considera `fuse-overlayfs` o `vfs` según compatibilidad. Ajusta
  `/etc/containers/storage.conf` o `~/.config/containers/storage.conf` para
  definir el driver por defecto y recuerda que cambiarlo requiere `podman system
  reset`.
- **Benchmarking**: crea un usuario dedicado para pruebas de rendimiento y evita
  limpiar imágenes productivas. Utiliza `/usr/bin/time -v` para medir ejecuciones
  (por ejemplo, `podman --storage-driver=vfs run --rm docker.io/library/alpine
  /bin/true`).
- **Red rootless**: la red `pasta` es el valor por defecto; si necesitas mayor
  rendimiento evalúa `--network=host`, configurar un bridge manual o aprovechar
  sockets activados por systemd.
- **Descarga diferida**: habilita lazy pulling con formatos `zstd:chunked` o
  `eStargz` y usa sistemas de archivos con soporte `reflink` (XFS, BTRFS) para
  maximizar beneficios.
- **Construcciones eficientes**: reutiliza cachés de paquetes (por ejemplo con
  `podman build -v $HOME/dnf_cache_f36:/var/cache/dnf:O ...`) y desactiva logs si
  no se requieren mediante `--log-driver=none`.

## Resolución de problemas
- Si un contenedor no puede acceder a servicios internos, confirma la red
  host-only que expone Vagrant (`192.168.1.0/24`) y comparte los puertos
  necesarios con `--network host` solo cuando sea imprescindible.
- Ante conflictos de puertos, usa `podman ps --all` para identificar contenedores
  rezagados y eliminarlos.
- Cuando una imagen no esté disponible, coordina con Operaciones para replicar o
  publicar el artefacto en el registro correcto.

## Referencias
- [Guía de entorno local con Vagrant](entorno_vagrant.md)
- [Validación funcional con Postman](postman_validacion.md)
- [Runbook post-create de entorno Vagrant](runbooks/post-create.md)
- [Índice general de documentación](../README.md)
