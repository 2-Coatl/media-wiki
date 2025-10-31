---
id: NOTE-SEG-002
estado: en_revision
propietario: Equipo de Seguridad
ultima_actualizacion: 2025-02-15
relacionados: [NOTE-SEG-001, ADR-2024-006]
---
# Brechas de seguridad y continuidad identificadas

Este documento registra las brechas detectadas durante la revisión del despliegue actual de MediaWiki. Cada entrada incluye una estimación cualitativa del impacto y del esfuerzo requerido para corregirla, con el fin de priorizar las mejoras.

## Resumen de brechas

| ID | Brecha | Impacto estimado | Esfuerzo estimado | Evidencia y notas |
| --- | --- | --- | --- | --- |
| B-01 | MariaDB expuesto a todas las interfaces mediante `bind-address = 0.0.0.0`. | Alto: habilita conexiones desde cualquier origen, incrementando el riesgo de acceso no autorizado si fallan los controles de red. | Bajo: requiere ajustar el valor de enlace y validar conectividad entre las VMs. | La configuración generada por `install_mariadb.sh` fuerza el parámetro `bind-address = 0.0.0.0`. |
| B-02 | Configuración de Fail2ban referencia una acción inexistente `%(action_mw)s`. | Alto: Fail2ban puede fallar al cargar `jail.local`, dejando sin protección frente a ataques de fuerza bruta. | Medio: es necesario definir una acción soportada (por ejemplo `%(action_mwl)s`) y validar los flujos de notificación. | El template de `jail.local` define `action = %(action_mw)s` sin que exista una acción con ese identificador. |
| B-03 | No existe automatización para generar respaldos periódicos de la base de datos. | Muy alto: una pérdida de datos implicaría restauraciones manuales o imposibles. | Medio/Alto: requiere diseñar scripts de respaldo, almacenamiento local en `backups/` y políticas de retención. | El repositorio documenta `backups/` como destino de respaldos, pero la carpeta de `infrastructure/` no contiene utilidades de respaldo. |

### Escala utilizada

- **Impacto**: Bajo (1), Medio (2), Alto (3), Muy alto (4).
- **Esfuerzo**: Bajo (≤0.5 días), Medio (1–2 días), Alto (>2 días). La escala asume un equipo familiarizado con el stack actual.

## Detalles por brecha

### B-01 – MariaDB expuesto en todas las interfaces
- **Descripción**: El script `install_mariadb.sh` genera `/etc/mysql/mariadb.conf.d/99-mediawiki.cnf` con `bind-address = 0.0.0.0`, exponiendo el servicio a todas las interfaces de red.
- **Impacto**: Alto. Aumenta la superficie de ataque, contradice la intención de aislar la base de datos y requiere que el firewall opere sin fallas.
- **Esfuerzo**: Bajo. Implica parametrizar el bind address (por ejemplo usando `DB_APP_IP`) y ejecutar pruebas de conectividad desde la VM web.
- **Mitigación propuesta**: Ajustar el parámetro a la IP interna del servidor y agregar pruebas automatizadas que aseguren el valor esperado.

### B-02 – Acción inexistente en Fail2ban
- **Descripción**: `install_fail2ban.sh` escribe `action = %(action_mw)s` en `jail.local`, pero el repositorio no proporciona un archivo `action.d` ni redefine el placeholder, lo que puede impedir que Fail2ban arranque.
- **Impacto**: Alto. Sin Fail2ban activo, el servidor queda expuesto a ataques de fuerza bruta en SSH y Apache.
- **Esfuerzo**: Medio. Se debe seleccionar una acción soportada o empaquetar una personalizada, probarla en ambos servidores y documentar el flujo.
- **Mitigación propuesta**: Reemplazar la acción por `%(action_mwl)s` (incluye logging y correo) o crear un archivo `action.d/mediawiki.local` con el comportamiento deseado.

### B-03 – Ausencia de automatización de respaldos
- **Descripción**: Aunque el README reserva el directorio `backups/` para respaldos, no existe un módulo en `infrastructure/` que genere copias de la base de datos ni políticas de retención.
- **Impacto**: Muy alto. Ante corrupción o compromisos, la recuperación dependería de respaldos manuales inexistentes.
- **Esfuerzo**: Medio/Alto. Se requiere diseñar scripts parametrizables, coordinar cron/Timers de systemd y validar restauraciones.
- **Mitigación propuesta**: Implementar un script `infrastructure/backups/create_mariadb_backup.sh` que use credenciales de `infrastructure/config/secrets.env`, almacene los dumps con sellos de tiempo y limite la retención.

## Priorización sugerida

1. **Corregir B-01 y B-02 de inmediato**: alto impacto, bajo/medio esfuerzo, refuerzan controles preventivos.
2. **Planificar B-03 como iniciativa prioritaria**: requiere diseño adicional pero mitiga el riesgo más crítico (pérdida de datos).
3. Documentar pruebas y checklists para asegurar que las mitigaciones se mantengan en futuras iteraciones.
