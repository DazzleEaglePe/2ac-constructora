import { PrismaClient, Role, SiteType } from '@prisma/client';
import { hash } from 'argon2';

const prisma = new PrismaClient();

/** Semilla mínima: almacén central, secuencias de código y administrador inicial (docs/05 §7). */
async function main(): Promise<void> {
  const dni = process.env.SEED_ADMIN_DNI;
  const password = process.env.SEED_ADMIN_PASSWORD;
  const fullName = process.env.SEED_ADMIN_NAME ?? 'Administrador A2C';
  if (!dni || !/^[0-9]{8}$/.test(dni) || !password) {
    throw new Error('Define SEED_ADMIN_DNI (8 dígitos) y SEED_ADMIN_PASSWORD en .env');
  }

  const warehouse = await prisma.site.findFirst({ where: { type: SiteType.ALMACEN } });
  if (!warehouse) {
    await prisma.site.create({ data: { type: SiteType.ALMACEN, name: 'Almacén central' } });
  }

  for (const prefix of ['MAQ', 'HER']) {
    await prisma.codeSequence.upsert({ where: { prefix }, update: {}, create: { prefix } });
  }

  await prisma.user.upsert({
    where: { dni },
    update: {},
    create: {
      dni,
      fullName,
      role: Role.ADMIN,
      passwordHash: await hash(password, { type: 2, memoryCost: 19456, timeCost: 2, parallelism: 1 }),
      mustChangePassword: true,
    },
  });

  console.log('Semilla aplicada: almacén central, secuencias MAQ/HER y administrador inicial.');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
