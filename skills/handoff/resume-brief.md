# Handoff step 8: the resume brief and the chip

The detail behind step 8 of the [handoff skill](SKILL.md): what a resume brief must hold to
survive contact with a fresh session, and how a posted chip behaves.

**What the brief must contain to survive contact:**

- **End the resume prompt with a `Recommended model:` line** (hybrid model routing):
  the tier the next session should start on plus a one-line why —
  e.g. `Recommended model: sonnet — remaining items are all low-stakes copy tweaks`.
  Default to the strong session model; recommend a cheaper tier only when the
  remaining contiguous run of work is uniformly low-stakes (source the tags from your
  queue's model-fit tags, if it keeps them — this install's source: `LOCAL.md` beside
  this skill, when your copy keeps one, *Recommended-model line*). The line
  is advisory — the user acts on it at spawn time; the brief must still work if the user
  ignores it.
- **Open with a branch VERIFY, not a `cd`.** A brief starting "cd `<worktree>` and
  read the handoff" strands the successor when the worktree was flipped to another
  branch at spawn — the handoff file appears to have vanished. First action: `cd`,
  then `git symbolic-ref -q HEAD || git checkout <branch>`, confirm
  `git branch --show-current` matches the branch the brief names, *then* read.
- **Write it worktree-agnostic.** A resume chip may start in a **fresh worktree**, so a
  hard-coded path points the new session at a tree it doesn't own — and a fresh
  worktree has **no `node_modules`**, which makes a coding agent exit 127 or symlink
  a sibling's. Name the **repo and the commit** ("main was `<sha>` at handoff"), say
  how deps are installed, and treat any worktree path as advisory with an "if the
  directory is missing, `git worktree add <path> <branch>`" clause.
- **State the blocker above the task.** What's useful to hand forward is usually not
  "do the QA" but *why it can't just be done*: no production credentials exist, prod
  403s behind Cloudflare, and entering a password is prohibited — so the task
  structurally requires the user to act first. Name the blocker, what unblocks it,
  and who can.
- **"The human never did their part" is the FIRST branch of the diagnostic tree.**
  An otherwise excellent brief stranded a session because its two branches were both
  *code* failure modes, while the truth was that the third party never filed the item
  the test needed — the drain had nothing to process. The human step is fresh every
  time; code paths were at least tested once. And say **how to tell "not done yet"
  from "done but broken"** when they look identical locally. Tell you're writing this
  bug: your brief says "ask X to do Y, then wait N seconds and check Z" with no step
  in between that confirms Y happened.
- **Phrase each remediation arm with its premise-check inline.** "If the probe shows
  v12 → tell the user to relaunch" encoded a stale theory as fact; the relaunch *had*
  happened and the real cause was elsewhere. Write "if v12 AND the app process
  predates the fix → relaunch; if v12 but the app postdates it → diagnose deeper," so
  the successor can tell "Y will fix it" from "Y already ran and didn't."
- **For a cross-repo issue, split the record.** Put the pointer where the symptom
  appears (that repo's tracker genuinely will be read) and the instructions where
  they can be executed (a globally-addressable brief). One without the other strands
  the work. Carry the *target* repo's git posture too — branch and `status --short`
  — since the resuming session will assume a clean tree.
- **Never overwrite a handoff artifact you haven't read.** Date-suffix a new one,
  mark it "**SUPERSEDES `<old>` — ignore that file**", and repoint memory's brief
  pointer in the same turn, saying *why* the old one is stale.

A default resume prompt, in that order:

```text
Resume <task> in <repo>; main was <sha> at handoff; install deps with <command>.
1. cd <worktree> (advisory: if it is missing, git worktree add <worktree> <branch>)
   git symbolic-ref -q HEAD || git checkout <branch>
   git branch --show-current must print <branch>; only then read <handoff file>.
2. Blocker: <blocker>. Unblocked by <input or event>, which <who> can supply.
3. First action: <exact command or edit>
Recommended model: <tier> — <one-line why>
```

**The chip is live and irrevocable — memory is the real control surface.**

- **A started chip cannot be recalled.** Where the harness offers a tool to withdraw a
  posted chip, it refuses once the user has clicked, and chip ids may not survive an
  app restart, so a stale chip can outlive your ability to withdraw it. Never report a
  chip as withdrawn without reading the tool result. (The tool's name: `LOCAL.md`
  beside this skill, when your copy keeps one, *Withdrawing a chip*.)
- **Memory's "NEXT =" pointer is what actually steers the successor.** Update it the
  moment priorities change, not after posting chips — a mis-started session reads
  memory on boot and self-corrects. Anything you cannot clean up, **annotate**: mark
  the follow-up CLOSED and say "if that chip is still on screen it is stale, ignore
  it."
- **The chip gets clicked before your handoff finishes** — recorded three times. Post
  it only once memory and the plan are already written, and make step 1 correct on
  its own.
- **One chip per stream, in dependency order.** Never post a second for a stream
  that already has a running successor (two sessions then race one worktree), and for
  strictly sequential work post only the *first* unit's chip — let that session post
  the next. Don't let a subagent spawn chips at all: a read-only investigator lacks
  the context to know whether its find is in scope, and a chip is only for work you
  have decided **not** to do.

One resume per independent work stream; sequential work gets ONE. Skip entirely
only when the program is complete and nothing remains to resume.

Caveat: claude.ai routines (the remote-trigger API) run in the cloud with **no
local filesystem access**, so they cannot continue local-repo work — never route
a local-repo handoff there regardless of device.

**Resume-routing failure modes.** Posting a clickable resume to a surface that can't show
it, trying to drive a launch surface only the user can operate, and arming an auto-firing
resume task nobody asked for are the three ways this step goes wrong. This install's
versions of them: `LOCAL.md` beside this skill, when your copy keeps one, *Resume-routing
failure modes and checklist*.
