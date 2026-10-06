import { generateKeyPairSync } from 'node:crypto';
import swc from 'unplugin-swc';
import { defineConfig } from 'vitest/config';
import { testDatabaseUrl } from './test/test-env';

// Par RSA efímero para firmar JWT en las pruebas (no se usan las claves de desarrollo).
const keys = generateKeyPairSync('rsa', {
  modulusLength: 2048,
  publicKeyEncoding: { type: 'spki', format: 'pem' },
  privateKeyEncoding: { type: 'pkcs8', format: 'pem' },
});

// SWC emite la metadata de decoradores que necesita la inyección de dependencias de NestJS.
export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
    include: ['src/**/*.spec.ts', 'test/**/*.e2e-spec.ts'],
    globalSetup: ['test/global-setup.ts'],
    fileParallelism: false,
    env: {
      NODE_ENV: 'test',
      DATABASE_URL: testDatabaseUrl(),
      JWT_PRIVATE_KEY: keys.privateKey,
      JWT_PUBLIC_KEY: keys.publicKey,
    },
  },
  plugins: [swc.vite({ module: { type: 'es6' } })],
});
