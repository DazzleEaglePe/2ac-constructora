-- CreateEnum
CREATE TYPE "Role" AS ENUM ('ADMIN', 'OPERADOR');

-- CreateEnum
CREATE TYPE "SiteType" AS ENUM ('ALMACEN', 'OBRA');

-- CreateEnum
CREATE TYPE "SiteStatus" AS ENUM ('ACTIVA', 'CERRADA');

-- CreateEnum
CREATE TYPE "AssetType" AS ENUM ('MAQUINA', 'HERRAMIENTA');

-- CreateEnum
CREATE TYPE "AssetStatus" AS ENUM ('OPERATIVO', 'MANTENIMIENTO', 'BAJA');

-- CreateEnum
CREATE TYPE "ObservationType" AS ENUM ('DANADO', 'INCOMPLETO', 'FALTANTE', 'OTRO');

-- CreateEnum
CREATE TYPE "ObservationStatus" AS ENUM ('ABIERTA', 'ATENDIDA');

-- CreateEnum
CREATE TYPE "MovementKind" AS ENUM ('ALTA', 'TRASLADO', 'BAJA', 'AJUSTE', 'REVERSION');

-- CreateTable
CREATE TABLE "users" (
    "id" UUID NOT NULL,
    "dni" VARCHAR(8) NOT NULL,
    "full_name" VARCHAR(120) NOT NULL,
    "password_hash" TEXT NOT NULL,
    "role" "Role" NOT NULL DEFAULT 'OPERADOR',
    "active" BOOLEAN NOT NULL DEFAULT true,
    "must_change_password" BOOLEAN NOT NULL DEFAULT true,
    "failed_attempts" INTEGER NOT NULL DEFAULT 0,
    "locked_until" TIMESTAMPTZ,
    "last_login_at" TIMESTAMPTZ,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "refresh_tokens" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "token_hash" TEXT NOT NULL,
    "family_id" UUID NOT NULL,
    "device_name" TEXT,
    "expires_at" TIMESTAMPTZ NOT NULL,
    "revoked_at" TIMESTAMPTZ,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "refresh_tokens_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "sites" (
    "id" UUID NOT NULL,
    "type" "SiteType" NOT NULL,
    "name" VARCHAR(120) NOT NULL,
    "owner_name" VARCHAR(120),
    "address" VARCHAR(200),
    "lat" DECIMAL(9,6),
    "lng" DECIMAL(9,6),
    "status" "SiteStatus" NOT NULL DEFAULT 'ACTIVA',
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "sites_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "assets" (
    "id" UUID NOT NULL,
    "code" VARCHAR(12) NOT NULL,
    "type" "AssetType" NOT NULL,
    "name" VARCHAR(120) NOT NULL,
    "description" TEXT,
    "status" "AssetStatus" NOT NULL DEFAULT 'OPERATIVO',
    "total_stock" INTEGER NOT NULL,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "assets_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "stock" (
    "asset_id" UUID NOT NULL,
    "site_id" UUID NOT NULL,
    "quantity" INTEGER NOT NULL,
    "updated_at" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "stock_pkey" PRIMARY KEY ("asset_id","site_id")
);

