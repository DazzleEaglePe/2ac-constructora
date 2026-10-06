# Prueba de carga de movimientos

`movement-load.js` mantiene 200 VUs durante 44 minutos; cada uno traslada un
activo de prueba aproximadamente cada 50 segundos. El objetivo es superar las
10 000 escrituras en el ensayo y verificar el p95 de confirmación de movimiento
de 800 ms y una tasa de aceptación superior al 99 %. El ritmo queda por debajo
del límite general de 300 peticiones/minuto por IP configurado en la API.

La prueba escribe movimientos y registros de auditoría. Ejecútala solo en un
staging aislado, con datos de prueba preparados; nunca uses credenciales ni
inventario de producción. Para que el token supere los 44 minutos, inicia el API
de staging con `JWT_ACCESS_TTL=1h` solo durante esta prueba y genera un token de
un usuario OPERADOR dedicado. Los 200 VUs comparten ese token; esta carga mide
concurrencia de clientes y escrituras, no escalado de autenticación por usuario.

Prepara al menos 200 activos-herramienta distintos, cada uno con una unidad en
la ubicación de origen, y dos ubicaciones activas. Pasa sus UUID en
`ASSET_IDS`, separados por comas. El guion asigna un activo por VU y alterna el
sentido del traslado entre iteraciones para conservar el stock.

```sh
TARGET_ENV=staging \
API_BASE_URL=https://api-staging.example.com/api/v1 \
API_TOKEN='<token-de-prueba>' \
FROM_SITE_ID='<uuid-origen>' \
TO_SITE_ID='<uuid-destino>' \
ASSET_IDS='<uuid-1>,<uuid-2>,...,<uuid-200>' \
k6 run tools/perf/movement-load.js
```

Se puede ajustar el perfil con `LOAD_DURATION`, `MOVEMENT_INTERVAL_SECONDS` y
`MAX_VUS`; `ASSET_IDS` debe incluir al menos `MAX_VUS` IDs únicos. Conserva una
duración e intervalo cuya ejecución pueda superar las 10 000 solicitudes. El resultado
debe archivarse junto al commit probado antes de marcar el gate de carga como
aprobado.
