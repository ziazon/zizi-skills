# Tabler UI — grid, badges, icons & visual patterns

Part of the `tabler-ui` skill. Layout, badge/status, icon, and typography patterns on
Tabler. All entries `[Vue 3]` unless tagged otherwise. (This install's stack tag and
component names: `LOCAL.md` beside this skill, when your copy keeps one.)

## Contents

- [Grid: size columns to tile count](#grid-size-columns-to-the-tile-count-so-a-row-fills-its-full-width) · [Table-cell badges & status pills](#table-cell-badges--status-pills)
- [Table/list error state](#tablelist-error-state-empty-state-in-the-body) · [Card/wizard/icon patterns](#card-wizard--icon-patterns-that-worked)
- [Hero eyebrow sizing](#hero-eyebrowsubheader-sizing) · [Custom icons in `.shape` badges](#custom-icon-in-a-shape-badge-must-be-a-square-2424-tabler-style-glyph)

## Grid: size columns to the tile COUNT so a row fills its full width

Tabler's grid is 12-wide, so the `col-lg-*` width must divide 12 by the number of tiles in
that row — otherwise the row leaves a dangling empty slot and reads as broken/misaligned. If
the count varies at runtime, write the literal class names out for PurgeCSS, per the
dynamic-class rule in [components-js.md](components-js.md). (Origin: `LOCAL.md` beside this
skill, when your copy keeps one — *layout-visuals.md — Grid*.)

## Table-cell badges & status pills

- **Status pills in data-table cells are soft badges, not solid ones, built from Bootstrap
  5.3's opaque pair `bg-<color>-subtle` + `text-<color>-emphasis`**, e.g.
  `<span class="badge bg-success-subtle text-success-emphasis">`. Use success (green),
  danger (red), warning (amber) and secondary (grey/neutral). Establish one pattern and
  mirror it: a Yes/No boolean cell uses the success/danger pair, and new status cells
  follow suit (e.g. a job-run status cell: success/failed/partial/skipped). (This
  install's cells: `LOCAL.md` beside this skill, when your copy keeps one —
  *layout-visuals.md — Table-cell badges*.)
  - **Why not Tabler's `-lt` variants** (`bg-success-lt`…), which look the same: measured
    on Tabler 1.5, every `-lt` badge fell between 2.5:1 and 4.4:1 in the light theme,
    under WCAG AA's 4.5:1. They are 10%-alpha tints that aren't redefined for dark mode,
    and inside a `.btn-outline-*` on hover the badge composites to its own text colour
    (1.00:1). The `-subtle`/`-emphasis` pair is opaque and is redefined under
    `[data-bs-theme="dark"]` (primary measured 10.58:1 light, 7.27:1 dark). v1.6 redefined
    colours in `oklch()`, so re-measure before relying on either number.
  - **The pair exists only for the theme colours** (primary, secondary, success, danger,
    warning, info, light, dark). v1.6's `tabler.css` has no `bg-blue-subtle` or
    `bg-cyan-subtle`, so map a palette colour to its theme colour, or define the extended
    pair in the app's own CSS.
  - **`-subtle` sets only the background.** Always pair it with the matching
    `text-*-emphasis`. `-lt` set both, so a blind `-lt` → `-subtle` rename ships grey text.
  - **Write both class names as literals.** PurgeCSS keeps them only while the full name
    appears in source (the dynamic-class rule in [components-js.md](components-js.md)).
- **Mapping an enum value → badge class: key the map by the STRING value, do NOT import the
  enum.** A workspace types package's runtime enum imports can crash Vue SFCs
  (reflect-metadata), so build the value→class lookup off raw string keys instead of the
  enum members.

## Table/list error state (empty state in the body)

When an async list fetch fails, render a Tabler empty-state in the table body — `.empty` >
`.empty-icon.text-danger` (a `@tabler/icons-vue` `IconAlertTriangle`) > `.empty-title`
("Something went wrong") > `.empty-subtitle.text-secondary` > `.empty-action` with a "Try
again" `btn btn-primary`. Wire it as a sibling branch of the loading placeholder inside the
existing `<transition mode="out-in">` (loading → error → table). Put it in the shared
table-list component, driven by an `error` prop + `retry` emit, so every list view gets
it. (This install's files: `LOCAL.md` beside this skill, when your copy keeps one — *layout-visuals.md — Table/list error state*.)

## Card, wizard & icon patterns that worked

- Multi-step wizard uses Tabler `.steps.steps-counter.steps-blue` with `.active` on the
  current step; sticky `.card-footer` for Back/Next/Submit.
- Icons: `@tabler/icons-vue` (e.g. `IconPlus`, `IconCar`, `IconSearch`) rather than
  icon-font markup.
- **`@tabler/icons-vue` size/stroke:** in this build `stroke` types as `string`, so pass
  `size="48" stroke="1.5"` as string literals (NOT `:size="48"`) or vue-tsc errors
  "number is not assignable to string".

## Hero eyebrow/subheader sizing

- `tabler-marketing.css` ships a `.hero-subheader` class, but it's an **uppercase, 0.75rem,
  secondary-color** eyebrow — do NOT reuse it for a mixed-case, primary-colored eyebrow; it'll
  look wrong (caps + tiny + gray).
- A subheader `<div>` placed **inside** `h1.hero-title` inherits the title's 3rem/bold, so it
  renders as large as the title. To make a primary-colored eyebrow that's smaller than the title
  with spacing below, put Tabler utilities on the div: `class="text-primary fs-1 fw-semibold mb-3"`
  (`fs-1`≈1.5rem vs the 3rem title — `fs-2`/1.25rem read a touch small; `mb-3` adds the gap).
  (This install's component: `LOCAL.md` beside this skill, when your copy keeps one — *layout-visuals.md — Hero eyebrow*.)

## Custom icon in a `.shape` badge must be a SQUARE 24×24 Tabler-style glyph

`.shape` lives in `tabler-marketing.css`, not `tabler.css`, so a page that loads only the
core stylesheet gets no badge at all. `.shape .icon` forces the icon to a **square** box, so a
custom **wide** icon renders at ~half height — visibly smaller than its neighbors.

- **Redesign as a square 24×24 / stroke-2 Tabler composite from the genuine primitives:**
  transform the real @tabler path data (scale+translate) into a square 24×24 grid, keeping
  stroke-2, so curves match the siblings exactly. Pull canonical path data from
  `node_modules/.pnpm/@tabler+icons-vue@*/.../dist/esm/icons/<Name>.mjs`.
- **Two-concept icons: balance both parts; don't make one a tiny corner badge.** Corner-badge is
  for a small *modifier* (a star/plus/shield ON a thing); when both nouns are first-class
  ("members & vehicles"), size them evenly side-by-side. (This install's icon file: `LOCAL.md`
  beside this skill, when your copy keeps one — *layout-visuals.md — Two-concept icons*.)
- **Don't hand-guess composite geometry — render and compare.** `rsvg-convert` (installed) → PNG,
  `magick montage` several candidates next to the REAL sibling icons in the same badge, then
  let the user pick from the montage.
