#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

LATEST_TAR=$(ls -1t backup_artifacts/sublev-app-backup-*.tar.gz 2>/dev/null | head -n1 || true)
if [ -z "$LATEST_TAR" ] || [ "$LATEST_TAR" = "" ]; then
  echo "Nenhum tarball de backup encontrado em backup_artifacts/"
  exit 1
fi

SHA_VAL=""
if [ -f "$LATEST_TAR.sha256" ]; then
  SHA_VAL=$(awk '{print $1}' "$LATEST_TAR.sha256")
fi

GIT_LOG=""
if [ -f backup_artifacts/git_log_last.txt ]; then
  GIT_LOG=$(sed 's/"/\\"/g' backup_artifacts/git_log_last.txt | tr '\n' ' ')
fi

cat > backup_artifacts/backup_manifest.json <<EOF
{
  "tarfile": "$LATEST_TAR",
  "sha256": "$SHA_VAL",
  "git_last": "$GIT_LOG",
  "sensitive_list_file": "backup_artifacts/secure_list.txt",
  "file_list": "backup_artifacts/backup_list.txt",
  "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

echo "$LATEST_TAR" > backup_artifacts/ULTIMO_BACKUP
echo "Manifest e ULTIMO_BACKUP criados em backup_artifacts/"
