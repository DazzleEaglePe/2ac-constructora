# 10 — Plan de Desarrollo

> **Duración del sprint:** 2 semanas · **Sprints hasta el MVP:** 7 (S0–S6) + 1 de lanzamiento (S7)
> **Inicio tentativo:** lunes 2026-10-05 · **Lanzamiento tentativo:** 2027-01-29
> **Metodología:** iterativa; cada sprint cierra con un **entregable verificable** en un dispositivo real.
> **Cómo se usa este documento:** se marca `[x]` cada tarea al completarla y se actualiza la tabla de §2 al cerrar el sprint.

---

## 1. Visión general

| Sprint | Fechas (tentativas)       | Objetivo                                 | Entregable verificable                                                     |
| ------ | ------------------------- | ---------------------------------------- | -------------------------------------------------------------------------- |
| **S0** | 05 oct – 16 oct           | Fundación técnica                        | Monorepo, API con salud, app Flutter con tema A2C corriendo en Android e iOS, CI verde |
| **S1** | 19 oct – 30 oct           | Bienvenida, autenticación y usuarios     | Splash animado → onboarding → ingreso por DNI → panel vacío; admin crea usuarios |
| **S2** | 02 nov – 13 nov           | Obras y almacén                          | Crear obra con mapa y ver su detalle; almacén central visible              |
| **S3** | 16 nov – 27 nov           | Catálogo de activos                      | Alta de máquina y herramienta con código automático; inventario con filtros |
| **S4** | 30 nov – 11 dic           | Movimientos e historial                  | Mover/asignar con stock atómico; historial por activo y obra; reversión    |
| **S5** | 14 dic – 25 dic           | Panel en tiempo real y auditoría         | Dos celulares ven el mismo movimiento en ≤ 2 s; panel con resumen          |
| **S6** | 28 dic – 08 ene           | Sin conexión, importación y calidad      | Movimiento sin señal se sincroniza solo; carga masiva desde Excel; beta cerrada |
| **S7** | 11 ene – 29 ene (3 sem.)  | Piloto y lanzamiento                     | Piloto en 1–2 obras reales, correcciones, publicación en tiendas           |

## 2. Estado

| Sprint | Estado        | Avance | Notas |
| ------ | ------------- | ------ | ----- |
| S0     | ✅ Completado* | 95 %   | *Quedan como tareas del usuario: probar en un celular físico y proteger `main`* |
| S1     | ⏳ En revisión | 95 %   | API (28 pruebas) + app (25 pruebas); flujo completo verificado en simulador iOS, web y emulador Android 15. PR #1. Pendiente: validación en Android físico y medición de 60 fps en equipo de gama media |
| S2     | 🟡 En progreso | 60 %   | API y flujo base de obras/almacén implementados; falta mapa integrado y cerrar pruebas de dispositivo. |
| S3     | 🟡 En progreso | 70 %   | Catálogo, alta, edición, distribución visual y notas listos; faltan búsqueda optimizada y prueba de concurrencia. |
| S4     | 🟡 En progreso | 85 %   | Traslados, reversiones, observaciones e historial por activo/obra listos; faltan tareas operativas y revisión final. |
| S5     | 🟡 En progreso | 45 %   | Resumen, observaciones abiertas y consulta de auditoría para ADMIN listos; falta tiempo real. |
| S6     | ⬜ Pendiente   | 0 %    |       |
| S7     | ⬜ Pendiente   | 0 %    |       |

Leyenda: ⬜ pendiente · ⏳ en curso · ✅ completado · ⚠️ bloqueado

### Decisiones pendientes que bloquean sprints

| Pregunta (`01` §9)                        | Necesaria antes de |
| ----------------------------------------- | ------------------ |
| ~~P2 Roles · P3 DNI · P6 permisos por obra~~ | ✅ Resueltas el 2026-10-04: ADMIN + OPERADOR, DNI Perú 8 dígitos, sin permisos por obra |
| P5 Plataformas y celulares                | S6                 |
| P1 Nombre definitivo · P8 Hosting         | S7                 |

---

## 3. Sprints

### Sprint 0 — Fundación técnica

**Objetivo:** dejar listo el esqueleto de API y app para que desde S1 solo se construyan funcionalidades.

