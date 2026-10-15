# Nocturne for Unraid — community templates

Four native DockerMan templates for Nocturne **0.2.7**, based on its published release bundle. This package uses the upstream API and web images, a dedicated PostgreSQL 17 database, and the upstream YARP gateway. Your existing HTTPS reverse proxy terminates TLS.

This is community packaging. Nocturne and the image publishers maintain the application; this package maintains the Unraid integration. Templates and packaging support: https://github.com/kevlacross/unraid-templates/issues. Application source: https://github.com/nightscout/nocturne. A Community Applications listing requires separate submission and review.

## Before installing

- An Unraid server with Docker and OpenSSL, plus an HTTPS reverse proxy.
- A hostname such as `gluco.example.com`, with DNS and a valid certificate.
- Four containers on a dedicated `nocturne` Docker network.
- Approximately 2 GB free RAM as an initial planning allowance; actual usage depends on data and connectors.
- A new, empty database directory. Nightscout MongoDB data cannot be mounted into PostgreSQL.

The templates require environment and bootstrap files generated below. Installing an XML file alone is insufficient.

## Prepare and install

Clone or download the entire repository, then enter its `nocturne` directory. Keep the sibling `templates` directory in place:

```bash
git clone https://github.com/kevlacross/unraid-templates.git
cd unraid-templates/nocturne
```

For an existing installation, retain its credentials and database. The following setup is for a new installation:

```bash
bash prepare.sh gluco.example.com /mnt/user/appdata/nocturne /tmp/nocturne-private
```

The script generates five independent random secrets without printing them. It refuses to overwrite an existing output directory. Keep and back up these private files; rerunning it with new passwords against an initialized database does not rotate database credentials.

Copy the files and install the templates:

```bash
install -d -m 700 /mnt/user/appdata/nocturne
install -m 600 /tmp/nocturne-private/config/*.env /mnt/user/appdata/nocturne/
install -m 755 /tmp/nocturne-private/config/00-init.sh /mnt/user/appdata/nocturne/
install -m 700 /tmp/nocturne-private/start.sh /mnt/user/appdata/nocturne/
install -m 600 /tmp/nocturne-private/templates/*.xml /boot/config/plugins/dockerMan/templates-user/
bash /mnt/user/appdata/nocturne/start.sh
```

`start.sh` creates the network and starts PostgreSQL, waits for the roles to exist, and starts API, Web and Gateway. Existing named containers are started without being replaced. The commands are generated from the XML templates. You can subsequently edit/recreate them in Unraid DockerMan. Alternatively create the network with `docker network create nocturne`, then install the four prepared templates in numerical order through **Docker → Add Container → Template**. Wait for PostgreSQL to finish its initial bootstrap before starting the API.

The four `.env` files live on the host and are consumed through `--env-file` in Extra Parameters. DockerMan retains this when recreating containers. The database path and gateway port are visible in the normal template UI; internal URLs and secrets stay in the host files. If you change the hostname, update it in both API and Web templates and their environment files, plus the gateway WebUI metadata.

No PUID/PGID overrides are used: PostgreSQL initializes its own data ownership. No Docker socket, privileged mode, Watchtower, bundled Caddy or host networking is required. API, Web and PostgreSQL publish no host ports. Gateway publishes HTTP port **1612 → 5000**. A dedicated Docker network isolates name resolution from other application stacks; it does not block outbound internet access needed by CGM connectors.

## HTTPS reverse proxy

Forward `https://gluco.example.com` to `http://UNRAID-IP:1612`. Enable WebSockets and forward the original Host, X-Forwarded-Host and X-Forwarded-Proto. Restrict access to the gateway port to your trusted LAN/proxy; forwarded client headers are trusted on this deployment path.

For nginx/Nginx Proxy Manager, the equivalent headers are:

```nginx
proxy_set_header Host $host;
proxy_set_header X-Forwarded-Host $host;
proxy_set_header X-Forwarded-Proto $scheme;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
```

