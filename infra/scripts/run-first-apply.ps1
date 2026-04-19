# PowerShell: Step 1 — terraform apply from infra\ (requires terraform on PATH and terraform.tfvars).
$ErrorActionPreference = "Stop"
$InfraDir = Split-Path $PSScriptRoot -Parent
Set-Location $InfraDir

if (-not (Get-Command terraform -ErrorAction SilentlyContinue)) {
    Write-Error "terraform not found. Install Terraform >= 1.5 and re-run."
}
if (-not (Test-Path "terraform.tfvars")) {
    Write-Error "Missing terraform.tfvars. Copy terraform.tfvars.example and set subscription_id."
}

terraform init -input=false
terraform apply -input=false -auto-approve

Write-Host ""
Write-Host "=== GitHub secret values (or run set-github-secrets-from-outputs.sh under WSL/Git Bash) ===" 
Write-Host ("AZURE_STORAGE_ACCOUNT_NAME=" + (terraform output -raw storage_account_name))
Write-Host ("AZURE_FUNCTION_APP_NAME=" + (terraform output -raw function_app_name))
