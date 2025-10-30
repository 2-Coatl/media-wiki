# 0003 - Convención de módulos para scripts Bash

## Estado
Aceptada

## Fecha
2024-06-07

## Contexto

Los directorios de `scripts/` concentran tareas operativas críticas (despliegue, migraciones, seguridad y
validaciones de calidad). Cada script evolucionó de forma independiente, mezclando responsabilidades,
nombres de funciones genéricos y flujos de inicialización duplicados. La ausencia de una convención única
provoca:

- Dificultad para descubrir dependencias entre scripts y reutilizar utilidades comunes.
- Barreras para escribir pruebas automatizadas bajo TDD, dado que los módulos no exponen contratos claros.
- Riesgo de colisiones al cargar funciones con el mismo nombre y efectos secundarios al hacer `source` de
  otros scripts.

## Decisión

Adoptar una convención modular inspirada en la estructura de `infrastructure/utils` descrita en el ADR 0001,
extendida a todos los scripts Bash:

1. Crear el directorio `scripts/modules` para almacenar utilidades compartidas por dominio (`logging`,
   `filesystem`, `network`, `security`).
2. Prefijar todas las funciones exportadas con `mw_<dominio>_` para evitar colisiones (`mw_logging_info`,
   `mw_security_hardening`).
3. Exponer un loader único `scripts/modules/loader.sh` responsable de inicializar variables de entorno,
   verificar dependencias y cargar módulos en el orden correcto.
4. Obligar a que cualquier script ejecutable (`scripts/**/foo.sh`) consuma utilidades mediante `source
   "$(dirname "$0")/../modules/loader.sh"` o path relativo equivalente.
5. Documentar contratos de entrada/salida en la cabecera de cada módulo e incluir ejemplos de uso y escenarios
   de prueba asociados.
6. Registrar nuevos módulos mediante documentación breve en `docs/notas/scripts-modules.md` para mantener el
   catálogo actualizado.

## Consecuencias

- **Positivas**
  - Se habilita un punto único de inicialización que reduce errores por dependencias implícitas.
  - La nomenclatura consistente simplifica la escritura de pruebas y facilita medir cobertura.
  - Se fomenta la reutilización de utilidades y la revisión por pares al centralizar la documentación.
- **Negativas**
  - Requiere migrar progresivamente scripts existentes hacia la nueva convención, priorizando los más críticos.
  - Añade un paso adicional (declarar módulos en el loader) cuando se crea un script nuevo.

## Próximos pasos

1. Inventariar los scripts actuales y clasificar funciones para migrarlas a módulos dedicados.
2. Crear pruebas Bats para el loader y para al menos un módulo representativo (`logging`).
3. Alinear las guías de contribución para exigir el uso del loader y el prefijo `mw_<dominio>_`.
