# 03 — Requerimientos No Funcionales

> Cada requerimiento tiene una **métrica verificable**. Los que dependen del volumen real quedan con valores iniciales que se revisan con la respuesta a la pregunta P4 de `01_CONTEXTO_Y_ANALISIS.md`.

---

## 1. Supuestos de volumen (MVP)

| Dimensión                      | Valor inicial | Diseñado para |
| ------------------------------ | ------------- | ------------- |
| Usuarios activos               | 30            | 300           |
| Obras simultáneas              | 10            | 100           |
| Activos (registros)            | 2 000         | 50 000        |
| Movimientos por día            | 300           | 10 000        |
| Usuarios conectados a la vez   | 20            | 200           |

## 2. Rendimiento (RNF-RE)

| ID        | Requerimiento                                                                 | Métrica                          |
| --------- | ----------------------------------------------------------------------------- | -------------------------------- |
| RNF-RE-01 | Arranque en frío hasta el splash                                              | ≤ 2 s en gama media (Android 10+) |
| RNF-RE-02 | Ingreso hasta ver el panel con datos (4G)                                     | ≤ 2 s (p95)                      |
| RNF-RE-03 | Latencia de lectura de la API (listas y detalle)                              | ≤ 300 ms (p95)                   |
| RNF-RE-04 | Confirmación de un movimiento                                                 | ≤ 800 ms (p95)                   |
| RNF-RE-05 | Propagación de un movimiento a otros dispositivos conectados                  | ≤ 2 s                            |
| RNF-RE-06 | Animación del splash y transiciones                                           | 60 fps sin cuadros perdidos visibles |
| RNF-RE-07 | Tamaño de la app instalada                                                    | ≤ 40 MB (Android, APK por ABI)   |
| RNF-RE-08 | Listas largas (inventario, historial) con paginación por cursor              | 50 ítems por página, scroll fluido |

## 3. Disponibilidad y confiabilidad (RNF-DI)

| ID        | Requerimiento                                                                 | Métrica                          |
| --------- | ----------------------------------------------------------------------------- | -------------------------------- |
| RNF-DI-01 | Disponibilidad mensual de la API                                              | ≥ 99,5 %                         |
| RNF-DI-02 | Respaldo de base de datos                                                     | Diario + PITR 7 días             |
| RNF-DI-03 | Objetivo de recuperación                                                      | RPO ≤ 24 h · RTO ≤ 4 h           |
| RNF-DI-04 | Integridad del stock: nunca negativo, nunca inconsistente con los movimientos | 0 discrepancias (verificación nocturna) |
| RNF-DI-05 | Idempotencia de movimientos (reintentos no duplican)                          | Clave `Idempotency-Key` obligatoria |

## 4. Modo sin conexión (RNF-OF)

| ID        | Requerimiento                                                                 | Métrica                          |
| --------- | ----------------------------------------------------------------------------- | -------------------------------- |
| RNF-OF-01 | Caché local de panel, obras, inventario e historial reciente                  | Disponible sin red tras el primer ingreso |
| RNF-OF-02 | Cola persistente de movimientos pendientes (sobrevive al cierre de la app)    | 100 % de pendientes conservados  |
| RNF-OF-03 | Reintento automático al recuperar conexión                                    | ≤ 10 s tras volver la red        |
| RNF-OF-04 | Indicador visible de estado (en línea / sin conexión / N pendientes)          | Siempre visible en el panel      |

## 5. Seguridad (RNF-SE)

Detalle completo en [`07_SEGURIDAD_AUTH.md`](./07_SEGURIDAD_AUTH.md).

