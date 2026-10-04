import { validateEnv } from './env.schema';

describe('validateEnv', () => {
  const base = {
    DATABASE_URL: 'postgresql://a2c:a2c@localhost:5433/a2c',
    REDIS_URL: 'redis://localhost:6380',
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

  it('rechaza una configuración sin base de datos', () => {
    expect(() => validateEnv({ REDIS_URL: base.REDIS_URL })).toThrow(/DATABASE_URL/);
  });
});
