# SMS compliance

What to settle the first time an app sends text messages, before the first one goes out.

Adapted from the `sms` skill in `coreyhaines31/marketingskills` (MIT); rewritten, with the
manipulative parts left out.

**Not legal advice. These rules change and differ by country and US state. Everything here is as
of 2026-10; check the current rules for every market you send to before relying on it.**

## Contents

- 1. Sort every message into one of two buckets
- 2. Marketing texts need prior express written consent (US)
- 3. STOP, HELP, and opt-outs
- 4. When to send
- 5. Carrier registration and records
- 6. Other regions (one line each)
- 7. What not to build
- Before the first text goes out

## 1. Sort every message into one of two buckets

| Bucket | Examples | Consent needed |
| --- | --- | --- |
| **Transactional** | sign-in and verification codes, order or appointment confirmations and reminders, delivery updates, account and security alerts | The person gave their number for this purpose, in a transaction they started |
| **Marketing** | offers, promotions, product announcements, win-back nudges, "we miss you" | Prior express written consent (section 2) |

- A transactional message that also carries a promotion is a marketing message. Keep them apart.
- If the app only sends transactional texts, sections 3–5 still apply (opt-out handling, carrier
  registration, records). Section 2 applies the day anyone wants to send marketing.

## 2. Marketing texts need prior express written consent (US)

- **Captured before the first marketing text**, by a clear action the person takes (an unticked
  box they tick, or texting a keyword). Never a pre-ticked box.
- **The disclosure sits next to the phone field and the submit button**, not in a footer or the
  terms. It names the sender, says the messages are marketing and automated, gives the expected
  frequency, says message and data rates may apply, and says how to get help and how to stop
  (reply HELP, reply STOP), with links to the terms and privacy policy.
- **Consent is not a condition of purchase.** Say so in the disclosure, and let people buy without
  it.
- **An existing customer relationship is not consent** for marketing texts in the US. Neither is a
  number collected for order updates.
- **Consent belongs to the brand that collected it.** Never buy, rent or share a list.
- **A timestamped record of each consent** (section 5).

## 3. STOP, HELP, and opt-outs

- **Honor STOP at once**, automatically, on the common variants: STOP, END, CANCEL, UNSUBSCRIBE,
  QUIT, STOPALL, OPTOUT. Treat any other clear request to stop ("please stop texting me") the same
  way. US rules on how fast and by what means a revocation must be honored have been changing;
  check the current FCC rule.
- Send **one confirmation** of the opt-out and nothing after it. Never require a login or a website
  visit to opt out.
- **HELP** (and INFO) gets a reply with the sender's name, a support contact, and how to stop.
- **One suppression list** that every sending path checks, so an opt-out from one flow stops all
  marketing texts.

## 4. When to send

- **Quiet hours, recipient-local time.** The US federal rule (TCPA) allows marketing texts from
  8am to 9pm; some states are stricter (Florida, for one, 8am to 8pm). A 9am–8pm default stays
  inside all of them. Area codes don't always match where someone lives, so stay well inside the
  window.
- Auth codes and alerts the person just asked for can go any time.
- Send only what is worth an interruption. If it can wait a day, it is probably an email.

## 5. Carrier registration and records

- **US A2P 10DLC.** Business texts from ordinary 10-digit numbers must be registered with The
  Campaign Registry through the SMS provider: the brand, then one campaign per use case
  (verification codes, account notifications, marketing...). Unregistered traffic is throttled or
  filtered, often while the provider still reports it as delivered. Allow several business days
  for approval.
- **Sample messages must match what you send.** The registered samples, opt-in description and
  opt-out wording are checked against real traffic; a mismatch gets the campaign rejected or
  suspended. Register a new campaign before sending a new kind of message.
- Toll-free and short-code numbers have their own verification processes; check the provider's
  current requirements.
- **Keep a record of each consent**: the phone number, the timestamp, where it was given (page URL
  or keyword), the exact disclosure text shown, and the IP or device where available. Record every
  opt-out with its timestamp too. Keep them at least as long as claims can be brought (four years
  under the TCPA).

## 6. Other regions (one line each)

- **UK:** marketing texts fall under PECR (with UK GDPR for the data): opt-in consent, except a
  narrow "soft opt-in" for your own existing customers about similar products when they were
  offered an opt-out at the time and in every message.
- **EU:** the ePrivacy rules plus GDPR: specific, freely given opt-in consent, separate from the
  terms, as easy to withdraw as to give; sender identity and an opt-out in every message.
- **Canada:** CASL: express consent (or limited implied consent, e.g. from a recent purchase, that
  expires), and every message identifies the sender, gives contact details and a working
  unsubscribe.
- Sending to several regions: apply the strictest rule to everyone, and record which rules applied
  to each number.

## 7. What not to build

- No urgency or discount templates ("only 2 hours left!"). Any marketing text passes
  [marketing](../marketing/SKILL.md) → "Honesty check".
- No marketing texts to numbers collected for verification codes or order updates.
- No sending path that skips the suppression list or the quiet-hours check.

## Before the first text goes out

- [ ] Every message type is labelled transactional or marketing.
- [ ] US: brand and campaigns registered (10DLC or toll-free verification), samples match the real
      messages.
- [ ] Marketing opt-in: unticked box or keyword, full disclosure beside the field, "not a condition
      of purchase", consent record written with a timestamp.
- [ ] STOP variants and plain-language requests opt the number out of all marketing at once;
      HELP replies correctly. Tested from a real phone.
- [ ] Quiet hours enforced in recipient-local time for marketing sends.
- [ ] Privacy policy and terms mention texts.
- [ ] Rules re-checked for each market, dated in the project's notes.
