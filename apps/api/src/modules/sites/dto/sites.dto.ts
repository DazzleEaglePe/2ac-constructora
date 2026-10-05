import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { SiteStatus, SiteType } from '@prisma/client';
import { Transform } from 'class-transformer';
import { IsEnum, IsNumber, IsOptional, IsString, Length, Max, Min } from 'class-validator';

const trim = ({ value }: { value: unknown }) =>
  typeof value === 'string' ? value.trim().replace(/\s+/g, ' ') : value;

export class CreateSiteDto {
  @ApiProperty({ example: 'Obra Juan Ramírez' })
  @IsString()
  @Length(3, 120)
  @Transform(trim)
  name: string;

  @ApiProperty({ example: 'Juan Ramírez' })
  @IsString()
  @Length(3, 120)
  @Transform(trim)
  ownerName: string;

  @ApiPropertyOptional({ example: 'Calle Los Pinos 245, Lima' })
  @IsOptional()
  @IsString()
  @Length(3, 200)
  @Transform(trim)
  address?: string;

  @ApiPropertyOptional({ example: -12.0464, minimum: -90, maximum: 90 })
  @IsOptional()
  @IsNumber({ maxDecimalPlaces: 6 })
  @Min(-90)
  @Max(90)
  lat?: number;

  @ApiPropertyOptional({ example: -77.0428, minimum: -180, maximum: 180 })
  @IsOptional()
  @IsNumber({ maxDecimalPlaces: 6 })
  @Min(-180)
  @Max(180)
  lng?: number;
}

export class UpdateSiteDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @Length(3, 120)
  @Transform(trim)
  name?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @Length(3, 120)
  @Transform(trim)
  ownerName?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @Length(3, 200)
  @Transform(trim)
  address?: string;

  @ApiPropertyOptional({ minimum: -90, maximum: 90 })
  @IsOptional()
  @IsNumber({ maxDecimalPlaces: 6 })
  @Min(-90)
  @Max(90)
  lat?: number | null;

  @ApiPropertyOptional({ minimum: -180, maximum: 180 })
  @IsOptional()
  @IsNumber({ maxDecimalPlaces: 6 })
  @Min(-180)
  @Max(180)
  lng?: number | null;
}

export class ListSitesQuery {
  @ApiPropertyOptional({ enum: SiteType })
  @IsOptional()
  @IsEnum(SiteType)
  type?: SiteType;

  @ApiPropertyOptional({ enum: SiteStatus })
  @IsOptional()
  @IsEnum(SiteStatus)
  status?: SiteStatus;

  @ApiPropertyOptional({ description: 'Busca por obra, dueño o dirección' })
  @IsOptional()
  @IsString()
  @Length(1, 80)
  q?: string;
}

export class SiteStockQuery {
  @ApiPropertyOptional({ enum: ['MAQUINA', 'HERRAMIENTA'] })
  @IsOptional()
  @IsEnum(['MAQUINA', 'HERRAMIENTA'])
  type?: 'MAQUINA' | 'HERRAMIENTA';
}
