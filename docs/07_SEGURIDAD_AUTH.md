# 07 — Seguridad y Autenticación

> Referencias: OWASP ASVS 4 (nivel 2), OWASP MASVS 2 (L1), OWASP API Security Top 10 (2023).

---

## 1. Modelo de amenazas (resumen)

| Activo a proteger                  | Amenaza                                           | Control principal                                  |
| ---------------------------------- | ------------------------------------------------- | -------------------------------------------------- |
| Cuentas de usuario                 | Fuerza bruta sobre DNI (fácil de adivinar)        | Bloqueo por intentos, rate limit, contraseñas robustas |
| Integridad del inventario          | Movimientos falsos o manipulados                  | Autorización por rol, historial inmutable, auditoría |
| Sesiones                           | Robo de token en el dispositivo                   | Keychain/Keystore, tokens cortos, rotación, revocación |
| Datos personales (DNI, nombre)     | Exposición o fuga                                 | TLS, mínimo privilegio, cifrado en reposo, minimización |
| API                                | Escalada de privilegios, abuso                    | `RolesGuard` en cada endpoint de escritura, throttling |
| Celular perdido                    | Uso por terceros                                  | Revocación remota (desactivar usuario), expiración  |

## 2. Ingreso con DNI y contraseña

| Aspecto                  | Política                                                                           |
| ------------------------ | ---------------------------------------------------------------------------------- |
| Identificador            | DNI peruano (8 dígitos), único                                                      |
| Contraseña               | Mínimo 8 caracteres, al menos 1 letra y 1 número; se rechazan las 10 000 más comunes y el propio DNI |
| Hash                     | **Argon2id** (m = 19 MiB, t = 2, p = 1) con sal por usuario                          |
| Contraseña temporal      | La crea el admin; `mustChangePassword = true`; expira en 72 h                        |
| Intentos fallidos        | 5 por cuenta → bloqueo 15 min (`CUENTA_BLOQUEADA`); 20 por IP/min                    |
| Mensajes de error        | Genéricos: "DNI o contraseña incorrectos"                                           |
| Tiempo de respuesta      | Constante (se calcula el hash aunque el DNI no exista) para no revelar cuentas      |
| Recuperación             | Solo a través del administrador (RF-AUT-06); no hay recuperación por correo en el MVP |

## 3. Tokens y sesiones

| Token          | Formato                        | Vida     | Almacenamiento en la app                    |
| -------------- | ------------------------------ | -------- | ------------------------------------------- |
| Access token   | JWT **RS256** (`sub`, `role`, `sid`, `exp`) | 15 min | Memoria (Riverpod)                 |
| Refresh token  | Aleatorio opaco (256 bits), se guarda **hasheado** (SHA-256) en BD | 30 días | `flutter_secure_storage` (Keychain / EncryptedSharedPreferences) |

- **Rotación:** cada `/auth/refresh` emite un refresh nuevo e invalida el anterior.
- **Detección de reutilización:** si llega un refresh ya rotado, se revoca toda la familia (`familyId`) y se fuerza un nuevo ingreso.
- **Revocación:** desactivar un usuario o restablecer su contraseña revoca todos sus refresh tokens y emite `session.revoked` por WebSocket.
- **Claves:** par RSA en un gestor de secretos; rotación anual con `kid` en el encabezado del JWT.
- El interceptor de Dio renueva el access token una sola vez ante un `401` y reintenta la solicitud.

## 4. Autorización (RBAC)

Dos roles, definidos por Constructora A2C (2026-10-04). Puede haber varios administradores. **No hay permisos por obra** (RN-14).

| Acción                                      | ADMIN | OPERADOR |
| ------------------------------------------- | :---: | :------: |
| Ver panel, obras, inventario, historial     | ✅    | ✅       |
| **Consultar disponibilidad** (dónde está cada activo) | ✅ | ✅  |
| **Mover / asignar activos** entre cualquier obra y el almacén | ✅ | ✅ |
| Agregar notas                               | ✅    | ✅       |
| **Reportar observación** al trasladar (dañado, incompleto, faltante) | ✅ | ✅ |
| Marcar observaciones como atendidas         | ✅    | ❌       |
| Alta y edición de activos                   | ✅    | ❌       |
| Cambiar estado (Mantenimiento / Baja)       | ✅    | ❌ (reporta con nota) |
| Revertir movimientos                        | ✅    | ❌       |
| Crear, editar, cerrar y reabrir obras       | ✅    | ❌       |
| Gestionar usuarios                          | ✅    | ❌       |
| Importación masiva, auditoría               | ✅    | ❌       |

