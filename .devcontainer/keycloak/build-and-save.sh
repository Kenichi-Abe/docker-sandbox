#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="${REPO_ROOT:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)}"
image="${KEYCLOAK_IMAGE:-quay.io/keycloak/keycloak:26.8}"
custom_image="localhost/keycloak-remember-me:26.8"
database_image="${KEYCLOAK_DB_IMAGE:-docker.io/library/postgres:17}"
tar_path="$repo_root/keycloak.tar"
database_tar_path="$repo_root/keycloak-db.tar"
tar_tmp="${tar_path}.tmp.$$"
database_tar_tmp="${database_tar_path}.tmp.$$"
trap 'rm -f -- "$tar_tmp" "$database_tar_tmp"' EXIT

command -v docker >/dev/null 2>&1 || {
  echo "docker CLI is required." >&2
  exit 1
}

docker info >/dev/null

theme_properties="$repo_root/themes/speednet21/login/theme.properties"
remember_me_script="$repo_root/themes/speednet21/login/resources/js/remember-me.js"
[[ -f "$theme_properties" && -f "$remember_me_script" ]] || {
  echo "speednet21 login theme files are required." >&2
  exit 1
}
grep -Fq 'scripts=js/remember-me.js' "$theme_properties"
grep -Fq 'input[name="rememberMe"]' "$remember_me_script"

echo "Pulling $image"
docker pull --platform linux/amd64 "$image"
echo "Pulling $database_image"
docker pull --platform linux/amd64 "$database_image"

echo "Building $custom_image with the speednet21 login theme"
docker build --platform linux/amd64 \
  --build-arg "KEYCLOAK_IMAGE=$image" \
  --tag "$custom_image" \
  --file "$repo_root/Dockerfile" \
  "$repo_root"
docker run --rm --platform linux/amd64 \
  --entrypoint test \
  "$custom_image" -f /opt/keycloak/themes/speednet21/login/theme.properties
docker run --rm --platform linux/amd64 \
  --entrypoint test \
  "$custom_image" -f /opt/keycloak/themes/speednet21/login/resources/js/remember-me.js
docker image tag "$custom_image" "$image"
docker image rm "$custom_image"

echo "Saving image archives"
docker save --output "$tar_tmp" "$image"
docker save --output "$database_tar_tmp" "$database_image"
mv -- "$tar_tmp" "$tar_path"
mv -- "$database_tar_tmp" "$database_tar_path"
sha256sum "$tar_path" "$database_tar_path"

echo "Keycloak image archives ready:"
echo "  $tar_path"
echo "  $database_tar_path"