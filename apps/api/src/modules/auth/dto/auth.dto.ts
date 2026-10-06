import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, Length, Matches, MaxLength } from 'class-validator';

export class LoginDto {
  @ApiProperty({ example: '30456789', description: 'DNI peruano de 8 dígitos' })
  @Matches(/^[0-9]{8}$/, { message: 'dni debe tener 8 dígitos' })
  dni: string;

  @ApiProperty()
  @IsString()
  @Length(1, 128)
  password: string;

  @ApiPropertyOptional({ example: 'Galaxy A54' })
  @IsOptional()
  @IsString()
  @MaxLength(80)
  deviceName?: string;
}

export class RefreshDto {
  @ApiProperty()
  @IsString()
  @Length(10, 200)
  refreshToken: string;
}

export class ChangePasswordDto {
  @ApiProperty()
  @IsString()
  @Length(1, 128)
  currentPassword: string;

  @ApiProperty({ description: 'Mínimo 8 caracteres, con letras y números' })
  @IsString()
  @Length(8, 128)
  newPassword: string;
}
