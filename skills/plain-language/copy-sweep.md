# Copy sweep — editing existing copy in passes

How to edit copy that already exists (a page, UI copy, an email) without flattening its voice or
inventing proof.

Adapted from the `copywriting` and `copy-editing` skills in `coreyhaines31/marketingskills` (MIT);
rewritten, with the expert-panel scoring and the manipulative emotion levers left out.

## Contents

- Step 1: pick the mode
- Step 2: the sweeps, in order
- The leave-it-alone test
- Step 3: AI-tells self-check
- Content refresh: updating a published article or page
- Before you hand it back

## Step 1: pick the mode

Decide what you were handed before changing a word. The mode sets how much you may change.

| Mode | You were handed | What you do |
| --- | --- | --- |
| **Point edit** | One named line, word or section ("fix this headline", "tighten paragraph two") | Change only that, plus the minimum around it to read cleanly (a pronoun, a transition). No sweep |
| **Real voice** | Copy with an angle, an opinion or recognizable word choices, roughly executed | Keep the voice, the argument and the emphasis. Fix only lines that fail a sweep below |
| **Blank or generic** | A one-line ask, or copy that could sit on any site (company-speak, AI mush) | Rewrite from the record: the behavior, obstacle and evidence list in the project's `docs/marketing.md` ([marketing](../marketing/SKILL.md); the record's shape is in [positioning-record](../marketing/positioning-record.md)). No record? Marketing's six questions come first |

State the mode in one line, with the evidence, before editing: "Real voice: the draft argues
against agencies in the founder's words and uses 'ship' and 'stuff'."

**Point-edit reply:** return only the changed lines, one reason each, and one alternative if the
choice is close. If you saw a serious problem elsewhere (a false claim, a broken CTA), name it in
one line at the end and leave it unfixed.

**Reading a real voice:** the author's vocabulary is a voice choice ("stuff" stays "stuff"), where
they spent words is a priority choice, and what they left out is a scope choice. Match all three.
If they gave a writing sample, it beats this skill's defaults.

## Step 2: the sweeps, in order

Run each sweep over the whole piece. When a later sweep changes a line, re-run the earlier sweeps
on that line: a proof added in sweep 4 can break the clarity sweep 1 fixed.

| # | Sweep | The question for each line | Fix |
| --- | --- | --- | --- |
| 1 | **Clarity** | Would the reader understand it on one read? | One idea per sentence; name the thing; cut qualifiers that bury the point. The de-jargon pass in [SKILL.md](SKILL.md) applies |
| 2 | **Voice** | Does it sound like the rest, and like the recorded voice? | Smooth shifts between casual and corporate, "we" and "the company". The voice in `LEARNINGS.md` or the record wins |
| 3 | **So what** | Does the reader learn what this does for them? | Tie each feature to the reader's benefit ("which means you…"). A claim with no benefit gets cut |
| 4 | **Prove it** | Can the page, or the evidence list, back this up? | Point at the proof. No proof: soften to what is true, or mark `[NEED: …]` (below) |
| 5 | **Specificity** | Could the reader picture it, and could it be shown false? | Swap adjectives for the fact they stand in for: the step count, the town, the turnaround. Apply the swap test |
| 6 | **Emotion** | Does it name a stake the reader really has? | Describe the real "before" in the reader's words. Only true stakes; no manufactured fear of missing out |
| 7 | **Zero risk near the CTA** | What would make someone hesitate right at the button? | Answer it beside the CTA with a guarantee, term or next step that is real: what happens after they click, the actual refund terms |

**`[NEED: …]` markers.** When a claim has no evidence, write the marker in place of the proof and
name the evidence that would unlock the claim: `[NEED: a review export or permission to quote the
customer]`, `[NEED: the written warranty terms]`. Never fill the gap with a plausible number, a
composite customer or a "studies show". The markers are the client's to-do list; collect them in
the reply. Before launch, grep for `[NEED:` the same way marketing greps for placeholders.

**The swap test.** Put a competitor's name where ours is. If the line still works, it says nothing
about us. Rewrite it from something only we can claim, or mark `[NEED: what sets us apart from
<named competitor>]`.

**Sweeps 4, 6 and 7 are where honesty breaks.** The rules live in marketing's Honesty check
([marketing](../marketing/SKILL.md)). The traps specific to editing: a number made "more specific"
by inventing it, a "Cancel anytime" next to a cancel flow that takes a phone call, and urgency
added because the emotion sweep felt flat.