**Repositorio y herramientas**
- [x] Repositorio en GitHub: [`DazzleEaglePe/2ac-constructora`](https://github.com/DazzleEaglePe/2ac-constructora) — *pendiente: protección de la rama `main`*
- [x] Estructura de monorepo según `11_ESTRUCTURA_PROYECTO.md`
- [x] `.editorconfig`, `.gitignore`, commitlint (Conventional Commits), plantillas de PR
- [x] Docker Compose local: PostgreSQL 16 + Redis 7 (puertos 5433 y 6380 para no chocar con otros proyectos)

**API (NestJS)**
- [x] Proyecto NestJS 11 en `apps/api` con configuración tipada (`@nestjs/config` + validación con zod)
- [x] Prisma con el esquema de `05_MODELO_DATOS.md` y primera migración (incluye restricciones SQL §4: stock ≥ 0, movimientos inmutables, DNI de 8 dígitos)
- [x] Semilla: almacén central, admin inicial, secuencias de código
- [x] Módulo `health` (`/health/live`, `/health/ready` con PostgreSQL y Redis)
- [x] Logs JSON con `requestId` (`X-Request-Id`), filtro de errores `problem+json`
- [x] OpenAPI generado en `/docs` y exportado a `apps/api/openapi.yaml`

**App (Flutter)**
- [x] Proyecto Flutter en `apps/mobile` (Android + iOS; web habilitado) — Flutter 3.47
- [x] Dependencias base: riverpod, go_router, dio, freezed, json_serializable, drift, flutter_secure_storage, intl
- [x] Tema `A2CTheme` con tokens de `09_DESIGN_SYSTEM.md` §11 y fuentes Geist / Geist Mono (empaquetadas, licencia OFL)
- [x] Biblioteca de widgets base: botones, campo de texto, chip, badge de estado, tarjetas, barra de navegación, FAB y logo `A2CLogo`
- [x] Pantalla "catálogo de componentes" (solo `ENV=dev`) con estado de conexión a la API
- [x] Entornos `dev` / `staging` / `prod` con `--dart-define-from-file=env/<entorno>.json` *(flavors nativos de Android/iOS se agregan en S6, al configurar la firma)*
- [ ] Cliente API generado desde OpenAPI en `packages/api_client` → **movido a S1**: se genera cuando existan los endpoints de auth (hoy solo hay `/health`)

**CI**
- [x] GitHub Actions: lint + typecheck + test (con Postgres y Redis de servicio) + build de API
- [x] GitHub Actions: formato + `flutter analyze` + `flutter test` + build web
- [x] gitleaks y auditoría de dependencias (`pnpm audit`: 0 vulnerabilidades tras overrides)

**Criterios de aceptación**
- [x] `docker compose up` + `pnpm dev:api` responde `200` en `/health/ready`
- [ ] La app abre en un Android y un iOS físicos con el tema A2C y la fuente Geist — *verificado en **simulador iOS (iPhone 18 Pro)**, **web** y **emulador Android 15**, conectado a la API; falta validar dispositivos físicos*
- [x] CI verde en GitHub Actions (API, Mobile y Seguridad)

---

### Sprint 1 — Bienvenida, autenticación y usuarios

**Requerimientos:** RF-BIE-01…05, RF-AUT-01…06, RF-USR-01…05, RF-USR-07

**Arrastrado de S0**
- [x] ~~Cliente API generado~~ → **reemplazado por repositorios Dio escritos a mano** con manejo de `problem+json` (ADR-11)

**API**
- [x] `POST /auth/login` con Argon2id, bloqueo por intentos y tiempo constante
- [x] JWT RS256 (15 min) + refresh rotativo con detección de reutilización
- [x] `POST /auth/refresh`, `/auth/logout`, `/auth/change-password`, `GET /auth/me`
- [x] `JwtAuthGuard`, `RolesGuard`, decorador `@Roles` (roles `ADMIN` y `OPERADOR`)
- [x] Módulo `users`: listar, crear (DNI peruano de 8 dígitos), editar, desactivar/activar, restablecer contraseña
- [x] Rate limiting de login (20/min por IP, en memoria) — *almacenamiento en Redis para varias instancias: S5*
- [x] Pruebas e2e de auth y usuarios (casos de bloqueo, desactivado, temporal)

**App**
- [x] **Splash animado** `A2CSplashAnimation` (CustomPainter, 6,5 s, cortes de fondo, viga, franja, revelado de CONSTRUCTORA) según `09` §8
- [x] Soporte de "reducir movimiento" en el splash
- [x] **Onboarding de 3 pasos** con tarjetas flotantes, puntos tocables, "Saltar" y CTA amarillo
- [x] Persistir "onboarding visto"
- [x] **Ingreso** (hero con edificios, franja, ícono A2C, hoja con DNI y contraseña, beneficios)
- [x] Cambio de contraseña temporal (diseñar pantalla)
- [x] Gestión de sesión: secure storage, interceptor de refresh, cierre de sesión
- [x] Guardas de `go_router` (sin sesión → login; temporal → cambio de contraseña)
- [x] Pantalla **Usuarios** (lista, alta en línea, edición, desactivar, restablecer) solo para admin
- [x] Panel con barra de navegación (3 destinos admin / 2 operador) y estado vacío
- [x] Ocultar acciones de admin al operador (barra con 2 destinos y guarda de `/users`; `can(Permission)` se generaliza en S3)

**Criterios de aceptación**
- [x] Primer uso: splash → onboarding → ingreso → cambio de contraseña → panel
- [x] Usos siguientes: splash breve → panel sin pedir credenciales
- [x] 5 intentos fallidos bloquean la cuenta 15 min con mensaje claro
- [x] Un usuario desactivado pierde la sesión en ≤ 15 min (o al instante con WS en S5)
- [ ] El splash corre a 60 fps en un Android de gama media — *verificado el flujo en simulador iOS, web y emulador Android 15; falta medir rendimiento en un Android físico de gama media*

---

### Sprint 2 — Obras y almacén

**Requerimientos:** RF-UBI-01…07, RF-BUS-03

**API**
- [x] Módulo `sites`: CRUD, cerrar/reabrir (valida stock 0), `GET /sites/{id}/stock`
- [x] Resumen por ubicación (`units`, `assetCount`, `topItems`, `lastMovementAt`)
- [x] Auditoría de altas, ediciones y cierres/reaperturas de obra

**App**
- [ ] **Nueva obra**: nombre, responsable, ubicación por coordenadas y acceso a Maps; falta geocodificación y mapa con pin ajustable
- [x] **Detalle de obra**: datos, stock, responsable, dirección/coordenadas, filtros por tipo y acceso a Maps
- [x] Almacén central visible en el panel y con detalle/stock
- [x] Lista de obras en el panel (tarjetas `SiteCard`, sin tiempo real aún)

**Criterios de aceptación**
- [x] Crear/editar una obra con coordenadas y verla en el panel y en su detalle
- [x] "Abrir en Maps" abre Maps con dirección o coordenadas
- [x] No se puede cerrar una obra con activos

---

### Sprint 3 — Catálogo de activos

**Requerimientos:** RF-ACT-01…08, RF-BUS-01, RF-BUS-02, RF-BUS-04, RF-BUS-05

**API**
- [x] Módulo `assets`: alta transaccional (código por secuencia + stock inicial + movimiento `ALTA`)
- [x] `GET /assets/next-code`, edición, cambio de estado con motivo y notas
- [ ] Búsqueda por nombre/código y filtros (búsqueda básica lista; paginación y trigram/unaccent pendientes)
- [x] `distribution[]` en los resultados de búsqueda (consulta de disponibilidad, RF-BUS-05)
- [x] Regla RN-01 (máquina = 1) en servicio y en BD
- [ ] Pruebas unitarias de reglas y concurrencia de códigos

**App**
- [x] **Nueva herramienta o equipo**: tipo, código automático, nombre, descripción, stock inicial (máquina limitada a 1) y ubicación inicial
- [x] **Inventario general**: buscador, filtros por tipo y estado, distribución resumida, botón de alta solo admin y estado vacío
- [x] **Consulta de disponibilidad**: resultados de búsqueda con distribución resumida por obra y almacén
- [x] **Detalle de activo**: código, tipo, estado, distribución proporcional por ubicación y notas
- [x] Edición de nombre y descripción, y cambio de estado con motivo obligatorio para dar de baja

**Criterios de aceptación**
- [ ] Dos altas simultáneas nunca generan el mismo código
- [ ] Una máquina no puede tener stock distinto de 1
- [ ] Buscar "amol" encuentra "Amoladora angular 4½\""
- [ ] Buscar "pala" muestra en qué obras y en el almacén hay palas, y cuántas, sin entrar al detalle
- [ ] Un operador no ve ni puede usar el alta de activos (la API responde `403`)

---

### Sprint 4 — Movimientos e historial

**Requerimientos:** RF-MOV-01…14, RF-UBI-03 (lista con movimientos)

**API**
- [x] `POST /movements` transaccional con bloqueo por activo y validaciones RN-01…RN-10
- [x] `Idempotency-Key` obligatorio y respuesta repetible
- [x] Permisos: `ADMIN` y `OPERADOR` mueven entre cualquier obra y almacén
- [x] Historial por activo y general con filtros
- [x] Historial filtrable por ubicación; la app muestra actividad reciente en la ficha de obra
- [x] `POST /movements/{id}/revert` solo ADMIN, creando el inverso sin modificar el historial original
- [x] Observaciones: creación junto al movimiento, `GET /observations` y resolución por ADMIN
- [x] Prueba concurrente: dos traslados sobre el mismo stock → uno confirma y el otro recibe stock insuficiente
- [ ] Job nocturno de verificación de invariantes

**App**
- [x] **Mover o asignar**: activo, origen con disponibles, destino, cantidad, nota, resumen y confirmación
- [x] Atajo para mover desde el detalle de una obra con origen precargado
- [x] Advertencia no bloqueante si el activo está en Mantenimiento y va a una obra
- [x] **Reportar observación** al mover (tipo + descripción), verla en el historial y marcar atendida como ADMIN
- [x] Confirmación "Movimiento registrado" y actualización de inventario/obras
- [x] Historial por activo y por obra
- [x] Reversión desde el historial del activo, solo para ADMIN
- [x] Manejo de `STOCK_INSUFICIENTE` con recarga de la disponibilidad

**Criterios de aceptación**
- [x] Mover 1 unidad en ≤ 4 toques desde el detalle del activo
- [x] El stock total del activo no cambia tras un traslado
- [x] Un reintento con la misma clave no duplica el movimiento
- [x] La reversión deja el stock como antes y ambos movimientos quedan enlazados
- [x] Un traslado con observación se registra sin aprobación y la observación queda ABIERTA

---

### Sprint 5 — Panel en tiempo real y auditoría

**Requerimientos:** RF-PAN-01…07, RF-AUD-01, RF-AUD-02

**API**
- [x] `GET /dashboard` con totales, obras, almacén y marca `changedSince`
- [ ] Gateway Socket.IO con autenticación en el handshake y salas
- [ ] Emisión de eventos tras `COMMIT` (`movement.created`, `stock.updated`, `site.updated`, `asset.updated`, `session.revoked`)
- [ ] Adaptador Redis para varias instancias
- [x] `GET /audit-logs` con filtros, cursor y acceso solo ADMIN

**App**
- [ ] **Panel**: tarjetas de métrica, obras, almacén y observaciones abiertas listos; faltan avatar, indicador "En vivo", hero, buscador y accesos rápidos
- [ ] Cliente WebSocket con reconexión exponencial y *resync*
- [ ] Destello de tarjetas actualizadas
- [x] Deslizar para refrescar el panel
- [ ] Cierre de sesión forzado al recibir `session.revoked`
- [x] Sección **Observaciones abiertas** en el panel del administrador, con "Marcar como atendida"
- [x] Pantalla ADMIN de auditoría con filtro por acción y paginación

**Criterios de aceptación**
- [ ] Un movimiento en el celular A aparece en el panel del celular B en ≤ 2 s
- [ ] Tras perder y recuperar la red, el panel queda consistente sin recargar a mano
- [x] Las acciones administrativas aparecen en la auditoría consultable por ADMIN

---

### Sprint 6 — Sin conexión, importación y calidad

**Requerimientos:** RF-OFF-01…04, RF-ACT-09

**App**
- [ ] Caché Drift de panel, obras, inventario e historial reciente
- [ ] Cola de movimientos pendientes con estado (PENDIENTE / ENVIADO / RECHAZADO)
- [ ] Actualización optimista y reversión al rechazo
- [ ] Banda "Sin conexión" y chip "N pendientes"
- [ ] Estados vacíos, de error y esqueletos en todas las pantallas
- [ ] Accesibilidad: `Semantics`, texto al 130 %, TalkBack/VoiceOver
- [ ] Integración de Sentry

**API**
- [ ] `POST /assets/import` (CSV/XLSX) con validación por fila y reporte
- [ ] Plantilla de importación descargable

**Calidad**
- [ ] Pruebas de integración Flutter de los flujos clave (ingreso, mover, alta)
- [ ] Prueba de carga de la API (200 usuarios, 10 000 movimientos/día)
- [ ] Revisión de seguridad (`07` §10)
- [ ] Beta cerrada: TestFlight + Google Play prueba interna

**Criterios de aceptación**
- [ ] Un movimiento hecho en modo avión se envía solo al volver la red
- [ ] Un movimiento pendiente rechazado muestra el motivo y permite corregir
- [ ] Importar 500 activos desde Excel en < 1 min con reporte de errores

---

### Sprint 7 — Piloto y lanzamiento (3 semanas)

- [ ] Despliegue de producción (API, base de datos con respaldos, Redis, dominio, TLS)
- [ ] Carga inicial del inventario real con el almacenero
- [ ] Capacitación (guía de 1 página + video corto) para encargados de obra
- [ ] Piloto en 1–2 obras durante 2 semanas; tablero de métricas de `01` §2
- [ ] Corrección de incidencias del piloto
- [ ] Fichas de tienda (íconos, capturas con la marca A2C, política de privacidad)
- [ ] Publicación en Google Play y App Store
- [ ] Retrospectiva y priorización del backlog posterior al MVP

**Criterios de aceptación del MVP**
- [ ] Todos los requerimientos **Must** de `02` implementados y probados
- [ ] Métricas del piloto: ≥ 90 % de traslados registrados, ≤ 30 s por movimiento
- [ ] 0 discrepancias en la verificación nocturna durante el piloto

---

## 4. Definición de terminado (DoD)

Una tarea se marca `[x]` solo si:
- [ ] Cumple sus criterios de aceptación y los requerimientos referenciados
- [ ] Tiene pruebas (unitarias o e2e según corresponda) y CI verde
- [ ] Sigue el sistema de diseño (sin colores ni tamaños literales fuera de los tokens)
- [ ] Es accesible (etiquetas, contraste, área táctil)
- [ ] Contrato de API actualizado (`openapi.yaml`) si cambió un endpoint
- [ ] Revisado en un dispositivo real

## 5. Backlog posterior al MVP

| Prioridad | Funcionalidad                                         | Valor                                       |
| --------- | ----------------------------------------------------- | ------------------------------------------- |
| 1         | **Etiquetas QR** por activo + escaneo para mover      | Registro en 2 toques, menos errores          |
| 2         | Panel web de administración (Flutter web)             | Gestión desde oficina, reportes en pantalla grande |
| 3         | Fotos de activos y evidencias de entrega              | Identificación y control de estado          |
| 4         | Reportes y exportación (Excel/PDF)                    | Gestión y auditorías                         |
| 5         | Mantenimiento programado y alertas                    | Menos paradas                                |
| 6         | Notificaciones push                                   | Avisos de movimientos en mis obras           |
| 7         | Conteos físicos (inventario cíclico)                  | Exactitud del inventario                     |
| 8         | Biometría para reabrir la app                         | Comodidad                                    |
| 9         | Valorización económica del inventario                 | Control financiero                           |

## 6. Riesgos del plan

| Riesgo                                  | Mitigación                                                       |
| --------------------------------------- | ---------------------------------------------------------------- |
| Las respuestas de A2C llegan tarde      | Tabla de bloqueos (§2); se avanza con el valor propuesto y se ajusta |
| Publicación en App Store se demora      | Enviar a revisión al inicio de S7; Android primero si hace falta |
| El splash animado consume tiempo extra  | Especificación cerrada en `09` §8; tope de 3 días en S1          |
| Cambio de logo durante el desarrollo    | Widget `A2CLogo` único; reemplazo en < 1 día                     |
