#!/usr/bin/env bash
# Uso: ./scripts/publish.sh <version> <version_code> "<release_notes>"
# Exemplo: ./scripts/publish.sh 1.2.0 12 "Correções de bug e melhorias"
#
# Pré-requisitos:
#   - supabase CLI autenticado (supabase login)
#   - SUPABASE_PROJECT_REF e SUPABASE_DB_URL no ambiente, OU configure abaixo
#   - flutter no PATH

set -euo pipefail

VERSION="${1:?Informe a versão, ex: 1.2.0}"
VERSION_CODE="${2:?Informe o version_code numérico, ex: 12}"
RELEASE_NOTES="${3:-}"

BUCKET="apk"
APK_NAME="wishnesita-latest.apk"
APK_PATH="build/app/outputs/flutter-apk/app-release.apk"

echo "==> Build APK release (versão $VERSION / code $VERSION_CODE)..."
flutter build apk --release --build-name="$VERSION" --build-number="$VERSION_CODE"

echo "==> Upload para Supabase Storage (bucket: $BUCKET)..."
supabase storage cp "$APK_PATH" "ss://$BUCKET/$APK_NAME" --project-ref "${SUPABASE_PROJECT_REF:?Defina SUPABASE_PROJECT_REF}"

# URL pública é determinística — construída direto do project ref (não existe subcomando "url" no CLI)
DOWNLOAD_URL="https://${SUPABASE_PROJECT_REF}.supabase.co/storage/v1/object/public/${BUCKET}/${APK_NAME}"

# Escapa aspas simples para não quebrar o SQL
RELEASE_NOTES_SAFE="${RELEASE_NOTES//\'/\'\'}"

echo "==> Atualizando tabela app_versions..."
psql "${SUPABASE_DB_URL:?Defina SUPABASE_DB_URL}" <<SQL
BEGIN;
DELETE FROM app_versions;
INSERT INTO app_versions (version, version_code, download_url, release_notes)
VALUES ('$VERSION', $VERSION_CODE, '$DOWNLOAD_URL', '$RELEASE_NOTES_SAFE');
COMMIT;
SQL

echo ""
echo "Publicado com sucesso!"
echo "  Versão:       $VERSION ($VERSION_CODE)"
echo "  Download URL: $DOWNLOAD_URL"
