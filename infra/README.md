# Digital Twin — Azure infrastructure (Terraform)

This repo root is **`digital-twin/`** (standalone). Terraform mirrors the Week 2 AWS pattern on Azure: **Blob Storage** (static site + private memory), **Linux Python 3.11 Functions** (consumption), **Azure OpenAI** (`gpt-4o`), and optional **Azure Front Door** (`var.enable_azure_front_door`; keep `false` on Azure for Students).

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) `>= 1.5.0`
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli)
- An Azure subscription with permission to create resource groups, Storage, Front Door, Functions, and Cognitive Services (OpenAI)

## One-time local setup

1. Log in to Azure:

   ```bash
   az login
   az account set --subscription "<SUBSCRIPTION_ID>"
   ```

2. Copy variables and set your subscription:

   ```bash
   cd infra
   cp terraform.tfvars.example terraform.tfvars
   ```

   Edit `terraform.tfvars` and set at least:

   - `subscription_id` — from `az account show --query id -o tsv`

3. **Check Azure OpenAI quota** in your chosen region (default in `variables.tf` is **eastus**; use the same region in the command):

   ```bash
   az cognitiveservices usage list --location eastus -o table
   ```

4. Initialize and apply:

   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

   The **`azurerm_cognitive_deployment`** for `gpt-4o` often takes **10–15 minutes** the first time; the apply may sit in “creating” until Azure finishes provisioning.

5. Read outputs:

   ```bash
   terraform output
   terraform output -raw openai_primary_access_key
   ```

## Static website container (`$web`)

Azure Storage **static website hosting always uses the `$web` container** for publicly served files. There is no supported option to point the static website feature at a differently named container. This project also creates a private **`frontend`** container for optional non-public artifacts; your CI pipeline uploads the built site to **`$web`** (see GitHub workflow).

## Front Door origin

The Front Door origin uses **`azurerm_storage_account.primary_web_host`** (the `*.web.core.windows.net` static website hostname), **not** the blob service hostname. Using the blob host is a common misconfiguration and will not serve your static site correctly.

## Service principal for GitHub Actions

Create a service principal scoped to your subscription (store the JSON output as the `AZURE_CREDENTIALS` secret):

```bash
az ad sp create-for-rbac --name "digital-twin-sp" \
  --role contributor \
  --scopes /subscriptions/<SUBSCRIPTION_ID> \
  --sdk-auth
```

## GitHub repository layout

Workflows live at **`.github/workflows/deploy.yml`** in this repo root (paths `infra/**`, `frontend/`, `function-app/`).

## GitHub Actions and Terraform state

The `deploy-infra` job runs `terraform apply` in CI. **Without a remote backend**, each runner starts with an empty local state and the next apply can fail or attempt to recreate resources. Before relying on CI applies:

1. Create an Azure Storage account + container for Terraform state.
2. Uncomment and fill in `backend.tf`.
3. Run `terraform init -migrate-state` locally once.

Until then, prefer **`terraform apply` locally** and use the workflow for **app** deployment only, or enable the backend first.

To provision state storage in Azure and get exact `terraform init -migrate-state` flags, run **[`scripts/bootstrap-remote-state.sh`](scripts/bootstrap-remote-state.sh)** (set `TF_STATE_STORAGE_ACCOUNT` to a globally unique alphanumeric name first).

## Scripted next steps (after `AZURE_*` credentials in GitHub)

With **`az login`** and **`terraform.tfvars`** in place:

| Step | Script |
| --- | --- |
| 1. First `terraform apply` (creates storage + function names) | **Bash/WSL:** `chmod +x scripts/*.sh && ./scripts/run-first-apply.sh` — **PowerShell:** `.\scripts\run-first-apply.ps1` |
| 2. Push `AZURE_STORAGE_ACCOUNT_NAME` + `AZURE_FUNCTION_APP_NAME` to GitHub | **`gh auth login`** then `./scripts/set-github-secrets-from-outputs.sh` |
| 3. Remote state (optional, before CI `deploy-infra` repeats) | `./scripts/bootstrap-remote-state.sh` then uncomment [`backend.tf`](backend.tf) and run `terraform init -migrate-state` as printed |

## GitHub secrets

| Secret | Purpose |
| --- | --- |
| `AZURE_CREDENTIALS` | JSON from `az ad sp create-for-rbac --sdk-auth` |
| `AZURE_SUBSCRIPTION_ID` | Same subscription as Terraform; passed as `TF_VAR_subscription_id` in CI |
| `AZURE_STORAGE_ACCOUNT_NAME` | From `terraform output storage_account_name` |
| `AZURE_FUNCTION_APP_NAME` | From `terraform output function_app_name` |
| `OPENAI_API_KEY` | Optional for workflows; Terraform already sets `AZURE_OPENAI_*` on the Function App. Use this secret for other jobs or local tooling if you want parity with the printed primary key |

### Pushing to Git — when do storage / function secrets appear?

**Nothing secret goes in Git.** You commit Terraform and app code only. `terraform.tfvars` (with `subscription_id`) stays **local** (gitignored). **GitHub secrets** are typed in the GitHub UI (or `gh secret set`); they are not files in the repo.

Because **`AZURE_STORAGE_ACCOUNT_NAME`** and **`AZURE_FUNCTION_APP_NAME`** describe resources that **Terraform creates**, you fill them **after the first successful apply** (local or CI):

1. **Before or on first push:** In GitHub → **Settings → Secrets and variables → Actions**, add at least **`AZURE_CREDENTIALS`** and **`AZURE_SUBSCRIPTION_ID`**. These do not depend on Azure resources existing yet.
2. **Create Azure resources:** Run **`terraform apply`** from `infra/` on your machine, **or** push a change under `infra/**` so the **`deploy-infra`** workflow runs (if remote state is configured; see above).
3. **After resources exist:** Read names from Terraform (or Azure CLI) and add the remaining secrets — still only in GitHub, not in Git:

   ```bash
   cd infra
   terraform output -raw storage_account_name
   terraform output -raw function_app_name
   ```

   Or with CLI (use your real resource group; default in `variables.tf` is **`digital-twin-rg`** unless you overrode `resource_group_name` in `terraform.tfvars`):

   ```bash
   RG="digital-twin-rg"
   az storage account list -g "$RG" --query "[].name" -o tsv
   az functionapp list -g "$RG" --query "[].name" -o tsv
   ```

4. **Next push to `main`:** The **`deploy-app`** job can upload to `$web` and deploy Functions because the secrets are now set.

**Predictable name (defaults only):** If you did **not** change `project_name` or `environment` in `terraform.tfvars`, the Function App name is **`digitaltwin-dev-functions`** before apply (see `functions.tf`). You can set **`AZURE_FUNCTION_APP_NAME`** early if you are sure those variables match what Terraform will use. The **storage account name** includes a random suffix in `locals.tf`, so you **must** copy it from **`terraform output`** (or `az storage account list`) **after** apply.

## Function App and storage keys

Conversation memory should use the **Function App’s system-assigned managed identity** and the **Storage Blob Data Contributor** role on the **`memory`** container (granted in Terraform). The host still uses **storage account keys internally** for `AzureWebJobsStorage` / Functions runtime wiring, which is separate from application blob access patterns.

## Naming

Resources follow `project-environment-type` with lowercase letters, numbers, and hyphens where the Azure resource type allows it. Storage account names are **alphanumeric only**, max **24** characters (computed in `locals.tf`).

## Remote state template

See `backend.tf` (commented `azurerm` backend). Uncomment and set your state storage account details when ready.
