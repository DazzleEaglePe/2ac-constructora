import { Global, Module } from '@nestjs/common';
import { AuditService } from './audit.service';
import { AuditLogsController } from './audit-logs.controller';
import { AuditLogsService } from './audit-logs.service';

@Global()
@Module({
  providers: [AuditService, AuditLogsService],
  controllers: [AuditLogsController],
  exports: [AuditService],
})
export class AuditModule {}
