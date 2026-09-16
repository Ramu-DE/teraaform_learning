#!/usr/bin/env bash
set -euo pipefail

seconds=${1:-20}
[[ $seconds =~ ^[0-9]+$ ]] && (( seconds >= 1 && seconds <= 60 )) || {
  echo "Usage: $0 [seconds: 1-60]" >&2
  exit 2
}

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
workload_dir=$(cd -- "$script_dir/.." && pwd)

generation=$(date +%s)
cd "$workload_dir"
echo "Holding the Terraform state lock for approximately $seconds seconds."
echo "In another terminal run: terraform plan -lock-timeout=2s"
terraform apply -auto-approve \
  -replace=terraform_data.lock_probe \
  -var="lock_probe_generation=$generation" \
  -var="lock_hold_seconds=$seconds"
