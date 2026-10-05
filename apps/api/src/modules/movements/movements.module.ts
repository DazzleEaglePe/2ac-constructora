import { Module } from '@nestjs/common';
import { MovementsController } from './movements.controller';
import { MovementsService } from './movements.service';
import { AuditModule } from '../audit/audit.module';
import { ObservationsController } from './observations.controller';
import { ObservationsService } from './observations.service';

@Module({
  imports: [AuditModule],
  controllers: [MovementsController, ObservationsController],
  providers: [MovementsService, ObservationsService],
})
export class MovementsModule {}