## The leave-it-alone test

For every change, ask whether the new line is measurably better or only different. A line that
already passes every sweep stays as written. Revert any change you can't give a reason for. This
matters most in real-voice mode, where most of the value is the author's own choices.

## Step 3: AI-tells self-check

Some sentence shapes read as generated and say little. Readers who spot one start doubting the
claims around it. Search the draft for these and rewrite each hit from the underlying fact (the
mechanism, the number, the customer, the step). Swapping in a synonym just makes a new tell.

| Pattern | Example | What to search for | Rewrite |
| --- | --- | --- | --- |
| Contrast reveal | "It's not a tool, it's a teammate." "Not because X. Because Y." | `not `, `isn't`, `just` | State the true thing directly, with its reason |
| Negation list | "No setup call, no templates, no waiting." | `no `, `without`, `zero` | Say what does happen, in order. Keep one real absence by the CTA ("No card required") |
| Trailing pile-on of three | "…syncs your calendar, saving time, cutting stress, keeping teams aligned." | sentences over 20 words with 3+ commas | End at the claim. A clause that adds a new fact may stay |
| Self-answered question | "The result? Faster onboarding." | `?` in body and headings | Delete the question, keep the answer. FAQ questions are fine |
| Colon reveal | "The best part: it learns." | `:` in headlines and short lines | Write a normal sentence |
| Tidy closing aphorism | "Because your team deserves better." | the last line of each section | End on a number, the offer or the CTA |
| Filler intensifiers | truly, genuinely, incredibly, seamless, robust, powerful | the words themselves | Cut, or replace with the fact they stand in for |

**Leave these alone:** FAQ questions, a single "No card required" beside the CTA, a list of three
when there really are three things, and a formal voice that makes specific claims.

"No em dashes" is a house taste some projects hold. It isn't a rule of this check; follow the
project's recorded voice.

## Content refresh: updating a published article or page

| Signal | Do |
| --- | --- |
| The core message holds; facts, prices, examples or links are stale | **Refresh**: run the sweeps on changed lines only |
| The recorded voice has moved on since it was written | Refresh plus a voice pass |
| The audience, the angle, or what searchers want has changed | **Rewrite**, treated as a new page on the old URL |

**Keep what already works:**

- **Keep the URL.** If it must change, it gets a 301 (the redirect rules are in
  [site-migration](../information-architecture/site-migration.md)).
- **Keep heading anchors** that other pages link to, and the sections that rank for their own
  queries (the page's query list in Search Console, or your tool's equivalent, shows which).
- **Keep the voice.** A refresh shouldn't read like a different author.
- **"Last updated" only when the substance changed.** A new fact, price, step or section earns a
  visible date. A typo fix or a reshuffle doesn't; a fresh date on unchanged content misleads the
  reader. Put the year beside any statistic.

**The gap grid (for a page meant to rank).** Search the page's main query. Take the top few
results plus any direct competitor ranking near you. List the topics each covers, with our page as
the first column, then sort each topic we lack:

| Covered by | Call it | Do |
| --- | --- | --- |
| Most of the pages you compared | **Expected** | Add it; searchers assume it's there |
| Some of them | **Common** | Add it if it serves our reader |
| One of them | **Distinctive** | Add it only if it is useful to our reader, never to copy one page |
| None of them | **Uncovered** | Our best angle, if our evidence supports it |

Match coverage, ignore word counts, and stop when the reader's question is answered. Show the grid
and an outline marked keep / revise / new before rewriting, and get it approved. Never promise a
ranking or a traffic result.

## Before you hand it back

- [ ] The mode is stated with its evidence; a point edit touched only the named lines.
- [ ] Every sweep ran, and earlier sweeps were re-run on lines a later sweep changed.
- [ ] Every claim traces to the page or the evidence list, or carries a `[NEED: …]` marker.
- [ ] Every line passed the swap test, or was rewritten or flagged.
- [ ] Nothing near the CTA promises a guarantee or term that isn't real.
- [ ] The AI-tells search ran and each hit was rewritten from a fact.
- [ ] Unchanged lines that already passed were left alone.
- [ ] The reply lists the `[NEED: …]` markers in one place for the client.
