# n8n + PostgreSQL

Self-hosted [n8n](https://n8n.io) with PostgreSQL via Docker Compose.

**Prerequisite:** [Docker Desktop](https://docs.docker.com/get-docker/) (includes Docker Compose).

| Port | Service |
|------|---------|
| 5678 | n8n UI → [http://localhost:5678](http://localhost:5678) |
| 5432 | Postgres |

If a port is already in use, stop the other process/container or change the host port in `docker-compose.yml` (e.g. `"5433:5432"`).

---

## Section 1 — How to download the project

### Option A: Clone from Git

```bash
git clone https://github.com/YOUR_USER/YOUR_REPO.git
cd YOUR_REPO
```

Use a **private** repo — `docker-compose.yml` contains database credentials.

### Option B: Copy the project folder

Copy this entire folder (at least `docker-compose.yml`, `README.md`, and `.gitignore`) to the new machine.

### If you also need your workflows (new machine / restore)

1. Download from Google Drive or Dropbox:
   - `n8n_postgres_backup.sql`
   - `n8n_data_backup.tar.gz`
2. Put them in a `backups` folder inside the project:

```bash
mkdir -p ./backups
# Copy the two backup files into ./backups/
```

3. Start the stack, then restore (see steps below after Section 2’s start command, or follow **Restore data on a new machine** at the end of this section).

### Restore data on a new machine

Run these **after** `docker compose up -d` once (so volumes exist):

```bash
# Stop n8n while restoring
docker compose stop n8n

# Restore Postgres
docker compose exec -T postgres psql -U n8n_user -d n8n_database -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
docker compose exec -T postgres psql -U n8n_user -d n8n_database < ./backups/n8n_postgres_backup.sql

# Check the n8n volume name on this machine
docker volume ls | grep n8n

# Restore n8n settings volume
docker run --rm \
  -v n8n-postgres_n8n_data:/data \
  -v "$PWD/backups":/backup \
  alpine sh -c 'rm -rf /data/* /data/.[!.]* 2>/dev/null; tar xzf /backup/n8n_data_backup.tar.gz -C /data'

# Start again
docker compose up -d
```

Open [http://localhost:5678](http://localhost:5678) and sign in with the same owner account as before.

---

## Section 2 — How to run and stop the project

### Run

From the project directory:

```bash
docker compose up -d
```

Open [http://localhost:5678](http://localhost:5678).

On first launch (no restore), create the owner account (email + password).

Workflows, users, and credentials live in Docker volumes — not in this folder.

### Stop

```bash
docker compose down
```

Containers stop; volumes (workflows, users, credentials) are **kept**.

### Stop and delete all data

```bash
docker compose down -v
```

This removes the Docker volumes. Only do this if you intend to wipe the instance.

---

## Section 3 — How to save the project manually

Two different things to save:

| What | Why | Where |
|------|-----|--------|
| Project files (`docker-compose.yml`, `README.md`, `.gitignore`) | Recreate the stack | **Git** (private repo) |
| Postgres dump + `n8n_data` archive | Workflows, users, credentials, encryption key | **Google Drive / Dropbox** |

Do **not** commit `.sql` or `.tar.gz` backups to Git — they contain secrets. This repo’s `.gitignore` already ignores them.

### 3A. Save source files to Git

```bash
git init
git add docker-compose.yml README.md .gitignore .cursor/mcp.json .mcp.json .env.example .codex/config.toml.example scripts/n8n-mcp.sh
git commit -m "Add n8n + Postgres Compose stack"

git remote add origin https://github.com/YOUR_USER/YOUR_REPO.git
git branch -M main
git push -u origin main
```

Later updates:

```bash
git add docker-compose.yml README.md .gitignore .cursor/mcp.json .mcp.json .env.example .codex/config.toml.example scripts/n8n-mcp.sh
git commit -m "Update project files"
git push
```

### 3B. Save runtime data to Google Drive or Dropbox

You cannot drag Docker volumes into Drive directly. Export them to files, then upload those files.

Each backup run creates a **new timestamped folder** so older copies are kept (nothing is overwritten).

**1. Export backups** (stack should be running). Paste and run the **whole block** each time you want a new backup:

```bash
BACKUP_DIR=~/Desktop/n8n-backups/$(date +%Y-%m-%d_%H-%M-%S)
mkdir -p "$BACKUP_DIR"

# Postgres data (workflows, users, etc.)
docker compose exec -T postgres pg_dump -U n8n_user n8n_database > "$BACKUP_DIR/n8n_postgres_backup.sql"

# n8n settings volume (encryption key, etc.)
docker run --rm \
  -v n8n-postgres_n8n_data:/data \
  -v "$BACKUP_DIR":/backup \
  alpine tar czf /backup/n8n_data_backup.tar.gz -C /data .
```

You should get a folder like:

`~/Desktop/n8n-backups/2026-07-13_19-49-02/`

containing:

- `n8n_postgres_backup.sql`
- `n8n_data_backup.tar.gz`

Confirm volume names if needed:

```bash
docker volume ls | grep n8n
```

On this project they are typically:

- `n8n-postgres_postgres_data`
- `n8n-postgres_n8n_data`

**2. Upload manually**

1. Open Finder → **Desktop** → **n8n-backups**
2. Drag the latest dated folder into **Google Drive** or **Dropbox**
3. Wait until upload finishes

Optional: delete old dated folders locally or in Drive when you no longer need them.

---

## Section 4 — Connect Cursor, Claude Code, and Codex

This project uses [n8n-mcp](https://github.com/czlonkowski/n8n-mcp) so AI tools can read n8n docs and, with an API key, list/update/run workflows on your local instance.

### 1. Create an n8n API key

1. Open [http://localhost:5678](http://localhost:5678) (stack must be running).
2. Go to **Settings → n8n API**.
3. Create an API key and copy it.

### 2. Store the key locally

```bash
cp .env.example .env
```

Edit `.env`:

```bash
N8N_API_URL=http://localhost:5678
N8N_API_KEY=paste-your-key-here
WEBHOOK_SECURITY_MODE=moderate
```

`WEBHOOK_SECURITY_MODE=moderate` is required for local n8n (`localhost`); the default `strict` mode blocks loopback. Do **not** commit `.env` — it is gitignored.

All three tools start MCP via `scripts/n8n-mcp.sh`, which loads that file.

### 3. Cursor

Project config is already at `.cursor/mcp.json`.

1. Reload the window or restart Cursor.
2. Open **Settings → MCP** and confirm `n8n-mcp` is enabled / connected.
3. Start a new chat in this project — the agent can use n8n tools once the server is green.

### 4. Claude Code

Project config is already at `.mcp.json` (project scope).

From this directory:

```bash
claude mcp list
```

You should see `n8n-mcp`. If Claude Code was already open, restart it or run `/mcp` in a session.

Optional (user scope instead of the project file):

```bash
claude mcp add n8n-mcp \
  -e MCP_MODE=stdio \
  -e LOG_LEVEL=error \
  -e DISABLE_CONSOLE_OUTPUT=true \
  -e N8N_API_URL=http://localhost:5678 \
  -e N8N_API_KEY=paste-your-key-here \
  -- npx n8n-mcp
```

### 5. Codex

On this machine, `~/.codex/config.toml` already points at `scripts/n8n-mcp.sh`.

On a new machine, copy from `.codex/config.toml.example` into `~/.codex/config.toml` and set an **absolute** path:

```toml
[mcp_servers.n8n-mcp]
command = "bash"
args = ["/ABS/PATH/TO/n8n-postgres/scripts/n8n-mcp.sh"]
```

Or:

```bash
codex mcp add n8n-mcp -- bash /ABS/PATH/TO/n8n-postgres/scripts/n8n-mcp.sh
```

Then open Codex and check `/mcp`.

### 6. Verify

With n8n running and `.env` filled:

```bash
./scripts/n8n-mcp.sh
```

It should start quietly (stdio MCP). Interrupt with Ctrl+C. If it errors about `N8N_API_KEY`, finish step 2.

In Cursor / Claude Code / Codex, ask something like: “List my n8n workflows.”

### Notes

- Without `N8N_API_KEY`, n8n-mcp still offers **docs/validation** tools, but not live workflow management.
- Agents talk to n8n over the **API**, not the browser canvas.
- Prefer editing on a copy of important workflows; AI changes can be wrong.
