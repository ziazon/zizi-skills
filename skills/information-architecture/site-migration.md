# Site migration — moving or restructuring a live site without losing it

How to move a client's old site to a new build, change platforms, or change the URL scheme so
visitors, bookmarks, links and search rankings all land on the right new page.

Adapted from the `site-architecture` skill in `coreyhaines31/marketingskills` (MIT); rewritten,
with the platform comparison and vendor routing left out.

Most traffic lost in a migration comes from URLs that changed with no redirect, metadata that
didn't come across, and internal links left pointing at old addresses. The new platform itself is
rarely the cause. The safest migration changes the platform and nothing else; every URL you keep
is one you don't have to redirect.

## Contents

- Before: inventory every live URL
- The redirect map
- URL rules for the new scheme
- Launch
- After: watch for at least two weeks
- A section served from another host (reverse proxy)
- Template: a small local business site
- Before you call the migration done

## Before: inventory every live URL

1. **Export every URL the old site serves.** Combine a crawl (any site crawler), the CMS export,
   the current XML sitemap and, if you can get them, server logs. A crawl alone misses pages that
   nothing links to but other sites still do.
2. **Record per URL:** status code, title, meta description, canonical, H1, and whether it is in
   the sitemap.
3. **Add what makes it matter, where available:** clicks and impressions (Search Console),
   visits and conversions (analytics), and inbound links from other sites. These pages get the
   most care and the first spot-checks.
4. **Decide each URL's fate** in one table. This table becomes the redirect map.

| Old URL | Decision | New URL | Why |
| --- | --- | --- | --- |
| `/our-services/decks.html` | **Keep** (content moves as is) | `/services/decks` | Top page by clicks |
| `/deck-staining` | **Merge** into a broader page | `/services/decks` | Thin page; same reader, same job |
| `/2019-holiday-hours` | **Drop** | none | Out of date, no inbound links |

5. **Check what the import carries.** Many CMS imports move body content but not URLs, metadata,
   redirects, structured data or image alt text. List what must be rebuilt by hand.
6. **Collect the old site's existing redirects.** They must be re-created on the new host, and
   folded into the new map so nothing chains.

## The redirect map

- **One-to-one 301s** from each old URL to its closest equivalent new page. A merged page goes to
  the page that absorbed its content.
- **Never redirect everything to the home page.** A visitor who wanted the deck page and lands on
  the home page is lost. Google says it treats a redirect to an unrelated page like a missing page
  (check the current docs before relying on the exact behavior). A dropped page with no
  equivalent returns 404 or 410, and a useful 404 page links to the main sections.
- **No chains.** Old A → new C directly, never A → B → C. When an earlier migration left
  redirects, point them straight at the final URL.
- **Query strings:** decide per pattern. Tracking tags (`?utm_…`) should pass through to the new
  URL untouched. A parameter that selects content (`?id=123`, `?page=2`) needs its own rule, since
  a plain path redirect drops or ignores it. Platforms differ on whether they match and forward
  query strings, so test on the real host.
- **Variants:** uppercase, trailing-slash, `www`/non-`www` and `http` versions of an old URL each
  reach the final URL in one hop.
