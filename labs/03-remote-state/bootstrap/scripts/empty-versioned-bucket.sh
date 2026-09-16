#!/usr/bin/env bash
set -euo pipefail

[[ $# -eq 1 ]] || { echo "Usage: $0 <bucket>" >&2; exit 2; }
bucket=$1

if [[ ${CONFIRM_EMPTY_VERSIONED_BUCKET:-} != "$bucket" ]]; then
  echo "DANGER: this permanently deletes every object version and delete marker in $bucket." >&2
  echo "Set CONFIRM_EMPTY_VERSIONED_BUCKET='$bucket' only after state is migrated elsewhere and backups are verified." >&2
  exit 1
fi

workdir=$(mktemp -d)
chmod 700 "$workdir"
trap 'rm -rf "$workdir"' EXIT
versions_json="$workdir/versions.json"
delete_json="$workdir/delete.json"

aws s3api list-object-versions --bucket "$bucket" > "$versions_json"
python3 - "$versions_json" "$delete_json" <<'PY'
import json, sys
source, destination = sys.argv[1:]
data = json.load(open(source))
objects = [
    {"Key": item["Key"], "VersionId": item["VersionId"]}
    for group in ("Versions", "DeleteMarkers")
    for item in data.get(group, [])
]
if len(objects) > 1000:
    raise SystemExit("More than 1000 versions found; aborting rather than performing partial cleanup")
json.dump({"Objects": objects, "Quiet": False}, open(destination, "w"))
print(f"OBJECT_VERSIONS_SELECTED={len(objects)}")
PY

count=$(python3 -c 'import json,sys; print(len(json.load(open(sys.argv[1]))["Objects"]))' "$delete_json")
if [[ $count -eq 0 ]]; then
  echo "Bucket is already empty."
  exit 0
fi

aws s3api delete-objects --bucket "$bucket" --delete "file://$delete_json"
echo "Deleted $count object versions/delete markers. Re-run without assuming the bucket is empty until list-object-versions confirms it."
