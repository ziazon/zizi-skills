# Onboarding — from signup to first real value

How to get a new user from "I signed up" to "this works for me" in as few steps as possible, and
how to choose the way they try the product before paying. The diagnosis row "they signed up but
didn't stick" in [SKILL.md](SKILL.md) points here.

Adapted from the `onboarding` and `signup` skills in `coreyhaines31/marketingskills` (MIT);
rewritten, with the manipulative parts left out.

## Minimum Path to Value

The shortest route to a moment convincing enough that the user decides "yes, this is for me". Not
the fastest path to any value, and not the full tour.

1. **Name the value moment** (the aha moment, below). The path leads there.
2. **List every step** between signup and that moment: each screen, field, click, confirmation,
   permission prompt and empty page. Count them honestly; the real number is usually larger than
   the team thinks.
3. **Remove or defer.** For each step ask: must they do this now to reach value? If not, cut it,
   do it later, pre-fill it, or make it skippable. Profile details, settings, team invites and
   "how it works" screens rarely belong before first value.
4. **Rebuild** the path from what survived, value first. Watch where people still stop, and cut
   again. The first rebuild is a guess, not the finish.

Also: one goal for the first session, doing over showing (let them make the real thing, not watch a
tour), and no dead ends. An empty page says what goes there and offers the one action that fills
it, or shows clearly labeled example data.

## Choosing how people try it

Choose the model before designing the flow; the model shapes the whole path. The market decides
more than taste does: price, how complex setup is, and what buyers in this category expect.

| Model | Fits when | Watch for |
|---|---|---|
| Free plan | The free plan is useful on its own and growing customers naturally need more | Paid plans must add real value, not withhold basics |
| Free trial, no card | Value shows within the trial window | Say exactly what happens when it ends |
| Free trial, card up front | Buyers are serious and setup is quick | Remind before the first charge; cancel in one step |
| Paid with money-back guarantee | Value shows quickly and we can honor refunds without a fight | The guarantee rules in [pricing-and-offers.md](pricing-and-offers.md) |
| Done with you (a call or hands-on setup) | High price, complex setup, or a small local service | Doesn't scale; keep it for where it pays |

**Judge a card-up-front trial on visitor to paid, not trial to paid.** Asking for a card cuts how
many people start, so trial-to-paid looks better even when fewer visitors end up paying. Compare
visitor→trial × trial→paid for each option over the same traffic and the same time span, and
include refunds and early cancels.

The free plan is honest when it is genuinely useful and the paid plan adds what bigger customers
need (more of the value metric, team features). We do not design a free plan to be deliberately
unsatisfying, and a trial never ends with the user's own data held back.

## Finding the aha moment

The aha moment is an early action that predicts people stay: "created the first project and
invited one person", "sent the first invoice", "booked the first job".

Find it with a cohort comparison: the early action measured in a window that ends *before* the
retention window, every signup old enough to count, and the result treated as a hypothesis until a
change confirms it. The method, step by step, is in
[site-measurement.md](../data-analytics/site-measurement.md) (section 6).

## Checklists

Use one when setup has several steps or the product has a few features worth finding.

- **Three to seven items.** More reads as homework.
- **Value first.** Order by what gets them to the aha moment, with a quick win at the top.
- **Always dismissible**, and it stays dismissed. A checklist is help, not a gate.
- **A pre-completed step only if it was really done** ("Account created" after they made one).
  Never tick a step they haven't done to make progress look further along.
- **Show progress** and mark the end clearly; the last step should land on something good.

Guided tours follow the same rules: a few steps, skippable at any point, not repeated for returning
users. Reminder emails for people who stalled reinforce the next in-app step; one idea per email.

## Signup: value first, signup second

- **Show value before asking for an account where possible**: let people try a calculator, browse
  examples, or build a draft, and ask for an account when they want to save it.
- **Ask only what's needed to start.** Usually an email (or phone) and a way to sign in. Company,
  role, team size and the rest can wait until the product needs them.
- **Say what happens next**: how long signup takes and what they'll see after.
- **Let people explore while email verification is pending.** Require verification only before
  the action that needs it (sending, paying, inviting). Offer an easy resend and a way to fix a
  mistyped address.
- Field-level form rules (labels, errors, password fields, no confirm-email field) live in
  [forms-and-overlays.md](../frontend/forms-and-overlays.md).

## Not here on purpose

- **Streaks, leaderboards and similar pressure mechanics.** They push people to come back for the
  streak, not for the value, and that is not what onboarding is for.
- **Benchmark numbers** for activation, abandonment or checklist completion. Our own numbers come
  from our own measurement (data-analytics).
- **Upgrade prompts during onboarding.** The first ask to pay comes after real value; see the
  upgrade-moment rules in [pricing-and-offers.md](pricing-and-offers.md).
