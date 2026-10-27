#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -eq 0 ] || [[ ! "$1" =~ ^[0-9a-f-]{36}$ ]]; then
  echo 'Usage: transcript-sweep.sh <sessionId> [extra-regex ...] (joined into a case-insensitive regular expression)' >&2
  exit 2
fi
id="$1"
shift
if ! command -v jq > /dev/null 2>&1; then
  echo 'transcript-sweep: jq is required' >&2
  exit 4
fi

if ! jq -n --args '
  $ARGS.positional | join("|") as $pattern | "" | test($pattern; "i")
' "$@" > /dev/null 2>&1; then
  echo 'transcript-sweep: invalid extra regex' >&2
  exit 2
fi

root="${CLAUDE_PROJECTS_DIR:-$HOME/.claude/projects}"
shopt -s nullglob
matches=("$root"/*/"$id.jsonl")
if [ "${#matches[@]}" -eq 0 ]; then
  printf 'transcript-sweep: no transcript for %s under %s\n' "$id" "$root" >&2
  exit 3
fi
if [ "${#matches[@]}" -gt 1 ]; then
  printf 'transcript-sweep: multiple transcripts for %s\n' "$id" >&2
  printf '%s\n' "${matches[@]}" >&2
  exit 3
fi
printf 'transcript: %s\n' "${matches[0]}"

skipped=$(jq -Rn '
  reduce (inputs | select(test("\\S"))) as $line (0; . + (try ($line | fromjson | 0) catch 1))
' < "${matches[0]}")
if [ "$skipped" -gt 0 ]; then
  printf 'transcript-sweep: skipped %s unparsable lines\n' "$skipped" >&2
fi

jq -nRr --args '
  def harness_start:
    sub("^\\s+"; "")
    | startswith("[SYSTEM") or startswith("<system-reminder>")
      or startswith("<task-notification>") or startswith("<agent-message")
      or startswith("<command-") or startswith("[Request interrupted")
      or startswith("<local-command-") or startswith("<ci-monitor-event")
      or startswith("<artifact-view-context");
  def human_string:
    select((harness_start or contains("<task-notification>")) | not);
  def human_content:
    if type == "string" then human_string
    elif type == "array" then
      map(objects | select(.type == "text") | .text | strings
          | select(harness_start | not)) | join("")
    else "" end;
  ["no, not", "not that", "actually", "that\u0027s wrong", "that is wrong",
   "i said", "i told you", "don\u0027t", "do not", "stop", "instead",
   "remember", "always", "never", "from now on", "prefer"]
  + $ARGS.positional | join("|") as $pattern
  | [inputs | fromjson? | objects
     | select(.isMeta != true and .isCompactSummary != true)
     | {timestamp: (.timestamp // "-"), text:
         (if .type == "user" and (has("toolUseResult") | not) then
            .message.content? | human_content
          elif .type == "attachment" and .attachment.type? == "queued_command"
            and .attachment.origin.kind? == "human" then
            .attachment.prompt? | human_content
          else empty end)}
     | select(.text | test("\\S"))] as $turns
  | [$turns[] | select(.text | test($pattern; "i"))] as $matched
  | ($matched | to_entries[]
     | "\(.key + 1). [\(.value.timestamp)] \(.value.text | gsub("[\r\n]+"; " ") | .[:300])"),
    "transcript-sweep: \($matched | length) of \($turns | length) user turns matched"
' "$@" < "${matches[0]}"
