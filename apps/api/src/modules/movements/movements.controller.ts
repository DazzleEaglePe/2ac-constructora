import { BadRequestException, Body, Controller, Get, Headers, Param, ParseUUIDPipe, Post, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import type { AuthUser } from '../auth/auth.types';
import { CurrentUser } from '../auth/decorators/auth.decorators';
import { CreateMovementDto, ListMovementsQuery } from './dto/movements.dto';
import { MovementsService } from './movements.service';

@ApiTags('movements')
@ApiBearerAuth()
@Controller('movements')
export class MovementsController {
  constructor(private readonly movements: MovementsService) {}

  @Get()
  list(@Query() query: ListMovementsQuery) {
    return this.movements.list(query);
  }

  @Post()
  create(
    @Body() dto: CreateMovementDto,
    @Headers('idempotency-key') idempotencyKey: string | undefined,
    @CurrentUser() actor: AuthUser,
  ) {
    if (!idempotencyKey || idempotencyKey.length > 64) {
      throw new BadRequestException('Idempotency-Key requerido (máximo 64 caracteres)');
    }
    return this.movements.create(dto, idempotencyKey, actor);
  }

  @Get(':id')
  get(@Param('id', ParseUUIDPipe) id: string) {
    return this.movements.get(id);
  }
}
