import { Module } from '@nestjs/common';
import { AuditModule } from '../audit/audit.module';
import { AssetsController } from './assets.controller';
import { AssetsService } from './assets.service';
import { AssetsImportService } from './assets-import.service';

@Module({
  imports: [AuditModule],
  controllers: [AssetsController],
  providers: [AssetsService, AssetsImportService],
})
export class AssetsModule {}
