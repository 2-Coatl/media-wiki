---
id: DOC-TRZ-001
estado: en_validacion
propietario: Equipo de Requisitos
ultima_actualizacion: 2025-02-15
relacionados: [DOC-INDEX-001, DOC-PLT-001]
---
# Matriz de Trazabilidad

Mantén esta matriz sincronizada con cada cambio de requisitos, casos de uso y pruebas. Actualiza el estado usando el semáforo: `En análisis`, `En diseño`, `En ejecución`, `Vigente`.

## RQ ↔ UC
| Requisito | Caso de Uso | Cobertura |
|-----------|-------------|-----------|
| RQ-ANL-001 | UC-DASH-001 | En análisis |
| RQ-ANL-002 | UC-DASH-003 | Alineado |
| RQ-INT-004 | UC-API-002  | Pendiente |
| RQ-SEG-007 | UC-AUTH-005 | En diseño |

## UC ↔ TC
| Caso de Uso | Caso de Prueba | Estado |
|-------------|----------------|--------|
| UC-DASH-001 | TC-USR-010     | En diseño |
| UC-DASH-003 | TC-USR-011     | Vigente |
| UC-API-002  | TC-API-005     | En ejecución |
| UC-AUTH-005 | TC-AUTH-014    | Pendiente |

## UC ↔ Endpoint/Módulo
| Caso de Uso | Endpoint/Módulo | Responsable |
|-------------|-----------------|-------------|
| UC-DASH-001 | /api/v1/dashboard/resumen | Equipo Front |
| UC-DASH-003 | /api/v1/dashboard/filtros | Equipo Datos |
| UC-API-002  | modulo-ingesta.etl_validaciones | Equipo Integraciones |
| UC-AUTH-005 | auth/session.create | Equipo Plataforma |

## Procedimiento de actualización
1. Revisa PRs con etiqueta `docs` y valida si impactan requisitos o casos de uso.
2. Ajusta las tablas anteriores manteniendo el orden alfabético por identificador.
3. Notifica a QA cuando una fila cambie a `Vigente` para que actualicen suites automatizadas.
4. Si un requisito se descarta, mueve la fila a un archivo histórico (`trazabilidad-archive.md`).
