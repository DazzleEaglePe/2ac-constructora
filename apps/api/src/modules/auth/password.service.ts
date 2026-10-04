import { randomInt } from 'node:crypto';
import { HttpStatus, Injectable } from '@nestjs/common';
import { argon2id, hash, verify } from 'argon2';
import { DomainException } from '../../common/filters/problem-details.filter';

// Parámetros Argon2id de docs/07 §2 (OWASP: m = 19 MiB, t = 2, p = 1).
const ARGON_OPTIONS = { type: argon2id, memoryCost: 19456, timeCost: 2, parallelism: 1 } as const;

// Lista corta de contraseñas comunes; se amplía con un archivo en S6.
const COMMON = new Set([
  'password1', 'contrasena1', '12345678a', 'qwerty123', 'abc12345', 'peru2026', 'admin123',
  'a2c12345', 'constructora1', 'obra1234', 'password123', 'iloveyou1',
]);

@Injectable()
export class PasswordService {
  /** Hash válido usado para igualar el tiempo de respuesta cuando el DNI no existe. */
  private dummyHash?: Promise<string>;

  hash(plain: string): Promise<string> {
    return hash(plain, ARGON_OPTIONS);
  }

  async verify(hashValue: string | null, plain: string): Promise<boolean> {
    if (!hashValue) {
      this.dummyHash ??= this.hash('tiempo-constante-0');
      await verify(await this.dummyHash, plain).catch(() => false);
      return false;
    }
    return verify(hashValue, plain).catch(() => false);
  }

  /** Política de contraseñas (docs/07 §2). Lanza `VALIDACION` si no se cumple. */
  assertPolicy(plain: string, dni: string): void {
    const problems: string[] = [];
    if (plain.length < 8) problems.push('Debe tener al menos 8 caracteres');
    if (!/[A-Za-zÁÉÍÓÚáéíóúÑñ]/.test(plain)) problems.push('Debe incluir al menos una letra');
    if (!/[0-9]/.test(plain)) problems.push('Debe incluir al menos un número');
    if (plain.includes(dni)) problems.push('No puede contener tu DNI');
    if (COMMON.has(plain.toLowerCase())) problems.push('Es demasiado común');
    if (problems.length) {
      throw new DomainException(
        'VALIDACION',
        'La contraseña no cumple la política',
        HttpStatus.UNPROCESSABLE_ENTITY,
        problems.join('. '),
        { errors: problems.map((message) => ({ field: 'password', message })) },
      );
    }
  }

  /** Contraseña temporal legible (sin 0/O ni 1/l), con letras y números. */
  generateTemporary(): string {
    const letters = 'ABCDEFGHJKMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz';
    const digits = '23456789';
    const all = letters + digits;
    const chars = [letters[randomInt(letters.length)], digits[randomInt(digits.length)]];
    while (chars.length < 10) chars.push(all[randomInt(all.length)]);
    for (let i = chars.length - 1; i > 0; i--) {
      const j = randomInt(i + 1);
      [chars[i], chars[j]] = [chars[j], chars[i]];
    }
    return chars.join('');
  }
}
