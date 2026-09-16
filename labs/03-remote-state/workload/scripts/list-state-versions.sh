#!/usr/bin/env bash
set -euo pipefail

[[ $# -eq 2 ]] || { echo "Usage: $0 <bucket> <state-key>" >&2; exit 2; }
bucket=$1
state_key=$2

aws s3api list-object-versions \
  --bucket "$bucket" \
  --prefix "$state_key" \
  --query "Versions[?Key=='$state_key'].[IsLatest,VersionId,LastModified,Size]" \
  --output table
