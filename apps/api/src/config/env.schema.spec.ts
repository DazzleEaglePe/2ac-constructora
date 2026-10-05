import { validateEnv } from './env.schema';

describe('validateEnv', () => {
  const base = {
    DATABASE_URL: 'postgresql://a2c:a2c@localhost:5433/a2c',
    REDIS_URL: 'redis://localhost:6380',
    JWT_PRIVATE_KEY: 'clave-de-prueba\\nlinea-2',
    JWT_PUBLIC_KEY: 'publica-de-prueba\\nlinea-2',
  };

  it('aplica valores por defecto', () => {
    const env = validateEnv(base);
    expect(env.PORT).toBe(3100);
    expect(env.CORS_ORIGINS).toEqual([]);
  });

  it('separa CORS_ORIGINS por comas', () => {
    expect(validateEnv({ ...base, CORS_ORIGINS: 'http://a.pe, http://b.pe' }).CORS_ORIGINS).toEqual([
      'http://a.pe',
      'http://b.pe',
    ]);
  });

  it('convierte los \\n escapados de las claves en saltos de línea reales', () => {
    expect(validateEnv(base).JWT_PRIVATE_KEY).toContain('\n');
  });

  it('exige las claves JWT', () => {
    const { JWT_PRIVATE_KEY: _k, ...rest } = base;
    expect(() => validateEnv(rest)).toThrow(/JWT_PRIVATE_KEY/);
  });

  it('rechaza una configuración sin base de datos', () => {
    expect(() => validateEnv({ ...base, DATABASE_URL: undefined })).toThrow(/DATABASE_URL/);
  });
});
