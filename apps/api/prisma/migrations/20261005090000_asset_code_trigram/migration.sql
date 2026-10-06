-- Accelerate the normalized substring search used for asset codes.
CREATE INDEX assets_code_trgm
  ON assets USING gin (lower(code) gin_trgm_ops);
