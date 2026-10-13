# Where user-facing strings hide — the surface inventory

"We missed a field" almost always means a whole *kind* of surface was never on the list.
During planning, walk every section below against the codebase and record each hit as a
row in the plan (surface, location, owner, phase). During review, ask which row a new
string belongs to. Grep patterns are starting points — confirm each by reading.

## A. In the UI code

1. **Template text** — headings, labels, buttons, table headers, empty states, tooltips.
2. **Attributes** — `placeholder`, `title`, `alt`, `aria-label`, `aria-description`,
   `label` on `<option>`/`<optgroup>`, `value` shown as text, `<input type=submit value>`.
   Raw-text lints usually skip attributes; check them separately.
3. **Script-built strings** — toasts, confirm dialogs (`confirm()`/`alert()`), strings
   assembled in JS/TS, chart titles, axis labels, legend entries, tooltips formatted in
   callbacks, CSV/clipboard text built client-side.
4. **Validation messages** — client form-validation libraries ship English defaults;
   each rule's message needs a key. Native browser validation bubbles follow the
   *browser's* locale, not the app's.
5. **Route and document metadata** — `<title>`, route-title maps, breadcrumbs,
   `<meta name=description>`, Open Graph tags and `og:locale`, the web app manifest,
   `hreflang`, per-locale sitemap entries.
6. **Third-party components** — date pickers, rich-text editors, data tables
   ("Showing 1 to 10 of 50"), file uploaders, map widgets, payment elements. Each has
   its own locale switch; most default to English.
7. **Static assets** — images or SVGs containing text, PDFs linked from the UI, videos
   without captions.
8. **Embedded / secondary bundles** — embeddable widgets, iframes, standalone pages built
   from a separate entry point. Each loads translations separately (or not at all).
9. **Error pages and fallbacks** — 404/500 pages, offline page, "something went wrong"
   boundaries, maintenance pages served by the proxy, not the app.
10. **Native browser widgets** — `<input type=date>`, the file input's "Choose file",
    and validation bubbles follow the *browser's* language, not the app's. Replace them
    or accept the mismatch knowingly.
11. **Fonts** — the font stack must cover every shipped script (CJK, Arabic, Indic);
    `:lang()` rules and Han glyph variants depend on a correct `lang` attribute.
12. **Hard-coded fallbacks** — `|| 'Text'`, `?? 'Text'`, default props with English
    values, `v-if` branches that render a literal when data is missing.

## B. In data (missed most often)

1. **Enums and statuses** shown to users — order states, booking states, roles, plan
   names. Store the code; translate the label.
2. **Categories and taxonomies** — service types, tags, filter facets, dimension names.
3. **Seeded reference data** — lookup tables whose `name` column is English (brand and
   model names are proper nouns and stay; a service or category name is not).
4. **Free-text content from imports** — survey answers, CMS entries, partner-supplied
   descriptions. Decide per field: translate, show as written, or translate on demand.
5. **Config-as-data** — feature lists, plan comparison tables, FAQ entries, onboarding
   steps kept in JSON/YAML or database rows.
6. **Computed labels** — "3 days ago", "Open until 6 pm", band words like "Most" /
   "Some" derived from numbers, units appended in code.

## C. From the server

1. **API error and success messages** that the UI shows verbatim. Prefer stable error
   codes + parameters rendered by the client; inventory every place the UI prints
   `error.message`.
2. **Server-side validation messages** (DTO/class validators, schema validators) — the
   defaults are English.
3. **Server-rendered HTML** — SSR pages, server templates, admin pages that end users see.
4. **Generated documents** — PDFs, invoices, quotes, receipts, calendar invites (`.ics`
   summary/description), CSV/Excel exports (column headers, enum values in cells).
5. **Background-job output** users see — notification text, digest emails. These run
   without a request, so they need the recipient's stored locale.
6. **Raw infrastructure errors** that reach the screen — database constraint messages,
   rate-limit / 429 bodies, gateway timeouts, proxy error pages.
7. **Download names** — export and attachment filenames (`Content-Disposition`), which
   need RFC 5987 `filename*=UTF-8''…` encoding for non-ASCII.

## D. Out of the app

1. **Email templates** — subject lines, preheaders, body, footer/legal text, often
   living in a third-party email/marketing tool rather than the repo.
2. **SMS and push notifications** — length limits differ per script (GSM-7 vs UCS-2: a
   single non-Latin character can halve an SMS's capacity).
3. **App-store / marketplace listings, help-center articles, legal pages** (terms and
   privacy — often need a legal review per language, not just a translator).
4. **Phone/IVR scripts and support macros** if users reach support in their language.
5. **Hosted identity pages** — a third-party sign-in, password-reset or OAuth consent
   screen has its own locale setting (often a URL parameter); it is part of the journey.
6. **Outbound integrations** users read — webhooks rendered into a customer's chat or
   ticketing tool, calendar invites, shared links' preview cards (`og:locale`).
7. **Versioned legal and consent text** — record which locale and version a user
   accepted.

## E. Formatting (not strings, still locale)

Dates, times, timezones, numbers, percentages, currency, units, phone numbers, addresses,
name order, list joining ("A, B and C"), sorting, case-insensitive and full-text search
(language-specific stemming), first day of the week, and pluralised counts.

## Grep starters

- Template literals in markup: text nodes between tags that aren't interpolations.
- `placeholder="`, `title="`, `alt="`, `aria-label="` with a literal value.
- `alert(`, `confirm(`, `toast(`, `notify(`, `.message =`, `throw new Error('` reaching
  the UI.
- `|| '`, `?? '`, `%||% "` next to a lookup call.
- Hand formatting: `toFixed(`, `+ '%'`, `'$' +`, manual month-name arrays,
  `n === 1 ?` / `count > 1 ?`.
- Database: columns named `name`, `label`, `title`, `description` on reference tables.
