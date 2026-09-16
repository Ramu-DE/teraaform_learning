#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
workload_dir=$(cd -- "$script_dir/.." && pwd)
backend_tf="$workload_dir/backend.tf"
disabled_tf="$workload_dir/backend.tf.remote-disabled"

[[ -f "$backend_tf" ]] || { echo "No active backend.tf was found" >&2; exit 1; }
[[ ! -e "$disabled_tf" ]] || { echo "$disabled_tf already exists; resolve it manually" >&2; exit 1; }

mv "$backend_tf" "$disabled_tf"
restore_backend() {
  if [[ -f "$disabled_tf" ]]; then mv "$disabled_tf" "$backend_tf"; fi
}
trap restore_backend ERR INT TERM

cd "$workload_dir"
echo "Migrating S3 state back to the local backend. Terraform will request confirmation."
terraform init -migrate-state
rm -f "$disabled_tf" "$workload_dir/backend.hcl"
trap - ERR INT TERM

echo "Remote backend disabled. Verify local state, then clean up the S3 workload objects before backend destruction."
terraform state list
