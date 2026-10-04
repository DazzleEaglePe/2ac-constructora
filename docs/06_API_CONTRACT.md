# 06 — Contrato de API

> **Base:** `https://api.a2c-inventario.[dominio]/api/v1` **[POR CONFIRMAR dominio]**
> **Formato:** JSON UTF-8 · fechas ISO 8601 en UTC · IDs UUID v4
> **Fuente de verdad:** `apps/api/openapi.yaml` (OpenAPI 3.1), generado desde los decoradores de NestJS y usado para generar el cliente Dart (`packages/api_client`).

---

## 1. Convenciones

| Tema              | Regla                                                                                          |
| ----------------- | ---------------------------------------------------------------------------------------------- |
| Autenticación     | `Authorization: Bearer <accessToken>` en todo excepto `/auth/login` y `/auth/refresh`          |
| Versionado        | Prefijo `/v1`. Cambios incompatibles → `/v2`; campos nuevos son compatibles                    |
| Paginación        | Por cursor: `?limit=50&cursor=<opaco>` → `{ "data": [...], "nextCursor": "..." \| null }`      |
| Filtros           | Query params simples: `?type=HERRAMIENTA&status=OPERATIVO&q=amol`                              |
| Idempotencia      | `Idempotency-Key: <uuid>` **obligatorio** en `POST /movements` y `POST /assets`                |
| Errores           | `application/problem+json` (RFC 9457)                                                           |
| Límite de tasa    | Encabezados `RateLimit-Limit`, `RateLimit-Remaining`, `RateLimit-Reset`                        |
| Trazabilidad      | `X-Request-Id` en la respuesta (y aceptado en la solicitud)                                     |

### Formato de error

```json
{
  "type": "https://a2c-inventario/errors/stock-insuficiente",
  "title": "Stock insuficiente en el origen",
  "status": 409,
  "code": "STOCK_INSUFICIENTE",
  "detail": "Almacén central tiene 2 unidades de HER-0142; se intentó mover 3.",
  "requestId": "01J9Z...",
  "errors": []
}
```

### Códigos de error de dominio

| `code`                    | HTTP | Cuándo                                                   |
| ------------------------- | ---- | -------------------------------------------------------- |
| `CREDENCIALES_INVALIDAS`  | 401  | DNI o contraseña incorrectos                              |
| `CUENTA_BLOQUEADA`        | 423  | Demasiados intentos (incluye `lockedUntil`)              |
| `CUENTA_DESACTIVADA`      | 403  | Usuario inactivo                                          |
| `CAMBIO_CLAVE_REQUERIDO`  | 403  | Debe cambiar la contraseña temporal                      |
| `SIN_PERMISO`             | 403  | El rol no permite la acción                               |
| `VALIDACION`              | 422  | Payload inválido (`errors[]` con campo y mensaje)         |
| `STOCK_INSUFICIENTE`      | 409  | Cantidad mayor a la disponible en el origen (RN-02)       |
| `MAQUINA_UNIDAD_UNICA`    | 422  | Cantidad ≠ 1 para una máquina (RN-01)                     |
| `ORIGEN_IGUAL_DESTINO`    | 422  | RN-03                                                     |
| `ACTIVO_DE_BAJA`          | 409  | Se intenta mover un activo en Baja (RN-06)               |
| `OBRA_CERRADA`            | 409  | Destino cerrado o cierre con stock (RN-10)               |
| `DNI_DUPLICADO`           | 409  | Alta de usuario con DNI existente                         |
| `NO_ENCONTRADO`           | 404  | Recurso inexistente                                       |
| `IDEMPOTENCIA_CONFLICTO`  | 409  | Misma clave con payload distinto                          |

## 2. Autenticación

### `POST /auth/login`

```json
// Solicitud
{ "dni": "30456789", "password": "********", "deviceName": "Galaxy A54" }

// 200
{
  "accessToken": "eyJ...",          // 15 min
  "refreshToken": "rt_9f2...",      // 30 días, rotativo
  "user": {
    "id": "6f1c...", "dni": "30456789", "fullName": "Carlos Pérez",
    "role": "ADMIN", "mustChangePassword": false
  }
}
```

### `POST /auth/refresh`

`{ "refreshToken": "rt_..." }` → `200` con un par nuevo. Reutilizar un refresh token ya rotado revoca toda la familia (ver `07` §3).

### `POST /auth/logout`

Revoca el refresh token actual. `204`.

### `POST /auth/change-password`

`{ "currentPassword": "...", "newPassword": "..." }` → `204`. Obligatorio si `mustChangePassword = true`.

### `GET /auth/me`

Devuelve el usuario autenticado.

## 3. Usuarios — rol `ADMIN`

