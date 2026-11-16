# Changelog

The newest `## vX.Y.Z` heading below is the version this repository publishes — the
release workflow reads it from this file. Entries are written by the monthly release
agent (`.github/workflows/release.yml`).

## v0.4.0 — 2026-11-16

| tool | from | to |
|------|------|----|
| postgresql-client | 18.6 | 18.7 |

Security rebuild. The previous image scanned as 12 Critical and 119 High; this one scans as 2 Critical and 14 High. The release notes list what remains and why.

### Fixed

- **certifi** 2026.2.25 — 1 Critical: GHSA-6q48-6c7w-9gw2
- **libcrypto3** 3.5.8-r0 — 4 High: CVE-2026-54873, CVE-2026-72897, CVE-2026-84782, CVE-2026-84784
- **libexpat** 2.8.4-r0 — 7 High: CVE-2026-102633, CVE-2026-113351, CVE-2026-115506, CVE-2026-117610, CVE-2026-118370, CVE-2026-77214, CVE-2026-93990
- **libpq** 18.6-r0 — 38 High: CVE-2026-116304, CVE-2026-116306, CVE-2026-116307, CVE-2026-116309, CVE-2026-116313, CVE-2026-116314, CVE-2026-116315, CVE-2026-116316, CVE-2026-116317, CVE-2026-116318, CVE-2026-116319, CVE-2026-116320, CVE-2026-116323, CVE-2026-116325, CVE-2026-116326, CVE-2026-116328, CVE-2026-116329, CVE-2026-116330, CVE-2026-116331, CVE-2026-116332, CVE-2026-116335, CVE-2026-116336, CVE-2026-120139, CVE-2026-120141, CVE-2026-120142, CVE-2026-120143, CVE-2026-120144, CVE-2026-120145, CVE-2026-120147, CVE-2026-120148, CVE-2026-120149, CVE-2026-120150, CVE-2026-120151, CVE-2026-120153, CVE-2026-14661, CVE-2026-18447, CVE-2026-6460, CVE-2026-6467
- **libssl3** 3.5.8-r0 — 4 High: CVE-2026-54873, CVE-2026-72897, CVE-2026-84782, CVE-2026-84784
- **musl** 1.2.6-r2 — 1 High: CVE-2026-107891
- **musl-utils** 1.2.6-r2 — 1 High: CVE-2026-107891
- **openssl** 3.5.8-r0 — 4 High: CVE-2026-54873, CVE-2026-72897, CVE-2026-84782, CVE-2026-84784
- **postgresql18-client** 18.6-r0 — 38 High: CVE-2026-116304, CVE-2026-116306, CVE-2026-116307, CVE-2026-116309, CVE-2026-116313, CVE-2026-116314, CVE-2026-116315, CVE-2026-116316, CVE-2026-116317, CVE-2026-116318, CVE-2026-116319, CVE-2026-116320, CVE-2026-116323, CVE-2026-116325, CVE-2026-116326, CVE-2026-116328, CVE-2026-116329, CVE-2026-116330, CVE-2026-116331, CVE-2026-116332, CVE-2026-116335, CVE-2026-116336, CVE-2026-120139, CVE-2026-120141, CVE-2026-120142, CVE-2026-120143, CVE-2026-120144, CVE-2026-120145, CVE-2026-120147, CVE-2026-120148, CVE-2026-120149, CVE-2026-120150, CVE-2026-120151, CVE-2026-120153, CVE-2026-14661, CVE-2026-18447, CVE-2026-6460, CVE-2026-6467
- **pyc** 3.14.7-r1 — 2 Critical, 2 High: CVE-2026-115557, CVE-2026-19445, CVE-2026-19553, CVE-2026-82049
- **python3** 3.14.7-r1 — 2 Critical, 2 High: CVE-2026-115557, CVE-2026-19445, CVE-2026-19553, CVE-2026-82049
- **python3-pyc** 3.14.7-r1 — 2 Critical, 2 High: CVE-2026-115557, CVE-2026-19445, CVE-2026-19553, CVE-2026-82049
- **python3-pycache-pyc0** 3.14.7-r1 — 2 Critical, 2 High: CVE-2026-115557, CVE-2026-19445, CVE-2026-19553, CVE-2026-82049
- **zlib** 1.3.2-r0 — 1 Critical, 1 High: CVE-2026-4738, CVE-2026-85091

### Contents

| tool | version |
|------|---------|
| alpine | 3.24.4 |
| psql | 18.7 |
| pg_dump | 18.7 |
| pg_restore | 18.7 |
| pg_dumpall | 18.7 |
| aws-cli | 2.34.63 |
| bash | 5.3.9 |
| coreutils | 9.11 |
| python3 | 3.14.10 |
| musl | 1.2.6-r3 |
| openssl | 3.5.9-r0 |
| ca-certificates | 20261020-r0 |

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