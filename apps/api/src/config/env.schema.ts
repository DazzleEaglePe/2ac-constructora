import { z } from 'zod';

/** Variables de entorno de la API, validadas al arrancar. */
export const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z.coerce.number().int().positive().default(3100),
  DATABASE_URL: z.string().url(),
  REDIS_URL: z.string().url(),
  CORS_ORIGINS: z
    .string()
    .default('')
    .transform((v) =>
      v
        .split(',')
        .map((s) => s.trim())
        .filter(Boolean),
    ),
  // PEM con saltos de línea escapados (\n), generados por tools/scripts/generate-jwt-keys.sh
  JWT_PRIVATE_KEY: z.string().min(1).transform((v) => v.replace(/\\n/g, '\n')),
  JWT_PUBLIC_KEY: z.string().min(1).transform((v) => v.replace(/\\n/g, '\n')),
  JWT_ACCESS_TTL: z.string().default('15m'),
  REFRESH_TTL_DAYS: z.coerce.number().int().positive().default(30),
  SENTRY_DSN: z.string().optional(),
});

export type Env = z.infer<typeof envSchema>;

export function validateEnv(config: Record<string, unknown>): Env {
  const parsed = envSchema.safeParse(config);
  if (!parsed.success) {
    const issues = parsed.error.issues.map((i) => `${i.path.join('.')}: ${i.message}`).join('; ');
    throw new Error(`Variables de entorno inválidas: ${issues}`);
  }
  return parsed.data;
}
