# postgres-awscli

Minimal Docker image containing:

- `pg_dump` (PostgreSQL client)
- `psql`
- `mcli` (MinIO client, for S3)
- `jq`
- PostgreSQL → S3 backup support
- PostgreSQL restore from S3 support
- Retention policy (keeps last 10 backups by default)

Designed for Kubernetes CronJobs and Jobs.

Image published to:  
`ghcr.io/kalpak44/postgres-awscli:latest`

---

# Features

## Backup Mode (default)

1. Connects to a PostgreSQL database
2. Creates a compressed dump (`.sql.gz`)
3. Uploads it to S3
4. Keeps only the latest **10 backups**

## Restore Mode

1. Downloads a selected `.sql.gz` from S3
2. Optionally drops & recreates the database
3. Restores the dump into PostgreSQL

---

# Environment Variables

## Common (required)

| Variable | Description |
|-----------|------------|
| `PGHOST` | PostgreSQL host |
| `PGPORT` | PostgreSQL port |
| `PGDATABASE` | Database name |
| `PGUSER` | Database user |
| `PGPASSWORD` | Database password |
| `S3_BUCKET` | S3 bucket name |
| `AWS_DEFAULT_REGION` | AWS region — also builds the default S3 endpoint |
| `AWS_ACCESS_KEY_ID` | S3 access key |
| `AWS_SECRET_ACCESS_KEY` | S3 secret key |
| `S3_ENDPOINT` | Optional. Defaults to `https://s3.<AWS_DEFAULT_REGION>.amazonaws.com`; set it for MinIO or another S3-compatible backend |

---

## Backup Mode (default)

| Variable | Description |
|-----------|------------|
| `S3_PREFIX` | S3 folder/prefix (e.g. `prod`) |
| `RETENTION_COUNT` | Optional. Default: `10` |
| `S3_SSE` | Optional. Default: `AES256` |

---

## Restore Mode

| Variable | Description |
|-----------|------------|
| `MODE=restore` | Enables restore mode |
| `RESTORE_S3_KEY` | Full object key (e.g. `prod/mydb_20260213T000000Z.sql.gz`) |
| `RECREATE_DB` | Optional. `true` to drop & recreate database |
| `ADMIN_DB` | Optional. Default: `postgres` (used for DROP/CREATE) |

⚠️ `RECREATE_DB=true` will destroy all existing data.

---

# Pull Image

```bash
docker pull ghcr.io/kalpak44/postgres-awscli:latest
```

---

# Backup Example (Default Mode)

```bash
docker run --rm \
  -e PGHOST=localhost \
  -e PGPORT=5432 \
  -e PGDATABASE=mydb \
  -e PGUSER=myuser \
  -e PGPASSWORD=mypassword \
  -e AWS_ACCESS_KEY_ID=xxx \
  -e AWS_SECRET_ACCESS_KEY=yyy \
  -e AWS_DEFAULT_REGION=eu-central-1 \
  -e S3_BUCKET=my-backups \
  -e S3_PREFIX=pg/mydb \
  ghcr.io/kalpak44/postgres-awscli:latest
```

No `MODE` variable = **backup mode**.

---

# Restore Example

Restore into existing database:

```bash
docker run --rm \
  -e MODE=restore \
  -e PGHOST=localhost \
  -e PGPORT=5432 \
  -e PGDATABASE=mydb \
  -e PGUSER=myuser \
  -e PGPASSWORD=mypassword \
  -e AWS_ACCESS_KEY_ID=xxx \
  -e AWS_SECRET_ACCESS_KEY=yyy \
  -e AWS_DEFAULT_REGION=eu-central-1 \
  -e S3_BUCKET=my-backups \
  -e RESTORE_S3_KEY=pg/mydb/mydb_20260213T000000Z.sql.gz \
  ghcr.io/kalpak44/postgres-awscli:latest
```

---

# Full Recreate Restore (Dangerous)

```bash
docker run --rm \
  -e MODE=restore \
  -e RECREATE_DB=true \
  -e PGHOST=localhost \
  -e PGPORT=5432 \
  -e PGDATABASE=mydb \
  -e PGUSER=adminuser \
  -e PGPASSWORD=adminpass \
  -e AWS_ACCESS_KEY_ID=xxx \
  -e AWS_SECRET_ACCESS_KEY=yyy \
  -e AWS_DEFAULT_REGION=eu-central-1 \
  -e S3_BUCKET=my-backups \
  -e RESTORE_S3_KEY=pg/mydb/mydb_20260213T000000Z.sql.gz \
  ghcr.io/kalpak44/postgres-awscli:latest
```

This will:

- terminate active connections
- drop the database
- recreate it
- restore from dump

User must have sufficient privileges.

---

# Kubernetes CronJob Example (Backup)

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: pg-backup
spec:
  schedule: "0 2 * * *"
  concurrencyPolicy: Forbid
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: Never
          containers:
            - name: backup
              image: ghcr.io/kalpak44/postgres-awscli:latest
              envFrom:
                - secretRef:
                    name: pg-backup-secret
                - secretRef:
                    name: s3-backup-secret
```

---

# Kubernetes Job Example (Restore)

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: pg-restore
spec:
  template:
    spec:
      restartPolicy: Never
      containers:
        - name: restore
          image: ghcr.io/kalpak44/postgres-awscli:latest
          env:
            - name: MODE
              value: "restore"
            - name: RECREATE_DB
              value: "true"
            - name: RESTORE_S3_KEY
              value: "prod/mydb_20260213T000000Z.sql.gz"
          envFrom:
            - secretRef:
                name: pg-backup-secret
            - secretRef:
                name: s3-backup-secret
```

---

# Notes

- Compatible with RDS, self-hosted PostgreSQL, or Kubernetes services.
- Requires static credentials. IAM roles are no longer picked up: S3 is reached through
  the MinIO client rather than the AWS CLI, which was dropped in v0.4.0 because its
  Python dependencies carried the image's entire Critical/High vulnerability surface.
- `S3_ENDPOINT` makes any S3-compatible backend work, not just AWS.
- Uses server-side encryption (SSE-S3) by default. `S3_SSE` is now a switch rather than
  an algorithm name; set it empty to disable. A backend with no KMS configured rejects
  the upload instead of storing the object unencrypted.
- Safe for production when used with correct database privileges.

---

# Recommended Usage Pattern

- Use **CronJob** for backups.
- Use **manual Job** for restores.
- Use separate admin credentials for `RECREATE_DB=true`.

---

Minimal. Predictable. Kubernetes-friendly.
