# Backup & Restore (impressão)

Instruções e avisos para backup e restauração incremental do código relacionado a impressão.

Avisos importantes
- `git clean -fdx` remove tudo que NÃO está versionado (builds, `.env`, APKs, caches). Revise duas vezes antes de rodar.
- Sempre verifique `backup_artifacts/ULTIMO_BACKUP` e `backup_artifacts/backup_manifest.json` antes de qualquer `clean` ou `reset`.
- Arquivos sensíveis que não podem sumir: `.env.*`, `android/local.properties`, keystores (`*.jks`, `*.keystore`), `cookies.txt`, `GoogleService-Info.plist`, `google-services.json`. Estes são copiados para `backup_artifacts/secure/` se existirem.

Scripts
- `scripts/backup_print.sh`: cria o tar.gz do workspace (exclui `.git` e `build`), salva SHA256 e chama `generate_manifest.sh`.
- `scripts/generate_manifest.sh`: gera `backup_artifacts/backup_manifest.json` e `backup_artifacts/ULTIMO_BACKUP` apontando para o tar mais recente.
- `scripts/restore_incremental.sh <path>`: restaura um arquivo do tar mais recente e executa `flutter analyze` e `flutter test`.

Fluxo sugerido antes de qualquer limpeza ou reset
1. Rode `./scripts/backup_print.sh` e confirme `backup_artifacts/backup_manifest.json` e `backup_artifacts/ULTIMO_BACKUP`.
2. Verifique `backup_artifacts/secure_list.txt` e confirme cópia dos sensíveis.
3. (Opcional) Copie `backup_artifacts/*.tar.gz` para armazenamento externo seguro.
4. Revise e só então execute `git clean -fdx`.

Restauração incremental recomendada
1. `git fetch origin && git checkout origin/main --detach` ou reset conforme política.
2. Para restaurar um arquivo: `./scripts/restore_incremental.sh lib/services/niimbot_print_bluetooth_thermal_service.dart`
3. Após cada restauração, rode `flutter analyze` e `flutter test` antes de restaurar o próximo arquivo.

Validação de fluxos de impressão
- Teste separadamente: Fracionar, Lista, Avulsa.
- Para cada fluxo: conectar impressora, imprimir 1 etiqueta, conferir densidade/cor.
- Anote parâmetros ajustados (densidade, gamma, passes) e mantenha em `backup_artifacts/notes.txt`.

Registro final
- Após validar que o app está no estado desejado, salve `git rev-parse HEAD` em `backup_artifacts/working_commit.txt`.
