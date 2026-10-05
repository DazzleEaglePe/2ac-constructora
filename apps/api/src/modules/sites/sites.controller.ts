import { Body, Controller, Get, HttpCode, HttpStatus, Ip, Param, ParseUUIDPipe, Patch, Post, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { Role } from '@prisma/client';
import type { AuthUser } from '../auth/auth.types';
import { CurrentUser, Roles } from '../auth/decorators/auth.decorators';
import { CreateSiteDto, ListSitesQuery, SiteStockQuery, UpdateSiteDto } from './dto/sites.dto';
import { SitesService } from './sites.service';

@ApiTags('sites')
@ApiBearerAuth()
@Controller('sites')
export class SitesController {
  constructor(private readonly sites: SitesService) {}

  @Get()
  list(@Query() query: ListSitesQuery) {
    return this.sites.list(query);
  }

  @Post()
  @Roles(Role.ADMIN)
  create(@Body() dto: CreateSiteDto, @CurrentUser() actor: AuthUser, @Ip() ip: string) {
    return this.sites.create(dto, actor, ip);
  }

  @Get(':id/stock')
  stock(@Param('id', ParseUUIDPipe) id: string, @Query() query: SiteStockQuery) {
    return this.sites.stock(id, query);
  }

  @Post(':id/close')
  @Roles(Role.ADMIN)
  @HttpCode(HttpStatus.OK)
  close(@Param('id', ParseUUIDPipe) id: string, @CurrentUser() actor: AuthUser, @Ip() ip: string) {
    return this.sites.close(id, actor, ip);
  }

  @Post(':id/reopen')
  @Roles(Role.ADMIN)
  @HttpCode(HttpStatus.OK)
  reopen(@Param('id', ParseUUIDPipe) id: string, @CurrentUser() actor: AuthUser, @Ip() ip: string) {
    return this.sites.reopen(id, actor, ip);
  }

  @Get(':id')
  get(@Param('id', ParseUUIDPipe) id: string) {
    return this.sites.get(id);
  }

  @Patch(':id')
  @Roles(Role.ADMIN)
  update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateSiteDto,
    @CurrentUser() actor: AuthUser,
    @Ip() ip: string,
  ) {
    return this.sites.update(id, dto, actor, ip);
  }
}
