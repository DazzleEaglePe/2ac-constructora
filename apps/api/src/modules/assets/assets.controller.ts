import {
  BadRequestException,
  Body,
  Controller,
  Get,
  Header,
  Headers,
  HttpCode,
  HttpStatus,
  Ip,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Query,
  UploadedFile,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiBearerAuth, ApiBody, ApiConsumes, ApiProduces, ApiTags } from '@nestjs/swagger';
import { Role } from '@prisma/client';
import type { AuthUser } from '../auth/auth.types';
import { CurrentUser, Roles } from '../auth/decorators/auth.decorators';
import {
  ChangeAssetStatusDto,
  CreateAssetDto,
  CreateAssetNoteDto,
  ListAssetsQuery,
  NextCodeQuery,
  SearchAssetsQuery,
  UpdateAssetDto,
} from './dto/assets.dto';
import { AssetsService } from './assets.service';
import { AssetsImportService, type UploadedAssetFile } from './assets-import.service';

@ApiTags('assets')
@ApiBearerAuth()
@Controller('assets')
export class AssetsController {
  constructor(
    private readonly assets: AssetsService,
    private readonly assetImport: AssetsImportService,
  ) {}

  @Get()
  list(@Query() query: ListAssetsQuery) {
    return this.assets.list(query);
  }

  @Get('search')
  search(@Query() query: SearchAssetsQuery) {
    return this.assets.search(query);
  }

  @Get('import/template')
  @Roles(Role.ADMIN)
  @Header('Content-Type', 'text/csv; charset=utf-8')
  @Header('Content-Disposition', 'attachment; filename="plantilla-activos.csv"')
  @ApiProduces('text/csv')
  importTemplate() {
    return this.assetImport.template();
  }

  @Post('import')
  @Roles(Role.ADMIN)
  @UseInterceptors(FileInterceptor('file', { limits: { fileSize: 5 * 1024 * 1024 } }))
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      required: ['file'],
      properties: { file: { type: 'string', format: 'binary' } },
    },
  })
  importAssets(
    @UploadedFile() file: UploadedAssetFile | undefined,
    @Headers('idempotency-key') idempotencyKey: string | undefined,
    @CurrentUser() actor: AuthUser,
    @Ip() ip: string,
  ) {
    if (!file) throw new BadRequestException('Adjunta un archivo CSV o XLSX');
    if (!idempotencyKey || idempotencyKey.length > 64) {
      throw new BadRequestException('Idempotency-Key requerido (máximo 64 caracteres)');
    }
    return this.assetImport.import(file, idempotencyKey, actor, ip);
  }

  @Get('next-code')
  @Roles(Role.ADMIN)
  nextCode(@Query() query: NextCodeQuery) {
    return this.assets.nextCode(query.type);
  }

  @Post()
  @Roles(Role.ADMIN)
  create(
    @Body() dto: CreateAssetDto,
    @Headers('idempotency-key') idempotencyKey: string | undefined,
    @CurrentUser() actor: AuthUser,
    @Ip() ip: string,
  ) {
    if (!idempotencyKey || idempotencyKey.length > 64) {
      throw new BadRequestException('Idempotency-Key requerido (máximo 64 caracteres)');
    }
    return this.assets.create(dto, idempotencyKey, actor, ip);
  }

  @Get(':id')
  get(@Param('id', ParseUUIDPipe) id: string) {
    return this.assets.get(id);
  }

  @Patch(':id')
  @Roles(Role.ADMIN)
  update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateAssetDto,
    @CurrentUser() actor: AuthUser,
    @Ip() ip: string,
  ) {
    return this.assets.update(id, dto, actor, ip);
  }

  @Post(':id/status')
  @Roles(Role.ADMIN)
  @HttpCode(HttpStatus.OK)
  changeStatus(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: ChangeAssetStatusDto,
    @CurrentUser() actor: AuthUser,
    @Ip() ip: string,
  ) {
    return this.assets.changeStatus(id, dto, actor, ip);
  }

  @Get(':id/notes')
  notes(@Param('id', ParseUUIDPipe) id: string) {
    return this.assets.notes(id);
  }

  @Post(':id/notes')
  @HttpCode(HttpStatus.CREATED)
  addNote(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: CreateAssetNoteDto,
    @CurrentUser() actor: AuthUser,
    @Ip() ip: string,
  ) {
    return this.assets.addNote(id, dto, actor, ip);
  }
}
