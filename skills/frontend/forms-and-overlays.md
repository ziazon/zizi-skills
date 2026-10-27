# Frontend — forms, signup and overlays

The rules for forms people fill in (contact, quote, lead, signup) and for overlays that interrupt
a page (popups, modals, slide-ins, banners).

Adapted from the `cro` (form reference), `signup` and `popups` skills in
`coreyhaines31/marketingskills` (MIT); rewritten, with the experiment lists, benchmarks and
urgency tactics left out.

Every offer, claim and decline line in these surfaces passes the honesty check in
[marketing](../marketing/SKILL.md). The words on labels, errors and buttons are
[plain-language](../plain-language/SKILL.md). Modal mechanics in a Tabler app are tabler-ui.

## Contents

- Forms
  - Fields
  - Validation and errors
  - Multi-step forms
- Signup
- Overlays, popups and modals
  - When to show one
  - Dismissing
  - Offers inside overlays
  - Accessibility (every modal, not just marketing ones)

## Forms

### Fields

- [ ] **Only fields you will use.** For each field, name who reads it and what they do with it.
      If nobody does, or it can be asked later, drop it. Phone, company and role are usually
      deferrable.

### Validation and errors

- [ ] Spam protection doesn't block real people. Prefer a honeypot or server-side checks over a
      challenge every visitor has to solve.

### Multi-step forms

Use steps only when they help: many fields, clearly separate topics, or later questions that
depend on earlier answers. Otherwise one short form is better.

- [ ] Progress shown ("Step 2 of 3").
- [ ] Easy questions first, sensitive ones last.
- [ ] Back works and keeps answers; a refresh doesn't lose them (save progress).

## Signup

Everything under *Forms* applies. In addition:

- [ ] **Offer SSO or a magic link where it fits the audience** (e.g. Google or Apple for
      consumers, Google or Microsoft for business tools). Keep email signup available beside it.
- [ ] **Let people in while email verification is pending.** Gate only what truly needs a
      verified address (sending to others, billing). Make resend and "change email" easy.
- [ ] **Keep enrichment out of account creation.** A lookup that times out or can't match a
      company must never fail or silently reject the signup. Enrich afterwards.
- [ ] **Defer profile questions** (role, team size, use case) to onboarding unless the product
      can't work without them; then ask one.
- [ ] **Terms acceptance is explicit where legally needed**: an unticked checkbox or a clear
      "By creating an account you agree to…" next to the button, linked to the terms. Never an
      "implicit acceptance" experiment.
- [ ] **No pre-ticked marketing consent.** Product email the account needs is separate from
      marketing email, which is opt-in.
- [ ] "Email already registered" offers the way forward (sign in, reset password). If the app
      hides which emails have accounts, both cases get the same response.

## Overlays, popups and modals

### When to show one

- [ ] **Prefer click-triggered.** A lead magnet, quote form or demo request opens when the
      person clicks for it. That interrupts nobody.
- [ ] **Avoid full-screen interstitials on mobile at entry.** Google's guidance on
      [intrusive interstitials](https://developers.google.com/search/docs/appearance/avoid-intrusive-interstitials)
      (checked 2026-10) says to avoid overlays that cover the content for promotional reasons,
      and to prefer small banners that leave the page readable. Legally required gates (age) are
      exempt but should overlay, not redirect.
- [ ] **Frequency cap after dismiss.** Remember the dismissal and don't show it again for a
      configurable number of days (store it per visitor; the storage can fail, so default to
      not showing). At most once per session. Never show it to someone who already converted.
- [ ] Keep overlays off checkout, signup and other flows the person is in the middle of.

### Dismissing

- [ ] **A visible close button**, large enough to tap, plus ESC and a click outside.
- [ ] **An honest decline**: "No thanks" or "Not now". No confirmshaming ("No, I don't like
      saving money").
- [ ] **Never hijack the back button.** Back leaves the page; it never opens an overlay or
      pushes fake history entries.

### Offers inside overlays

- [ ] **No countdowns** unless the offer truly ends then, and **no "bigger offer on exit"**: it
      teaches people to leave to get the real price. Both fail the honesty check in
      [marketing](../marketing/SKILL.md).
- [ ] Email capture asks for the email and says what they'll get and how often.

### Accessibility (every modal, not just marketing ones)

- [ ] `role="dialog"` with `aria-modal="true"` and `aria-labelledby` pointing at its heading
      (or a native `<dialog>` opened with `showModal()`).
- [ ] Focus moves into the dialog on open, **stays trapped** while open, and **returns to the
      element that opened it** on close.
- [ ] ESC closes it; every control is reachable by keyboard.
- [ ] The page behind is inert to screen readers and doesn't scroll.
- [ ] Contrast and focus rings hold in light and dark themes.
- [ ] Announcement banners don't trap focus; they're dismissible and don't cover content.