Nocturne's setup page sends large response headers. For nginx/Nginx Proxy Manager, also set `proxy_buffer_size 64k;`, `proxy_buffers 8 64k;` and `proxy_busy_buffers_size 128k;` at server scope. Otherwise `/setup` can fail with `upstream sent too big header` and HTTP 502.

Nginx Proxy Manager already supplies most headers, but its generated custom-location template may overwrite X-Forwarded-Proto. For a dedicated HTTPS hostname behind a Cloudflare Tunnel, use one explicit `location /` in Advanced configuration with the headers above, WebSocket headers and your gateway `proxy_pass`. Use `https` for the forwarded protocol when the tunnel reaches NPM over HTTP. Keep the database's advanced configuration in sync with the generated nginx file; editing only the file is not persistent. A plain IP HTTP URL is useful for connectivity checks, but not for completing passkey login. For multi-tenant deployments, the upstream domain and wildcard certificate requirements also apply; this package targets one household instance at its existing hostname.

## First login and existing Nightscout

Visit the HTTPS hostname and complete Nocturne's setup wizard. Register your own passkey and save the recovery codes. A fresh API may return `503 setup_required` until setup completes; this is expected.

Keep Nightscout and MongoDB intact during evaluation. Nocturne has a Nightscout connector and migration facilities, but client tokens, accounts and all integrations are not assumed to transfer automatically. Verify data import, current values, device uploads and any follower applications before retiring Nightscout. Importing old readings alone does not establish a continuing sensor feed.

## Backups, upgrades and removal

Back up all private environment files and take consistent PostgreSQL backups with `pg_dump`, or stop the stack before copying its database directory. Secret files and backups must never be committed to the public template repository. Protect the Unraid flash backup too: Docker templates can contain your hostname and host paths.

API and Web are pinned together to `0.2.7`. PostgreSQL follows `17-bookworm` for patch updates within major version 17. YARP uses the upstream `2.3-preview` tag; the live deployment records its resolved digest. Before publication, review current database patch releases and gateway availability. Updates are explicit; test and back up before changing tags. Major PostgreSQL upgrades require a database migration, not simply replacing the image.

Removing containers does not remove `/mnt/user/appdata/nocturne`. Do not delete it unless you intend to remove your Nocturne data. To revert a domain switch, restore its original reverse-proxy destination and leave Nightscout running.

## Maintainer verification

`python3 build_templates.py` regenerates the XML and Docker start script using the checked-in JSON representation of the upstream release. Only Python's standard library is needed. Generated environment files contain placeholders; `prepare.sh` fills them without Python on Unraid.

Sanitized validation notes are in `VALIDATION.md`; source provenance is in `UPSTREAM.md`.

## Optional automatic updates

`auto-update.sh` checks the latest stable upstream GitHub release and updates API and Web to the same explicit version. PostgreSQL follows `17-bookworm`, allowing PostgreSQL 17 patch releases while holding the database major version at 17. Gateway follows the reviewed upstream YARP tag. The script pulls all target images before downtime, stops application writers, saves a PostgreSQL dump and configuration, and uses Unraid's native update tool to recreate containers. A failed application check triggers restoration of the saved images and database. Rollback images are local and do not depend on the registry being online. Backup and update logs remain in appdata; review these periodically.

Installed templates use Unraid's canonical `my-<container-name>.xml` filenames, including when generated by prepare.sh. Copy `auto-update.sh` and `refresh-unraid.php` to your appdata directory before enabling updates. Run `bash auto-update.sh --check` first; it only reports desired tags. Run the updater once manually and verify the installation before scheduling it.

On Unraid, a file `/boot/config/plugins/dynamix/nocturne.cron` can hold a normal cron entry calling the updater. Run `update_cron` to apply it; Unraid restores these plugin cron entries after reboot. Schedule interpretation follows the server timezone. No separate Watchtower instance or recurring Codex chat is needed.
