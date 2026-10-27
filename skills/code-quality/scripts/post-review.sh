#!/usr/bin/env bash
# Validate every anchor before posting: one bad line rejects the whole review.
# Usage: post-review.sh <owner/repo> <pr-number> <review.json> [--post]
# Input: {"body":"Review summary", "comments":[{"path":"a/b.ts","line":42,"side":"RIGHT",
#   "start_line":40,"start_side":"RIGHT","body":"Comment"}]}
# side defaults to RIGHT; optional start_side defaults to side. event may only be
# COMMENT (or absent); commit_id is set by this script and must not be supplied.
# Exits: 0 ok; 2 usage/invalid input; 3 anchor outside the diff; 4 missing tool;
# 5 GitHub call failed or head moved; 6 posted but read-back short.
set -euo pipefail
usage() { echo 'usage: post-review.sh <owner/repo> <pr-number> <review.json> [--post]' >&2; exit 2; }
if [ "$#" -lt 3 ] || [ "$#" -gt 4 ]; then usage; fi
repo=$1
pr=$2
input=$3
post=false
if [ "$#" -eq 4 ]; then
  [ "$4" = --post ] || usage
  post=true
fi
[[ "$repo" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] || usage
[[ "$pr" =~ ^[1-9][0-9]*$ ]] || usage
if [ ! -f "$input" ] || [ ! -r "$input" ]; then usage; fi
for tool in jq gh; do
  if ! command -v "$tool" > /dev/null 2>&1; then
    printf 'post-review: %s is required\n' "$tool" >&2
    exit 4
  fi
done

# Slurp to reject empty input and multiple JSON documents, not just syntax errors.
if ! review=$(jq -s -e 'if length == 1 then .[0] else error("expected one JSON object") end' < "$input"); then
  echo 'post-review: invalid JSON input' >&2
  exit 2
fi
# Normalize once so anchor validation and the POST use the same sides.
review=$(jq '
  if type == "object" and (.comments | type) == "array" then
    .comments |= map(if type == "object" then
      (if .side == null then .side = "RIGHT" else . end)
      | (if .start_side == null then .start_side = .side else . end)
      | if has("start_line") then .
        elif .start_side == null or .start_side == "LEFT" or .start_side == "RIGHT" then del(.start_side)
        else . end
    else . end)
  else . end
' <<< "$review")
problems=$(jq -r '
  def integer: if type == "number" then floor == . else false end;
  def side: . == "LEFT" or . == "RIGHT";
  if type != "object" then "post-review: input must be an object"
  else
    (if (.body | type) != "string" or .body == "" then "post-review: body must be a non-empty string" else empty end),
    (keys_unsorted[] | select(. != "body" and . != "comments" and . != "event" and . != "commit_id")
     | "post-review: unknown key \(.)"),
    (if has("commit_id") then "post-review: refuses input commit_id; this script sets it" else empty end),
    (if has("event") and .event != "COMMENT" then
       "post-review: refuses event \(.event); this script only posts COMMENT reviews" else empty end),
    (if (.comments | type) != "array" then "post-review: comments must be a non-empty array"
     elif (.comments | length) == 0 then "post-review: comments must be a non-empty array"
     else .comments | to_entries[] | .key as $i | .value |
       (if type != "object" then "must be an object"
        else
          (keys_unsorted[] | select(. != "path" and . != "line" and . != "side" and . != "start_line" and . != "start_side" and . != "body")
           | "unknown key \(.)"),
          (if (.path | type) != "string" then "path must be a string" else empty end),
          (if ((.line | integer) and .line >= 1) | not then "line must be an integer >= 1" else empty end),
          (if (.body | type) != "string" or .body == "" then "body must be a non-empty string" else empty end),
          (if has("side") and ((.side | side) | not) then "side must be LEFT or RIGHT" else empty end),
          (if has("start_line") and (((.start_line | integer) and (.line | integer) and .start_line < .line) | not)
           then "start_line must be an integer < line" else empty end),
          (if has("start_side") and ((.start_side | side) | not) then "start_side must be LEFT or RIGHT" else empty end)
        end) | "post-review: comment \($i): \(.)"
     end)
  end
' <<< "$review")
if [ -n "$problems" ]; then
  printf '%s\n' "$problems" >&2
  exit 2
fi
endpoint="repos/$repo/pulls/$pr"
sha=$(gh api "$endpoint" --jq .head.sha) || exit 5
files=$(gh api --paginate "$endpoint/files" --jq '.[] | {filename, patch}') || exit 5
bad=$(jq -nr --argjson review "$review" --arg sha "$sha" --slurpfile files /dev/stdin '
  def hunks:
    (.patch // "") | split("\n")[]
    | capture("^@@ -(?<left>[0-9]+)(,(?<left_count>[0-9]+))? \\+(?<right>[0-9]+)(,(?<right_count>[0-9]+))? @@")
    | {LEFT: [(.left | tonumber), ((.left_count // "1") | tonumber)],
       RIGHT: [(.right | tonumber), ((.right_count // "1") | tonumber)]};
  def inside($line; $side): .[$side] | $line >= .[0] and $line < (.[0] + .[1]);
  $review.comments | to_entries[] | .key as $i | .value as $c
  | $c.side as $side
  | $c.start_side as $start_side
  | [$files[] | select(.filename == $c.path)] as $matching
  | if any($matching[]; .patch == null) then
      "post-review: comment \($i) \($c.path): GitHub returned no patch (binary or too large); anchor it elsewhere or put the point in the review body"
    else
    [$matching[] | hunks
     | select(inside($c.line; $side))
     | select(if $c | has("start_line") then inside($c.start_line; $start_side) else true end)]
  | select(length == 0)
  | "post-review: comment \($i) \($c.path):\($c.start_line // $c.line) (\($side)) is outside the PR diff at \($sha)"
    end
' <<< "$files")
if [ -n "$bad" ]; then
  printf '%s\n' "$bad" >&2
  exit 3
fi
count=$(jq '.comments | length' <<< "$review")
if [ "$post" = false ]; then
  printf 'post-review: OK — %s comments validated against %s; re-run with --post to submit\n' "$count" "$sha"
  exit 0
fi
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
jq --arg sha "$sha" '. + {commit_id: $sha, event: "COMMENT"}' <<< "$review" > "$work/review.json"
head=$(gh api "$endpoint" --jq .head.sha) || exit 5
if [ "$head" != "$sha" ]; then
  printf 'post-review: head moved from %s to %s; re-run to validate against the new head\n' "$sha" "$head" >&2
  exit 5
fi
# Never retry a POST: it may already have succeeded despite a failed response.
response=$(gh api "$endpoint/reviews" --method POST --input "$work/review.json") || exit 5
if ! id=$(jq -er '.id | select(type == "number" and floor == .)' <<< "$response") ||
   ! url=$(jq -er '.html_url | strings | select(length > 0)' <<< "$response"); then
  echo 'post-review: invalid GitHub review response; do not retry without checking GitHub' >&2
  exit 5
fi
urls=$(gh api --paginate "$endpoint/comments" --jq ".[] | select(.pull_request_review_id == $id) | .html_url") || exit 5
printf '%s\n' "$url"
read_count=0
while IFS= read -r comment_url; do
  if [ -n "$comment_url" ]; then
    printf '%s\n' "$comment_url"
    read_count=$((read_count + 1))
  fi
done <<< "$urls"
if [ "$read_count" -ne "$count" ]; then
  printf 'post-review: posted review %s but read back %s of %s comments\n' "$url" "$read_count" "$count" >&2
  exit 6
fi
