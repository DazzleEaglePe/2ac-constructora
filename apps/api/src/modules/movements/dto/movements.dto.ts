import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { ObservationStatus, ObservationType } from '@prisma/client';
import { Transform, Type } from 'class-transformer';
import { IsDateString, IsEnum, IsInt, IsOptional, IsString, IsUUID, Length, Min, ValidateNested } from 'class-validator';

const trim = ({ value }: { value: unknown }) =>
  typeof value === 'string' ? value.trim().replace(/\s+/g, ' ') : value;

export class CreateMovementObservationDto {
  @ApiProperty({ enum: ObservationType })
  @IsEnum(ObservationType)
  type: ObservationType;

  @ApiProperty({ minLength: 3, maxLength: 500 })
  @IsString()
  @Length(3, 500)
  @Transform(trim)
  description: string;
}

export class CreateMovementDto {
  @ApiProperty()
  @IsUUID()
  assetId: string;

  @ApiProperty()
  @IsUUID()
  fromSiteId: string;

  @ApiProperty()
  @IsUUID()
  toSiteId: string;

  @ApiProperty({ minimum: 1 })
  @IsInt()
  @Min(1)
  quantity: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @Length(0, 500)
  @Transform(trim)
  note?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsDateString()
  clientCreatedAt?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @ValidateNested()
  @Type(() => CreateMovementObservationDto)
  observation?: CreateMovementObservationDto;
}

export class ListMovementsQuery {
  @ApiPropertyOptional()
  @IsOptional()
  @IsUUID()
  assetId?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsUUID()
  siteId?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsUUID()
  userId?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsDateString()
  from?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsDateString()
  to?: string;
}

export class ListObservationsQuery {
  @ApiPropertyOptional({ enum: ObservationStatus })
  @IsOptional()
  @IsEnum(ObservationStatus)
  status?: ObservationStatus;

  @ApiPropertyOptional()
  @IsOptional()
  @IsUUID()
  assetId?: string;
}

export class ResolveObservationDto {
  @ApiProperty({ minLength: 3, maxLength: 500 })
  @IsString()
  @Length(3, 500)
  @Transform(trim)
  resolution: string;
}
