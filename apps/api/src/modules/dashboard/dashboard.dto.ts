import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsDateString, IsOptional } from 'class-validator';

export class DashboardQuery {
  @ApiPropertyOptional({ description: 'Fecha desde la última sincronización' })
  @IsOptional()
  @IsDateString()
  since?: string;
}
