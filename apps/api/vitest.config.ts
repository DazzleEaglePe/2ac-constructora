import swc from 'unplugin-swc';
import { defineConfig } from 'vitest/config';

// SWC emite la metadata de decoradores que necesita la inyección de dependencias de NestJS.
export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
    include: ['src/**/*.spec.ts', 'test/**/*.e2e-spec.ts'],
  },
  plugins: [swc.vite({ module: { type: 'es6' } })],
});
