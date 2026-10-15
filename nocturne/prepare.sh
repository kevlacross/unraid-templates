#!/usr/bin/env bash
# Generate private files and installable DockerMan templates. Does not start containers.
set -euo pipefail
umask 077
SOURCE=$(cd -- "$(dirname -- "$0")" && pwd)
DOMAIN=${1:-}
APPDATA=${2:-/mnt/user/appdata/nocturne}
OUTPUT=${3:-$SOURCE/private}
if [[ ! "$DOMAIN" =~ ^[a-z0-9]([a-z0-9.-]*[a-z0-9])?$ || "$DOMAIN" != *.* || "$DOMAIN" == *..* || "$DOMAIN" =~ ^[0-9.]+$ ]]; then
  echo 'Usage: bash prepare.sh hostname.example [/mnt/user/appdata/nocturne] [output-directory]' >&2; exit 1
fi
if [[ ! "$APPDATA" =~ ^/[a-zA-Z0-9_./-]+$ || "$APPDATA" == / || "$APPDATA" == *..* ]]; then
  echo 'Appdata must be an absolute path without spaces or shell metacharacters.' >&2; exit 1
fi
command -v openssl >/dev/null
if [[ -e "$OUTPUT" ]]; then echo "Output already exists: $OUTPUT. Keep existing credentials; do not overwrite them." >&2; exit 1; fi
mkdir -p "$OUTPUT/config" "$OUTPUT/templates"
BASE_DOMAIN=$DOMAIN
INSTANCE_KEY=$(openssl rand -hex 32)
POSTGRES_PASSWORD=$(openssl rand -hex 32)
POSTGRES_APP_PASSWORD=$(openssl rand -hex 32)
POSTGRES_MIGRATOR_PASSWORD=$(openssl rand -hex 32)
POSTGRES_WEB_PASSWORD=$(openssl rand -hex 32)
# Hex secrets need no shell, URL, connection-string, XML or sed escaping.
render() {
 sed -e "s|/mnt/user/appdata/nocturne|$APPDATA|g" -e "s|nocturne\.example\.com|$BASE_DOMAIN|g" -e "s|@APPDATA@|$APPDATA|g" -e "s|@BASE_DOMAIN@|$BASE_DOMAIN|g" \
  -e "s|@INSTANCE_KEY@|$INSTANCE_KEY|g" -e "s|@POSTGRES_PASSWORD@|$POSTGRES_PASSWORD|g" \
  -e "s|@POSTGRES_APP_PASSWORD@|$POSTGRES_APP_PASSWORD|g" \
  -e "s|@POSTGRES_MIGRATOR_PASSWORD@|$POSTGRES_MIGRATOR_PASSWORD|g" \
  -e "s|@POSTGRES_WEB_PASSWORD@|$POSTGRES_WEB_PASSWORD|g" "$1" > "$2"
}
for file in "$SOURCE"/config/*.env.in; do render "$file" "$OUTPUT/config/$(basename "${file%.in}")"; done
cp "$SOURCE/config/00-init.sh" "$OUTPUT/config/00-init.sh"
chmod 755 "$OUTPUT/config/00-init.sh"
for file in "$SOURCE"/../templates/0*-nocturne-*.xml; do
 name=$(sed -n 's/.*<Name>\(.*\)<\/Name>.*/\1/p' "$file")
 render "$file" "$OUTPUT/templates/my-$name.xml"
done
render "$SOURCE/start.sh.in" "$OUTPUT/start.sh"
chmod 700 "$OUTPUT/start.sh"
printf '%s\n' "Prepared private files in $OUTPUT" "Copy config files to $APPDATA and XML files to /boot/config/plugins/dockerMan/templates-user/." "Start order: PostgreSQL, API, Web, Gateway. See README.md for HTTPS configuration."
