#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="${REPO_ROOT:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)}"
dockerfile="$repo_root/Dockerfile"
image="docker.io/library/ubi-minimal:9.2"
tar_path="$repo_root/ansible-ubi-minimal_9.2.tar"
tar_tmp="${tar_path}.tmp.$$"
trap 'rm -f -- "$tar_tmp"' EXIT

command -v docker >/dev/null 2>&1 || {
  echo "docker CLI is required." >&2
  exit 1
}

docker info >/dev/null
[[ -f "$dockerfile" ]] || {
  echo "Ansible environment Dockerfile not found: $dockerfile" >&2
  exit 1
}

echo "Building $image"
docker build --platform linux/amd64 \
  --tag "$image" \
  --file "$dockerfile" \
  "$repo_root"

echo "Checking Ansible and Python dependencies"
docker run --rm --platform linux/amd64 "$image" ansible --version
docker run --rm --platform linux/amd64 "$image" ansible-galaxy collection list
docker run --rm --platform linux/amd64 "$image" python3.11 -c 'import openpyxl; print(openpyxl.__version__)'

echo "Saving image archive"
docker save --output "$tar_tmp" "$image"
mv -- "$tar_tmp" "$tar_path"
sha256sum "$tar_path"

echo "Image archive ready:"
echo "  $tar_path"