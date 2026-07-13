# n8n + PostgreSQL

Self-hosted [n8n](https://n8n.io) with PostgreSQL via Docker Compose.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) and Docker Compose

## Start

From this directory:

```bash
docker compose up -d
```

Open n8n at [http://localhost:5678](http://localhost:5678).

On first launch, create the owner account (email + password). Workflows, users, and credentials live in Docker volumes — not in this folder.

## Stop

```bash
docker compose down
```

Containers stop; volumes (workflows, users, credentials) are kept.

To stop and delete all stored data:

```bash
docker compose down -v
```

## Ports

| Service  | Port |
|----------|------|
| n8n      | 5678 |
| Postgres | 5432 |

If a port is already in use, stop the other process/container or change the host port in `docker-compose.yml` (e.g. `"5433:5432"`).

---

## What to back up

| Item | Purpose | Where to store |
|------|---------|----------------|
| This project folder (`docker-compose.yml`, `README.md`) | Recreate the stack | **Git** (private repo recommended) |
| Postgres dump + `n8n_data` archive | Workflows, users, credentials, encryption key | **Dropbox / Google Drive** |

Do **not** commit database dumps or volume backups to GitHub — they contain secrets. Prefer a **private** repo for the compose file (it has credentials).

Confirm volume names on this machine:

```bash
docker volume ls | grep n8n
```

On this project they are typically:

- `n8n-postrgres_postgres_data`
- `n8n-postrgres_n8n_data`

(The prefix matches the folder/Compose project name.)

---

## Backup: Git (source / project files)

From this directory, once:

```bash
git init
git add docker-compose.yml README.md
git commit -m "Add n8n + Postgres Compose stack"
```

Create a **private** repo on GitHub, then:

```bash
git remote add origin https://github.com/YOUR_USER/YOUR_REPO.git
git branch -M main
git push -u origin main
```

Later updates:

```bash
git add docker-compose.yml README.md
git commit -m "Update Compose config"
git push
```

Optional `.gitignore` so dumps never get committed:

```gitignore
*.sql
*.tar.gz
backups/
```

---

## Backup: Dropbox or Google Drive (runtime data)

Create a local backup folder (example: Desktop, then sync that folder with Dropbox/Drive):

```bash
mkdir -p ~/Desktop/n8n-backups
cd /Users/openclaw/Desktop/n8n-postrgres
```

### 1. Dump Postgres (workflows, users, most app data)

Stack should be running:

```bash
docker compose exec -T postgres pg_dump -U n8n_user n8n_database > ~/Desktop/n8n-backups/n8n_postgres_backup.sql
```

### 2. Archive the n8n settings volume (encryption key, etc.)

```bash
docker run --rm \
  -v n8n-postrgres_n8n_data:/data \
  -v ~/Desktop/n8n-backups:/backup \
  alpine tar czf /backup/n8n_data_backup.tar.gz -C /data .
```

### 3. Sync to the cloud

- **Dropbox:** Put `~/Desktop/n8n-backups` inside your Dropbox folder, or move the files there.
- **Google Drive:** Put them in Google Drive (Desktop app or upload in the browser).

You should end up with at least:

- `n8n_postgres_backup.sql`
- `n8n_data_backup.tar.gz`

Re-run these dump commands whenever you want a fresh backup (after important workflow changes).

---

## Move to a different machine

### On the new machine

1. Install [Docker Desktop](https://docs.docker.com/get-docker/).
2. Clone the project from Git:

```bash
git clone https://github.com/YOUR_USER/YOUR_REPO.git
cd YOUR_REPO
```

3. Copy the backup files from Dropbox/Drive into that folder (or any path you prefer), e.g.:

```bash
mkdir -p ./backups
# Copy n8n_postgres_backup.sql and n8n_data_backup.tar.gz into ./backups/
```

4. Start the stack (creates empty volumes):

```bash
docker compose up -d
```

5. Stop **only** the n8n app so nothing writes while restoring:

```bash
docker compose stop n8n
```

6. Restore Postgres:

```bash
docker compose exec -T postgres psql -U n8n_user -d n8n_database -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
docker compose exec -T postgres psql -U n8n_user -d n8n_database < ./backups/n8n_postgres_backup.sql
```

7. Restore the `n8n_data` volume (use the volume name from `docker volume ls` on the new machine):

```bash
docker volume ls | grep n8n
```

```bash
docker run --rm \
  -v YOUR_PROJECT_n8n_data:/data \
  -v "$PWD/backups":/backup \
  alpine sh -c "rm -rf /data/* /data/.[!.]* 2>/dev/null; tar xzf /backup/n8n_data_backup.tar.gz -C /data"
```

Replace `YOUR_PROJECT_n8n_data` with the actual name (often `<folder-name>_n8n_data`).

8. Start everything again:

```bash
docker compose up -d
```

9. Open [http://localhost:5678](http://localhost:5678) and sign in with the same owner account as before.

### Checklist

- [ ] Private Git repo with `docker-compose.yml`
- [ ] Fresh `.sql` + `.tar.gz` in Dropbox/Drive
- [ ] Docker installed on the new machine
- [ ] Same compose env (DB user/password/db name) as when the dump was made
- [ ] Ports `5678` and `5432` free on the new machine
