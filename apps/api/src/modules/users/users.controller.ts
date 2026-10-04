import { Body, Controller, Get, HttpCode, HttpStatus, Ip, Param, ParseUUIDPipe, Patch, Post, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { Role } from '@prisma/client';
import type { AuthUser } from '../auth/auth.types';
import { CurrentUser, Roles } from '../auth/decorators/auth.decorators';
import { CreateUserDto, ListUsersQuery, UpdateUserDto } from './dto/users.dto';
import { UsersService } from './users.service';

@ApiTags('users')
@ApiBearerAuth()
@Roles(Role.ADMIN)
@Controller('users')
export class UsersController {
  constructor(private readonly users: UsersService) {}

  @Get()
  list(@Query() query: ListUsersQuery) {
    return this.users.list(query);
  }

  @Post()
  create(@Body() dto: CreateUserDto, @CurrentUser() actor: AuthUser, @Ip() ip: string) {
    return this.users.create(dto, actor, ip);
  }

  @Get(':id')
  get(@Param('id', ParseUUIDPipe) id: string) {
    return this.users.get(id);
  }

  @Patch(':id')
  update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateUserDto,
    @CurrentUser() actor: AuthUser,
    @Ip() ip: string,
  ) {
    return this.users.update(id, dto, actor, ip);
  }

  @Post(':id/deactivate')
  @HttpCode(HttpStatus.OK)
  deactivate(@Param('id', ParseUUIDPipe) id: string, @CurrentUser() actor: AuthUser, @Ip() ip: string) {
    return this.users.setActive(id, false, actor, ip);
  }

  @Post(':id/activate')
  @HttpCode(HttpStatus.OK)
  activate(@Param('id', ParseUUIDPipe) id: string, @CurrentUser() actor: AuthUser, @Ip() ip: string) {
    return this.users.setActive(id, true, actor, ip);
  }

  @Post(':id/reset-password')
  @HttpCode(HttpStatus.OK)
  resetPassword(@Param('id', ParseUUIDPipe) id: string, @CurrentUser() actor: AuthUser, @Ip() ip: string) {
    return this.users.resetPassword(id, actor, ip);
  }
}
