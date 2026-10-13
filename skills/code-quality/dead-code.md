# Dead code — the deletion discipline

The procedure behind [code-quality](SKILL.md)'s *Dead code: prove it first*. Read it before
deleting anything your own change did not orphan, and whenever asked to "remove dead code".

"Dead code" = code that can never be reached or referenced through ANY path.
Apparently-dead is not dead. Before deleting, you must actively rule out every
non-obvious form of use below. **The default answer to "is this safe to delete?"
is "prove it first."**

## Step 0 — establish a green baseline before touching anything

Run the relevant build / type-check / lint / tests FIRST and confirm they pass
(or note what's already red). Without a known-good baseline you can't tell
whether breakage came from your deletion or was pre-existing. Also rebuild any
workspace lib you depend on — stale `dist/` produces phantom type errors and
false "unused" signals (e.g. a shared types package `@acme/types` that resolves
from `dist`; this install's real cases are under *Shared workspace lib examples* in
`LOCAL.md` beside this skill, when your copy keeps one).

## Step 1 — search exhaustively, across the whole stack

A single-package grep is not enough in a monorepo. For each symbol:

- **Calibrate your detector first:** run the search/loop against a symbol you KNOW
  is used and confirm it reports references — a silently-broken search (e.g. zsh
  globbing `grep --include='*.ts'` into an error) makes *everything* look dead.
- Grep the **entire workspace**, not just the current package — shared libs
  (e.g. `@acme/types`) are consumed by other apps, frontends, and services.
- Search for the **bare name** AND for **string forms** of it (quoted, in arrays,
  in config). Dynamic dispatch hides references in strings.
- Search **other repos** that depend on this one when the symbol is exported
  from a published/shared package. An export with no in-repo use may still be
  another repo's public API.
- Check **tests, fixtures, mocks, seeds, migrations, config files, and non-code
  references** (HTML/template ids & classes, `data-*` attributes, i18n keys, SQL,
  CSS selectors) — not just `src/`.
- **Read the hits; don't trust counts.** Common identifiers (`Service`, `User`,
  `index`) produce substring false positives both ways — a high grep count can be
  noise, and a *type* can be reached transitively through another type with zero
  direct hits. Open the file and confirm the actual reference.
- **Distinguish a real reference from a mention.** A name appearing in a comment,
  a doc-string, a changelog, or a disabled/commented block is not a live call.
  Conversely, don't assume a commented block is dead (see intentional stubs below).
- **Compare paths, not names, in a monorepo.** Scope the proof to the package that
  owns the symbol, then open each out-of-package hit: a sibling app often carries
  its own same-named copy, which inflates the count without being a reference. The
  reverse error is worse — deleting the sibling's copy because "it's one repo".
- **Prove a branch dead by enumerating its call sites**, not by reading the
  function: list every caller and the arguments it passes, and show none reaches it.
- **"Nothing runs this" needs the CI config too.** A test or script can be invoked
  from a workflow file without appearing in any package script or task runner.

## Step 2 — rule out non-obvious "use"

Code is NOT dead if it is reached by any of these. Each is a way a symbol looks
unreferenced to a naive grep but is live at runtime:

- **Public/library API:** exported from a package others import. Unused *inside*
  the repo ≠ unused. Check `package.go`/`index.ts` barrels and the package's
  consumers before touching exports.
- **Dynamic / string-based references:** `import()`, `require(name)`,
  computed property access `obj[methodName]`, route tables, event names, DI
  tokens, job/queue names, GraphQL resolver maps, template strings.
- **Reflection & metaprogramming:** Go reflection + **struct tags**
  (`json:`/`db:`/`validate:` — the field is "unused" in Go but drives
  serialization); Rails metaprogramming (`send`, `method_missing`,
  `define_method`, `constantize`, callbacks, STI); decorators/annotations that
  register via reflection (NestJS providers, EntitySchema, DI).
- **Convention-based wiring:** framework auto-registration by file location or
  name (controllers, migrations, Rails autoload, Vue auto-imported components,
  Nest module scanning). The "caller" is the framework, not your code. Watch for
  routes/endpoints registered under **dotted/string names via mixins** (e.g. Rails
  Grape IPC routes registered through `self.included(base)` — no literal call
  site exists) and **runtime route registration** (routers that mount only routes
  matching a `meta`/auth predicate, so the route def looks statically unreferenced).
- **Intentional stubs & rebuild markers:** an empty component, a commented-out
  block with a "add back when we rebuild X" TODO, or a deliberately-omitted module
  registration may be a placeholder, not litter. Confirm intent (git log, the
  TODO, the user) before removing — deleting it loses the breadcrumb.
- **Pattern/contract-based config:** schemas that accept anything matching a
  pattern (e.g. a Joi rule that allows any `*_API_URL` env var) mean a value can be
  consumed without ever being named in code. "Undeclared" ≠ unused.
- **Serialization & external contracts:** fields read from / written to JSON,
  DB columns, API payloads, env vars, feature flags, CLI args. Removing a field
  that "nothing reads" can break a wire format or a stored record.
- **Build-conditional code:** Go build tags, `NODE_ENV`/env-gated branches,
  platform-specific files, feature-flag-gated paths. Off in your config ≠ dead.
- **Framework lifecycle hooks:** callbacks/handlers invoked by the framework
  (`after_commit`, lifecycle methods, signal handlers, scheduled jobs).
