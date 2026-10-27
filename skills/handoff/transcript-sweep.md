# Handoff step 7: sweeping this session's transcript

The detail behind step 7 of the [handoff skill](SKILL.md): where the current session's
transcript lives, how to parse it, and the tools that look right but search the wrong thing.

**Sweep the transcript, not your context.** A sweep that only looks at what you can
still see cannot find anything from before a compaction — which in a long session is
most of it, and is exactly where the write-through discipline was most likely to slip.

🚨 **A cross-session transcript-search tool will NOT do this** — where the harness has
one, it searches *other* sessions, never the one you are in, so pointing the sweep at it
returns nothing and reads as "no stragglers found." Verified 2026-08-08 (the tool's name:
`LOCAL.md` beside this skill, when your copy keeps one, *Transcript sweep specifics*).
Use it for what it is good at (finding which PAST session covered a topic), not for this.

The current session's transcript is on disk at
`~/.claude/projects/<project-slug>/<sessionId>.jsonl`. 🚨 **Do NOT assume that is the
same directory as the auto-memory files — in a worktree session it is not.** Memory
lives under the main repo slug; the transcript lives under a worktree-suffixed slug
(`…-<repo>--claude-worktrees-<name>/`), so a sweep pointed at the memory
directory greps OTHER sessions and returns nothing for yours — the same silent
"no stragglers found" failure as the MCP tool, one directory over. Find the file,
don't derive it: `find ~/.claude/projects -name "<sessionId>.jsonl" -maxdepth 2`
(the session id is in any scratchpad/task path already in context), or
`grep -rl "<my-branch-name>" ~/.claude/projects/` when the id isn't handy — then
confirm the path carries YOUR worktree. Parse it for the high-signal patterns: explicit corrections
("no, not that", "actually", "that's wrong"), stated preferences, reversed decisions,
and anything you were told twice.

`<skill-dir>/scripts/transcript-sweep.sh` does all of this (exit 2 for a bad id or regex, 3 when the
transcript is missing or ambiguous, 4 when `jq` is missing). What it counts as a genuine user turn,
measured on a live transcript (2026-10-26), because most `"type": "user"` records are not:

- A `user` record with no `toolUseResult` key and no `"isMeta": true`. Tool results
  (most of the records) and harness turns (sub-agent hand-backs, skill bodies, slash-command
  expansions) fail that test.
- Its `.message.content` is a string or an array of `text` blocks. Filter per block: a
  session's first prompt arrives as a `<system-reminder>` block followed by the person's
  words, and dropping the whole turn for its first block loses the prompt.
- A message typed while the agent was working is not a `user` record at all: it is
  `{"type":"attachment","attachment":{"type":"queued_command","origin":{"kind":"human"},
  "prompt":…}}`, where `prompt` is a string or an array of blocks (filtered per block, like
  `.message.content`). The same attachment with `origin.kind` `task-notification` is noise.
- Harness output is filtered, or it dominates every hit: `isCompactSummary` records, and
  text starting with `[SYSTEM`, `<system-reminder>`, `<task-notification>`, `<agent-message`,
  `<command-`, `[Request interrupted`, `<local-command-`, `<ci-monitor-event` or
  `<artifact-view-context`, plus whitespace-only turns. Unparsable lines are skipped and
  counted on stderr.

Targeted searches, not a full re-read — the point is to recover what fell out of
context, not to re-derive the session.

Anything that spans skills goes to a cross-skill principles file, if you keep one,
rather than into three `LEARNINGS.md` files (this install's file and rule: `LOCAL.md`
beside this skill, when your copy keeps one, *Cross-skill principles file*).

(This step replaces what `claude-mem` and `headroom learn` do with a plugin: mine the
session record instead of relying on the agent having noticed. Both were evaluated
2026-08-08 and rejected — 60–90s per-tool latency and a cloud sync of private-repo tool
output respectively. The transcript tool is already installed and nothing leaves the
machine.)
