# App store platform specs (snapshot: upstream March 2026, folded 2026-10)

The limits, sizes and rules behind [SKILL.md](SKILL.md), per store. **This is a dated snapshot:
check Apple's and Google's current docs before relying on any number here.**

Compiled from the `aso` skill's reference files in `coreyhaines31/marketingskills` (MIT), which
cite the official docs as of March 2026. The numbers were not re-checked against those pages
when this file was written. Lines marked *unverified* have no official source cited upstream.

Official sources:

- Apple product page: https://developer.apple.com/app-store/product-page/
- Apple search: https://developer.apple.com/app-store/search/
- Apple App Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- Google Play preview assets: https://support.google.com/googleplay/android-developer/answer/9866151
- Google Play metadata policy: https://support.google.com/googleplay/android-developer/answer/9898842
- Google Play store listing help: https://support.google.com/googleplay/android-developer/answer/4448378
- Android vitals: https://developer.android.com/topic/performance/vitals

## Contents

- Apple App Store
  - Text fields
  - Screenshots and previews
  - Review prompt
  - Testing and alternate pages
  - Rejection triggers (App Review Guidelines, section 2.3)
- Google Play
  - Text fields
  - Banned in metadata
  - Graphics and video
  - Quality thresholds (Android vitals)
  - Testing and alternate listings
- Re-check before each listing change

## Apple App Store

### Text fields

| Field | Limit | Searched? | Notes |
| --- | --- | --- | --- |
| App name | 30 characters (min 2) | yes | unique; no trademarks, competitor names or prices |
| Subtitle | 30 characters | yes | no unverifiable claims |
| Keywords | **100** (docs: characters; practitioners report bytes) | yes, hidden | commas, no spaces; if bytes, non-Latin scripts use 2–3 a character |
| Description | 4,000 characters | no | plain text |
| Promotional text | 170 characters | no | changeable without a new version |
| What's new | 4,000 characters | no | required for every version after the first |
| In-app purchase name | 35 characters | yes | |
| In-app purchase description | 55 characters | no | |
| In-app event name / short description | 30 / 50 characters | yes | |

*Unverified:* upstream says that since June 2025 Apple extracts screenshot caption text for
search, citing no official page. Treat captions as written for people until Apple's docs say otherwise.

### Screenshots and previews

| Asset | Rule |
| --- | --- |
| Screenshots | 1–10 per device; JPEG or PNG; 6.9" iPhone and 13" iPad sizes required, smaller devices scaled from them |
| 6.9" iPhone portrait | 1260 × 2736 |
| 13" iPad portrait | 2064 × 2752 |
| App previews | up to 3; 15–30 seconds; .mov, .m4v or .mp4; H.264 or ProRes 422 HQ; up to 500 MB |
| Preview playback | autoplays muted on the product page |

### Review prompt

- The system review request (StoreKit) shows at most **3 times in 365 days** per user, and the
  system may show it less.
- Don't build custom buttons that ask for a review in place of the system prompt.
- Developers can reply to every review in App Store Connect. Ratings are per country.

### Testing and alternate pages

- **Product page optimization:** up to 3 treatments against the original, one test at a time,
  up to 90 days. Icons, screenshots and previews can be tested; title, subtitle, description and
  keywords cannot. Icon variants must ship in the binary.
- **Custom product pages:** up to 70, each with its own screenshots, previews and promotional
  text; each goes through review.

### Rejection triggers (App Review Guidelines, section 2.3)

| Guideline | Trigger |
| --- | --- |
| 2.3.1 | hidden features, misleading marketing, false pricing |
| 2.3.2 | in-app purchases not disclosed in description or screenshots |
| 2.3.3 | screenshots that don't show the app in use (only splash or login) |
| 2.3.4 | previews with content that isn't the app |
| 2.3.5 | wrong category |
| 2.3.7 | trademarks, competitor names, prices or irrelevant terms in metadata |
| 2.3.8 | metadata not suitable for all audiences |
| 2.3.10 | other platforms' names or imagery |
| 2.3.12 | generic "what's new" for significant changes |

## Google Play

### Text fields

| Field | Limit | Searched? | Notes |
| --- | --- | --- | --- |
| App title | 30 characters | yes, strongest signal | |
| Short description | 80 characters | yes | visible without expanding |
| Full description | 4,000 characters | yes | the whole text is read |
| Developer name | 64 characters | partly | same rules as the title |

### Banned in metadata

| Where | Not allowed |
| --- | --- |
| Title, icon, developer name | emoji or repeated special characters; ALL CAPS unless a registered brand; "top", "best", "#1", "free", "no ads"; claims about store performance or endorsement; calls to action |
| Short description | the same performance claims; calls to action; unattributed testimonials |
| Screenshots, feature graphic, video | time-sensitive taglines; calls to action; anything that doesn't show the real app |

### Graphics and video

| Asset | Rule |
| --- | --- |
| Phone screenshots | 2–8; 9:16 or 16:9; at least 320 px a side, at most 3,840 px long edge; JPEG or 24-bit PNG, no alpha; up to 8 MB each |
| Tablet / Chromebook screenshots | 4–8; at least 1,080 px short edge |
| Feature graphic | exactly 1024 × 500; JPEG or 24-bit PNG; needed for featured placements |
| Icon | 512 × 512, 32-bit PNG, up to 1,024 KB; full square (Google rounds the corners); no ranking claims or deal text |
| Preview video | a public or unlisted YouTube URL; no ads or monetization; embeddable; not age-restricted; may autoplay muted for up to 30 seconds depending on device and settings |

### Quality thresholds (Android vitals)

Apps above these rates can get reduced visibility and warnings on the listing, judged on a
28-day rolling average:

| Metric | Overall | Per device |
| --- | --- | --- |
| User-perceived crash rate | 1.09% | 8% |
| User-perceived ANR rate | 0.47% | 8% |

### Testing and alternate listings

- **Store listing experiments:** up to 3 variants plus the control; icon, feature graphic,
  screenshots, video and both descriptions are testable; run at least 7 days; signed-in users
  only.
- **Custom store listings:** up to 50, targeted by country, install state, inactive users or ad
  campaign.
- **Promotional content:** submit at least 4 days before start, 14 for a featuring request.

## Re-check before each listing change

- [ ] Every limit used in the change re-read on the official page today.
- [ ] Any rule here that the official page no longer states removed from this file, dated.
