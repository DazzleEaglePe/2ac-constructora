import { Module } from '@nestjs/common';
import { InventoryIntegrityService } from './inventory-integrity.service';

@Module({ providers: [InventoryIntegrityService], exports: [InventoryIntegrityService] })
export class IntegrityModule {}
