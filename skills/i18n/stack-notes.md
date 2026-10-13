# Stack notes — mechanics per stack

Starting points, not a substitute for the library's current docs: confirm APIs against
the source at plan time (see [source-driven-development](../source-driven-development/SKILL.md)).
Versions below were read from the npm registry on 2026-10-12. The nestjs-i18n behaviour
was read from its shipped 10.8.5 code.

## Message syntax per stack

The completeness gate needs one parser per syntax (SKILL.md §3, items 3–4). If packs are
shared across stacks, pick one source syntax and compile it into each.

| Stack / library | Named argument | Plurals | Escaping / gotchas |
|---|---|---|---|
| vue-i18n (v11) | `{name}`; list `{0}` | `a \| b \| c` chosen by count. The default rule is English-like, so register `pluralRules` per locale for Russian, Arabic, Polish and similar | `{ } @ $ \|` are syntax. Write a literal as `{'@'}`. `@:key` links another message. Parse with `@intlify/message-compiler` |
| nestjs-i18n (v10) | `{name}` (default formatter `string-format`); `{{name \| pipe}}` for transform pipes | A message is an object keyed by CLDR category (`one`, `few`, `many`, `other`, plus an optional `zero`), selected with `Intl.PluralRules` from `args.count` | A missing category falls through to the whole plural object rather than a string, so check every category. An ICU MessageFormat helper ships in its utils if you want ICU |
| go-i18n (`nicksnyder/go-i18n/v2`) | `{{.Name}}` (Go `text/template`) | `one:` / `few:` / `other:` … fields per message, CLDR rules for 200+ languages | Template syntax errors surface at runtime; parse every message in the gate |
| `golang.org/x/text/message` | printf verbs. Use explicit indexes `%[1]s` so translators can reorder | `plural.Selectf` in the catalog | Bare `%s` order is fixed by the source language |
| ICU MessageFormat (`@messageformat/core`, FormatJS) | `{name}` | `{count, plural, one {…} other {…}}` | Apostrophe escaping. Translators often break nested braces, so parse in the gate |

## Any stack: translation packs as JSON

- One file per locale (`locales/<code>.json`), nested by feature namespace. The source
  locale's file is the schema. The gate flattens keys to dotted paths and compares sets.
- **Propagating a new key:** use an **order-preserving** script that inserts the key at
  the same position in every file, so review diffs line up. Write the value as a marked
  draft (`"⟦TODO⟧ English text"`) that the gate's untranslated check rejects. Never
  hand-edit every pack.
- **Translator metadata** goes in a sidecar (`locales/_meta.json`), because JSON has no
  comments. Per key: `description`, `maxLength`, a screenshot link and, if you use the
  staleness policy, `sourceHash`. The gate reads `maxLength` and `sourceHash`.

## Vue 3 + Vite (incl. SSR)

- **Library:** `vue-i18n` in Composition mode (`legacy: false`), `useI18n()` in components.
  Set the `missing` handler and `missingWarn` / `fallbackWarn` so a missing key is loud in
  dev and reported in prod (SKILL.md §2).
- **SSR: create the i18n instance per request** in the app factory, never as a module
  singleton, or one request's locale leaks into another's render. Set `<html lang dir>` in
  the server entry from the resolved locale. Hydrate the client with the same locale and
  messages so the first client render matches.
- **Build:** `@intlify/unplugin-vue-i18n` (v11) precompiles message files and supports
  lazy-loaded per-locale chunks. Every separate Vite config (an embed or widget build, a
  second entry point) needs the plugin and its own locale loading. Check each one.
- **Lints:**
  - `@intlify/eslint-plugin-vue-i18n`: `no-raw-text`, `no-missing-keys`,
    `no-unused-keys`.
  - `eslint-plugin-vue`: `vue/no-bare-strings-in-template`.
  - Call-site literal fallbacks, via core `no-restricted-syntax`:
    `LogicalExpression[operator=/^(\|\||\?\?)$/][left.callee.name=/^\$?t$/][right.type='Literal']`.
    Extend it to `left.callee.property.name` for `i18n.t(…)` member calls.

  None of these lints see strings built in script code or attributes bound from JS. The
  pseudo-locale sweep does.