| Método | Ruta                               | Descripción                                   |
| ------ | ---------------------------------- | --------------------------------------------- |
| GET    | `/users?q=&role=&active=`          | Lista paginada                                |
| POST   | `/users`                           | Crear (`dni` de 8 dígitos, `fullName`, `role`: `ADMIN` \| `OPERADOR`, `temporaryPassword`) |
| GET    | `/users/{id}`                      | Detalle                                       |
| PATCH  | `/users/{id}`                      | Editar `fullName`, `role`                     |
| POST   | `/users/{id}/deactivate`           | Desactivar (revoca sesiones)                  |
| POST   | `/users/{id}/activate`             | Reactivar                                     |
| POST   | `/users/{id}/reset-password`       | Genera contraseña temporal → `{ "temporaryPassword": "..." }` (se muestra una vez) |

```json
// Usuario (respuesta)
{
  "id": "…", "dni": "35112604", "fullName": "Martín Ruiz", "role": "OPERADOR",
  "active": true, "lastMovementAt": "2026-10-04T14:42:00Z"
}
```

## 4. Ubicaciones: obras y almacén

| Método | Ruta                               | Rol mínimo   | Descripción                                    |
| ------ | ---------------------------------- | ------------ | ---------------------------------------------- |
| GET    | `/sites?type=&status=&q=`          | Todos        | Lista con resumen (`units`, `assetCount`, `lastMovementAt`) |
| POST   | `/sites`                           | ADMIN        | Crear obra                                     |
| GET    | `/sites/{id}`                      | Todos        | Detalle                                        |
| PATCH  | `/sites/{id}`                      | ADMIN        | Editar                                         |
| POST   | `/sites/{id}/close`                | ADMIN        | Cerrar (requiere stock 0)                      |
| POST   | `/sites/{id}/reopen`               | ADMIN        | Reabrir                                        |
| GET    | `/sites/{id}/stock?type=`          | Todos        | Activos en la ubicación con cantidad y estado  |
| GET    | `/sites/{id}/movements`            | Todos        | Historial de la ubicación                      |

```json
// POST /sites
{
  "name": "Obra Juan Ramírez", "ownerName": "Juan Ramírez",
  "address": "Calle Los Pinos 245", "lat": -12.0464, "lng": -77.0428
}

// Site (respuesta)
{
  "id": "…", "type": "OBRA", "name": "Obra Juan Ramírez", "ownerName": "Juan Ramírez",
  "address": "Calle Los Pinos 245", "lat": -12.0464, "lng": -77.0428, "status": "ACTIVA",
  "summary": { "units": 9, "assetCount": 5, "lastMovementAt": "2026-10-04T14:30:00Z",
               "topItems": [ { "name": "Trompo", "quantity": 1 }, { "name": "Palas", "quantity": 2 } ] }
}
```

## 5. Activos

| Método | Ruta                               | Rol mínimo   | Descripción                                    |
| ------ | ---------------------------------- | ------------ | ---------------------------------------------- |
| GET    | `/assets?q=&type=&status=&siteId=` | Todos        | Inventario paginado; cada ítem incluye `distribution[]` (consulta de disponibilidad, RF-BUS-05) |
| GET    | `/assets/next-code?type=`          | ADMIN        | Vista previa del próximo código (no lo reserva)|
| POST   | `/assets`                          | ADMIN        | Alta (crea movimiento `ALTA`)                  |
| GET    | `/assets/{id}`                     | Todos        | Detalle con `distribution[]`                   |
| PATCH  | `/assets/{id}`                     | ADMIN        | Editar nombre y descripción                    |
| POST   | `/assets/{id}/status`              | ADMIN        | Cambiar estado (`reason` obligatorio para `BAJA`) |
| GET    | `/assets/{id}/movements`           | Todos        | Historial                                      |
| GET    | `/assets/{id}/notes`               | Todos        | Notas                                          |
| POST   | `/assets/{id}/notes`               | Todos        | Agregar nota `{ "body": "..." }`               |
| POST   | `/assets/import`                   | ADMIN        | Importación CSV/XLSX (Sprint 6), devuelve reporte por fila |

```json
// POST /assets   (Idempotency-Key requerido)
{
  "type": "HERRAMIENTA", "name": "Amoladora angular 4½\"",
  "description": "850 W, disco de 115 mm", "status": "OPERATIVO",
  "initialQuantity": 4, "initialSiteId": "<almacén>"
}
// Para MAQUINA, initialQuantity se ignora y vale 1.

// Asset (respuesta de detalle)
{
  "id": "…", "code": "HER-0142", "type": "HERRAMIENTA", "name": "Amoladora angular 4½\"",
  "description": "850 W, disco de 115 mm", "status": "OPERATIVO", "totalStock": 4,
  "distribution": [
    { "siteId": "…", "siteName": "Almacén central", "siteType": "ALMACEN", "quantity": 2 },
    { "siteId": "…", "siteName": "Obra Juan Ramírez", "siteType": "OBRA", "quantity": 1 },
    { "siteId": "…", "siteName": "Casa Morales", "siteType": "OBRA", "quantity": 1 }
  ],
  "notesCount": 2, "updatedAt": "2026-10-04T14:42:00Z"
}
```

