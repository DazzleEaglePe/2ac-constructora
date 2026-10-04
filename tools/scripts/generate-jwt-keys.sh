#!/usr/bin/env bash
# Genera un par RSA para firmar los JWT (RS256) y lo imprime como variables de entorno.
# Uso: ./tools/scripts/generate-jwt-keys.sh >> apps/api/.env
set -euo pipefail
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out "$tmp/private.pem" 2>/dev/null
openssl rsa -in "$tmp/private.pem" -pubout -out "$tmp/public.pem" 2>/dev/null
printf 'JWT_PRIVATE_KEY="%s"\n' "$(awk 'BEGIN{ORS="\\n"} {print}' "$tmp/private.pem")"
printf 'JWT_PUBLIC_KEY="%s"\n' "$(awk 'BEGIN{ORS="\\n"} {print}' "$tmp/public.pem")"
