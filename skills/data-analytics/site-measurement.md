# Measuring a small site or app

How to tell whether a change to a public site or small app worked, without traffic it doesn't have.

Adapted from the `ab-testing`, `analytics`, `attribution`, `onboarding` and `ads` skills in
`coreyhaines31/marketingskills` (MIT); rewritten, with the manipulative parts left out.

## Contents

- 1. Do the sample-size arithmetic before proposing an A/B test
- 2. Name events and keep a tiny tracking plan
- 3. UTM links
- 4. Consent first
- 5. Ask "How did you hear about us?"
- 6. Find the aha moment without fooling yourself
- 7. Brand searches and payback
- Common failure modes

## 1. Do the sample-size arithmetic before proposing an A/B test

Most small sites can't reach a trustworthy result in a useful time. Check first, with the standard
two-proportion approximation (about 80% power at α = 0.05, two variants):

```
n per variant ≈ 16 · p(1 − p) / δ²

p = the conversion rate (use the average of the current and hoped-for rate)
δ = the absolute difference you want to detect (3.0% → 3.6% is δ = 0.006)
weeks ≈ (n × number of variants) / eligible visitors per week
```

Worked examples, for a page with 1,000 eligible visitors a week:

| Change you hope to detect | p | n per variant | Total | Weeks |
| --- | --- | --- | --- | --- |
| 3.0% → 3.6% (a modest gain) | 0.033 | ≈ 14,200 | ≈ 28,400 | 29 (rounded up to whole weeks) |
| 3.0% → 6.0% (doubling) | 0.045 | ≈ 760 | ≈ 1,530 | 2 (rounded up to whole weeks) |

Count people (or sessions, consistently), not page views. Each extra variant multiplies the total.

**If the answer is months, don't A/B test.** Ship the best-judged version and compare before and
after:

- Write the date and the change in a dated change log in the repo (one line: date, what changed,
  why, which number should move).

**When you do run a test:**

- [ ] The hypothesis is written before launch: because we saw X, we expect change Y to move metric
      Z for audience W.
- [ ] One primary metric decides it. Others are context, or guardrails that must not get worse.
- [ ] The duration is fixed in whole weeks, from the arithmetic above, before launch.
- [ ] No peeking and no stopping early on a good day. Checking a running test repeatedly and
      stopping when it looks good produces false winners. Stop early only for a broken variant or a
      guardrail that is clearly being harmed.
- [ ] A returning visitor sees the same variant every time.
- [ ] Report the effect size and its interval, not only "significant". A test that ends with no
      clear difference is a result; don't extend it until it turns significant.

## 2. Name events and keep a tiny tracking plan

- **Names are `object_action`, lowercase with underscores:** `signup_completed`,
  `quote_requested`, `invoice_paid`. Context goes in properties (`plan`, `location`), not in the
  name. Where the analytics tool has its own recommended event names, use those rather than
  inventing a synonym.
