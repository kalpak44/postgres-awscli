# Changelog

The newest `## vX.Y.Z` heading below is the version this repository publishes — the
release workflow reads it from this file. Entries are written by the monthly release
agent (`.github/workflows/release.yml`).

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