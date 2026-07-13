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

# Restore n8n settings volume (replace YOUR_PROJECT_n8n_data with the name from above)
docker run --rm \
  -v YOUR_PROJECT_n8n_data:/data \
  -v "$PWD/backups":/backup \
  alpine sh -c "rm -rf /data/* /data/.[!.]* 2>/dev/null; tar xzf /backup/n8n_data_backup.tar.gz -C /data"

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
git add docker-compose.yml README.md .gitignore
git commit -m "Add n8n + Postgres Compose stack"

git remote add origin https://github.com/YOUR_USER/YOUR_REPO.git
git branch -M main
git push -u origin main
```

Later updates:

```bash
git add docker-compose.yml README.md .gitignore
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
  -v n8n-postrgres_n8n_data:/data \
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

- `n8n-postrgres_postgres_data`
- `n8n-postrgres_n8n_data`

**2. Upload manually**

1. Open Finder → **Desktop** → **n8n-backups**
2. Drag the latest dated folder into **Google Drive** or **Dropbox**
3. Wait until upload finishes

Optional: delete old dated folders locally or in Drive when you no longer need them.
