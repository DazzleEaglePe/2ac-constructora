import http from 'k6/http';
import { check, sleep } from 'k6';
import { Counter, Rate } from 'k6/metrics';

const accepted = new Rate('movement_accepted');
const requestCount = new Counter('movement_requests');
const baseUrl = (__ENV.API_BASE_URL || '').replace(/\/$/, '');
const token = __ENV.API_TOKEN || '';
const fromSiteId = __ENV.FROM_SITE_ID || '';
const toSiteId = __ENV.TO_SITE_ID || '';
const assets = (__ENV.ASSET_IDS || '')
  .split(',')
  .map((id) => id.trim())
  .filter(Boolean);
const duration = __ENV.LOAD_DURATION || '44m';
const maxVUs = Number(__ENV.MAX_VUS || 200);
const intervalSeconds = Number(__ENV.MOVEMENT_INTERVAL_SECONDS || 50);

if (__ENV.TARGET_ENV !== 'staging') {
  throw new Error('La prueba de movimientos solo se ejecuta con TARGET_ENV=staging.');
}
if (!baseUrl || !token || !fromSiteId || !toSiteId || fromSiteId === toSiteId) {
  throw new Error('Configura API_BASE_URL, API_TOKEN y dos ubicaciones distintas.');
}
if (assets.length < maxVUs || new Set(assets).size !== assets.length) {
  throw new Error(`Se requieren al menos ${maxVUs} IDs de activos únicos en ASSET_IDS.`);
}
if (!Number.isInteger(maxVUs) || maxVUs < 1 || intervalSeconds <= 0) {
  throw new Error('MAX_VUS e intervalo de movimiento deben ser positivos.');
}

export const options = {
  scenarios: {
    movement_write_load: {
      executor: 'constant-vus',
      vus: maxVUs,
      duration,
      exec: 'createMovement',
      tags: { workload: 'movement-write' },
    },
  },
  thresholds: {
    http_req_duration: ['p(95)<800'],
    http_req_failed: ['rate<0.01'],
    movement_accepted: ['rate>0.99'],
    movement_requests: ['count>10000'],
  },
};

export function createMovement() {
  const assetId = assets[(__VU - 1) % assets.length];
  const forward = __ITER % 2 === 0;
  const response = http.post(
    `${baseUrl}/movements`,
    JSON.stringify({
      assetId,
      fromSiteId: forward ? fromSiteId : toSiteId,
      toSiteId: forward ? toSiteId : fromSiteId,
      quantity: 1,
    }),
    {
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
        'Idempotency-Key': `perf-${__VU}-${__ITER}-${Date.now()}`,
      },
      timeout: '10s',
      tags: { name: 'POST /movements' },
    },
  );
  const ok = check(response, {
    'movement accepted with 201': (res) => res.status === 201,
  });
  requestCount.add(1);
  accepted.add(ok);
  sleep(intervalSeconds);
}
