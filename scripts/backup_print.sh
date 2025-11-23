#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

mkdir -p backup_artifacts
TARFILE=backup_artifacts/sublev-app-backup-$(date +%Y%m%d-%H%M%S).tar.gz
echo "Criando tarball (excluindo .git, build, backup_artifacts): $TARFILE"
tar --exclude='.git' --exclude='build' --exclude='**/build' --exclude='backup_artifacts' -czf "$TARFILE" .
shasum -a 256 "$TARFILE" > "$TARFILE.sha256"
echo "SHA256 salvo em $TARFILE.sha256"

./scripts/generate_manifest.sh
echo "Backup completo e manifest criado. Veja backup_artifacts/" 
