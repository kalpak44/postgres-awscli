FROM alpine:3.23

RUN set -eux; \
    apk add --no-cache \
      postgresql18-client \
      aws-cli \
      bash \
      ca-certificates \
      coreutils; \
    update-ca-certificates

WORKDIR /app

COPY backup.sh restore.sh entrypoint.sh ./
RUN chmod +x backup.sh restore.sh entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]
