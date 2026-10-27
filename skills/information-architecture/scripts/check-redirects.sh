#!/usr/bin/env bash
# Verify a CSV redirect map against a staging or production origin.
set -euo pipefail
usage() { echo 'usage: check-redirects.sh <map.csv> <base-url>' >&2; exit 2; }
[ "$#" -eq 2 ] || usage
map=$1
base=${2%/}
[[ "$base" =~ ^https?://(\[[0-9a-fA-F:]+\]|[a-zA-Z0-9.-]+)(:[0-9]+)?$ ]] || usage
if [ ! -f "$map" ] || [ ! -r "$map" ]; then
  echo 'check-redirects: map is not a readable file' >&2
  exit 2
fi
passed=0
failed=0
number=0
while IFS= read -r line || [ -n "$line" ]; do
  line=${line%$'\r'}
  number=$((number + 1))
  case "$line" in
    ''|'#'*) continue ;;
  esac
  if [ "$number" -eq 1 ] && { [ "$line" = old,new ] || [ "$line" = old_path,new_path ]; }; then
    continue
  fi
  if [[ ! "$line" =~ ^/[^,[:space:]]*,/[^,[:space:]]*$ ]]; then
    printf 'FAIL line %s: malformed\n' "$number"
    failed=$((failed + 1))
    continue
  fi
  old=${line%%,*}
  new=${line#*,}
  reason=
  if response=$("${CURL:-curl}" -sS -o /dev/null --max-redirs 0 -w '%{http_code} %{redirect_url}' "$base$old"); then
    status=${response%% *}
    location=${response#* }
    if [ "$status" != 301 ]; then
      reason="$status, expected 301"
    elif [ "$location" != "$base$new" ] && [ "$location" != "$new" ]; then
      reason="redirects to $location, expected $new"
    fi
  else
    reason='request failed'
  fi
  if response=$("${CURL:-curl}" -sS -o /dev/null --max-redirs 0 -w '%{http_code} %{redirect_url}' "$base$new"); then
    status=${response%% *}
    if [ -z "$reason" ] && [ "$status" != 200 ]; then
      case "$status" in
        3??) reason="target answered $status, expected 200 (a chain)" ;;
        *) reason="target answered $status" ;;
      esac
    fi
  elif [ -z "$reason" ]; then
    reason='target request failed'
  fi
  if [ -z "$reason" ]; then
    printf 'PASS %s -> %s\n' "$old" "$new"
    passed=$((passed + 1))
  else
    printf 'FAIL %s: %s\n' "$old" "$reason"
    failed=$((failed + 1))
  fi
done < "$map"
if [ "$((passed + failed))" -eq 0 ]; then
  echo 'check-redirects: the map has no redirect pairs' >&2
  exit 2
fi
printf 'check-redirects: %s passed, %s failed\n' "$passed" "$failed"
[ "$failed" -eq 0 ]