## 6. Movimientos

| Método | Ruta                                        | Rol mínimo      | Descripción                         |
| ------ | ------------------------------------------- | --------------- | ----------------------------------- |
| POST   | `/movements`                                | OPERADOR · ADMIN | Mover / asignar (traslado)         |
| GET    | `/movements?assetId=&siteId=&userId=&from=&to=` | Todos       | Historial general                   |
| GET    | `/movements/{id}`                           | Todos           | Detalle                             |
| POST   | `/movements/{id}/revert`                    | ADMIN           | Revertir (crea `REVERSION`)         |
| GET    | `/observations?status=ABIERTA&assetId=`     | Todos           | Observaciones reportadas            |
| POST   | `/observations/{id}/resolve`                | ADMIN           | Marcar como atendida `{ "resolution": "..." }` |

> Los traslados **no requieren aprobación**: `POST /movements` aplica el cambio de stock de inmediato (RN-14).

Sin restricción por obra: un operador puede mover entre **cualquier** obra y el almacén (RN-14).

```json
// POST /movements   (Idempotency-Key: 7c1e…)
{
  "assetId": "…", "fromSiteId": "<almacén>", "toSiteId": "<obra JR>",
  "quantity": 1, "note": "Sale con disco nuevo", "clientCreatedAt": "2026-10-04T14:41:50Z",
  "observation": { "type": "DANADO", "description": "Protector del disco flojo" }   // opcional (RN-15)
}

// 201
{
  "id": "…", "kind": "TRASLADO", "asset": { "id": "…", "code": "HER-0142", "name": "Amoladora angular 4½\"" },
  "from": { "id": "…", "name": "Almacén central" }, "to": { "id": "…", "name": "Obra Juan Ramírez" },
  "quantity": 1, "note": "Sale con disco nuevo",
  "user": { "id": "…", "fullName": "Martín Ruiz" },
  "createdAt": "2026-10-04T14:42:00Z",
  "stockAfter": { "from": 1, "to": 2 },
  "observation": { "id": "…", "type": "DANADO", "description": "Protector del disco flojo", "status": "ABIERTA" }
}
```

- `createdAt` lo fija el servidor; `clientCreatedAt` se guarda como referencia para movimientos hechos sin conexión.
- Repetir la misma `Idempotency-Key` con el mismo payload devuelve el mismo `201` sin duplicar.

## 7. Panel

### `GET /dashboard?since=<ISO>`

```json
{
  "generatedAt": "2026-10-04T14:42:04Z",
  "totals": { "unitsOnSites": 23, "assetsInMaintenance": 2, "activeSites": 3, "warehouseUnits": 31, "openObservations": 1 },
  "sites": [ /* Site con summary (ver §4) */ ],
  "warehouse": { /* Site ALMACEN con summary */ },
  "changedSince": true
}
```

## 8. Auditoría — rol `ADMIN`

`GET /audit-logs?userId=&action=&entityType=&from=&to=` → lista paginada de `{ action, entityType, entityId, before, after, user, createdAt }`.

## 9. Tiempo real (Socket.IO)

**Conexión:** `wss://api…/realtime` con `auth: { token: "<accessToken>" }`. Token inválido → desconexión con `error: "UNAUTHORIZED"`.

| Dirección | Evento               | Payload                                                         |
| --------- | -------------------- | --------------------------------------------------------------- |
| C → S     | `subscribe`          | `{ "rooms": ["inventory", "site:<id>", "asset:<id>"] }`         |
| C → S     | `unsubscribe`        | `{ "rooms": [...] }`                                            |
| S → C     | `movement.created`   | Movimiento (§6)                                                 |
| S → C     | `stock.updated`      | `{ "assetId", "siteId", "quantity", "totalStock" }`             |
| S → C     | `asset.updated`      | Activo resumido (estado, nombre)                                 |
| S → C     | `site.updated`       | Site con summary                                                |
| S → C     | `observation.created` / `observation.resolved` | Observación (§6)                      |
| S → C     | `session.revoked`    | `{}` → la app cierra sesión (usuario desactivado)               |

## 10. Límites de tasa

| Grupo                       | Límite                       |
| --------------------------- | ---------------------------- |
| `POST /auth/login`          | 20 / min por IP · 5 fallidos / 15 min por DNI |
| Escrituras (`POST/PATCH`)   | 60 / min por usuario         |
| Lecturas                    | 300 / min por usuario        |

## 11. Salud

`GET /health/live` → `200`. `GET /health/ready` → `200` si PostgreSQL y Redis responden.
