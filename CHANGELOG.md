# Changelog

The newest `## vX.Y.Z` heading below is the version this repository publishes — the
release workflow reads it from this file. Entries are written by the monthly release
agent (`.github/workflows/release.yml`).

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