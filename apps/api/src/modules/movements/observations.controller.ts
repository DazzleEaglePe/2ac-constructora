import { Body, Controller, Get, HttpCode, HttpStatus, Ip, Param, ParseUUIDPipe, Post, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { Role } from '@prisma/client';
import type { AuthUser } from '../auth/auth.types';
import { CurrentUser, Roles } from '../auth/decorators/auth.decorators';
import { ListObservationsQuery, ResolveObservationDto } from './dto/movements.dto';
import { ObservationsService } from './observations.service';

@ApiTags('observations')
@ApiBearerAuth()
@Controller('observations')
export class ObservationsController {
  constructor(private readonly observations: ObservationsService) {}

  @Get()
  list(@Query() query: ListObservationsQuery) {
    return this.observations.list(query);
  }

  @Post(':id/resolve')
  @Roles(Role.ADMIN)
  @HttpCode(HttpStatus.OK)
  resolve(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: ResolveObservationDto,
    @CurrentUser() actor: AuthUser,
    @Ip() ip: string,
  ) {
    return this.observations.resolve(id, dto, actor, ip);
  }
}