-- CreateTable
CREATE TABLE "movements" (
    "id" UUID NOT NULL,
    "kind" "MovementKind" NOT NULL,
    "asset_id" UUID NOT NULL,
    "from_site_id" UUID,
    "to_site_id" UUID,
    "quantity" INTEGER NOT NULL,
    "user_id" UUID NOT NULL,
    "note" VARCHAR(500),
    "reverts_id" UUID,
    "idempotency_key" VARCHAR(64) NOT NULL,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "movements_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "asset_notes" (
    "id" UUID NOT NULL,
    "asset_id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "body" VARCHAR(1000) NOT NULL,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "asset_notes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "movement_observations" (
    "id" UUID NOT NULL,
    "movement_id" UUID NOT NULL,
    "asset_id" UUID NOT NULL,
    "type" "ObservationType" NOT NULL,
    "description" VARCHAR(500) NOT NULL,
    "status" "ObservationStatus" NOT NULL DEFAULT 'ABIERTA',
    "resolved_by_id" UUID,
    "resolved_at" TIMESTAMPTZ,
    "resolution" VARCHAR(500),
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "movement_observations_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "code_sequences" (
    "prefix" VARCHAR(4) NOT NULL,
    "last_value" INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT "code_sequences_pkey" PRIMARY KEY ("prefix")
);

-- CreateTable
CREATE TABLE "audit_logs" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "action" VARCHAR(60) NOT NULL,
    "entity_type" VARCHAR(30) NOT NULL,
    "entity_id" UUID NOT NULL,
    "before" JSONB,
    "after" JSONB,
    "ip" VARCHAR(45),
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "audit_logs_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "users_dni_key" ON "users"("dni");

-- CreateIndex
CREATE UNIQUE INDEX "refresh_tokens_token_hash_key" ON "refresh_tokens"("token_hash");

-- CreateIndex
CREATE INDEX "refresh_tokens_user_id_idx" ON "refresh_tokens"("user_id");

-- CreateIndex
CREATE INDEX "sites_type_status_idx" ON "sites"("type", "status");

-- CreateIndex
CREATE UNIQUE INDEX "assets_code_key" ON "assets"("code");

-- CreateIndex
CREATE INDEX "assets_type_status_idx" ON "assets"("type", "status");

-- CreateIndex
CREATE INDEX "assets_name_idx" ON "assets"("name");

-- CreateIndex
CREATE INDEX "stock_site_id_idx" ON "stock"("site_id");

-- CreateIndex
CREATE UNIQUE INDEX "movements_reverts_id_key" ON "movements"("reverts_id");

-- CreateIndex
CREATE INDEX "movements_asset_id_created_at_idx" ON "movements"("asset_id", "created_at" DESC);

-- CreateIndex
CREATE INDEX "movements_from_site_id_created_at_idx" ON "movements"("from_site_id", "created_at" DESC);

-- CreateIndex
CREATE INDEX "movements_to_site_id_created_at_idx" ON "movements"("to_site_id", "created_at" DESC);

-- CreateIndex
CREATE UNIQUE INDEX "movements_user_id_idempotency_key_key" ON "movements"("user_id", "idempotency_key");

-- CreateIndex
CREATE INDEX "asset_notes_asset_id_created_at_idx" ON "asset_notes"("asset_id", "created_at" DESC);

-- CreateIndex
CREATE UNIQUE INDEX "movement_observations_movement_id_key" ON "movement_observations"("movement_id");

-- CreateIndex
CREATE INDEX "movement_observations_status_created_at_idx" ON "movement_observations"("status", "created_at" DESC);

-- CreateIndex
CREATE INDEX "movement_observations_asset_id_idx" ON "movement_observations"("asset_id");

-- CreateIndex
CREATE INDEX "audit_logs_entity_type_entity_id_idx" ON "audit_logs"("entity_type", "entity_id");

-- CreateIndex
CREATE INDEX "audit_logs_user_id_created_at_idx" ON "audit_logs"("user_id", "created_at" DESC);

-- AddForeignKey
ALTER TABLE "refresh_tokens" ADD CONSTRAINT "refresh_tokens_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "stock" ADD CONSTRAINT "stock_asset_id_fkey" FOREIGN KEY ("asset_id") REFERENCES "assets"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "stock" ADD CONSTRAINT "stock_site_id_fkey" FOREIGN KEY ("site_id") REFERENCES "sites"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "movements" ADD CONSTRAINT "movements_asset_id_fkey" FOREIGN KEY ("asset_id") REFERENCES "assets"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "movements" ADD CONSTRAINT "movements_from_site_id_fkey" FOREIGN KEY ("from_site_id") REFERENCES "sites"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "movements" ADD CONSTRAINT "movements_to_site_id_fkey" FOREIGN KEY ("to_site_id") REFERENCES "sites"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "movements" ADD CONSTRAINT "movements_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "movements" ADD CONSTRAINT "movements_reverts_id_fkey" FOREIGN KEY ("reverts_id") REFERENCES "movements"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "asset_notes" ADD CONSTRAINT "asset_notes_asset_id_fkey" FOREIGN KEY ("asset_id") REFERENCES "assets"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "asset_notes" ADD CONSTRAINT "asset_notes_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "movement_observations" ADD CONSTRAINT "movement_observations_movement_id_fkey" FOREIGN KEY ("movement_id") REFERENCES "movements"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "movement_observations" ADD CONSTRAINT "movement_observations_asset_id_fkey" FOREIGN KEY ("asset_id") REFERENCES "assets"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "movement_observations" ADD CONSTRAINT "movement_observations_resolved_by_id_fkey" FOREIGN KEY ("resolved_by_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "audit_logs" ADD CONSTRAINT "audit_logs_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- ============================================================
-- Restricciones de dominio (docs/05_MODELO_DATOS.md §4)
-- ============================================================
-- Stock nunca negativo
ALTER TABLE stock ADD CONSTRAINT stock_quantity_non_negative CHECK (quantity >= 0);

-- Movimientos con cantidad positiva
ALTER TABLE movements ADD CONSTRAINT movements_quantity_positive CHECK (quantity > 0);

-- RN-03: origen distinto de destino
ALTER TABLE movements ADD CONSTRAINT movements_from_to_distinct
  CHECK (from_site_id IS NULL OR to_site_id IS NULL OR from_site_id <> to_site_id);

-- Forma de cada tipo de movimiento
ALTER TABLE movements ADD CONSTRAINT movements_kind_shape CHECK (
  (kind = 'ALTA'      AND from_site_id IS NULL     AND to_site_id IS NOT NULL) OR
  (kind = 'BAJA'      AND from_site_id IS NOT NULL AND to_site_id IS NULL)     OR
  (kind IN ('TRASLADO','REVERSION') AND from_site_id IS NOT NULL AND to_site_id IS NOT NULL) OR
  (kind = 'AJUSTE')
);

-- RN-01: una máquina tiene stock total 1 (o 0 si está dada de baja)
ALTER TABLE assets ADD CONSTRAINT assets_machine_unit CHECK (
  type <> 'MAQUINA' OR total_stock IN (0, 1)
);

-- DNI peruano de 8 dígitos (RN-11)
ALTER TABLE users ADD CONSTRAINT users_dni_format CHECK (dni ~ '^[0-9]{8}$');

-- Movimientos inmutables: bloquear UPDATE y DELETE
CREATE OR REPLACE FUNCTION forbid_movement_changes() RETURNS trigger AS $$
BEGIN
  RAISE EXCEPTION 'movements es inmutable';
END; $$ LANGUAGE plpgsql;

CREATE TRIGGER movements_immutable
  BEFORE UPDATE OR DELETE ON movements
  FOR EACH ROW EXECUTE FUNCTION forbid_movement_changes();

-- Búsqueda por nombre (insensible a mayúsculas y acentos)
CREATE EXTENSION IF NOT EXISTS unaccent;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
-- unaccent() no es IMMUTABLE; este envoltorio permite usarlo en un índice.
CREATE OR REPLACE FUNCTION immutable_unaccent(text) RETURNS text
  LANGUAGE sql IMMUTABLE PARALLEL SAFE STRICT
  AS $$ SELECT public.unaccent('public.unaccent', $1) $$;
CREATE INDEX assets_name_trgm ON assets USING gin (lower(immutable_unaccent(name)) gin_trgm_ops);
