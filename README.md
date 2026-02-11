# postgres-awscli

Minimal Docker image containing:

- `pg_dump` (PostgreSQL client)
- `aws-cli`
- Backup script for PostgreSQL → S3
- Retention policy (keeps last 10 backups)

Designed for Kubernetes CronJobs.

Image published to: `ghcr.io/kalpak44/postgres-awscli:latest`

## What It Does

1. Connects to a PostgreSQL database
2. Creates a compressed dump (`.sql.gz`)
3. Uploads it to S3
4. Keeps only the latest **10 backups**

## Pull Image

```bash
docker pull ghcr.io/kalpak44/postgres-awscli:latest
```

## Run Locally

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

## Kubernetes CronJob Example

```bash
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