# Notices

Nocturne application and upstream deployment configuration: contributors to https://github.com/nightscout/nocturne. The upstream project declares GNU Affero General Public License version 3.0 in its README. The source release used here is v0.2.7. Preserve its contributor attribution and license when redistributing derived configuration.

Unraid packaging scripts and templates in this directory are offered under AGPL-3.0-or-later. Nocturne, Unraid, PostgreSQL and Microsoft names identify their respective projects and are not endorsements.

The database init script is adapted from the release compose: Compose dollar escaping is removed, and PGPASSWORD is explicitly derived from POSTGRES_PASSWORD so it works with local SCRAM authentication. It must be readable by the PostgreSQL container user (mode 755); it contains no secret values.

Docker images are downloaded directly from their respective publishers and are not redistributed by this package.
