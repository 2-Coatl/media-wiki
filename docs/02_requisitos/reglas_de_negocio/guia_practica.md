---
id: DOC-RQ-RN-GUIA
estado: borrador
propietario: Oficina de Cumplimiento
ultima_actualizacion: 2025-02-16
relacionados: [DOC-RQ-RN-INDEX, DOC-RQ-UC-INDEX]
---
# Guía práctica de reglas de negocio

Esta guía complementa el catálogo de reglas documentando definiciones, taxonomía y ejemplos aplicables al proyecto.

## 1. Conceptos fundamentales
- Las reglas de negocio son políticas, leyes y estándares que rigen la operación de la organización.
- Constituyen el nivel superior de la jerarquía de requerimientos y guían objetivos, necesidades de usuario y funcionalidad del sistema.
- Son conocidas como lógica de negocio e impactan directamente en acceso, funcionalidad y atributos de calidad.

### Influencia en los tipos de requerimientos
| Tipo | Impacto de la regla | Ejemplo |
|------|---------------------|---------|
| Requerimiento de negocio | Define objetivos obligatorios para cumplir regulaciones. | Cumplir normativas de manejo y eliminación de químicos en 5 meses. |
| Requerimiento de usuario  | Restringe quién puede ejecutar tareas. | Solo gerentes pueden generar reportes de exposición química. |
| Requerimiento funcional   | Determina pasos del proceso automatizado. | Alta automática de proveedor no registrado al recibir factura. |
| Atributo de calidad       | Impone controles de seguridad o desempeño. | Verificar capacitación antes de solicitar químicos peligrosos. |

## 2. Clasificación principal
Identifica y etiqueta cada regla según su naturaleza para facilitar su implementación y validación.

### 2.1 Hechos
- Declaraciones verdaderas e inmutables sobre el negocio.
- Describen asociaciones entre términos (p. ej. "Cada contenedor químico tiene un código de barras único").
- Ejemplos adicionales: matrícula obligatoria para alumnos, órdenes con combinación de producto, grado y tamaño de envase.

### 2.2 Restricciones
- Limita acciones de usuarios o del sistema.
- Indicadores lingüísticos comunes: "debe", "no debe", "no puede", "solo puede".
- Ejemplos: menores de 18 requieren tutor para préstamos; máximo de 10 artículos en espera; ocultar dígitos sensibles de identificadores.
- Documenta restricciones complejas mediante matrices de roles y permisos.

```
┌────────────────────────────┬─────────┬────────┬──────────┐
│ Operación                  │ Admin   │ Staff  │ Usuario  │
├────────────────────────────┼─────────┼────────┼──────────┤
│ Ver registros              │   ✓     │   ✓    │   ✓      │
│ Editar registros           │   ✓     │   ✓    │   ✗      │
│ Eliminar registros         │   ✓     │   ✗    │   ✗      │
│ Configurar sistema         │   ✓     │   ✗    │   ✗      │
└────────────────────────────┴─────────┴────────┴──────────┘
```

### 2.3 Desencadenadores de acción
- Reglas de tipo "Si [condición] entonces [acción]" que provocan comportamientos.
- Ejemplos: ofrecer contenedores disponibles al solicitante; notificar responsable al alcanzar fecha de vencimiento.

### 2.4 Inferencias
- Generan nuevo conocimiento a partir de condiciones verdaderas.
- Diferencia clave: la cláusula "entonces" produce un estado, no una acción.
- Ejemplos: marcar cuenta como deudora tras 30 días sin pago; cancelar órdenes que no se envían en cinco días.

### 2.5 Cálculos computacionales
- Transforman datos usando fórmulas o algoritmos definidos (frecuentemente externos, como impuestos o cuotas).
- Ejemplos: cálculo de envío base + peso adicional; precio total = artículos − descuentos + impuestos + envío + seguros.
- Recomienda representar cálculos complejos en tablas para evitar ambigüedad.

```
┌────────────────────────┬────────────────────┬────────────────────┐
│ Identificador          │ Cantidad comprada  │ % Descuento        │
├────────────────────────┼────────────────────┼────────────────────┤
│ DISC-1                 │ 1 – 5              │ 0%                 │
│ DISC-2                 │ 6 – 10             │ 10%                │
│ DISC-3                 │ 11 – 20            │ 20%                │
│ DISC-4                 │ 21 o más           │ 30%                │
└────────────────────────┴────────────────────┴────────────────────┘
```

