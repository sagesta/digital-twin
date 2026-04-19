# Remote state is required for GitHub Actions: runners discard the workspace after each job,
# so without a backend every apply starts with an empty state and hits "already exists" errors.
#
# 1) Create storage (once): from repo root, see scripts/bootstrap-remote-state.sh
# 2) terraform init -reconfigure -backend-config=...   (see infra/README.md)
# 3) Add the same values as GitHub Actions secrets: TF_BACKEND_RG, TF_BACKEND_STORAGE_ACCOUNT, TF_BACKEND_ACCESS_KEY

terraform {
  backend "azurerm" {}
}
