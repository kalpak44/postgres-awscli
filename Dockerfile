FROM alpine:3.20

RUN apk add --no-cache \
      postgresql18-client \
      aws-cli \
      bash \
      ca-certificates \
      coreutils \
    && update-ca-certificates

WORKDIR /app
COPY backup.sh /app/backup.sh
RUN chmod +x /app/backup.sh

ENTRYPOINT ["/app/backup.sh"]
