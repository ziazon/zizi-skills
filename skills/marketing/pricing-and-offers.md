# Pricing, offers and upgrade moments

How to choose what to charge for, shape plans, build an offer, and ask for an upgrade inside an
app, all inside [SKILL.md](SKILL.md)'s honesty check. Pricing a client's service is the client's
call; this file helps frame a price, not set one for them.

Adapted from the `pricing`, `offers` and `paywalls` skills in `coreyhaines31/marketingskills`
(MIT); rewritten, with the manipulative parts left out.

## Contents

- Pricing
  - What to charge for: the value metric
  - The first price
  - Plans: good-better-best
  - Anchoring
  - Prices written as text
  - Changing a price
  - Price research
- Offers
  - An offer, not a discount
  - The value equation, as a diagnostic
  - Guarantees
  - Why now: honest formats only
- Upgrade moments in an app
  - Triggers
  - Hard and soft gates
  - Rules

## Pricing

### What to charge for: the value metric

Charge on the thing that grows as the customer gets more value. Ask: "when a customer uses more of
this, do they get more out of the product?" If yes, it can be the metric.

| Metric | Fits when |
|---|---|
| Per person (seat) | The value is people working together |
| Per use (records, sends, calls) | Use varies a lot between customers |
| Per job or project | The customer thinks in jobs (a quote, an install) |
| Flat fee | The product is simple and use is similar for everyone |

A good metric is easy to explain in one sentence, grows with the customer, and is hard to game.
A metric that punishes the behavior we want (charging per invite in a tool that needs teams) is
the wrong one.

### The first price

On day one there is no price to optimize, only a bet to learn from. Ship it and let real buyers
answer.

- **Price by order of magnitude first.** Decide which bucket the customer is in (one person's tool,
  a small team's tool, something a business runs on) and start at a round number in that bucket.
  Fine-tune inside the bucket once there is signal.
- **Beware the too-cheap trap.** A very low price draws signups from people who would never pay a
  real price. It looks like traction and isn't, and raising it later is much harder than starting
  higher.
- **Price between the next-best alternative and the value delivered.** Cost to serve is a floor,
  not the basis. A competitor's price is a data point, not a target.

### Plans: good-better-best

- **Three plans at most for most products**, one marked as best for most customers (the default
  effect, used for the customer).
- **Every plan is one a real customer would pick.** No decoy plan built to be bad value so another
  looks good. (Some playbooks tell you to make the middle plan the "best value" by making its
  neighbors worse; we don't.)
- **Say who each plan is for** in a line, and state each plan's limits in words.
- **Plans differ on one or two clear axes**: usage limits, features, support level, access.

### Anchoring

Anchor only against something real: a real competitor's published price (dated), the real cost of
doing it by hand, or the plan above. Never an inflated "was" price or a "worth $X" with nothing
behind it.

### Prices written as text

Prices, plan limits and what each plan includes live in the page's text, not only in an image, a
script-only render or a "contact us". A person, a screen reader and an AI assistant all need to read
them. If one plan really is quote-only, show a starting price or say what the quote depends on.

**The paste test:** give the pricing page URL (or its rendered text) to an AI assistant that can
browse and ask "What are the plans and prices?" A wrong or partial answer is a real finding. It is
a quick check, not proof every assistant fails. Structured data for prices and crawler access go
to [public-site-checklist.md](../frontend/public-site-checklist.md).

### Changing a price

1. **Test on new customers first.** New signups have no old price to compare against; watch
   whether they still buy.
2. **Give existing customers notice before their price changes**, in plain words: the new price,
   the date, why (usually more value shipped), and what they can do (keep the old price for a
   stated period, switch plans, or cancel). The date and the terms are the ones we honor.
3. Never change an existing customer's price silently or bury it in a renewal email.

### Price research

Van Westendorp's four questions (too expensive, too cheap, getting expensive, a bargain) give a
**shortlist** of prices to test. They measure how a price feels, not how many will buy at it, so
the "optimal" point is not an optimum. Confirm with real purchases.

## Offers

### An offer, not a discount

A discount lowers the price; an offer raises the value: a guarantee, done-for-you setup, a
migration, a real bonus. A discount to win a stranger anchors the product as cheap and draws
customers who leave when the price returns. Discount, if at all, to reward existing customers or in
a real seasonal window that everyone gets.

### The value equation, as a diagnostic

```
             dream outcome × perceived likelihood
  value  =  ─────────────────────────────────────
                 time delay × effort
```

When an offer is stuck, score each part honestly and fix the weakest one first:

| Part | Ask | Raise it with |
|---|---|---|
| Dream outcome | Can they picture the result they actually want? | Name the outcome, not the deliverable |
| Perceived likelihood | Do they believe it will work for them? | Real proof from people like them, a guarantee we honor |
| Time delay | How soon is the first win? | A faster first result, assets on day one |
| Effort | What do they spend besides money? | Done-for-you, fewer decisions, defaults |

"Lower the price" is usually a likelihood or effort problem in disguise. Proof comes from the
record's evidence list ([positioning-record.md](positioning-record.md)), never invented.

### Guarantees

- **Offer only a guarantee we will actually honor, quickly, without a fight.** No conditions
  written so refunds rarely happen. If a condition is needed (the customer did the work), keep it to
  one or two, state them next to the guarantee, and make the claim process one step.
- **Never promise an outcome we cannot control.** A missed promise costs more than no promise.

### Why now: honest formats only

| Format | Honest when |
|---|---|
| Real capacity | We really can take only so many ("two installs a week; next opening is the 14th") |
| A cohort | It has a real start date and the door really closes |
| A founding price | The price really rises when the stated count or date is reached |
| A bonus that expires | The bonus really goes away on the date; the core offer stays |
| A scheduled price increase | It really happens on the date, and the date is public |

Anything else (resetting timers, constant "only 3 left", invented viewer counts, repeated "last
chance") fails the honesty check in [SKILL.md](SKILL.md). Many offers need no urgency at all:
monthly plans people can cancel, and low-priced products. If an offer only works with fake
urgency, the value equation is the problem.

## Upgrade moments in an app

Where a free or trial user is asked to pay.

### Triggers

| Trigger | The screen should |
|---|---|
| Feature gate (they tapped a paid feature) | Say what it does and why it's paid; let them go back |
| Usage limit (they hit a cap) | Show the limit and what upgrading changes; offer a free way to continue (archive, delete) |
| Trial end | Warn ahead of time; say exactly what happens on the end date and what they keep |

### Hard and soft gates

- **Hard gate**: the action stops until they pay. Fits a feature that is clearly part of a paid
  plan.
- **Soft gate**: they can preview, finish the current task, or continue in a limited way. Fits
  usage limits and most first encounters.

### Rules

- **Always a way out.** A visible "Not now" or "Continue free" on every upgrade screen.
- **Never during onboarding or in the middle of a task.** Ask after they have had real value
  ([onboarding.md](onboarding.md)), at a natural pause.
- **A long cool-down after a dismiss** (days, not hours), and a cap per session.
- **Show what they keep** when a trial ends or they stay free: their data, their work, the free
  features. Never hold data hostage.
- **Upgrading takes few steps and works at once.** Downgrading and cancelling are as easy (the
  honesty check). Failed payments and subscription emails go to
  [billing-recovery.md](../integrations/billing-recovery.md).
