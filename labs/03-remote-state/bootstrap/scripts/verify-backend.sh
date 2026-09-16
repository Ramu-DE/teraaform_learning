#!/usr/bin/env bash
set -euo pipefail

[[ $# -eq 1 ]] || { echo "Usage: $0 <bucket>" >&2; exit 2; }
bucket=$1

echo "== Versioning =="
aws s3api get-bucket-versioning --bucket "$bucket"
echo "== Encryption =="
aws s3api get-bucket-encryption --bucket "$bucket"
echo "== Public access block =="
aws s3api get-public-access-block --bucket "$bucket"
echo "== Public policy status =="
aws s3api get-bucket-policy-status --bucket "$bucket"
