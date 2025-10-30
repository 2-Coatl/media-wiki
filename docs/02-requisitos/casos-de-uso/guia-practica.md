---
id: DOC-RQ-UC-GUIA
estado: borrador
propietario: Equipo de Análisis
ultima_actualizacion: 2025-02-16
relacionados: [DOC-RQ-UC-INDEX, DOC-RQ-RN-INDEX]
---
# Guía práctica de casos de uso

Esta guía consolida criterios operativos para especificar y modelar casos de uso dentro del proyecto.

## 1. Definición y propósito
- Un caso de uso describe una secuencia de interacciones entre un sistema y un actor que entrega un resultado de valor para dicho actor.
- El término proviene del trabajo de Ivar Jacobson (1986) y es parte del cuerpo metodológico de UML y el Proceso Unificado.
- Los casos de uso expresan el comportamiento visible del sistema desde la perspectiva del usuario.

### Diferencia con los escenarios
- Un escenario (o flujo) es una instancia concreta del caso de uso.
- Un caso de uso es la colección completa de escenarios necesarios para lograr el objetivo del actor.

## 2. Especificar vs. ilustrar
- **Especificar** casos de uso implica escribir documentación textual de los flujos.
- **Ilustrar** se refiere a crear diagramas UML de casos de uso que muestran actores, casos y relaciones en una "fotografía" del sistema.
- Evita frases como "dibujar casos de uso" cuando la tarea es elaborar la especificación textual.

## 3. Relación con desarrollo
- El desarrollo implementa requisitos funcionales que habilitan a los usuarios a ejecutar los casos de uso.
- Los casos de uso no sustituyen otras vistas necesarias (diagramas de actividades, clases, procesos, estructura de datos, etc.).

## 4. Nomenclatura
- Regla obligatoria: nombrar cada caso como **verbo + objeto** (p. ej. `Registrar vuelo`).
- Mantén consistencia con las acciones que los usuarios realizan sobre el sistema.

### Ejemplos
- Registrar vuelo / Registro en vuelo / Hacer check-in.
- Imprimir pases de abordar.
- Cambiar asientos.
- Registrar equipaje.
- Comprar actualización de asiento.

## 5. Actores
- Un actor puede ser persona, sistema externo, dispositivo o base de datos que interactúa con el sistema.
- Buenas prácticas:
  - Capitalizar los nombres en especificaciones.
  - Diferenciar **actores primarios** (disparan el caso) y **actores secundarios** (proveen soporte).

## 6. Escenarios
- Un escenario es una historia particular descrita mediante pasos actor ↔ sistema.
- Cada escenario debe indicar claramente el intercambio en cada paso.
- Los escenarios alternos pueden representar rutas de éxito o fracaso.

## 7. Formatos de documentación

### Principio "qué" vs. "cómo"
- Las especificaciones deben describir **qué** hace el sistema, nunca **cómo** lo implementa.
- Ejemplo válido: "El sistema guarda una venta".
- Ejemplo inválido: "El sistema ejecuta un `INSERT` en la base de datos".

### Grados de formalidad
| Formato | Características | Cuándo usar |
|---------|-----------------|-------------|
| Breve   | Un párrafo resume el flujo principal. | Notas rápidas o alcance preliminar. |
| Casual  | Varios párrafos informales cubren múltiples escenarios. | Talleres o pizarrones colaborativos. |
| Completo| Lista detallada de pasos, variaciones, pre/post-condiciones. | Base contractual y trazabilidad. |

### Plantilla en dos columnas
Utiliza dos columnas para separar acciones del actor y responsabilidades del sistema.

```
┌──────────────────────────────────┬────────────────────────────┐
│ ACCIONES DEL ACTOR               │ RESPUESTAS DEL SISTEMA     │
├──────────────────────────────────┼────────────────────────────┤
│ 1. El cliente presenta artículos │                            │
│ 2. El cajero inicia venta        │                            │
│ 3. Captura identificador         │ 4. El sistema registra y   │
│                                  │    subtotaliza artículos   │
│ ...                              │ ...                        │
│ 7. Cliente paga                  │ 8. El sistema procesa pago │
└──────────────────────────────────┴────────────────────────────┘
```

### Plantillas completas listas para copiar
Las siguientes plantillas estandarizan la captura de información clave y deben utilizarse al crear o actualizar casos de uso.

#### 7.1 Formato completo en Markdown

```markdown
---
id: UC-<dominio>-<n>
nombre: <Verbo + Objeto>
prioridad: <alta | media | baja>
estado: <borrador | en_revision | aprobado>
version: <vMayor.vMenor>
autor: <Nombre responsable>
fecha: <AAAA-MM-DD>
relacionados:
  requisitos: [RF-XXX, RN-YYY]
  pruebas: [TC-ZZZ]
  diagramas: [UML-UC-XX]
---

## Descripción
Breve objetivo del actor y valor generado.

## Actores
- **Primarios:** <Actor principal>
- **Secundarios:** <Actor de soporte, sistema externo, BD>

## Precondiciones
- <Condición 1>
- <Condición 2 (opcional)>

## Postcondiciones
- <Resultado esperado en éxito>
- <Resultados alternos si aplica>

## Flujo principal (Happy Path)
| Paso | Actor | Acción |
|------|-------|--------|
| 1    | <Actor/Sistema> | <Descripción del paso> |
| 2    | <Actor/Sistema> | <Descripción> |

## Flujos alternos
- **FA-1** — Condición: <condición detectable>
  1. <Paso alterno>
  2. <Paso alterno>
  - Retorna a paso `<n>` del flujo principal

- **FA-2** — Condición: <condición>
  1. ...

## Excepciones
- **EX-1** — Condición: <error o evento>
  - <Acción / finalización>

## Requisitos especiales
- <Atributo de calidad, restricción técnica, tecnología involucrada>

## Notas y decisiones
- <Suposiciones, referencias a ADR, acuerdos de stakeholders>
```

