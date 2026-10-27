#!/usr/bin/env bash
# Apply one literal mutation without discarding uncommitted source changes.
set -euo pipefail

invalid() { printf 'mutate-check: %s\n' "$1" >&2; exit 2; }
[ "$#" -ge 5 ] || invalid 'expected <file> <old> <new> -- <test command> [args...]'
file="$1"
old="$2"
new="$3"
shift 3
[ "$1" = -- ] || invalid 'missing -- before test command'
shift
[ "$#" -gt 0 ] && [ -n "$1" ] || invalid 'test command is empty'
[ -f "$file" ] || invalid 'source is not a regular file'
[ -w "$file" ] || invalid 'source is not writable'
[ -n "$old" ] || invalid 'old string is empty'
case "$file" in
  /*) ;;
  *) file="./$file" ;;
esac

# Work in bytes, including NULs and non-UTF-8 source; argv strings are literal.
python3 -I - "$file" "$old" "$new" <<'PY' || exit 2
import os
import sys

try:
    with open(sys.argv[1], 'rb') as source:
        data = source.read()
    old, new = map(os.fsencode, sys.argv[2:])
    first = data.find(old)
    if first < 0 or data.find(old, first + 1) >= 0:
        raise ValueError('old string must occur exactly once')
    if old == new:
        raise ValueError('replacement would not change the file')
except (OSError, ValueError) as error:
    print(f'mutate-check: {error}', file=sys.stderr)
    sys.exit(2)
PY

tmp="$(mktemp -d "${TMPDIR:-/tmp}/mutate-check.XXXXXX")"
backup="$tmp/original"
if ! cp "$file" "$backup"; then
  rm -rf "$tmp"
  invalid 'could not back up source'
fi
result=''
# Called indirectly by the EXIT trap.
# shellcheck disable=SC2329
restore() {
  local status="$?"
  trap - EXIT
  trap '' INT QUIT TERM
  if ! cp "$backup" "$file" || ! cmp -s "$backup" "$file"; then
    printf 'mutate-check: RESTORE FAILED — original is at %s\n' "$backup" >&2
    exit 3
  fi
  rm -rf "$tmp"
  if [ -n "$result" ]; then
    printf '%s\n' "$result"
  fi
  exit "$status"
}
trap restore EXIT
trap 'exit 130' INT
trap 'exit 131' QUIT
trap 'exit 143' TERM

python3 -I - "$file" "$backup" "$old" "$new" <<'PY'
import os
import sys

with open(sys.argv[2], 'rb') as source:
    data = source.read()
old, new = map(os.fsencode, sys.argv[3:])
with open(sys.argv[1], 'wb') as source:
    source.write(data.replace(old, new, 1))
PY
if cmp -s "$backup" "$file"; then
  invalid 'mutation did not change source'
fi

status=0
"$@" || status="$?"
if [ "$status" -ne 0 ]; then
  result="mutate-check: KILLED — the tests failed with the mutation (exit $status)"
  exit 0
fi
result='mutate-check: SURVIVED — the tests passed with the mutation applied'
exit 1
