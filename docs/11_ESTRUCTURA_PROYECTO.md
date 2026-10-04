# 11 — Estructura del Proyecto

> Proyecto **independiente**: repositorio propio `a2c-inventario`, sin relación con otros proyectos.

---

## 1. Monorepo

```
a2c-inventario/
├── apps/
│   ├── api/                      # NestJS 11 (TypeScript) — pnpm workspace
│   └── mobile/                   # Flutter (Android · iOS · Web)
├── packages/
│   └── api_client/               # Cliente Dart generado desde apps/api/openapi.yaml
├── assets/
│   └── branding/                 # Logo animado MP4/GIF, ícono de app, recursos de marca
├── docs/                         # Esta documentación (01–11)
├── tools/
│   ├── docker/                   # docker-compose.yml (PostgreSQL, Redis)
│   └── scripts/                  # generate-jwt-keys.sh, gen-api-client.sh, seed helpers
├── .claude/skills/inventario-obras-ui/   # Reglas visuales para agentes
├── .github/workflows/            # ci-api.yml, ci-mobile.yml, release-mobile.yml
├── package.json                  # Scripts raíz (pnpm)
├── pnpm-workspace.yaml           # Solo incluye apps/api; overrides de seguridad
└── README.md
```

> La app Flutter vive dentro del monorepo pero se compila con su propia herramienta (`flutter`), fuera del workspace de pnpm.

## 2. API — `apps/api`

```
apps/api/
├── prisma/
│   ├── schema.prisma
│   ├── migrations/
│   └── seed.ts
├── src/
│   ├── main.ts
│   ├── app.module.ts
│   ├── config/                   # env.schema.ts, configuración tipada
│   ├── common/                   # guards, decorators (@Roles, @CurrentUser), filters, interceptors, pipes
│   ├── prisma/                   # PrismaService
│   ├── modules/
│   │   ├── auth/
│   │   ├── users/
│   │   ├── sites/
│   │   ├── assets/
│   │   ├── movements/
│   │   ├── dashboard/
│   │   ├── realtime/
│   │   ├── audit/
│   │   └── health/
│   └── jobs/                     # stock-integrity.job.ts
├── test/                         # e2e (supertest) con base de datos de prueba
├── openapi.yaml                  # exportado en el build
├── Dockerfile
└── package.json
```

Cada módulo: `*.module.ts`, `*.controller.ts`, `*.service.ts`, `dto/`, `*.spec.ts`.

## 3. App — `apps/mobile`

```
apps/mobile/
├── lib/
│   ├── main.dart                 # entorno por --dart-define-from-file=env/<entorno>.json
│   ├── app.dart                  # MaterialApp.router + A2CTheme
│   ├── core/
│   │   ├── theme/                # a2c_colors.dart, a2c_typography.dart, a2c_theme.dart, a2c_radii.dart
│   │   ├── router/               # app_router.dart, guards
│   │   ├── network/              # dio_client.dart, auth_interceptor.dart, idempotency.dart
│   │   ├── realtime/             # socket_service.dart
│   │   ├── storage/              # secure_storage.dart, database.dart (Drift)
│   │   ├── errors/               # failure.dart, problem_details.dart
│   │   └── l10n/                 # app_es.arb
│   ├── shared/
│   │   └── widgets/              # a2c_primary_button.dart, a2c_nav_bar.dart, status_badge.dart, a2c_logo.dart …
│   └── features/
│       ├── welcome/              # splash (a2c_splash_animation.dart), onboarding
│       ├── auth/
│       ├── dashboard/
│       ├── sites/
│       ├── assets/
│       ├── movements/
│       └── users/
│           ├── data/             # repositories, datasources (remote/local), dto
│           ├── domain/           # entidades, reglas
│           └── presentation/     # screens, widgets, controllers (Riverpod)
├── assets/
│   ├── fonts/                    # Geist, Geist Mono
│   └── images/
├── test/                         # unit y widget tests
├── integration_test/             # flujos completos
├── android/ · ios/ · web/
├── analysis_options.yaml         # flutter_lints + reglas estrictas
└── pubspec.yaml
```

### Dependencias Flutter principales

| Paquete                          | Uso                                   |
| -------------------------------- | ------------------------------------- |
| `flutter_riverpod`, `riverpod_annotation` | Estado                       |
| `go_router`                      | Navegación y guardas                  |
| `dio`                            | HTTP                                  |
| `freezed`, `json_serializable`   | Modelos inmutables                    |
| `drift`                          | Caché y cola offline                  |
| `flutter_secure_storage`         | Tokens                                |
| `socket_io_client`               | Tiempo real                           |
| `connectivity_plus`              | Estado de red                         |
| `flutter_map`, `latlong2`        | Mapas                                 |
| `url_launcher`                   | "Abrir en Maps"                       |
| `intl`, `flutter_localizations`  | Español                               |
| `lucide_icons_flutter`           | Íconos                                |
| `sentry_flutter`                 | Errores                               |
| Dev: `build_runner`, `riverpod_generator`, `freezed`, `drift_dev`, `mocktail`, `flutter_lints` (reglas extra) | Generación y pruebas |

