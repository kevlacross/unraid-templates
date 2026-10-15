# Source provenance

- Application: https://github.com/nightscout/nocturne
- Reviewed release: https://github.com/nightscout/nocturne/releases/tag/v0.2.7
- Release compose: https://github.com/nightscout/nocturne/releases/download/v0.2.7/docker-compose.yaml
- Release environment: https://github.com/nightscout/nocturne/releases/download/v0.2.7/default.env.example
- Existing-proxy override: https://github.com/nightscout/nocturne/releases/download/v0.2.7/docker-compose.byo-proxy.yaml
- Downloaded 2026-10-15.

`upstream/` retains the published inputs and their parsed JSON. `config/00-init.sh` is the release's embedded bootstrap script with Compose's double-dollar escaping removed. The gateway environment is taken from the same release. `build_templates.py` omits Scalar's cosmetic CSS and empty optional integration settings remain unset. It explicitly uses the Production environment for the API.

The upstream README declares AGPL-3.0. The license text and attribution are included in LICENSE and NOTICE.md. The bootstrap additionally exports PGPASSWORD from POSTGRES_PASSWORD for local SCRAM authentication. No application image is modified or redistributed.
