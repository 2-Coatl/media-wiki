---
id: DOC-DEVOPS-004
estado: vigente
propietario: Plataforma
ultima_actualizacion: 2025-02-21
relacionados: [DOC-INDEX-001, DOC-DEVOPS-002, RB-OPS-VER-001]
---
# Validación funcional con Postman y Newman

## Objetivo
Establecer el flujo estándar para ejecutar validaciones funcionales de MediaWiki
mediante Postman (modo Desktop) y Newman (CLI), reutilizando las colecciones y
entornos versionados en este repositorio.

## Alcance
- Equipos de QA, plataforma y desarrollo que necesiten validar endpoints y
  flujos básicos de MediaWiki desplegado en el laboratorio Vagrant oficial.
- Incluye configuración de clientes, ejecución manual y automatizada de pruebas,
  y consideraciones para compartir colecciones.
- No cubre aprovisionamiento de infraestructura ni utilidades en contenedores.

## Requisitos previos
1. **Postman Desktop** instalado con sesión activa para importar colecciones.
2. **Newman** 6.x para ejecuciones automatizadas (`npm install -g newman`).
3. Acceso a las colecciones y entornos almacenados en `docs/07-devops/postman/`.
4. Entorno Vagrant activo o endpoint equivalente documentado en el runbook.

## Artefactos versionados
- Colección principal: `docs/07-devops/postman/mediawiki-smoke.postman_collection.json`.
- Entorno base: `docs/07-devops/postman/mediawiki-vagrant.postman_environment.json` con la variable `baseUrl` apuntando a `http://192.168.1.100`.
- Cualquier suite adicional debe almacenarse en la misma carpeta y referenciarse
  desde este documento.

## Flujo de ejecución manual (Postman Desktop)
1. Importa la colección y el entorno mencionados desde el repositorio.
2. Selecciona el entorno `mediawiki-vagrant` y confirma los valores de `baseUrl`
   y credenciales temporales si existen.
3. Ejecuta la colección completa o los folders necesarios para validar los
   endpoints `/api.php`, `/index.php` y `/wiki/Main_Page`.
4. Documenta resultados y hallazgos en el runbook correspondiente cuando haya
   desviaciones.

## Flujo de ejecución automatizada (Newman)
1. Asegura que `node` y `npm` estén disponibles en el host donde se ejecutará
   Newman.
2. Corre `newman run docs/07-devops/postman/mediawiki-smoke.postman_collection.json -e docs/07-devops/postman/mediawiki-vagrant.postman_environment.json`.
3. Para reportes en HTML agrega `-r cli,html` y define el directorio de salida
   con `--reporter-html-export reports/mediawiki-smoke.html`.
4. Integra la ejecución dentro de pipelines CI almacenando artefactos y salidas
   en la carpeta `reports/` o el repositorio designado.

## Buenas prácticas de colaboración
- Versiona modificaciones a colecciones y entornos mediante pull requests,
  incluyendo descripción de casos de prueba nuevos o actualizados.
- Evita compartir variables sensibles; usa placeholders y secretos locales.
- Documenta suites específicas (por ejemplo, regresión o API extendida) en
  subsecciones adicionales dentro de este archivo.

## Solución de problemas
- Si las ejecuciones fallan por tiempo de espera, verifica que el entorno
  Vagrant esté activo y que `baseUrl` resuelva correctamente desde el host.
- Cuando Newman reporte diferencias en snapshots, elimina la caché local de la
  colección e importa nuevamente desde el repositorio.
- Para automatizaciones en CI, revisa permisos de red hacia `192.168.1.100` o
  publica temporalmente un túnel documentado.

## Referencias
- [Guía de entorno local con Vagrant](entorno_vagrant.md)
- [Utilidades auxiliares con Podman](podman_utilidades_auxiliares.md)
- [Runbook post-create de entorno Vagrant](runbooks/post-create.md)
- [Índice general de documentación](../README.md)