## 3. Procedimiento de documentación
1. Determina si la regla modifica hechos existentes, restringe comportamientos, dispara acciones, deriva conocimiento o realiza cálculos.
2. Asigna un identificador `RN-<dominio>-<n>` y registra la clasificación principal.
3. Describe:
   - Condiciones y alcance (¿cuándo aplica?).
   - Datos de referencia (legislación, políticas internas, estándares externos).
   - Impacto en casos de uso, requisitos y pruebas.
4. Define mecanismos de verificación (auditorías, pruebas automatizadas, revisiones manuales).

## 4. Consideraciones operativas
- Mantén alineada la documentación con cambios regulatorios (LGPD, ISO 27001, OSHA/EPA, SSA).
- Integra reglas con los casos de uso mediante trazabilidad (`RN-` ↔ `UC-` ↔ `TC-`).
- Para reglas complejas, evalúa capturarlas como artefactos separados (p. ej. políticas anexas o catálogos de cálculos).
- Revisa los vacíos actuales: `RN-LOG-010`, matriz de segregación de funciones y referencias normativas vigentes.

## 5. Próximos pasos
- Catalogar las reglas extraídas durante talleres de requisitos, clasificándolas según esta guía.
- Incorporar ejemplos de cálculos (envíos, impuestos) en los artefactos afectados.
- Sincronizar cambios con la matriz de trazabilidad y los casos de uso correspondientes.

## 6. Plantillas completas listas para copiar

### 6.1 Formato maestro en Markdown

```markdown
---
id: RN-<dominio>-<n>
titulo: <Enunciado breve>
tipo: <hecho | restriccion | activador | inferencia | calculo>
estado: <borrador | en_revision | vigente | obsoleta>
version: <vMayor.vMenor>
autor: <Responsable>
fecha: <AAAA-MM-DD>
fuentes: [<Norma externa>, <Política interna>]
relacionados:
  casos_de_uso: [UC-XXX]
  requisitos: [RF-YYY]
  pruebas: [TC-ZZZ]
---

## Declaración
Texto exacto de la regla.

## Intención de negocio
Objetivo o riesgo que la regla busca cubrir.

## Condiciones de aplicación
- <Situación o contexto>
- <Excepciones permitidas>

## Acciones / Derivaciones
- <Impacto en procesos, mensajes, cálculos>

## Datos involucrados
- <Entidades, atributos, catálogos>

## Mecanismos de verificación
- <Prueba automatizada, auditoría, revisión manual>

## Notas y decisiones
- <Suposiciones, referencias a ADR, acuerdos regulatorios>
```

### 6.2 Plantilla tabular

| Campo | Detalle | Ejemplo |
|-------|---------|---------|
| Identificador | RN-<dominio>-<n> | RN-LOG-010 |
| Título | Resumen claro | Validar vigencia de permisos de almacenamiento |
| Tipo | Clasificación | restriccion |
| Estado | Workflow | vigente |
| Fuente | Regulación / política | NOM-005-STPS-1998 |
| Declaración | Texto literal | "El sistema debe impedir la entrega de químicos sin permiso vigente" |
| Condiciones | Contexto | Cuando el solicitante tiene permiso vencido |
| Acción / Derivación | Resultado | Bloquear entrega y notificar cumplimiento |
| Datos | Campos | Fecha_permiso, ID_permiso |
| Casos de uso | Referencia | UC-ALM-004 |
| Requisitos | RF/RN relacionados | RF-INV-012 |
| Pruebas | Casos de prueba | TC-RN-010-01 |
| Seguimiento | Métrica / control | Reporte mensual de incumplimientos |

### 6.3 Checklist de validación

1. [ ] El identificador sigue el patrón `RN-<dominio>-<n>` y es único.
2. [ ] Se documentó la fuente normativa o política interna.
3. [ ] La regla está clasificada según los cinco tipos aceptados.
4. [ ] Se definieron condiciones de aplicación y excepciones.
5. [ ] Se detallaron acciones, cálculos o conocimiento derivado.
6. [ ] Se identificaron datos afectados y validaciones asociadas.
7. [ ] Existe trazabilidad con casos de uso, requisitos y pruebas.
8. [ ] Se indicaron mecanismos de verificación y responsables.
