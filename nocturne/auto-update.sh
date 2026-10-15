#!/usr/bin/env bash
# Native Unraid updates. API/Web follow matching stable GitHub release tags.
set -Eeuo pipefail
umask 077
APPDATA=${NOCTURNE_APPDATA:-/mnt/user/appdata/nocturne}
TEMPLATES=/boot/config/plugins/dockerMan/templates-user
UPDATER=/usr/local/emhttp/plugins/dynamix.docker.manager/scripts/update_container
exec 9>/var/lock/nocturne-update.lock
flock -n 9 || exit 0
names=(nocturne-postgres-server nocturne-api nocturne-web nocturne-gateway)
files=(my-nocturne-postgres-server.xml my-nocturne-api.xml my-nocturne-web.xml my-nocturne-gateway.xml)
release=$(curl --fail --silent --show-error --location --max-time 45 https://api.github.com/repos/nightscout/nocturne/releases/latest | php -r '$d=json_decode(stream_get_contents(STDIN),true);if(empty($d["tag_name"])||!empty($d["prerelease"])||!empty($d["draft"]))exit(1);echo $d["tag_name"];')
[[ "$release" =~ ^v?([0-9]+\.[0-9]+\.[0-9]+)$ ]] || { echo 'Invalid stable release'; exit 1; }
version=${BASH_REMATCH[1]}
images=(postgres:17-bookworm "ghcr.io/nightscout/nocturne/nocturne-api:$version" "ghcr.io/nightscout/nocturne/nocturne-web:$version" mcr.microsoft.com/dotnet/nightly/yarp:2.3-preview)
changed=0
for i in "${!names[@]}"; do
 [[ -f "$TEMPLATES/${files[$i]}" ]] || { echo "Missing template ${files[$i]}"; exit 1; }
 docker container inspect "${names[$i]}" >/dev/null
 current=$(docker inspect --format '{{.Config.Image}}' "${names[$i]}")
 if [[ "$i" == 1 || "$i" == 2 ]]; then
  current_version=${current##*:}
  php -r 'exit(version_compare($argv[1],$argv[2],"<")?1:0);' "$version" "$current_version" || { echo 'Refusing release downgrade'; exit 1; }
 fi
 if [[ "${1:-}" == --check ]]; then echo "${names[$i]}: $current -> ${images[$i]}"; continue; fi
 docker pull "${images[$i]}" >/dev/null
 old=$(docker inspect --format '{{.Image}}' "${names[$i]}")
 new=$(docker image inspect --format '{{.Id}}' "${images[$i]}")
 [[ "$old" == "$new" && "$current" == "${images[$i]}" ]] || changed=1
 done
[[ "${1:-}" == --check ]] && exit 0
if [[ "$changed" == 0 ]]; then php "$APPDATA/refresh-unraid.php"; echo "Already current: Nocturne $version"; exit 0; fi
stamp=$(date -u +%Y%m%dT%H%M%SZ)
backup="$APPDATA/update-backups/$stamp"
mkdir -p "$backup"
for i in "${!names[@]}"; do
 cp "$TEMPLATES/${files[$i]}" "$backup/${files[$i]}"
 docker inspect "${names[$i]}" > "$backup/${names[$i]}.json"
 docker tag "$(docker inspect --format '{{.Image}}' "${names[$i]}")" "nocturne-rollback/${names[$i]}:$stamp"
done
cp "$APPDATA"/*.env "$backup/"
restore_templates() { for file in "${files[@]}"; do cp "$backup/$file" "$TEMPLATES/$file"; done; }
# Stop all application writers before taking the database snapshot.
docker stop nocturne-gateway nocturne-web nocturne-api >/dev/null
snapshot=0
rollback() {
 local rc=$?
 trap - ERR
 echo "Update failed (exit $rc); restoring previous stack. Backup: $backup" >&2
 docker stop nocturne-gateway nocturne-web nocturne-api >/dev/null 2>&1 || true
 restore_templates
 for i in "${!names[@]}"; do
  php -r '$f=$argv[1];$x=simplexml_load_file($f);$x->Repository=$argv[2];$x->asXML($f);' "$TEMPLATES/${files[$i]}" "nocturne-rollback/${names[$i]}:$stamp"
 done
 /usr/local/emhttp/plugins/dynamix.docker.manager/scripts/rebuild_container nocturne-postgres-server > "$backup/rollback-postgres.log" 2>&1 || true
 docker start nocturne-postgres-server >/dev/null
 for attempt in {1..120}; do docker exec nocturne-postgres-server pg_isready -U nocturne -d nocturne >/dev/null 2>&1 && break; sleep 2; done
 if [[ "$snapshot" == 1 ]]; then
  docker exec -i nocturne-postgres-server sh -c 'export PGPASSWORD="$POSTGRES_PASSWORD"; pg_restore -h 127.0.0.1 -U "$POSTGRES_USER" --clean --if-exists --exit-on-error -d nocturne' < "$backup/nocturne.dump" || { echo 'Database restore failed; stack remains stopped' >&2; exit 1; }
 fi
 for name in nocturne-api nocturne-web nocturne-gateway; do /usr/local/emhttp/plugins/dynamix.docker.manager/scripts/rebuild_container "$name" > "$backup/rollback-$name.log" 2>&1 || true; docker start "$name" >/dev/null; done
 restore_templates
 logger -t nocturne-update "Update failed; previous images and database restored; see $backup"
 exit 1
}
trap rollback ERR
docker exec nocturne-postgres-server sh -c 'export PGPASSWORD="$POSTGRES_PASSWORD"; pg_dump -h 127.0.0.1 -U "$POSTGRES_USER" -Fc nocturne' > "$backup/nocturne.dump"
[[ -s "$backup/nocturne.dump" ]]
snapshot=1
for i in "${!names[@]}"; do
 php -r '$f=$argv[1];$x=simplexml_load_file($f);$x->Repository=$argv[2];$x->asXML($f);' "$TEMPLATES/${files[$i]}" "${images[$i]}"
 "$UPDATER" "${names[$i]}" ca_docker_run_override > "$backup/update-${names[$i]}.log" 2>&1
 if [[ "$i" == 0 ]]; then
  ready=0
  for attempt in {1..120}; do if docker exec nocturne-postgres-server pg_isready -U nocturne -d nocturne >/dev/null 2>&1; then ready=1; break; fi; sleep 2; done
  [[ "$ready" == 1 ]]
 fi
done
ready=0
for attempt in {1..120}; do
 if docker exec nocturne-web node -e 'fetch("http://nocturne-api:8080/api/auth/passkey/status",{headers:{Host:process.env.BASE_DOMAIN}}).then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))' >/dev/null 2>&1; then ready=1; break; fi
 sleep 2
done
[[ "$ready" == 1 ]]
for i in "${!names[@]}"; do
 [[ "$(docker inspect --format '{{.Image}}' "${names[$i]}")" == "$(docker image inspect --format '{{.Id}}' "${images[$i]}")" ]]
done
trap - ERR
php "$APPDATA/refresh-unraid.php"
logger -t nocturne-update "Nocturne updated to $version; database backup: $backup"
echo "Success: Nocturne $version. Backup: $backup"
