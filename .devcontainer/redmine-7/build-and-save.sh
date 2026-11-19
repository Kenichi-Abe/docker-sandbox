#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="${REPO_ROOT:-/workspaces/docker-sandbox/.devcontainer/redmine-7}"
dockerfile="$repo_root/markitdown-image/Dockerfile"
plugins_dir="$repo_root/plugins"
base_image="docker.io/library/redmine:7.0.3"
build_image="localhost/redmine-markitdown:7.0.3"
deploy_image="docker.io/library/redmine:7.0.3"
tar_path="$repo_root/redmine-app-7.0.3.tar"
database_image="docker.io/percona/percona-server:8.4.11"
database_tar_path="$repo_root/redmine-db-8.4.11.tar"
app_tar_tmp="${tar_path}.tmp.$$"
database_tar_tmp="${database_tar_path}.tmp.$$"
trap 'rm -f -- "$app_tar_tmp" "$database_tar_tmp"' EXIT

command -v docker >/dev/null 2>&1 || {
  echo "docker CLI is required." >&2
  exit 1
}

docker info >/dev/null
[[ -f "$dockerfile" ]] || {
  echo "Redmine Dockerfile not found: $dockerfile" >&2
  exit 1
}
mkdir -p "$(dirname -- "$tar_path")"
mkdir -p "$plugins_dir"

plugin_ids=()
for plugin_dir in "$plugins_dir"/*; do
  [[ -d "$plugin_dir" ]] || continue
  plugin_id="${plugin_dir##*/}"
  [[ -f "$plugin_dir/init.rb" ]] || {
    echo "Redmine plugin is missing init.rb: $plugin_dir" >&2
    exit 1
  }
  registered_id=$(sed -nE '/^[[:space:]]*Redmine::Plugin\.register[[:space:]]+:/ { s/^[[:space:]]*Redmine::Plugin\.register[[:space:]]+:([[:alnum:]_]+).*/\1/p; q; }' "$plugin_dir/init.rb")
  if [[ -n "$registered_id" && "$registered_id" != "$plugin_id" ]]; then
    echo "Plugin directory '$plugin_id' does not match init.rb registration '$registered_id'. Rename it to '$registered_id'." >&2
    exit 1
  fi
  plugin_ids+=("$plugin_id")
done

if ((${#plugin_ids[@]})); then
  printf 'Including Redmine plugins: %s\n' "${plugin_ids[*]}"
else
  echo "No local Redmine plugins found; building without plugins."
fi

echo "Removing existing local Redmine image tags"
images_to_remove=(
  "$base_image"
  "$build_image"
  "docker.io/library/redmine-app:7.0.3"
  "localhost/redmine:7.0.3"
  "localhost/redmine-app:7.0.3"
  "localhost/redmine-markitdown:7.0.3"
)
for image in "${images_to_remove[@]}"; do
  if docker image inspect "$image" >/dev/null 2>&1; then
    docker image rm --force "$image"
  fi
done

echo "Pulling $base_image"
docker pull --platform linux/amd64 "$base_image"

echo "Pulling $database_image"
docker pull --platform linux/amd64 "$database_image"
database_version=$(docker run --rm --platform linux/amd64 \
  --entrypoint mysqld \
  "$database_image" --version)
printf '%s\n' "$database_version"
[[ "$database_version" == *"8.4.11"* ]] || {
  echo "Expected Percona Server 8.4.11, got: $database_version" >&2
  exit 1
}

echo "Building $build_image"
docker build --platform linux/amd64 \
  --tag "$build_image" \
  --file "$dockerfile" \
  "$repo_root"

echo "Checking Python and MarkItDown"
docker run --rm --platform linux/amd64 \
  --entrypoint pandoc \
  "$build_image" --version
docker run --rm --platform linux/amd64 \
  --entrypoint /opt/markitdown-venv/bin/python \
  "$build_image" -c 'import markitdown; print(markitdown.__file__)'
docker run --rm --platform linux/amd64 \
  --entrypoint /opt/markitdown-venv/bin/markitdown \
  "$build_image" --help >/dev/null
docker run --rm --platform linux/amd64 \
  --entrypoint bundle \
  "$build_image" check
printf 'Codespaces smoke test\n' | docker run --rm -i --platform linux/amd64 \
  --entrypoint /opt/markitdown-venv/bin/markitdown \
  "$build_image"
if ((${#plugin_ids[@]})); then
  docker run --rm --platform linux/amd64 \
    --entrypoint bash \
    "$build_image" -c '
      for plugin_id in "$@"; do
        test -f "/usr/src/redmine/plugins/$plugin_id/init.rb" || {
          echo "Plugin was not copied into the image: $plugin_id" >&2
          exit 1
        }
      done
    ' bash "${plugin_ids[@]}"
fi

if [[ -f "$plugins_dir/redmine_omniauth_oidc/initializers/redmine_omniauth_oidc.rb" ]]; then
  docker run --rm --platform linux/amd64 \
    --entrypoint test \
    "$build_image" -f /usr/src/redmine/config/initializers/redmine_omniauth_oidc.rb
fi

docker run --rm --platform linux/amd64 \
  --entrypoint bash \
  "$build_image" -c '
    controller=/usr/src/redmine/plugins/redmine_omniauth_oidc/lib/redmine_omniauth_oidc/account_controller_patch.rb
    grep -Fq "find_user_by_login_case_insensitive" "$controller"
    ruby -c "$controller"
  '

echo "Tagging $build_image as $deploy_image"
docker image tag "$build_image" "$deploy_image"

echo "Removing temporary build tag $build_image"
docker image rm "$build_image"

echo "Saving image archives"
docker save --output "$app_tar_tmp" "$deploy_image"
docker save --output "$database_tar_tmp" "$database_image"
mv -- "$database_tar_tmp" "$database_tar_path"
mv -- "$app_tar_tmp" "$tar_path"
sha256sum "$tar_path" "$database_tar_path"

echo "Image archives ready:"
echo "  $tar_path"
echo "  $database_tar_path"
echo "Transfer both tars to the Ansible repository after leaving Codespaces."
