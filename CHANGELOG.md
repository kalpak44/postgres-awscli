# Changelog

The newest `## vX.Y.Z` heading below is the version this repository publishes — the
release workflow reads it from this file. Entries are written by the monthly release
agent (`.github/workflows/release.yml`).

## vNEXT

Replaced the AWS CLI with the MinIO client (`mcli`) for all S3 access. On Alpine the AWS
CLI is the Python build: it pulled in a Python runtime and around sixty packages, and
every Critical and all but one High finding in the image came from two of them, with no
fixed version Alpine had packaged.

Breaking:

- `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` are now required. IAM roles are no
  longer picked up.
- `S3_SSE` is a switch rather than an algorithm name; any non-empty value enables SSE-S3.
- New optional `S3_ENDPOINT` points the scripts at any S3-compatible backend.

## v0.3.2 — 2026-09-07

Security rebuild. The previous image scanned as 6 Critical and 19 High; this one scans as 2 Critical and 3 High. The release notes list what remains and why.

### Fixed

- **libcrypto3** 3.5.7-r0 — 2 Critical, 7 High: CVE-2026-14456, CVE-2026-14457, CVE-2026-18798, CVE-2026-54874, CVE-2026-63072, CVE-2026-63073, CVE-2026-63075, CVE-2026-63076, CVE-2026-75803
- **libexpat** 2.8.3-r0 — 2 High: CVE-2026-66046, CVE-2026-76641
- **libssl3** 3.5.7-r0 — 2 Critical, 7 High: CVE-2026-14456, CVE-2026-14457, CVE-2026-18798, CVE-2026-54874, CVE-2026-63072, CVE-2026-63073, CVE-2026-63075, CVE-2026-63076, CVE-2026-75803

### Contents

| tool | version |
|------|---------|
| alpine | 3.24.1 |
| psql | 18.6 |
| pg_dump | 18.6 |
| pg_restore | 18.6 |
| pg_dumpall | 18.6 |
| aws-cli | 2.34.63 |
| bash | 5.3.9 |
| coreutils | 9.11 |
| python3 | 3.14.7 |
| musl | 1.2.6-r2 |
| openssl | 3.5.8-r0 |
| ca-certificates | 20260611-r0 |

## v0.3.1 — 2026-08-24

| tool | from | to |
|------|------|----|

Rebuild against current Alpine packages. No pinned version changed.

## v0.3.0 — 2026-08-24

| tool | from | to |
|------|------|----|
| alpine | 3.23 | 3.24 |
| aws-cli | 2.32.7 | 2.34.63 |
| bash | 5.3.3 | 5.3.9 |
| coreutils | 9.8 | 9.11 |

The base image moves from Alpine 3.23 to 3.24, carrying aws-cli up to 2.34.63,
bash to 5.3.9, and coreutils to 9.11. The PostgreSQL client is unchanged at 18.6 —
the major did not move, so dump compatibility is unaffected.

## v0.2.0 — 2026-08-24

| tool | from | to |
|------|------|----|
| postgresql-client | 18 (pinned major) | unversioned |

The PostgreSQL client is no longer pinned to a major. `postgresql-client` without a
number resolves to whichever major the Alpine release ships — 18 on Alpine 3.23, so
this is not a version change today — which means the pin can never name a major that
Alpine has stopped packaging. Alpine stays at 3.23; the base image tag is now the
only pin, and the monthly release agent moves it.

## v0.1.0

Initial image: Alpine with the PostgreSQL client, the AWS CLI and backup/restore
scripts.