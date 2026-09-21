# Pinned upstream version. Maintained by the monthly release agent in
# .github/workflows/release.yml — see CHANGELOG.md for the history. There is no
# separate versions file: this Dockerfile is the source of truth.
#
# The base image tag is the only pin. Every package below is installed unversioned
# on purpose: an exact `=version` apk pin breaks as soon as Alpine drops the old
# package, and `postgresql-client` without a number resolves to whichever major the
# Alpine release ships. Bumping the tag is what moves the tools.
#
# Object storage is reached through the MinIO client, not aws-cli. aws-cli on Alpine
# is the Python build: it pulls in a Python runtime and about sixty packages, and the
# image's entire Critical/High surface came from two of them, with no fix Alpine had
# packaged. mcli is a single static binary and covers the three operations the backup
# and restore scripts use.
FROM alpine:3.24

RUN set -eux; \
    apk add --no-cache \
      postgresql-client \
      minio-client \
      jq \
      bash \
      ca-certificates \
      coreutils \
      openssl; \
    update-ca-certificates; \
    psql --version; \
    pg_dump --version; \
    mcli --version; \
    jq --version

WORKDIR /app

COPY backup.sh restore.sh entrypoint.sh ./
RUN chmod +x backup.sh restore.sh entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]