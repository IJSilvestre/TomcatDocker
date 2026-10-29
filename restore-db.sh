#!/bin/sh
# Restaura um dump do pg_dump (formato custom) no Postgres do docker compose.
# Uso: ./restore-db.sh [arquivo.backup]   (padrao: solocria.backup)
set -e
cd "$(dirname "$0")"

BACKUP_FILE="${1:-solocria.backup}"
[ -f .env ] && . ./.env
DB="${POSTGRES_DB:-solocria}"
USER="${POSTGRES_USER:-appuser}"

if [ ! -f "$BACKUP_FILE" ]; then
  echo "Arquivo nao encontrado: $BACKUP_FILE" >&2; exit 1
fi

echo ">> Garantindo que o Postgres esta de pe..."
docker compose up -d postgres
until docker compose exec -T postgres pg_isready -U "$USER" -d postgres >/dev/null 2>&1; do sleep 2; done

echo ">> Criando banco '$DB' se nao existir..."
docker compose exec -T postgres psql -U "$USER" -d postgres -tc \
  "SELECT 1 FROM pg_database WHERE datname='$DB'" | grep -q 1 || \
  docker compose exec -T postgres createdb -U "$USER" "$DB"

echo ">> Copiando $BACKUP_FILE para o container..."
docker compose cp "$BACKUP_FILE" postgres:/tmp/restore.backup

echo ">> Restaurando em '$DB' (objetos existentes sao recriados)..."
# --no-owner/--no-privileges: ignora o owner/grants do servidor original e usa o usuario atual.
# --clean --if-exists: apaga e recria os objetos, permitindo rodar o script mais de uma vez.
# Avisos de "already exists"/"does not exist" sao normais e nao abortam a restauracao.
docker compose exec -T postgres pg_restore -U "$USER" -d "$DB" \
  --no-owner --no-privileges --clean --if-exists --verbose /tmp/restore.backup 2>&1 \
  | grep -vE "^pg_restore: (processing|creating|executing|dropping|finished|connecting)" || true

docker compose exec -T postgres rm -f /tmp/restore.backup

echo ">> Tabelas restauradas por schema:"
docker compose exec -T postgres psql -U "$USER" -d "$DB" -c \
  "SELECT schemaname, count(*) AS tabelas FROM pg_tables WHERE schemaname NOT IN ('pg_catalog','information_schema') GROUP BY 1 ORDER BY 1;"
echo ">> Concluido."
