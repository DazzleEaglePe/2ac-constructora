import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Role } from '@prisma/client';
import { Transform } from 'class-transformer';
import {
  IsBoolean,
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  Length,
  Matches,
  Max,
  Min,
} from 'class-validator';

export class CreateUserDto {
  @ApiProperty({ example: '35112604', description: 'DNI peruano de 8 dígitos' })
  @Matches(/^[0-9]{8}$/, { message: 'dni debe tener 8 dígitos' })
  dni: string;

  @ApiProperty({ example: 'Martín Ruiz' })
  @IsString()
  @Length(3, 120)
  @Transform(({ value }) => (typeof value === 'string' ? value.trim().replace(/\s+/g, ' ') : value))
  fullName: string;

  @ApiProperty({ enum: Role })
  @IsEnum(Role)
  role: Role;

  @ApiProperty({ description: 'Contraseña temporal; el usuario deberá cambiarla en su primer ingreso' })
  @IsString()
  @Length(8, 128)
  temporaryPassword: string;
}

export class UpdateUserDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @Length(3, 120)
  @Transform(({ value }) => (typeof value === 'string' ? value.trim().replace(/\s+/g, ' ') : value))
  fullName?: string;

  @ApiPropertyOptional({ enum: Role })
  @IsOptional()
  @IsEnum(Role)
  role?: Role;
}

export class ListUsersQuery {
  @ApiPropertyOptional({ description: 'Busca por nombre o DNI' })
  @IsOptional()
  @IsString()
  @Length(1, 60)
  q?: string;

  @ApiPropertyOptional({ enum: Role })
  @IsOptional()
  @IsEnum(Role)
  role?: Role;

  @ApiPropertyOptional()
  @IsOptional()
  @Transform(({ value }) => (value === 'true' ? true : value === 'false' ? false : value))
  @IsBoolean()
  active?: boolean;

  @ApiPropertyOptional({ default: 50 })
  @IsOptional()
  @Transform(({ value }) => Number(value))
  @IsInt()
  @Min(1)
  @Max(100)
  limit?: number;

  @ApiPropertyOptional({ description: 'Cursor opaco devuelto en nextCursor' })
  @IsOptional()
  @IsUUID()
  cursor?: string;
}
