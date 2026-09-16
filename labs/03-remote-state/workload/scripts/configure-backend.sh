#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 <bucket> <region> <state-key>" >&2
  exit 2
}

[[ $# -eq 3 ]] || usage
bucket=$1
region=$2
state_key=$3

[[ $bucket =~ ^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$ ]] || { echo "Invalid S3 bucket name" >&2; exit 2; }
[[ $region =~ ^[a-z]{2}(-gov)?-[a-z]+-[0-9]$ ]] || { echo "Invalid AWS region" >&2; exit 2; }
[[ $state_key != /* && $state_key == *.tfstate && $state_key != *..* ]] || { echo "Invalid state key" >&2; exit 2; }

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
workload_dir=$(cd -- "$script_dir/.." && pwd)

if [[ -e "$workload_dir/backend.tf" || -e "$workload_dir/backend.hcl" ]]; then
  echo "backend.tf or backend.hcl already exists; refusing to overwrite" >&2
  exit 1
fi

cp "$workload_dir/backend.tf.example" "$workload_dir/backend.tf"
cat > "$workload_dir/backend.hcl" <<EOF
bucket       = "$bucket"
key          = "$state_key"
region       = "$region"
encrypt      = true
use_lockfile = true
EOF

chmod 600 "$workload_dir/backend.hcl"
echo "Created $workload_dir/backend.tf and backend.hcl"
echo "Review both files, then run scripts/migrate-to-remote.sh"
