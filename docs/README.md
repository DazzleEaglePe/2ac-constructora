# A2C Inventario

> **Cada herramienta y máquina, siempre ubicada.**
> App móvil de Constructora A2C para saber dónde está cada activo, cuánto hay y quién lo movió.

---

## Qué es

Sistema de control de inventario de **herramientas y maquinaria por obra**. El personal de Constructora A2C registra activos (máquinas y herramientas), los asigna a obras o al almacén central y deja trazabilidad de cada movimiento: origen → destino, cantidad, usuario y fecha y hora. El panel muestra el inventario **en tiempo real**.

**Problema que resuelve:** hoy no se sabe con certeza en qué obra está cada herramienta, se pierden equipos, se compran duplicados y no hay responsables de cada traslado.

**Alcance del MVP:** app **Flutter multiplataforma** (Android e iOS) + API NestJS + PostgreSQL. El mismo código Flutter se compilará para **web** como panel de administración después del MVP.

**Stack:** Flutter · Riverpod · go_router · Drift (offline) · NestJS · Prisma · PostgreSQL · Redis · Socket.IO. Detalle en [`04_ARQUITECTURA_SOFTWARE.md`](./04_ARQUITECTURA_SOFTWARE.md).

---

## Documentación

| #   | Documento                                                              | Contenido                                                                 |
| --- | ---------------------------------------------------------------------- | ------------------------------------------------------------------------- |
| 01  | [Contexto y Análisis](./01_CONTEXTO_Y_ANALISIS.md)                     | Problema, objetivos, usuarios, alcance, glosario, reglas de negocio, riesgos |
| 02  | [Requerimientos Funcionales](./02_REQUERIMIENTOS_FUNCIONALES.md)       | Requerimientos por módulo, priorizados (MoSCoW) y con criterios de aceptación |
| 03  | [Requerimientos No Funcionales](./03_REQUERIMIENTOS_NO_FUNCIONALES.md) | Rendimiento, disponibilidad, modo sin conexión, seguridad, accesibilidad  |
| 04  | [Arquitectura de Software](./04_ARQUITECTURA_SOFTWARE.md)              | Stack, componentes, flujos, tiempo real, decisiones (ADR)                 |
| 05  | [Modelo de Datos](./05_MODELO_DATOS.md)                                | Diagrama ER, esquema Prisma, restricciones SQL, semilla, índices          |
| 06  | [Contrato de API](./06_API_CONTRACT.md)                                | Endpoints REST, payloads, errores, eventos WebSocket, versionado          |
| 07  | [Seguridad y Autenticación](./07_SEGURIDAD_AUTH.md)                    | Ingreso por DNI, tokens, roles y permisos, auditoría, protección de datos |
| 08  | [Flujos de Experiencia](./08_UX_FLUJOS.md)                             | Mapa de navegación, flujos clave, estados de interfaz, accesibilidad      |
| 09  | [Sistema de Diseño](./09_DESIGN_SYSTEM.md)                             | Marca A2C, tokens, tipografía, componentes, animación del logo            |
| 10  | [Plan de Desarrollo](./10_PLAN_DESARROLLO.md)                          | Sprints, checklists, entregables y criterios de aceptación                |
| 11  | [Estructura del Proyecto](./11_ESTRUCTURA_PROYECTO.md)                 | Monorepo, carpetas, convenciones, entorno local, scripts                  |

---

## Estado del proyecto

| Fase                     | Estado         |
| ------------------------ | -------------- |
| Diseño UI (canvas)       | ✅ Completo (v1) |
| Documentación base       | ✅ Completa (v1) |
| Sprint 0 — Fundación     | ✅ Completado    |
| Sprint 1 — Bienvenida, auth y usuarios | ⏳ En curso |

El avance por sprint se marca en las checklists de [`10_PLAN_DESARROLLO.md`](./10_PLAN_DESARROLLO.md) §3.

---

## Recursos de diseño

| Recurso                       | Ubicación                                                                                     |
| ----------------------------- | --------------------------------------------------------------------------------------------- |
| Canvas de diseño (todas las versiones) | <https://claude.ai/artifact/NSoVekPv3gJuHQjkXjqrpk> — página **Constructora A2C**   |
| Logo animado (MP4 / GIF)      | [`assets/branding/`](../assets/branding/)                                                     |
| Reglas visuales para agentes  | [`.claude/skills/inventario-obras-ui/SKILL.md`](../.claude/skills/inventario-obras-ui/SKILL.md) |

> La versión de diseño elegida para construir es **Constructora A2C**: fondo blanco, componentes negros, acento amarillo `#FFC20E`, splash con la animación del logo, onboarding de 3 pasos e ingreso por DNI. Detalle en [`09_DESIGN_SYSTEM.md`](./09_DESIGN_SYSTEM.md).

---

## Convenciones de estos documentos

- Idioma: español. Términos técnicos en inglés solo cuando son estándar (JWT, WebSocket, endpoint).
- Identificadores: `RF-XXX-NN` (funcional), `RNF-XX-NN` (no funcional), `RN-NN` (regla de negocio), `ADR-NN` (decisión de arquitectura).
- Lo marcado **[POR CONFIRMAR]** es una propuesta que requiere validación de Constructora A2C antes del sprint que lo implementa.
- Fecha de esta versión: 2026-10-04.