#### 7.2 Formato tabular (hoja de cálculo)

| Campo | Detalle | Ejemplo |
|-------|---------|---------|
| Identificador | UC-<dominio>-<n> | UC-ALM-004 |
| Nombre | Verbo + Objeto | Solicitar producto químico |
| Objetivo | Resultado de valor | Garantizar abastecimiento seguro |
| Actor primario | Responsable del disparo | Solicitante |
| Actores secundarios | Soporte | Comprador, Base de datos |
| Precondiciones | Estado previo | Usuario autenticado |
| Postcondiciones | Estado final | Solicitud registrada |
| Curso normal | Lista numerada | 1. Selecciona producto ... |
| Flujos alternos | Identificador + descripción | FA-1: Producto no disponible |
| Excepciones | Fin anómalo | EX-1: Catálogo sin registro |
| Requisitos especiales | NFR / restricciones | RN-SEC-012: Trazabilidad |
| Reglas relacionadas | RN- | RN-LOG-010 |
| Pruebas relacionadas | TC- | TC-UC-004-01 |
| Decisiones | Referencias a ADR | ADR-012: Política de sustitución |

#### 7.3 Checklist de verificación

1. [ ] El nombre cumple con la nomenclatura verbo + objeto.
2. [ ] Se definieron actores primarios y secundarios.
3. [ ] Pre y postcondiciones están alineadas con reglas vigentes.
4. [ ] El flujo principal describe interacción paso a paso actor ↔ sistema.
5. [ ] Los flujos alternos tienen condición detectable y manejo claro.
6. [ ] Excepciones documentan cierres anticipados y mensajes al usuario.
7. [ ] Se vincularon reglas de negocio, requisitos y casos de prueba.
8. [ ] Se registraron notas o decisiones relevantes (o referencias a ADR).

## 8. Diagramas UML de casos de uso
- Elementos clave: actores (figuras de palo), casos (óvalos), relaciones (líneas/flechas) y límite del sistema (rectángulo).
- La dirección de la flecha desde actor → caso identifica al actor principal. Flechas desde caso → actor indican soporte.

```
┌────────────────────────────┐
│        Sistema POS         │
│  ○ Procesar venta ◀───👤BD  │
│  ○ Registrar vuelo ◀───👤DB │
│        ▲             │     │
│        │             ▼     │
│      👤Cajero────▶○Pagar    │
└────────────────────────────┘
```

## 9. Elementos de información
- **Actores:** Primarios y secundarios relevantes.
- **Precondiciones:** Estados que deben cumplirse antes de iniciar el flujo (pueden no existir).
- **Postcondiciones:** Estado tras completar el caso (éxito o final alterno).
- **Curso normal (happy path):** Trayectoria típica sin desviaciones.
- **Cursos alternos:** Flujos secundarios con condición + manejo.
- **Excepciones:** Variaciones que terminan el caso o disparan errores.
- **Requisitos especiales:** Atributos de calidad, restricciones no funcionales, variaciones tecnológicas.
- **Reglas de negocio asociadas:** Referenciar identificadores (`RN-XXX`).

## 10. Ejemplo UC-04 "Solicitar producto químico"
- **Actores:** Solicitante (primario), Comprador y Base de datos (secundarios).
- **Precondiciones:** Solicitante autenticado, catálogo disponible.
- **Curso normal:** Seleccionar producto, validar disponibilidad, confirmar y registrar solicitud, notificar al comprador.
- **Flujo alterno 4.1:** Manejar producto no disponible (sugerencias, selección alternativa, retorno al paso 5).
- **Excepción 4.1.1:** Producto no encontrado en catálogo → mensaje de error, opción de solicitar alta y fin del caso.
- **Postcondiciones:** Solicitud registrada y comprador notificado.
- **Trazabilidad:** Prioridad alta, uso diario, reglas `BR-28` y `BR-31` vinculadas.

## 11. Apoyo visual
- Refuerza la especificación con diagramas de actividad para mapear ramificaciones y extensiones.
- Ejemplo general:

```
[Precondiciones]
   ▼
 Paso 1 → Paso 2 → ¿Condición?
                  ↙         ↘
             Flujo alterno  Flujo normal
                  ▼               ▼
               Paso 4        Paso 4
                  ▼               ▼
             [Postcondiciones]
```

## 12. Buenas prácticas
- Mantén identificadores únicos (`UC-XXX`) para asegurar trazabilidad.
- Relaciona cada caso con requisitos, reglas (`RN-`), pruebas (`TC-`) y actores.
- Documenta criterios de negocio relevantes directamente en el caso de uso en lugar de duplicarlos en múltiples artefactos.
- Evalúa dividir extensiones complejas en nuevos casos de uso relacionados.

## 13. Próximos pasos
- Completar documentación de `UC-PORTAL-001` conforme a esta guía.
- Incorporar diagramas UML y de actividad en los casos existentes.
- Revisar la matriz de trazabilidad para asegurar que actores, reglas y pruebas estén alineadas con los escenarios descritos.