- **Tests-only but intentional:** test helpers, factories, fixtures. Used only
  by tests is still used.

## Step 3 — lean on tooling, then verify

Tools find candidates; they do not authorize deletion.

- Use the language's own unused-code detectors as a *first pass*: TS
  `noUnusedLocals`/`tsc`, ESLint/oxlint `no-unused-vars`, `ts-prune`/`knip` for
  exports, `staticcheck`/`go vet`/`deadcode` for Go, Ruby `debride`/coverage for
  Rails. For languages with no good detector (e.g. R/Shiny), the first pass is a
  disciplined project-wide grep instead.
- **Configure the tool's real entry points before trusting it.** Detectors infer
  reachability from declared entrypoints; a non-obvious one (a TS module loaded by
  a plain `server.js`, a CLI script, a dynamically-imported route) makes everything
  it pulls in look "unused." Most knip/ts-prune false positives trace to this.
- Treat their output as **candidates**, then apply Steps 1–2 to each. These
  tools routinely miss reflection, string dispatch, cross-repo use, and
  framework wiring — and over-report behind bad entrypoints.
- **Peel orphans iteratively, not in one shot.** A deletion orphans whatever the
  deleted code referenced (DTOs → sub-DTOs → validators). Re-run detection after
  each deletion pass and repeat until a pass finds nothing new; keep any file
  that retains a single non-spec, non-self reference.
- **A deletion takes its registrations and its prose with it.** Remove the DI or
  module registration (a `providers` entry, a route table, any framework registry),
  the test wiring that registers it, and the doc comments that name it — in the same
  commit. A registration naming a deleted file fails at boot, not at compile, and
  unit tests rarely build that graph; a stale doc comment tells the next reader the
  rule still applies.
- After deleting, **build + run the test suite + boot the affected path**. A
  green compile is necessary, not sufficient — exercise the code path (or a
  live stack) when the use could be dynamic. Report what you verified.
- **Don't infer "dead/broken" from stale data.** An empty table or zero-result
  query in a dev snapshot can be old data, not a dead code path — reproduce live
  before concluding the code is unused.

## Prefer the smallest safe reduction

Removing the whole symbol is the last resort, not the first. Scale the cut to what
you can actually prove is unreachable:

- An **unused export** that's still used internally → drop the `export` keyword,
  keep the symbol.
- A **dead barrel re-export** where the underlying thing is imported directly →
  remove the re-export line, keep the component/module.
- Only delete the entire definition when nothing anywhere — in any repo, by any
  mechanism above — reaches it.

## Step 4 — when uncertain, don't delete

If you cannot prove a symbol is dead, **leave it and report it** as a candidate
with what you found (where you looked, why it's ambiguous), rather than removing
it. Group confirmed-dead deletions into their own atomic commit, separate from
quality refactors, so they're easy to review and revert.

## Consumer-bounded removal (when the user names the complete consumer set)

The reason removing an exported/public symbol (an API endpoint, a library export)
is normally unsafe is a *single* unknown: **we don't know everyone who calls it.**
So a published endpoint with no in-repo use is still presumed live (Step 2). When
the **user explicitly tells you the complete, authoritative set of consumers**,
that unknown is gone — and only then may you treat cross-consumer absence as proof
of death. Use this mode ONLY on the user's explicit instruction; never assume a
consumer set yourself.

When instructed, treat the named consumers as ground truth:

- **Make the consumer set explicit in your report** ("user states the only consumer
  of `orders-api` is `web-app`"). The whole removal rests on this claim — surface it
  so the user can correct it before anything is deleted.
- **Search every named consumer exhaustively** for the endpoint/symbol, applying
  Step 1 (bare name + string forms: URL paths, route constants, service-method
  names, generated clients) and Step 2 (dynamic/string dispatch, config). The path
  may be assembled (`base + '/v1/' + resource`), so grep for path fragments, not
  just whole strings.
- **An endpoint absent from all named consumers is confirmed dead** — remove it,
  even though it's "public." Present in any consumer → live; keep it.
- **Re-confirm the boundary still holds** before deleting: verify no *other*
  in-repo or sibling app has quietly started consuming it (a new service, a cron, a
  test harness). The user's claim covers known consumers; a quick workspace grep
  guards against a new one. If you find a consumer the user didn't name, stop and
  report — the boundary was wrong.
- **Migration ordering matters.** When old endpoints are being superseded by new
  ones (e.g. `v1` → `v2`), only remove the old endpoint after its consumer has been
  cut over to the replacement *and* that cutover is merged/verified — otherwise you
  delete something still live in the current consumer revision. Sequence:
  add new → migrate consumer → confirm no consumer references old → remove old.

Worked example (hypothetical): the user states **the only consumer of a service
`orders-api` is `web-app`.** Once an old orders-api list endpoint has been replaced
by a new versioned one and web-app is moved onto the new version, diff orders-api's
exposed endpoints against web-app's usage to identify the now-orphaned old
endpoints, and remove them as confirmed-dead. (This install's standing consumer
set, stated by the user: `LOCAL.md` beside this skill, when your copy keeps one —
*Standing consumer set*.)

## Output when asked to "remove dead code"

1. List candidates found (tooling + manual search).
2. For each: verdict — **confirmed dead** (with the search evidence) /
   **live** (with the use you found) / **uncertain** (flag, don't delete).
3. Delete only the confirmed set; keep it in a dedicated commit.
4. State what you ran to verify (build, tests, live boot) and what's unverified.
