#!/usr/bin/env bash
# Run from anywhere: completes Step 1 of the post-secrets plan (local terraform apply).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if ! command -v terraform >/dev/null 2>&1; then
  echo "terraform not found. Install Terraform >= 1.5, then re-run this script."
  exit 1
fi

if [ ! -f terraform.tfvars ]; then
  echo "Missing terraform.tfvars. Copy terraform.tfvars.example and set subscription_id."
  exit 1
fi

terraform init -input=false
terraform apply -input=false -auto-approve

echo ""
echo "=== Copy these for GitHub Secrets (or run scripts/set-github-secrets-from-outputs.sh) ==="
echo "AZURE_STORAGE_ACCOUNT_NAME=$(terraform output -raw storage_account_name)"
echo "AZURE_FUNCTION_APP_NAME=$(terraform output -raw function_app_name)"