| ID        | Requerimiento                                                                 | Métrica                          |
| --------- | ----------------------------------------------------------------------------- | -------------------------------- |
| RNF-SE-01 | Tráfico cifrado                                                               | TLS 1.2+ (HSTS en la API)        |
| RNF-SE-02 | Contraseñas con hash robusto                                                  | Argon2id                         |
| RNF-SE-03 | Tokens almacenados de forma segura en el dispositivo                          | Keychain / Keystore (`flutter_secure_storage`) |
| RNF-SE-04 | Autorización por rol verificada en el servidor en cada endpoint               | 100 % de endpoints con guardas   |
| RNF-SE-05 | Límite de intentos de ingreso                                                 | 5 por cuenta / 15 min; 20 por IP / min |
| RNF-SE-06 | Sin dependencias con vulnerabilidades críticas                                | 0 críticas en CI                 |
| RNF-SE-07 | Cumplimiento de protección de datos personales (DNI, nombre)                  | Ver `07` §9                      |

## 6. Usabilidad y accesibilidad (RNF-UX)

| ID        | Requerimiento                                                                 | Métrica                          |
| --------- | ----------------------------------------------------------------------------- | -------------------------------- |
| RNF-UX-01 | Contraste de texto                                                            | WCAG 2.2 AA (4,5:1; 3:1 ≥ 24 px) |
| RNF-UX-02 | Áreas táctiles                                                                | ≥ 44 × 44 pt (48 dp en Android)  |
| RNF-UX-03 | Legibilidad a pleno sol                                                       | Tema claro A2C, sin texto amarillo sobre blanco |
| RNF-UX-04 | Lectores de pantalla                                                          | TalkBack / VoiceOver con etiquetas `Semantics` en íconos |
| RNF-UX-05 | Texto escalable                                                               | Interfaz usable hasta 130 % del tamaño de fuente del sistema |
| RNF-UX-06 | Respeto de "reducir movimiento"                                               | Splash y transiciones sin animación |
| RNF-UX-07 | Idioma                                                                        | Español (es-PE) con `intl`; textos externalizados (ARB) |
| RNF-UX-08 | Registrar un movimiento                                                       | ≤ 4 toques desde el detalle del activo |

## 7. Compatibilidad (RNF-CO)

| ID        | Requerimiento                                                                 | Métrica                          |
| --------- | ----------------------------------------------------------------------------- | -------------------------------- |
| RNF-CO-01 | Android                                                                       | 8.0 (API 26) o superior          |
| RNF-CO-02 | iOS                                                                           | 15 o superior                    |
| RNF-CO-03 | Pantallas                                                                     | 360–430 pt de ancho; tabletas en modo adaptado |
| RNF-CO-04 | Web (post-MVP, panel admin)                                                   | Chrome, Edge, Safari actuales    |

## 8. Mantenibilidad (RNF-MA)

| ID        | Requerimiento                                                                 | Métrica                          |
| --------- | ----------------------------------------------------------------------------- | -------------------------------- |
| RNF-MA-01 | Cobertura de pruebas del dominio (reglas de stock y movimientos)              | ≥ 90 % (API) · ≥ 80 % (lógica Flutter) |
| RNF-MA-02 | Análisis estático sin errores                                                 | `flutter analyze` y ESLint en CI |
| RNF-MA-03 | Contrato de API versionado y generado                                         | OpenAPI 3.1 como fuente de verdad |
| RNF-MA-04 | Migraciones de base de datos versionadas y reversibles                        | Prisma Migrate                   |
| RNF-MA-05 | Tokens de diseño centralizados                                                | Un solo `A2CTheme` en Flutter    |

## 9. Observabilidad (RNF-OB)

| ID        | Requerimiento                                                                 | Métrica                          |
| --------- | ----------------------------------------------------------------------------- | -------------------------------- |
| RNF-OB-01 | Registro estructurado (JSON) con `requestId` en la API                       | 100 % de solicitudes             |
| RNF-OB-02 | Reporte de errores de app y API                                               | Sentry (Flutter + NestJS)        |
| RNF-OB-03 | Salud de servicios                                                            | `/health` (liveness/readiness)   |
| RNF-OB-04 | Alertas                                                                       | Caída de API > 2 min, error rate > 2 % |