- **Test the map with a script** before launch: for every old URL, the response is a 301 whose
  target returns 200, in one hop. Run exactly this against staging, and again against
  production right after the switch (the map is one `old_path,new_path` pair per line):

  ```bash
  <skill-dir>/scripts/check-redirects.sh redirects.csv https://<host>
  ```

  (`<skill-dir>` is this skill's base directory, which Claude Code prints when the skill loads).

  It prints PASS or FAIL per pair with the reason (a 302, a wrong target, a chain, a 404)
  and exits 1 if any pair fails (2 for bad arguments or a map with no pairs).

## URL rules for the new scheme

| Rule | Example |
| --- | --- |
| Lowercase only; uppercase versions redirect | `/About` → `/about` |
| Hyphens between words, never underscores or spaces | `/services/kitchen-remodels` |
| Short and readable, in the visitor's words | `/services/decks`, not `/our-professional-deck-building-services` |
| Stable: name the thing, not its date or database ID, unless that is meaningful to the reader | `/blog/choosing-deck-boards`, not `/blog/2026/03/12/post-4471` |
| Path mirrors the hierarchy; one parent per page type | all services under `/services/`, never split with `/offerings/` |
| One trailing-slash policy, enforced by redirect | always `/services/decks` (or always `/services/decks/`) |
| One canonical host and protocol; the others redirect | `https://example.com`, with `www` and `http` redirecting |

## Launch

- **Redirects go live in the same release as the switch.** Not the next morning.
- **Sitemap updated** to list only new, final URLs that return 200.
- **Canonicals updated:** each new page's canonical is its own new URL on the canonical host.
  None point at the old site or a staging host.
- **Internal links point at the new URLs directly**, in navigation, body copy and footers.
  Leaning on redirects for your own links adds a hop on every click.
- **Domain change:** verify both the old and new domains in Search Console and use its
  change-of-address tool, after the redirects are live. Keep the old domain registered and
  redirecting for the long term. Google's guidance on how long has changed over time; check its
  current site-move documentation (as of 2026-10).
- **Spot-check the top pages** from the inventory: content, title, meta description, canonical,
  structured data, and a 200 status.
- Run the launch-day checks in [public-site-checklist](../frontend/public-site-checklist.md)
  (staging noindex leaks, robots, analytics, forms).

## After: watch for at least two weeks

- **Daily for two weeks, then weekly:** the 404 report and index coverage in Search Console, plus
  the server's own 404 log. Each real old URL that 404s gets a redirect added to the map.
- **Compare traffic page by page** against the same period before the move. A dip for a few weeks
  can be normal. A sustained drop on specific pages usually means a missing redirect or content
  that didn't come across.
- **Record the final map** in the project's docs, so the next migration starts from it and
  doesn't chain.

## A section served from another host (reverse proxy)

When `example.com/blog` is served by a different system behind a proxy or edge rewrite:

- The proxied pages' canonical tags, sitemap entries and Open Graph URLs use the **main domain**,
  never the origin host.
- The **origin host** (`origin.example.com`, the vendor's default domain) must not be indexed
  separately. Block it by hostname: a password, an IP allowlist, or an `X-Robots-Tag: noindex`
  header set only on the origin host. A `robots.txt` block alone doesn't keep a URL out of the
  index.
- **Then confirm production carries no `noindex`.** An origin-wide `noindex` can pass straight
  through the proxy and deindex the live section.
- Route the section's assets (CSS, scripts, images, fonts) through the proxy too, or the pages
  break.
- Link the section from the main site's navigation, so it is part of the site's structure and not
  an island.

## Template: a small local business site

A starting hierarchy for a small service business. Keep it flat: every page one click from the
header. Each page still gets a one-sentence job (see [SKILL.md](SKILL.md), *Every page has one
job*).

```
Home (/)
├── Services (/services)
│   └── One page per service the business really sells (/services/<service>)
├── About (/about)
├── Reviews (/reviews)
├── Areas served (/areas)        only if the business really serves distinct areas
└── Contact (/contact)           the header CTA
```

- **Areas served** exists only when the business really works there and each area page has
  something true and local to say (jobs done there, travel terms). Templated town pages with the
  name swapped are doorway pages: don't build them.
- **Reviews** shows real reviews, used with permission. How to ask for them is in
  [reviews](../marketing/reviews.md), and the honesty rules in [marketing](../marketing/SKILL.md).
- Privacy and terms pages live in the footer.

## Before you call the migration done

- [ ] Every old URL has a decision (keep / merge / drop) in the inventory table.
- [ ] The redirect test passed against production: 301, one hop, target returns 200.
- [ ] Nothing redirects to the home page that didn't mean the home page.
- [ ] Sitemap, canonicals and internal links all use the new URLs on the canonical host.
- [ ] Change of address filed, if the domain changed.
- [ ] 404s and index coverage watched for two weeks, and every real miss redirected.
- [ ] The final redirect map is recorded in the project's docs.