> El **operador** es el único rol operativo: consulta, traslada y reporta observaciones **sin aprobación** del administrador. El **administrador** tiene acceso técnico a todas las funciones, pero su función es administrar y supervisar; no es quien ejecuta los traslados.

**Implementación:**
- API: decorador `@Roles('ADMIN')` en endpoints administrativos + `RolesGuard` global; los endpoints de movimiento aceptan `ADMIN` y `OPERADOR`.
- App: la interfaz oculta acciones no permitidas (`can(Permission.x)`), pero **la decisión siempre la toma el servidor**.

## 5. Seguridad en la app Flutter

| Control                                       | Implementación                                                  |
| --------------------------------------------- | --------------------------------------------------------------- |
| Almacenamiento seguro                         | `flutter_secure_storage`; nada sensible en `shared_preferences` |
| Base local                                    | Drift sin datos de credenciales; se borra al cerrar sesión      |
| Comunicación                                  | Solo HTTPS; *certificate pinning* opcional en producción        |
| Ofuscación                                    | `flutter build --obfuscate --split-debug-info`                  |
| Capturas en pantallas sensibles               | No aplica en el MVP (sin datos financieros)                     |
| Logs                                          | Sin tokens ni contraseñas; Sentry con `beforeSend` que filtra   |
| Root / jailbreak                              | Aviso no bloqueante (post-MVP)                                  |
| Biometría (RF-AUT-07)                         | `local_auth` para reabrir la sesión (post-MVP)                  |

## 6. Seguridad en la API

| Control                         | Implementación                                                           |
| ------------------------------- | ------------------------------------------------------------------------ |
| Validación de entrada           | `ValidationPipe` con `whitelist` y `forbidNonWhitelisted`                |
| Inyección SQL                   | Prisma con consultas parametrizadas; SQL crudo solo con `$queryRaw` etiquetado |
| Encabezados                     | Helmet, HSTS, `X-Content-Type-Options`, CORS restringido al panel web    |
| Rate limiting                   | `@nestjs/throttler` con ventana deslizante compartida en Redis: 300 solicitudes/min por IP en general y 20/min en login. La actualización del contador y el bloqueo son atómicos. |
| Secretos                        | Variables de entorno desde el gestor del proveedor; nunca en el repo (gitleaks en CI) |
| Dependencias                    | `pnpm audit` + Dependabot; `dart pub outdated` en CI                     |
| Errores                         | Sin trazas internas en respuestas de producción                          |

## 7. Integridad del inventario

- Movimientos **inmutables** (trigger en BD, ver `05` §4); correcciones solo por `REVERSION` o `AJUSTE` con motivo.
- Transacción con `SELECT … FOR UPDATE` y `CHECK (quantity >= 0)`.
- `Idempotency-Key` por usuario evita duplicados por reintentos.
- Verificación nocturna de invariantes con alerta (RNF-DI-04).

## 8. Auditoría

Se registra en `audit_logs` (quién, qué, cuándo, antes/después, IP):
`USER_CREATED`, `USER_UPDATED`, `USER_DEACTIVATED`, `USER_PASSWORD_RESET`, `LOGIN_LOCKED`, `ASSET_CREATED`, `ASSET_UPDATED`, `ASSET_STATUS_CHANGED`, `SITE_CREATED`, `SITE_CLOSED`, `MOVEMENT_REVERTED`, `IMPORT_EXECUTED`.

## 9. Protección de datos personales

> La operación es en **Perú**: aplica la **Ley N.° 29733**, Ley de Protección de Datos Personales, y su reglamento (D.S. N.° 016-2024-JUS).

| Principio           | Aplicación                                                                |
| ------------------- | ------------------------------------------------------------------------- |
| Finalidad           | DNI y nombre se usan solo para identificar al personal y atribuir movimientos |
| Minimización        | No se recogen correo, teléfono ni ubicación del usuario                    |
| Consentimiento      | Aviso de privacidad visible en el primer ingreso; texto aprobado por A2C   |
| Seguridad           | Cifrado en tránsito (TLS) y en reposo (disco de la base de datos)          |
| Acceso restringido  | Solo administradores ven la lista completa de usuarios y sus DNI           |
| Derechos ARCO       | Anonimización de un usuario retirado manteniendo la integridad del historial |
| Registro del banco  | Evaluar inscripción del banco de datos de personal ante la autoridad       |

## 10. Checklist de seguridad antes de producción

- [ ] Pentest básico de la API (OWASP API Top 10)
- [ ] Revisión MASVS L1 de la app
- [ ] Rotación de claves y secretos de staging ≠ producción
- [ ] Copias de seguridad probadas con restauración real
- [ ] Rate limits verificados con prueba de carga
- [ ] Aviso de privacidad aprobado
- [ ] Usuario administrador inicial con contraseña cambiada
