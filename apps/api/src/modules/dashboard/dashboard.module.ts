import { Module } from '@nestjs/common';
import { SitesModule } from '../sites/sites.module';
import { DashboardController } from './dashboard.controller';
import { DashboardService } from './dashboard.service';

@Module({ imports: [SitesModule], controllers: [DashboardController], providers: [DashboardService] })
export class DashboardModule {}
