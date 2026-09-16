#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
workload_dir=$(cd -- "$script_dir/.." && pwd)

[[ -f "$workload_dir/backend.tf" ]] || { echo "Missing backend.tf; run configure-backend.sh first" >&2; exit 1; }
[[ -f "$workload_dir/backend.hcl" ]] || { echo "Missing backend.hcl; run configure-backend.sh first" >&2; exit 1; }

cd "$workload_dir"
echo "Migrating local state to the reviewed S3 backend. Terraform will request confirmation."
terraform init -migrate-state -backend-config=backend.hcl
terraform state list
terraform plan -detailed-exitcode || rc=$?
rc=${rc:-0}
if [[ $rc -eq 1 ]]; then exit 1; fi
if [[ $rc -eq 2 ]]; then echo "Migration completed, but desired changes remain; review before apply."; fi
