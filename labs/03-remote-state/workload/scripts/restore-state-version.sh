#!/usr/bin/env bash
set -euo pipefail

[[ $# -eq 3 ]] || { echo "Usage: $0 <bucket> <state-key> <version-id>" >&2; exit 2; }
bucket=$1
state_key=$2
version_id=$3
lock_key="${state_key}.tflock"

expected_confirmation="$bucket/$state_key@$version_id"
if [[ ${CONFIRM_STATE_RESTORE:-} != "$expected_confirmation" ]]; then
  echo "Refusing restore. Inspect the version first, stop all Terraform processes, then set:" >&2
  echo "CONFIRM_STATE_RESTORE='$expected_confirmation'" >&2
  exit 1
fi

if aws s3api head-object --bucket "$bucket" --key "$lock_key" >/dev/null 2>&1; then
  echo "Lock object s3://$bucket/$lock_key exists; do not restore while an operation may be active." >&2
  exit 1
fi

workdir=$(mktemp -d)
chmod 700 "$workdir"
trap 'rm -rf "$workdir"' EXIT
state_file="$workdir/restored.tfstate"

aws s3api get-object \
  --bucket "$bucket" \
  --key "$state_key" \
  --version-id "$version_id" \
  "$state_file" >/dev/null
chmod 600 "$state_file"

terraform show -json "$state_file" >/dev/null

aws s3api put-object \
  --bucket "$bucket" \
  --key "$state_key" \
  --body "$state_file" \
  --server-side-encryption AES256

echo "Historical content restored as a new S3 object version. Run terraform plan before any apply."
