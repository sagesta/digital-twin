#!/usr/bin/env bash
# Step 2: push AZURE_STORAGE_ACCOUNT_NAME and AZURE_FUNCTION_APP_NAME from terraform state into GitHub.
# Requires: gh CLI (https://cli.github.com/), gh auth login, and terraform output available (after apply).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if ! command -v gh >/dev/null 2>&1; then
  echo "Install GitHub CLI: https://cli.github.com/ then: gh auth login"
  exit 1
fi
if ! command -v terraform >/dev/null 2>&1; then
  echo "terraform not found."
  exit 1
fi

STORAGE="$(terraform output -raw storage_account_name)"
FUNCAPP="$(terraform output -raw function_app_name)"

echo "Setting GitHub Actions secrets in repo detected by gh (cwd git remote)..."
gh secret set AZURE_STORAGE_ACCOUNT_NAME --body "$STORAGE"
gh secret set AZURE_FUNCTION_APP_NAME --body "$FUNCAPP"

echo "Done. Verify: gh secret list"
