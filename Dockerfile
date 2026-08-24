# Pinned upstream version. Maintained by the monthly release agent in
# .github/workflows/release.yml — see CHANGELOG.md for the history. There is no
# separate versions file: this Dockerfile is the source of truth.
#
# The base image tag is the only pin. Every package below is installed unversioned
# on purpose: an exact `=version` apk pin breaks as soon as Alpine drops the old
# package, and `postgresql-client` without a number resolves to whichever major the
# Alpine release ships. Bumping the tag is what moves the tools.
FROM alpine:3.23

RUN set -eux; \
    apk add --no-cache \
      postgresql-client \
      aws-cli \
      bash \
      ca-certificates \
      coreutils; \
    update-ca-certificates; \
    psql --version; \
    pg_dump --version; \
    aws --version

WORKDIR /app

COPY backup.sh restore.sh entrypoint.sh ./
RUN chmod +x backup.sh restore.sh entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]