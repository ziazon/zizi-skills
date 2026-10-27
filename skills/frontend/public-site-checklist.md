# Frontend — public site checklist

One checklist for a public website, or an app's public pages: what every new page needs, what the
site needs once, and what to check on launch day and the week after.

Adapted from the `seo-audit`, `schema`, `ai-seo`, `launch` and `image` skills in
`coreyhaines31/marketingskills` (MIT); rewritten, with the vendor defaults and the doorway-page
patterns left out.

Scope: getting pages found, read and shared correctly. Speed and Lighthouse scores are
[web-performance.md](web-performance.md); multi-language URLs and `hreflang` are
[i18n](../i18n/SKILL.md); the claims on the page pass the honesty check in
[marketing](../marketing/SKILL.md). Ongoing SEO work (rankings pushes, keyword targeting, AI
visibility tracking, link building) is out of scope here.

## Contents

- 1. Every new public page
  - Images on the page
- 2. Site-wide (once, then re-check at launch)
  - Crawling and hosts
  - AI crawlers in robots.txt (the owner's choice)
  - Structured data (JSON-LD)
  - A local business
  - Multi-language
- 3. Launch day and the week after

## 1. Every new public page

| Check | How to know it passes |
| --- | --- |
| Unique `<title>` | No other page has the same string. Lead with what the page is about; brand last, and only if it helps. Keep the important words in the first ~50 characters. |
| Unique meta description | Says what the reader gets on this page, in a sentence or two. Not a template repeated site-wide. |
| One `<h1>` | Matches the title's topic. Title, H1, slug and description all describe the same thing. |
| Self-referencing canonical | `<link rel="canonical">` points at this page's own production URL, on the canonical host. |
| In the XML sitemap | The production URL appears, and only canonical, indexable URLs are listed. |
| Linked from existing pages | At least three relevant existing pages link to it with descriptive anchor text. A page nothing links to is an orphan. |
| Primary content in server HTML | `curl -s <url>` shows the heading and body text. Google renders JavaScript in a later pass, and most AI fetchers don't run it at all. |
| No stray `noindex` | Neither a `<meta name="robots">` nor an `X-Robots-Tag` header blocks it, and robots.txt doesn't disallow it. |
| Share preview | `og:title`, `og:description`, `og:image` (1200×630 is the usual size) and `twitter:card`. Make the image with [design-assets](../design-assets/SKILL.md). |
| Structured data, where the page type has one | See *Structured data* below. |

**Title patterns by page type** (pick the type first; don't blend two):

| Page type | Pattern |
| --- | --- |
| Home | `[What it is] for [who] \| [Brand]` |
| Service or product | `[Service] in [area] \| [Brand]` or `[Category] for [audience] \| [Brand]` |
| Pricing | `[Brand] pricing: plans and costs` |
| Comparison | `[A] vs [B]: [the deciding difference]` |
| How-to or article | `How to [task]` or `[Topic]: [what the reader gets]` |
| Contact, about | `Contact [Brand]`, `About [Brand]`, plain and short |

Only put "free", a year or a number in a title when the page delivers it.

### Images on the page

- **Modern formats.** AVIF or WebP for photos, SVG for logos and icons, PNG only where lossless
  matters; keep a fallback through `<picture>` or the CDN.
- **Sized to the display.** Don't ship a 4000px file into an 800px slot; use `srcset` for widths.
- **Explicit `width` and `height`** on every `<img>` so the page doesn't shift as it loads.
- **Loading strategy.** The LCP image is eager with `fetchpriority="high"`; everything below the
  fold is `loading="lazy"`. The full contract and its test are in
  [web-performance.md](web-performance.md), step 3.
- **Real alt text.** Describe what the image shows and why it's there. Decorative images get
  `alt=""`. No keyword lists.
- **Real screenshots for product UI.** Capture the actual app. Image models invent interfaces
  that don't exist, which is a false claim about the product.
- **No AI-generated people presented as real staff or customers.** That is invented social proof
  (see the honesty check in [marketing](../marketing/SKILL.md)). Use real photos with permission,
  or no faces.

## 2. Site-wide (once, then re-check at launch)

### Crawling and hosts

- [ ] **One canonical host.** `http://` and the non-canonical host (`www` or apex) 301 to
      `https://` on the canonical one, in one hop. Trailing-slash and case rules are consistent
      across links, canonicals and the sitemap.
- [ ] **robots.txt** exists, allows the pages you want found, and names the sitemap
      (`Sitemap: https://…/sitemap.xml`).
- [ ] **XML sitemap** lists production URLs only, all canonical, all returning 200.
- [ ] **A missing page returns HTTP 404** (or 410), not a 200 with "not found" text. Check with
      `curl -s -o /dev/null -w '%{http_code}' https://<host>/no-such-page`. An SPA catch-all route
      is the usual culprit.
- [ ] Your CDN or firewall doesn't silently block the crawlers you chose to allow. Check what it
      does per user agent; many block bots by default without anyone deciding to.

### AI crawlers in robots.txt (the owner's choice)

AI vendors run separate agents for different purposes, and each can be allowed or blocked on its
own. Allowing search and user fetches while blocking training is a common stance, not a rule.
**Ask the site owner which they want and record the answer**; don't pick for them.

Names as of 2026-10, from the vendors' published lists. They change: check each vendor's
current page before relying on them.

| Purpose | User agents | What blocking it does |
| --- | --- | --- |
| Classic search | `Googlebot`, `Bingbot` | Removes the site from that search engine. Almost never wanted. |
| AI search / discovery | `OAI-SearchBot`, `PerplexityBot`, `Claude-SearchBot` | May keep the site out of that assistant's search results and citations. |
| User-triggered fetch | `ChatGPT-User`, `Claude-User`, `Perplexity-User` | Fetches made when a person asks about a page. Some vendors say these may not follow robots.txt. |
| Model training | `GPTBot`, `ClaudeBot` | Opts out of potential training use. Not, by itself, a visibility loss. |
| Gemini training and grounding | `Google-Extended` (a robots token, not a crawler) | Google says it doesn't affect Google Search ranking or inclusion. |

Vendor pages: [OpenAI](https://developers.openai.com/api/docs/bots),
[Anthropic](https://privacy.anthropic.com/en/articles/8896518-does-anthropic-crawl-data-from-the-web-and-how-can-site-owners-block-the-crawler),
[Perplexity](https://docs.perplexity.ai/docs/resources/perplexity-crawlers),
[Google](https://developers.google.com/crawling/docs/crawlers-fetchers/google-common-crawlers).

**Don't write separate content for AI.** Google's own guidance says no special files or markup
are needed for its AI features, and that pages made for machines rather than people risk its
scaled-content spam policy. Good headings, real answers near the top and server-rendered HTML
serve both. An `llms.txt` at the root is an optional nice-to-have with no proven effect; add it
only if it's cheap and kept in sync.

### Structured data (JSON-LD)

- [ ] **Rendered in the server HTML.** Put the `<script type="application/ld+json">` in the
      SSR output, not injected by client JS. `curl` showing it proves it's server-rendered. If
      `curl` doesn't show it, check the rendered page (DevTools:
      `document.querySelectorAll('script[type="application/ld+json"]')`) or Google's
      [Rich Results Test](https://search.google.com/test/rich-results) before reporting it
      missing; a client-injected block exists but should move server-side.
- [ ] **Escape `<` when embedding.** Serialize with `JSON.stringify(data).replace(/</g, '\\u003c')`
      (or the framework's helper). Plain JSON escaping lets a string containing `</script>` end
      the tag early, which is an injection hole when any field comes from user or CMS data.
- [ ] **Mark up only what is visible on the page.** Prices, hours, addresses and reviews in the
      markup match what the reader sees.
- [ ] **Never a self-serving or invented `aggregateRating`.** A business marking up its own
      testimonials doesn't earn review stars, and made-up ratings are false claims (the honesty
      check in [marketing](../marketing/SKILL.md)).
- [ ] **Check Google's current [search gallery](https://developers.google.com/search/docs/appearance/structured-data/search-gallery)
      before promising a rich result.** Valid schema.org markup is not the same as a Google
      feature. Upstream reports, as of 2026-10 (re-check): FAQ rich results ended 2026-05, HowTo
      in 2023, the sitelinks search box in 2024. Those types may still describe visible content;
      just don't sell them as a search appearance.
- [ ] Validate with the Rich Results Test (Google features) and the
      [Schema Markup Validator](https://validator.schema.org/) (everything else).

### A local business

- [ ] `LocalBusiness` (or its most specific accurate subtype) on the real location's page, with
      the same name, phone, hours and address the page shows. Google's local rich result needs a
      public address; a service-area business that can't publish one doesn't get it, and never
      gets an invented one.
- [ ] A service area is described as a service area, not as extra branches.
- [ ] **No fake city pages.** A templated "[service] in [city]" page per town, with only the
      town name swapped, is a doorway page under Google's
      [spam policies](https://developers.google.com/search/docs/essentials/spam-policies#doorway-abuse).
      Publish a town page only when it carries distinct local content (real jobs done there, real
      local details); otherwise one honest coverage page.

### Multi-language

`hreflang`, localized URLs, translated titles and meta, per-locale sitemap entries:
[i18n](../i18n/SKILL.md) (*Planning a multi-language program*, decision 9).

## 3. Launch day and the week after

**Before the switch**

- [ ] Staging's `noindex` or basic auth is **not** in the production build, and production is
      not blocked in robots.txt. Shipping the staging `noindex` is the classic launch failure.
- [ ] Canonicals and the sitemap point at the production host, not staging.
- [ ] Old URLs have a tested 1:1 redirect map: [site-migration.md](../information-architecture/site-migration.md).
- [ ] No placeholder copy, test prices or lorem ipsum left (grep for it).
- [ ] Analytics fires on the **confirmed** conversion (the thank-you state or server success),
      not the button click: [site-measurement.md](../data-analytics/site-measurement.md).
- [ ] Rollback is a step you have actually practiced on this host, not one you've read about.
- [ ] Lower DNS TTL a day ahead if DNS changes.

**At the switch**

- [ ] HTTPS works on every hostname and the redirects land on the canonical one.
- [ ] Top pages return 200 with the right title, canonical and content.
- [ ] Every form submitted end to end on production, and the entry arrives wherever it should
      (inbox, CRM, database).
- [ ] Re-check that production isn't `noindex`.
- [ ] Search Console and Bing Webmaster Tools verified; sitemap submitted to both.

**The following days**

- [ ] Watch index coverage and 404s in Search Console daily for the first week, then weekly.
      Add redirects for real 404s as they appear.
- [ ] Fix internal links that still point at redirected URLs.
- [ ] Compare traffic and conversions to the period before, page by page, not just in total.
