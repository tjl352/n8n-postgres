#!/usr/bin/env bash
# Launch n8n-mcp with credentials from the project .env (never commit .env).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if [[ ! -f "$ROOT/.env" ]]; then
  echo "Missing $ROOT/.env — copy .env.example to .env and set N8N_API_KEY" >&2
  exit 1
fi

set -a
# shellcheck disable=SC1091
source "$ROOT/.env"
set +a

if [[ -z "${N8N_API_KEY:-}" || "${N8N_API_KEY}" == "replace-with-your-n8n-api-key" ]]; then
  echo "Set N8N_API_KEY in $ROOT/.env (n8n → Settings → n8n API)" >&2
  exit 1
fi

export N8N_API_URL="${N8N_API_URL:-http://localhost:5678}"
export WEBHOOK_SECURITY_MODE="${WEBHOOK_SECURITY_MODE:-moderate}"
export MCP_MODE=stdio
export LOG_LEVEL=error
export DISABLE_CONSOLE_OUTPUT=true

exec npx -y n8n-mcp
