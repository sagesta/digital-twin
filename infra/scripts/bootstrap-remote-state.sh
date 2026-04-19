#!/usr/bin/env bash
# If ./bootstrap-remote-state.sh fails under WSL with bash\r: run from repo root:
#   sed 's/\r$//' ./infra/scripts/bootstrap-remote-state.sh | bash
# Optional Step: create Azure Storage for Terraform remote state and print backend.tf values.
# Usage:
#   export TF_STATE_RG="terraform-state-rg"
#   export TF_STATE_STORAGE_ACCOUNT="tfstateYOURUNIQUE12"   # 3-24 chars, lowercase letters+numbers only, globally unique
#   export TF_STATE_LOCATION="eastus"                      # optional (use a Students-allowed region slug)
#   ./scripts/bootstrap-remote-state.sh
#
# Then configure terraform init -backend-config=... (see infra/README.md) and GitHub TF_BACKEND_* secrets.
set -euo pipefail

TF_STATE_RG="${TF_STATE_RG:-terraform-state-rg}"
TF_STATE_STORAGE_ACCOUNT="${TF_STATE_STORAGE_ACCOUNT:-}"
TF_STATE_LOCATION="${TF_STATE_LOCATION:-eastus}"
CONTAINER="${TF_STATE_CONTAINER:-tfstate}"
STATE_KEY="${TF_STATE_KEY:-digital-twin.terraform.tfstate}"

if [ -z "$TF_STATE_STORAGE_ACCOUNT" ]; then
  echo "Set TF_STATE_STORAGE_ACCOUNT to a globally unique name (lowercase alphanumeric, max 24 chars), e.g.:"
  echo "  export TF_STATE_STORAGE_ACCOUNT=tfstate\$(openssl rand -hex 4)"
  exit 1
fi

if ! command -v az >/dev/null 2>&1; then
  echo "Azure CLI not found."
  exit 1
fi

az group create --name "$TF_STATE_RG" --location "$TF_STATE_LOCATION" --output none
az storage account create \
  --resource-group "$TF_STATE_RG" \
  --name "$TF_STATE_STORAGE_ACCOUNT" \
  --location "$TF_STATE_LOCATION" \
  --sku Standard_LRS \
  --encryption-services blob \
  --output none

KEY="$(az storage account keys list --resource-group "$TF_STATE_RG" --account-name "$TF_STATE_STORAGE_ACCOUNT" --query '[0].value' -o tsv)"
az storage container create \
  --name "$CONTAINER" \
  --account-name "$TF_STATE_STORAGE_ACCOUNT" \
  --account-key "$KEY" \
  --output none

echo ""
echo "=== GitHub Actions secrets (TF_BACKEND_*) and local terraform init: ==="
echo "TF_BACKEND_RG                 = $TF_STATE_RG"
echo "TF_BACKEND_STORAGE_ACCOUNT    = $TF_STATE_STORAGE_ACCOUNT"
echo "TF_BACKEND_ACCESS_KEY         = <use output of: az storage account keys list -g $TF_STATE_RG -n $TF_STATE_STORAGE_ACCOUNT>"
echo ""
echo "resource_group_name  = \"$TF_STATE_RG\""
echo "storage_account_name = \"$TF_STATE_STORAGE_ACCOUNT\""
echo "container_name       = \"$CONTAINER\""
echo "key                  = \"$STATE_KEY\""
echo ""
echo "From infra/:"
echo "  terraform init -input=false -reconfigure \\"
echo "    -backend-config=\"resource_group_name=$TF_STATE_RG\" \\"
echo "    -backend-config=\"storage_account_name=$TF_STATE_STORAGE_ACCOUNT\" \\"
echo "    -backend-config=\"container_name=$CONTAINER\" \\"
echo "    -backend-config=\"key=$STATE_KEY\" \\"
echo "    -backend-config=\"access_key=<STORAGE_KEY>\""
echo ""
