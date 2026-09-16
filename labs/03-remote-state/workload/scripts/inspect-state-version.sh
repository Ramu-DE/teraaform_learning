#!/usr/bin/env bash
set -euo pipefail

[[ $# -eq 3 ]] || { echo "Usage: $0 <bucket> <state-key> <version-id>" >&2; exit 2; }
bucket=$1
state_key=$2
version_id=$3

workdir=$(mktemp -d)
chmod 700 "$workdir"
trap 'rm -rf "$workdir"' EXIT
state_file="$workdir/selected.tfstate"

aws s3api get-object \
  --bucket "$bucket" \
  --key "$state_key" \
  --version-id "$version_id" \
  "$state_file" >/dev/null
chmod 600 "$state_file"

# State can contain secrets. Display remains in the current terminal only and
# the temporary file is removed on exit.
terraform show -no-color "$state_file"
