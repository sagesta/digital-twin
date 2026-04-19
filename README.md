# Digital Twin (Azure)

Standalone repo: **Next.js** frontend + **FastAPI** backend (Week 2 pattern from `production/week2`), **Azure** infrastructure (Terraform), and **Azure Functions** for production API (mirrors Lambda in the course).

## Layout

| Path | Role |
|------|------|
| `frontend/` | Next.js App Router + chat UI (`components/twin.tsx`) |
| `backend/` | FastAPI + OpenAI + file memory (`../memory`) — local dev |
| `function-app/` | Azure Functions HTTP API (`/api/chat`) — production on Azure |
| `infra/` | Terraform (Storage, optional Front Door, Functions, Azure OpenAI) |

Persona text comes from `backend/me.txt` (seeded from your professional summary).

## Local development

1. `cd backend` — copy `.env.example` to `.env`, set `OPENAI_API_KEY`.
2. `pip install -r requirements.txt` then `uvicorn server:app --reload --host 0.0.0.0 --port 8000`
3. `cd frontend` — `npm install` then `npm run dev`
4. Open http://localhost:3000 — chat hits `http://localhost:8000/chat` by default.

For production static hosting, set `NEXT_PUBLIC_API_BASE` to your Function App base URL (e.g. `https://digitaltwin-dev-functions.azurewebsites.net`) before `npm run build`.

## Azure / Terraform

See [infra/README.md](infra/README.md). Copy `infra/terraform.tfvars.example` to `terraform.tfvars`, set `subscription_id`, then `terraform init` / `apply` from `infra/`.

GitHub Actions: [.github/workflows/deploy.yml](.github/workflows/deploy.yml) — set repository secrets as documented in `infra/README.md`.
