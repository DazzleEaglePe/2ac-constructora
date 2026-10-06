import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { APP_GUARD } from '@nestjs/core';
import { JwtModule } from '@nestjs/jwt';
import type { Env } from '../../config/env.schema';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { JwtAuthGuard } from './guards/jwt-auth.guard';
import { RolesGuard } from './guards/roles.guard';
import { PasswordService } from './password.service';
import { TokenService } from './token.service';

@Module({
  imports: [
    JwtModule.registerAsync({
      global: true,
      inject: [ConfigService],
      useFactory: (config: ConfigService<Env, true>) => ({
        privateKey: config.get('JWT_PRIVATE_KEY', { infer: true }),
        publicKey: config.get('JWT_PUBLIC_KEY', { infer: true }),
        signOptions: {
          algorithm: 'RS256',
          expiresIn: config.get('JWT_ACCESS_TTL', { infer: true }) as `${number}m`,
          issuer: 'a2c-inventario',
        },
        verifyOptions: { algorithms: ['RS256'], issuer: 'a2c-inventario' },
      }),
    }),
  ],
  controllers: [AuthController],
  providers: [
    AuthService,
    TokenService,
    PasswordService,
    // Orden: primero autenticación, luego roles.
    { provide: APP_GUARD, useClass: JwtAuthGuard },
    { provide: APP_GUARD, useClass: RolesGuard },
  ],
  exports: [PasswordService, TokenService],
})
export class AuthModule {}
