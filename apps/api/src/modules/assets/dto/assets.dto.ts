import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { AssetStatus, AssetType } from '@prisma/client';
import { Transform } from 'class-transformer';
import { IsEnum, IsInt, IsOptional, IsString, IsUUID, Length, Max, Min } from 'class-validator';

const trim = ({ value }: { value: unknown }) =>
  typeof value === 'string' ? value.trim().replace(/\s+/g, ' ') : value;

export class ListAssetsQuery {
  @ApiPropertyOptional({ description: 'Busca por nombre o código' })
  @IsOptional()
  @IsString()
  @Length(1, 80)
  q?: string;

  @ApiPropertyOptional({ enum: AssetType })
  @IsOptional()
  @IsEnum(AssetType)
  type?: AssetType;

  @ApiPropertyOptional({ enum: AssetStatus })
  @IsOptional()
  @IsEnum(AssetStatus)
  status?: AssetStatus;

  @ApiPropertyOptional()
  @IsOptional()
  @IsUUID()
  siteId?: string;
}

export class SearchAssetsQuery extends ListAssetsQuery {
  @ApiPropertyOptional({ description: 'Último ID de la página anterior' })
  @IsOptional()
  @IsUUID()
  cursor?: string;

  @ApiPropertyOptional({ minimum: 1, maximum: 100, default: 50 })
  @IsOptional()
  @Transform(({ value }) => Number(value))
  @IsInt()
  @Min(1)
  @Max(100)
  limit?: number;
}

export class NextCodeQuery {
  @ApiProperty({ enum: AssetType })
  @IsEnum(AssetType)
  type: AssetType;
}

export class CreateAssetDto {
  @ApiProperty({ enum: AssetType })
  @IsEnum(AssetType)
  type: AssetType;

  @ApiProperty({ example: 'Amoladora angular 4½"' })
  @IsString()
  @Length(2, 120)
  @Transform(trim)
  name: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @Length(0, 2000)
  @Transform(trim)
  description?: string;

  @ApiPropertyOptional({ enum: AssetStatus, default: AssetStatus.OPERATIVO })
  @IsOptional()
  @IsEnum(AssetStatus)
  status?: AssetStatus;

  @ApiProperty({ minimum: 1, example: 4 })
  @IsInt()
  @Min(1)
  initialQuantity: number;

  @ApiProperty()
  @IsUUID()
  initialSiteId: string;
}

export class UpdateAssetDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @Length(2, 120)
  @Transform(trim)
  name?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @Length(0, 2000)
  @Transform(trim)
  description?: string | null;
}

export class ChangeAssetStatusDto {
  @ApiProperty({ enum: AssetStatus })
  @IsEnum(AssetStatus)
  status: AssetStatus;

  @ApiPropertyOptional({ description: 'Obligatorio para dar de baja' })
  @IsOptional()
  @IsString()
  @Length(3, 500)
  @Transform(trim)
  reason?: string;
}

export class CreateAssetNoteDto {
  @ApiProperty({ example: 'Se revisó el cable y está en buen estado.' })
  @IsString()
  @Length(2, 1000)
  @Transform(trim)
  body: string;
}
