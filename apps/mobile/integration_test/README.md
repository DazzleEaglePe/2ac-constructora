# Flujo de integración móvil

El recorrido automatizado inicia sesión, crea una obra, registra una herramienta
y confirma un movimiento. Solo debe apuntar a la base local aislada `a2c_test`.
El test rechaza otros entornos, hosts externos y mutaciones no habilitadas.

## Preparación local

1. Inicia PostgreSQL y Redis del proyecto: `pnpm docker:up`.
2. Copia `apps/api/.env.integration.example` a `apps/api/.env.integration` y
   reemplaza el DNI de 8 dígitos y la contraseña de pruebas (8 caracteres o más).
3. Añade claves JWT de desarrollo al archivo local:
   `./tools/scripts/generate-jwt-keys.sh >> apps/api/.env.integration`.
4. Carga las variables y prepara la base aislada con el usuario de prueba:

   ```sh
   set -a
   source apps/api/.env.integration
   set +a
   pnpm --filter @a2c/api seed:mobile-integration
   ```

5. Mantén esas variables cargadas y arranca la API en otra terminal:
   `pnpm --filter @a2c/api start:dev`.
6. Copia `apps/mobile/env/integration.example.json` a
   `apps/mobile/env/integration.local.json` y coloca el mismo DNI y contraseña.
   El archivo local está ignorado por Git. Para el simulador iOS conserva
   `localhost`; para Android Emulator usa `10.0.2.2` tanto en `API_BASE_URL`
   como en `WS_URL`, que es la dirección del host desde el emulador.

## Ejecución al cierre de pruebas

Con la API local activa, selecciona un simulador iOS o Android y ejecuta desde
`apps/mobile`:

```sh
flutter test integration_test/app_flow_test.dart -d <device-id> \
  --dart-define-from-file=env/integration.local.json
```

El flujo crea datos de prueba y no los elimina. La base `a2c_test` puede
reiniciarse antes de otra ejecución. No reutilices credenciales reales ni
apuntes este test a staging o producción.