- **Track for a decision.** Each event answers a business question from Step 2 of
  [the skill's workflow](SKILL.md). An event nobody reads is noise to maintain.
- **Keep the plan as a short table in the repo**, next to the code that fires the events:

| Event | Fires when | Properties |
| --- | --- | --- |
| `quote_requested` | the server accepts the quote form (not the button click) | `service`, `source` |
| `signup_completed` | the account row is created | `method`, `plan` |
| `order_paid` | the payment provider confirms the payment | `plan`, `value`, `order_id` |

- **Fire conversions on the confirmed outcome**, not the click: from the server after it accepts
  the form or payment, or on the thank-you state that only renders after success. A click counts
  failed validations, double clicks and abandoned payments. Send a stable id (`order_id`) so a
  retried or reloaded confirmation counts once.
- **No personal data in event properties**: no emails, names, phone numbers or free-text fields.

## 3. UTM links

- **Lowercase everything, hyphens between words.** Many tools treat `Newsletter` and `newsletter`
  as two sources, and the split never merges back.
- **A short, fixed vocabulary** for `utm_source` and `utm_medium`, written down once and reused:

| Parameter | Allowed values (example set; keep yours just as short) |
| --- | --- |
| `utm_medium` | `email`, `social`, `cpc`, `referral`, `print`, `qr` |
| `utm_source` | one spelling per sender: `newsletter`, `facebook`, `google`, `partner-name` |
| `utm_campaign` | `topic-yyyy-mm`, e.g. `spring-offer-2026-04` |

- **Never put personal data in a URL**: no email, name, phone or user id in a UTM or any query
  string. URLs land in analytics reports, server logs and referrer headers.
- Click the final link (after any shortener or redirect) and check the parameters survived.

## 4. Consent first

- **Where the law requires consent (the EU, the UK and others), load no analytics or ad tag that
  sets an identifier until the visitor agrees.** Check before launch that the page makes zero
  analytics requests pre-consent, not just that a banner shows. The integrations skill's
  [GA4 notes](../integrations/google-analytics.md) have a worked end-to-end check.
- **Prefer cookieless or privacy-first analytics for small sites** (e.g. a self-hosted or
  privacy-focused counter). It often removes the banner question and gives a small business all
  it needs. Confirm for your markets that the chosen setup really needs no consent; rules differ
  by country and change (as of 2026-10).
- **No visitor de-anonymization and no identity stitching across third-party domains** without
  the visitor's consent: no tools that reveal who an anonymous visitor is, and no passing a
  visitor id into another company's URLs to join records later. See
  [security-and-hardening](../security-and-hardening/SKILL.md) for handling the data you do keep.
- Collect only what a decision needs, and decide how long to keep it.

## 5. Ask "How did you hear about us?"

For a small business this one form field is often worth more than any attribution model. It
catches word of mouth, a neighbour's recommendation, a podcast or a printed flyer, which tracking
cannot see.

- Put it on the lead, quote or signup form, at the moment of conversion, when memory is freshest.
- A short pick-list of your real channels plus "Other (tell us)" with a text box. Keep it optional.
- Store it with the lead or account record, and read it next to the UTM data.
- It is recall, not truth: people name the memorable touch, not the first one. Use it to spot
  channels, not to divide credit to the decimal.

## 6. Find the aha moment without fooling yourself

To learn which early behavior goes with users staying:

1. **Set the windows.** Signup is time zero. Pick an early window (e.g. the first 7 days) and a
   separate retention outcome that starts **after** it ends (e.g. active in week 4). Fit both to
   how often the product is naturally used.
2. **List candidate early behaviors**: created a first project, invited someone, connected an
   account, saw a first report.
3. **Use complete cohorts only.** Include every signup old enough to have reached the end of the
   retention window. Leave out recent signups rather than counting them as churned.
4. **Compare retention** of users who did each behavior in the early window against those who
   didn't. A behavior measured inside the retention window can't predict it (that's circular).
5. **Treat a strong difference as a correlation.** Motivated users do everything more. Confirm
   with a change: make the behavior easier for new users and see if retention follows. Re-check the
   finding on a later cohort before you build onboarding around it.

The onboarding flow and activation model themselves are in
[marketing's onboarding notes](../marketing/onboarding.md).

## 7. Brand searches and payback

When a business runs paid search, report brand and non-brand terms separately. A cheap cost per
acquisition on people searching the business's own name mostly measures demand it already had, so
it isn't a win. Judge spend on non-brand results. For a small business, ask how many months of
**gross margin** (revenue minus the cost of serving the customer) it takes to earn back what a
customer cost to acquire, per plan or service, and compare that with the cash it can tie up. A
lifetime-value ratio hides when the money comes back.

## Common failure modes

- **Running an A/B test the traffic can't support**, then shipping the "winner" of a coin flip.
- **Stopping a test the day it looks good.**
- **Counting clicks as conversions**, or the same order twice on a reload.
- **Mixed-case UTMs** splitting one source into several rows.
- **Analytics firing before consent**, found by a visitor or a regulator instead of a pre-launch
  check.
- **Several changes in one week**, so the before/after can't say which one mattered.