## 4. Convenciones

| Tema                    | Convención                                                                     |
| ----------------------- | ------------------------------------------------------------------------------ |
| Idioma del código       | Inglés (identificadores); textos de interfaz en español vía ARB                |
| Idioma de documentación | Español                                                                        |
| Commits                 | Conventional Commits: `feat(movements): …`, `fix(auth): …`                     |
| Ramas                   | `main` (protegida) · `feat/s{N}-descripcion` · `fix/…`                         |
| PR                      | Plantilla con requerimientos cubiertos (RF-…), capturas y checklist DoD        |
| Dart                    | `snake_case.dart`, clases `PascalCase`, widgets propios con prefijo `A2C`       |
| TypeScript              | ESLint + Prettier; DTO con `class-validator`                                   |
| Base de datos           | Tablas y columnas `snake_case` (`@@map` / `@map` en Prisma)                     |
| API                     | Rutas en inglés plural (`/sites`, `/assets`, `/movements`); códigos de error en español mayúsculas |
| Versionado de la app    | SemVer `1.0.0+build`; `CHANGELOG.md` por release                               |

## 5. Variables de entorno

### API (`apps/api/.env`)

| Variable                 | Ejemplo                                        |
| ------------------------ | ---------------------------------------------- |
| `NODE_ENV`               | `development`                                  |
| `PORT`                   | `3100`                                         |
| `DATABASE_URL`           | `postgresql://a2c:a2c@localhost:5433/a2c`      |
| `REDIS_URL`              | `redis://localhost:6380`                       |
| `JWT_PRIVATE_KEY` / `JWT_PUBLIC_KEY` | PEM generados por `tools/scripts/generate-jwt-keys.sh` |
| `JWT_ACCESS_TTL`         | `15m`                                          |
| `REFRESH_TTL_DAYS`       | `30`                                           |
| `SEED_ADMIN_DNI` / `SEED_ADMIN_PASSWORD` | Admin inicial (solo semilla)   |
| `SENTRY_DSN`             | —                                              |
| `CORS_ORIGINS`           | `http://localhost:5173`                        |

### App (`--dart-define`)

| Variable        | Ejemplo                         |
| --------------- | ------------------------------- |
| `API_BASE_URL`  | `http://localhost:3100/api/v1` (emulador Android: `10.0.2.2`) |
| `WS_URL`        | `http://localhost:3100/realtime` |
| `SENTRY_DSN`    | —                               |
| `ENV`           | `dev` · `staging` · `prod`      |

## 6. Entorno local

```bash
# 1. Infraestructura
docker compose -f tools/docker/docker-compose.yml up -d

# 2. API
cd apps/api
cp .env.example .env
../../tools/scripts/generate-jwt-keys.sh >> .env
pnpm install
pnpm prisma migrate dev
pnpm prisma db seed
pnpm start:dev                      # http://localhost:3100  ·  docs en /docs

# 3. Cliente API (cuando cambie el contrato)
../../tools/scripts/gen-api-client.sh

# 4. App
cd ../mobile
cp env/example.json env/dev.json     # entorno local (env/*.json no se versiona)
flutter pub get
flutter gen-l10n
flutter run --dart-define-from-file=env/dev.json   # en dev abre el catálogo de componentes
```

## 7. Scripts raíz

| Script                 | Acción                                          |
| ---------------------- | ----------------------------------------------- |
| `pnpm docker:up/down`  | Levantar / bajar PostgreSQL y Redis             |
| `pnpm dev:api`         | API en modo desarrollo                          |
| `pnpm db:migrate`      | Migraciones Prisma                              |
| `pnpm db:seed`         | Semilla                                         |
| `pnpm test:api`        | Pruebas unitarias + e2e de la API               |
| `pnpm gen:client`      | Generar `packages/api_client` desde OpenAPI     |
| `pnpm mobile:test`     | `flutter analyze && flutter test` en `apps/mobile` |

## 8. CI/CD

| Workflow              | Disparador        | Pasos                                                                |
| --------------------- | ----------------- | -------------------------------------------------------------------- |
| `ci-api.yml`          | PR y `main`       | install → lint → typecheck → test (con Postgres de servicio) → build Docker |
| `ci-mobile.yml`       | PR y `main`       | formato → `flutter analyze` → `flutter test` → build web            |
| `security.yml`        | PR y `main`       | gitleaks + `pnpm audit` (críticas)                                   |
| `release-mobile.yml`  | Tag `v*`          | Build firmado Android (AAB) e iOS (IPA) → Play prueba interna / TestFlight |
| `deploy-api.yml`      | `main` / tag      | Imagen Docker → staging; producción con aprobación manual            |
