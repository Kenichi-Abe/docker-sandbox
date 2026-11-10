#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="${REPO_ROOT:-/workspaces/docker-sandbox/.devcontainer/redmine-7}"
dockerfile="$repo_root/markitdown-image/Dockerfile"
base_image="docker.io/library/redmine:7.0.3"
build_image="localhost/redmine-markitdown:7.0.3"
deploy_image="docker.io/library/redmine:7.0.3"
tar_path="$repo_root/redmine-app-7.0.3.tar"

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

echo "Building $build_image"
docker build --platform linux/amd64 \
  --tag "$build_image" \
  --file "$dockerfile" \
  "$repo_root"

echo "Checking Python and MarkItDown"
docker run --rm --platform linux/amd64 \
  --entrypoint /opt/markitdown-venv/bin/python \
  "$build_image" -c 'import markitdown; print(markitdown.__file__)'
docker run --rm --platform linux/amd64 \
  --entrypoint /opt/markitdown-venv/bin/markitdown \
  "$build_image" --help >/dev/null
printf 'Codespaces smoke test\n' | docker run --rm -i --platform linux/amd64 \
  --entrypoint /opt/markitdown-venv/bin/markitdown \
  "$build_image"

echo "Tagging $build_image as $deploy_image"
docker image tag "$build_image" "$deploy_image"

echo "Saving $tar_path"
docker save --output "$tar_path" "$build_image" "$deploy_image"
sha256sum "$tar_path"

echo "Image archive ready: $tar_path"
echo "Transfer this tar to the Ansible repository after leaving Codespaces."
