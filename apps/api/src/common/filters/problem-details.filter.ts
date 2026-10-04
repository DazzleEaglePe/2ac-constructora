import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import type { Request, Response } from 'express';

/** Error de dominio con código estable (ver docs/06_API_CONTRACT.md §1). */
export class DomainException extends HttpException {
  constructor(
    readonly code: string,
    title: string,
    status: HttpStatus,
    readonly detail?: string,
    readonly extra?: Record<string, unknown>,
  ) {
    super(title, status);
  }
}

interface FieldError {
  field: string;
  message: string;
}

/** Convierte toda excepción en `application/problem+json` (RFC 9457). */
@Catch()
export class ProblemDetailsFilter implements ExceptionFilter {
  private readonly logger = new Logger(ProblemDetailsFilter.name);

  catch(exception: unknown, host: ArgumentsHost): void {
    const ctx = host.switchToHttp();
    const res = ctx.getResponse<Response>();
    const req = ctx.getRequest<Request & { id?: string }>();

    let status = HttpStatus.INTERNAL_SERVER_ERROR;
    let code = 'ERROR_INTERNO';
    let title = 'Ocurrió un error inesperado';
    let detail: string | undefined;
    let errors: FieldError[] = [];
    let extra: Record<string, unknown> = {};

    if (exception instanceof DomainException) {
      status = exception.getStatus();
      code = exception.code;
      title = exception.message;
      detail = exception.detail;
      extra = exception.extra ?? {};
    } else if (exception instanceof HttpException) {
      status = exception.getStatus();
      const body = exception.getResponse();
      const messages =
        typeof body === 'object' && body !== null && 'message' in body ? body.message : undefined;
      if (status === HttpStatus.BAD_REQUEST && Array.isArray(messages)) {
        status = HttpStatus.UNPROCESSABLE_ENTITY;
        code = 'VALIDACION';
        title = 'Los datos enviados no son válidos';
        errors = messages.map((m: string) => ({ field: m.split(' ')[0] ?? '', message: m }));
      } else {
        code = defaultCode(status);
        title = typeof messages === 'string' ? messages : exception.message;
      }
    } else {
      this.logger.error(exception);
    }

    res
      .status(status)
      .type('application/problem+json')
      .json({
        type: `https://a2c-inventario/errors/${code.toLowerCase().replace(/_/g, '-')}`,
        title,
        status,
        code,
        ...(detail ? { detail } : {}),
        requestId: req.id,
        errors,
        ...extra,
      });
  }
}

function defaultCode(status: number): string {
  switch (status) {
    case 401:
      return 'NO_AUTENTICADO';
    case 403:
      return 'SIN_PERMISO';
    case 404:
      return 'NO_ENCONTRADO';
    case 429:
      return 'DEMASIADAS_SOLICITUDES';
    default:
      return status >= 500 ? 'ERROR_INTERNO' : 'SOLICITUD_INVALIDA';
  }
}
