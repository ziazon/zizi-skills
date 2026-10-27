# GitHub Issues and Projects backend

The `gh` CLI is the whole backend: issues, sub-issues, blocking links and Projects
(v2) boards all have first-class commands. Where your install has a tracker CLI that
covers the project's board (`LOCAL.md` beside this skill, when your copy keeps one), its
commands replace the `gh` reads and writes below that it has verbs for; `LOCAL.md` names
the ones that stay on `gh`. Every mode in [SKILL.md](SKILL.md) works the
same way here; this file is only the GitHub mechanics. The approval gate is unchanged:
draft every write and ask before running it.

Command surface checked against `gh` 2.102.0 (2026-09-30). When a flag below surprises
you, read `gh <command> --help` before you trust this file — the CLI moves faster than it.

## Before the first call

1. **Know which repo, and which board.** `pm-config.md` records `Tracker: github`, the
   `owner/repo`, and, when the project uses one, the Projects board number and its
   status field. Pass `-R owner/repo` on every issue command, so a call made from the
   wrong checkout cannot land in the wrong repo.
2. **Projects need their own token scope.** Issue commands work with the `repo` scope;
   every `gh project` command, and adding an issue to a board (`-p`, `--add-project`),
   fails until the user runs `gh auth refresh -s project` — a read fails with
   `missing required scopes [read:project]`. It opens a browser login, so it is the
   user's step: ask for it, never work around it.

## Reading

```sh
gh issue list -R owner/repo --state open --search '<words> in:title,body' \
  --json number,title,state,labels,updatedAt
gh issue view 123 -R owner/repo \
  --json title,body,state,stateReason,labels,parent,subIssues,blockedBy,blocking,projectItems,comments
gh project item-list <board> --owner <owner> --format json   # board rows and their field values
```

`--search` takes GitHub's issue search syntax. The duplicate hunt in
[audit.md](audit.md) runs on it: search titles and bodies for the change's key terms,
open and closed (`--state all`).

## Writing (each one drafted and approved first)

| Need | Command |
|---|---|
| New issue | `gh issue create -R owner/repo -t '<title>' -F body.md -l <label>`, plus `--type <name>` where the owner defines issue types |
| Sub-issue of an epic | `--parent <n>` on create, or `gh issue edit <epic> --add-sub-issue <n>` |
| Dependency | `--blocked-by <n>` / `--blocking <n>` on create; `--add-blocked-by` / `--remove-blocked-by` on edit |
| Put it on the board | `-p '<board title>'` on create, or `gh issue edit <n> --add-project '<board title>'` |
| Move it on the board | `gh project item-edit --project-id <PVT_…> --id <PVTI_…> --field-id <PVTSSF_…> --single-select-option-id <option>` |
| Comment | `gh issue comment <n> -R owner/repo -F comment.md` |
| Close as done or dropped | `gh issue close <n> -r completed` / `-r 'not planned'` |
| Close as a duplicate | `gh issue close <n> --duplicate-of <m>` |

Moving a board item needs IDs, not names. Get the project ID and the status field's ID
and option IDs once from `gh project view <board> --owner <owner> --format json` and
`gh project field-list <board> --owner <owner> --format json`, record them in
`pm-config.md`, and read the item's `PVTI_…` ID from `gh project item-list`.

Write bodies to a file and pass `-F`. A body built inline in the shell breaks on
quotes, backticks and `$`, and a mangled QA test plan is worse than none.

## How the general rules map

- **Ticket format:** [ticket-writing.md](ticket-writing.md) applies unchanged. GitHub
  renders markdown, so the QA steps go in as a numbered list and the acceptance
  criteria as a task list (`- [ ]`).
- **Status follows the work:** on a repo with a board, status is the board's status
  field; without one, it is open or closed plus labels. Record which in
  `pm-config.md`, along with the label or option that stands for each lifecycle stage.
- **Link the PR:** a `Fixes #123` line in the PR body closes the issue when the PR
  merges into the default branch. On a repo whose merge does not mean "done" (the
  change still has to reach staging), write `Refs #123` instead and close it by hand
  at the right stage.
- **Attribution:** `gh` adds no signature to what it posts, so a comment written on
  the user's behalf carries the same one-line "written by Claude on your behalf"
  footer any other unsigned tool's message gets.
