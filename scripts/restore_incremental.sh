#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

if [ ! -f backup_artifacts/ULTIMO_BACKUP ]; then
  echo "Arquivo backup_artifacts/ULTIMO_BACKUP não encontrado. Execute scripts/generate_manifest.sh primeiro." >&2
  exit 1
fi

TARFILE=$(cat backup_artifacts/ULTIMO_BACKUP)
if [ ! -f "$TARFILE" ]; then
  echo "Tarfile $TARFILE não encontrado. Verifique backup_artifacts/" >&2
  exit 1
fi

if [ "$#" -lt 1 ]; then
  echo "Uso: $0 <caminho/do/arquivo/no/repositorio> [--no-analyze]" >&2
  echo "Ex: $0 lib/services/niimbot_print_bluetooth_thermal_service.dart" >&2
  exit 1
fi

TARGET_PATH="$1"
NO_ANALYZE=false
if [ "${2-}" = "--no-analyze" ]; then
  NO_ANALYZE=true
fi

echo "Extraindo $TARGET_PATH de $TARFILE (sobrescrevendo)..."
tar -xzf "$TARFILE" --strip-components=0 -C . "$TARGET_PATH"
echo "Arquivo restaurado: $TARGET_PATH"

if [ "$NO_ANALYZE" = false ]; then
  echo "Rodando flutter analyze..."
  flutter analyze || { echo "flutter analyze falhou"; exit 2; }

  echo "Rodando flutter test... (pule com --no-analyze se preferir)"
  flutter test || echo "Alguns testes falharam - revise antes de prosseguir";
fi

echo "Restauro incremental concluído para $TARGET_PATH"
