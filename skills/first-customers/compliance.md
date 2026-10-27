# Outreach compliance basics (as of 2026-10)

The legal floor under [SKILL.md](SKILL.md)'s outreach rules, by country and channel. Our own
rules there are stricter than most of these laws; follow both.

**Not legal advice.** Laws, thresholds and penalties change. Check the current rules for each
country you contact before the first send, and ask a lawyer before any campaign of real size or
one aimed at the EU or UK.

Adapted from the `prospecting` skill's compliance reference in `coreyhaines31/marketingskills`
(MIT); rewritten and trimmed to the email, call and text rules a small builder needs.

## Contents

- Keep for every contact
- United States: email (CAN-SPAM)
- EU: email (GDPR plus national rules)
- United Kingdom: email (UK GDPR and PECR)
- Canada: email (CASL)
- Australia: email (Spam Act)
- United States: calls and texts (TCPA)
- Platform terms
- Before the first send

## Keep for every contact

| Field | Why |
| --- | --- |
| Source URL | answers "where did you get my address?" and backs a lawful basis |
| Date collected | shows the data was current; drives deletion |
| Lawful basis (EU/UK contacts) | legitimate interest or consent, written down |
| Opt-out status | feeds the one suppression list every channel checks |

Delete a list when the outreach it was built for is over.

## United States: email (CAN-SPAM)

CAN-SPAM applies to commercial email, business recipients included.

- **Honest headers.** The From name, reply-to and routing say truthfully who is sending.
- **Honest subject line.** It matches the message; no fake "Re:" or "Fwd:".
- **Say it's an ad** when it is one and the person hasn't agreed to hear from you.
- **A valid physical postal address** in every message.
- **A working opt-out**, honored within **10 business days**, and never sold or passed on.
- **You stay responsible** for any service you hire to send for you.

## EU: email (GDPR plus national rules)

GDPR covers any data about an identifiable person, a named work address included.

- **Legitimate interest** is the usual basis for a first business email. Write the balancing
  test down: why this person, in this role, would reasonably expect the message, and why it
  doesn't override their interests. Upstream reports that the EU Court of Justice confirmed in
  October 2024 (the KNLTB case) that a purely commercial interest can qualify.
- **Say where you got their data**, at the latest in the first message ("I found your address on
  your company's contact page; reply 'remove' and I'll delete it").
- **Answer access and deletion requests**, and keep data only as long as the outreach needs it.
- **Individuals are stricter than companies.** Many EU countries require prior consent for
  marketing email to individuals and some for any email. Never cold-email a personal address.
- **Germany requires prior consent for advertising email, business recipients included**
  (unfair-competition law, UWG section 7). Leave German contacts out of cold email.
- **National ePrivacy rules sit on top of GDPR.** When a campaign leans on one country, check its
  rules.

## United Kingdom: email (UK GDPR and PECR)

- **Corporate subscribers** (limited companies, LLPs, public bodies) can get a first email at a
  work address without consent, if you say who you are and offer an opt-out.
- **Sole traders and partnerships count as individuals** and need consent first. Many small
  local businesses are one of these: check the entity type before emailing.
- Upstream reports that the Data (Use and Access) Act 2025 raised PECR fines sharply. Check the
  current maximum before quoting it.

## Canada: email (CASL)

- Needs **express consent**, or **implied consent**: an existing business relationship within
  the past two years, or an address the person published conspicuously, with no "no unsolicited
  messages" notice, where the message relates to their role.
- Every message identifies the sender and includes a mailing address and an unsubscribe.

## Australia: email (Spam Act)

Consent-based. Inferred consent can come from a conspicuously published business address with
no "no unsolicited messages" notice, where the message relates to the person's role.
Address-harvesting software is banned outright. Every message identifies the sender and has a
working unsubscribe.

## United States: calls and texts (TCPA)

Text messaging has its own reference: [sms-compliance.md](../integrations/sms-compliance.md).
For calls (as upstream reported them; check the FCC's current rules):

- **Scrub against the National Do Not Call Registry** and your own do-not-call list first.
  Numbers found online are often personal mobiles, which the rules protect.
- **AI-generated voices count as artificial voices** (FCC ruling, February 2024). Calls to
  mobiles with one need prior express consent, written consent for marketing. Don't use them
  for cold calls.
- **Consent can be revoked by any reasonable means** (a spoken "stop", a reply), honored within
  10 business days (FCC rule, upstream dates it April 2025).
- **Don't cold-text.** Texts go only to people who opted in.

## Platform terms

- **Communities and forums** set their own self-promotion rules. Read them before replying.
- **Map and directory sites** usually forbid bulk extraction and limit what you may store. Use
  them to find a business, then take details from the business's own pages.
- **Professional networks** generally forbid scraping and third-party automation. Messages sent
  there are still personal data under GDPR and PECR.
- **Login walls and CAPTCHAs are a "no".** If a page needs either, work with what is public.

## Before the first send

- [ ] Every contact has a source URL, a date and (EU/UK) a written lawful basis.
- [ ] Country gating applied: Germany out of cold email; UK sole traders and partnerships out
  without consent; CASL and Spam Act conditions met for Canada and Australia.
- [ ] No personal addresses; no guessed or bought addresses.
- [ ] Every message has the sender's real name, a postal address, an opt-out and (EU/UK) where
  the data came from.
- [ ] Phone numbers scrubbed against do-not-call lists; no AI-voice or cold texts.
- [ ] The suppression list is current and checked by every channel.
- [ ] A deletion date is set for the list.
