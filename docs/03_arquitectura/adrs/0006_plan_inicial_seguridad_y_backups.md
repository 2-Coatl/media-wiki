---
id: ADR-2024-006
estado: propuesta
propietario: Equipo de Infraestructura
ultima_actualizacion: 2025-02-15
relacionados: [NOTE-SEG-001, NOTE-SEG-002]
---
# 0006. Plan inicial para reforzar seguridad de servicios y respaldos

- **Estado:** Propuesto
- **Fecha:** 2024-06-08
- **Autores:** Equipo de infraestructura
- **Revisión:** Seguridad de plataforma

## Contexto

La revisión de los scripts de aprovisionamiento identificó brechas que incrementan la superficie de ataque y comprometen la capacidad de recuperación del despliegue:

- MariaDB se publica en todas las interfaces (`bind-address = 0.0.0.0`), contraviniendo el aislamiento de red esperado para la base de datos.
- Fail2ban referencia una acción inexistente (`%(action_mw)s`), lo que puede impedir que el servicio bloquee intentos de intrusión.
- No existe automatización para generar respaldos periódicos a pesar de contar con un directorio reservado para ellos.

Las tres brechas se describen con mayor detalle en `docs/05_operaciones/notas/seguridad_brechas.md` y fueron priorizadas por su impacto alto o muy alto.

## Decisión

Adoptar un plan inicial de mejoras con los siguientes alcances:

1. **Restringir la exposición de MariaDB**: parametrizar el `bind-address` para que utilice la IP interna (`DB_APP_IP`) y agregar validaciones automatizadas que aseguren que el servicio únicamente escuche en la red interna.
2. **Corregir la acción de Fail2ban**: sustituir `%(action_mw)s` por una acción soportada (por ejemplo `%(action_mwl)s`) o empaquetar una acción personalizada `action.d/mediawiki.local`, asegurando que Fail2ban inicie correctamente en los servidores web y de base de datos.
3. **Implementar respaldos automatizados**: crear un módulo `infrastructure/backups/create-mariadb-backup.sh` que genere dumps con sellos de tiempo, almacene los archivos en `backups/` y aplique políticas de retención y verificación básica de restauración.

El plan deberá seguir la metodología TDD del proyecto: cada mejora se desarrollará a través de pruebas automatizadas (Bats) que validen las configuraciones resultantes.

## Consecuencias

- **Positivas**
  - Reduce la probabilidad de accesos no autorizados a la base de datos al depender de una interfaz interna explícita.
  - Restablece la protección de Fail2ban frente a ataques de fuerza bruta y mantiene registros de auditoría.
  - Garantiza un proceso repetible de respaldos que soporta los objetivos de recuperación.
- **Negativas**
  - Incrementa el esfuerzo inicial en pruebas y documentación para cada script nuevo.
  - Requiere coordinar ventanas de mantenimiento para aplicar los cambios sin afectar entornos existentes.
  - Los respaldos incrementarán el consumo de almacenamiento y demandarán rotación periódica.

## Alternativas

- **Aplazar los cambios**: mantener la configuración actual y confiar en firewalls manuales. *Descartado* por el riesgo alto de exposición y la ausencia de respaldos.
- **Limitarse a monitoreo**: agregar alertas sin modificar la configuración actual. *Descartado* porque no reduce la superficie de ataque ni ofrece recuperación ante pérdida de datos.
- **Implementar una solución externa de respaldos**: depender de herramientas SaaS. *Descartado* temporalmente por la necesidad de contar con una solución offline que funcione en entornos desconectados.
