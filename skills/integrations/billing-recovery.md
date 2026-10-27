# Billing recovery and subscription lifecycle

Failed payments, the subscription emails apps forget, and a cancellation that stays honest.

Adapted from the `churn-prevention` (dunning half) and `emails` skills in
`coreyhaines31/marketingskills` (MIT); rewritten, with the manipulative parts left out. Its
cancel-flow "save" tactics were not adopted.

## Contents

- 1. Tell the customer, in email and in the app
- 2. Grace period, then a clear final state
- 3. Billing webhooks (as of 2026-10, check current docs)
- 4. Lifecycle emails a subscription app usually forgets
- 5. Cancellation
- Before you call this done

## 1. Tell the customer, in email and in the app

A short sequence after a failure. Each message is plain, assumes an accident, and has **one
direct link to the update-payment page** (no login maze).

- **In-app banner** on every session during the failure period, dismissible per session, with the
  same direct link. Don't block the product with it.
- State real dates and real consequences only. No invented urgency (see
  [marketing](../marketing/SKILL.md) → "Honesty check").

## 2. Grace period, then a clear final state

- **A grace period with read-only access** (they can see and export their data but not create or
  edit) rather than an instant lockout. Keep retrying in the background during it.
- **Then one clear final state**: paused or cancelled, said plainly, with how to restore access and
  how long data is kept before deletion.
- **Keep data for a stated period**, then send a deletion notice (section 4) before deleting.

## 3. Billing webhooks (as of 2026-10, check current docs)

Event names change and differ between products. Confirm each one in the provider's current
webhook reference before wiring account state to it.

| Provider | Event | Use it to |
| --- | --- | --- |
| Stripe | `invoice.payment_failed` | start the failure sequence |
| Stripe | `invoice.paid` | stop the sequence, restore access |
| Stripe | `customer.subscription.updated` | follow status changes (e.g. to past due or unpaid) |
| Stripe | `customer.subscription.deleted` | apply the final cancellation |
| Paddle Billing | `transaction.payment_failed` | a payment attempt failed; use its `subscription_id` to tie it to a renewal (a failed one-off purchase isn't a subscription failure) |
| Paddle Billing | `subscription.past_due` | the subscription is past due |
| Paddle Billing | `subscription.updated` | a cancellation scheduled for period end shows up here first; keep access until it takes effect |
| Paddle Billing | `subscription.canceled` | the cancellation has taken effect |

- **Paddle Billing is not Paddle Classic.** Classic uses a separate set of alert names. Names like
  `subscription.payment_failed` or `subscription.cancelled` (two l's) are not Paddle Billing
  events. Check which product the account is on before writing a handler.
  Paddle docs: <https://developer.paddle.com/webhooks/transactions/transaction-payment-failed/>,
  <https://developer.paddle.com/webhooks/subscriptions/subscription-canceled/>.
- **Handle webhooks idempotently.** Providers deliver an event more than once and out of order.
  Store each processed event id and skip repeats; on each event, re-read the subscription's current
  state from the provider and apply that, rather than trusting arrival order. The general rules
  are in [integrations](SKILL.md) → "Make external writes idempotent".
- **Verify the webhook signature** before acting on it; an inbound webhook is a security trigger
  path ([security-and-hardening](../security-and-hardening/SKILL.md)).
- Make the provider the source of truth for billing state. The app's copy is a cache.

## 4. Lifecycle emails a subscription app usually forgets

Audit the app against this list before launch. Each is **transactional**: it tells the customer
about their own account.

| Email | Trigger | Must include |
| --- | --- | --- |
| Receipt | each successful charge | amount, date, plan, invoice link |
| Payment failed | a charge fails | section 1 |
| Card expiring | before the card on file expires | expiry month, update link |
| Renewal reminder | before an annual or long-term renewal (and wherever state auto-renewal laws require it) | date, amount, how to change or cancel |
| Trial ending | a few days before a trial ends | the date, what happens next (charged or downgraded), how to cancel |
| Trial ended | the day it ends | what changed, what they keep |
| Plan changed | upgrade, downgrade, seat change | new price, when it applies, any proration |
| Cancellation confirmation | they cancel | when access ends, what happens to their data, how to export it |
| Data deletion notice | before data from a closed account is deleted | the deletion date, an export link, how to reactivate |

**Transactional vs marketing.** Marketing email (offers, newsletters, upgrade campaigns) needs
the person's consent and a working unsubscribe. Transactional email doesn't, so keep promotions out
of it: a receipt stuffed with offers can be treated as marketing and stops being something you can
send to everyone. Send the two from separate streams so an unsubscribe from marketing never stops
receipts.

## 5. Cancellation

The bar is [marketing](../marketing/SKILL.md) → "Honesty check" (leaving is as easy as joining).
The trap to avoid here is cancel friction:

- **Cancel is self-serve and one clear step for every customer, whatever their plan size.** No
  "call us to cancel" tier.
- An optional, one-time offer of a pause or a cheaper plan is fine if declining it is one click.
- **Don't:** a forced survey before the cancel button works, a "stay" offer that "expires when you
  leave this page", or a ladder of growing discounts. An optional one-question survey after
  cancelling is fine.
- The confirmation email (section 4) says when access ends and how to export.
- **Law (as of 2026-10, not legal advice):** the FTC's amended "click-to-cancel" Negative Option
  rule was vacated by the Eighth Circuit on 2025-07-08, so don't cite it as current law. ROSCA and
  state auto-renewal laws still apply; check them for the markets you sell in.

## Before you call this done

- [ ] Card-updater status checked; pre-expiry and pre-renewal notices send with a direct update
      link.
- [ ] Retries follow decline type (provider smart retries, or a short written schedule).
- [ ] Failure emails and an in-app banner both point straight at the update-payment page.
- [ ] Grace period is read-only, then a stated final state; data kept for a stated period.
- [ ] Webhook names confirmed against current docs (Stripe, or Paddle Billing vs Classic);
      handlers verify signatures, dedupe by event id and re-read current state.
- [ ] Every row of the lifecycle table exists, transactional mail carries no promotions.
- [ ] Cancel is one self-serve step for every plan; the confirmation covers data and export.