- **Dates:** prefer `Intl.DateTimeFormat` / `Intl.RelativeTimeFormat` (or vue-i18n's `d()`)
  for display, and keep dayjs for date arithmetic. dayjs (1.11) is not CLDR-based:
  - its locale codes are lowercase (`zh-cn`, `pt-br`), so map them in the registry;
  - each locale must be imported (`dayjs/locale/<code>`);
  - localized formats and relative time need the `localizedFormat` and `relativeTime`
    plugins;
  - the global `dayjs.locale()` is process-wide on an SSR server, so use the per-instance
    `.locale(code)`.
- **Hydration:** server and browser ICU data and default timezones differ. Pass
  `timeZone` explicitly to every `Intl.DateTimeFormat`, or format on the client only.
  Treat hydration-mismatch warnings as failures in the e2e sweep.

## NestJS API

- **Prefer codes over prose** on API errors consumed by your own UI:
  `{ code: 'BOOKING_SLOT_TAKEN', params: { time: '…' } }`, rendered by the client. Keep the
  English `message` for logs and third-party consumers; the UI never prints it. The
  error-code enum belongs in the shared contract package, where gate item 9 checks every
  code has a label in every locale.
- **Where the server must localize** (emails, PDFs, SMS, server-rendered pages, third-party
  consumers), use `nestjs-i18n` (v10). It provides `I18nModule` with pluggable resolvers
  (query, header, `Accept-Language`, cookie, custom, e.g. the user's saved preference) and
  DTO-validation message translation.
- 🚨 **nestjs-i18n's missing-key default is silent.** On a miss it walks the fallback
  language and then **returns the key itself, with no log**, unless `throwOnMissingKey` is
  set; `logging` controls the error log on that path (10.8.5,
  `services/i18n.service.js`). Set `throwOnMissingKey: true` in dev and test. Never pass a
  per-call `defaultValue` with a user-facing literal; that is the banned call-site fallback.
- Resolve the locale once per request and pass it explicitly into queues, jobs and outbound
  service calls (the shared locale header). An async email reads the recipient's stored
  locale, not the locale of whoever triggered it.
- `class-validator` defaults are English; give every validation rule a message key.

## Go services

- **Libraries:** `github.com/nicksnyder/go-i18n/v2/i18n` (message files, CLDR plurals for
  200+ languages, and the `goi18n` extract/merge command), or `golang.org/x/text/message`
  with a `catalog`. `golang.org/x/text/language` provides a `Matcher` that negotiates
  `Accept-Language` (or the shared locale header) against the supported set.
- `html/template` and `text/template` don't translate. Pass a localizer into the template
  data, or a `T` func via `FuncMap`, and keep every template string behind it.
- Formatting: `x/text/message` printers format numbers per locale. Go's `time` package has
  no localized month or day names, so use a CLDR-backed library or translated names from
  the packs.
- Generated customer documents (quotes, offers, invoices) are the surface most often
  missed in Go services. Inventory every `fmt.Sprintf` and string literal that reaches a
  user, and render each document in the pseudo-locale in a test.

## PostgreSQL

- **Translatable reference data:** either a side table `(entity_id, locale, field, value)`
  or a per-field `jsonb` map `{ "en": "…", "es": "…" }`. The side table is easier to keep
  complete (a parity query is a `GROUP BY … HAVING count(*) < n_locales`); the `jsonb` map
  is simpler to read. Either way, the completeness query runs in the test suite.
- Store codes, not labels, in transactional rows (SKILL.md §5).
- **Collation:**
  - Use an ICU collation per locale for user-visible sorts (`CREATE COLLATION … (provider =
    icu, locale = '…')`), applied as `ORDER BY name COLLATE "…"`.
  - For paginated lists, sort in the database. Sorting a page in the app with
    `Intl.Collator` disagrees with the database's page boundaries.
  - **Collation version drift:** after an ICU or OS upgrade, Postgres warns of a version
    mismatch. Indexes on text columns using that collation must be rebuilt (`REINDEX`),
    then the collation refreshed (`ALTER COLLATION … REFRESH VERSION`). Put this in the
    upgrade runbook.
  - Accent- or case-insensitive matching needs a non-deterministic ICU collation
    (`deterministic = false`), which restricts pattern matching and some index uses.
    Check your server version's docs before choosing it over `unaccent` + `pg_trgm`.
- **Full-text search** is language-specific: `to_tsvector('<config>', …)` per locale, with
  the config chosen from the registry, not hard-coded `'english'`.
- Encoding: UTF-8 everywhere; check `client_encoding` on every importer.

## R / Shiny and other server-templated apps

- Load each language pack once. The lookup function owns the fallback; templates call the
  lookup, never `pack$key %||% "English"`.
- Client-side JS that reads injected translations must use the *same* fallback rule as
  the server. Otherwise one page shows English where another blanks.
- Read CSV and Excel imports with an explicit encoding (UTF-8, UTF-8-BOM or Windows-1252,
  detected deliberately). Survey-tool exports can differ by column.
