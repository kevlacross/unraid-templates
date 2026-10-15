# Unraid Community Applications templates

Community-maintained Unraid DockerMan templates by kevlacross.

## Applications

| Application | Templates | Installation |
|---|---|---|
| Ecowitt Share to MQTT | MQTT bridge and Home Assistant discovery | [Ecowitt setup guide](ecowitt/README.md) |
| Nocturne | PostgreSQL, API, Web and gateway | [Nocturne setup guide](nocturne/README.md) |

`templates/` holds the public Community Applications XML files, one per container. `nocturne/` holds the preparation script, database bootstrap, optional automatic updater, validation and source provenance.

**Nocturne needs preparation before installation.** Run its preparation script to generate private credentials and host configuration; install all four containers on the dedicated network. Clicking a single component in CA without completing the prerequisites will not produce a working installation. These are native DockerMan templates, not an Unraid 8 Compose package.

For local installation without a CA listing, follow the setup guide: it generates canonical `my-<container>.xml` files for `/boot/config/plugins/dockerMan/templates-user/`.

## Support

For template, packaging and installation issues, [open an issue](https://github.com/kevlacross/unraid-templates/issues). Application bugs belong to the relevant upstream project. This repository is community packaging and is not endorsed by Nocturne, Nightscout or Unraid.

Ecowitt and Nocturne templates are consolidated here. The former Ecowitt-only template repository is retained during the CA catalog migration; the application source repository remains separate.

## Validation

```bash
python3 nocturne/build_templates.py
python3 nocturne/validate.py
bash -n nocturne/prepare.sh nocturne/auto-update.sh nocturne/start.sh.in
```

See [validation results](nocturne/VALIDATION.md). Source and license notices are in [UPSTREAM.md](nocturne/UPSTREAM.md) and [NOTICE.md](nocturne/NOTICE.md).

## License

AGPL-3.0-or-later for Nocturne packaging and new repository material. The imported Ecowitt template and icon retain their original MIT license in ecowitt/LICENSE. Retain the upstream attribution in NOTICE.md. Application images are downloaded from their publishers and are not redistributed here.
