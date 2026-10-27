# Brief: mine the incident history (cheap, read-only agent)

You are building the incident list for an adversarial design panel on: <PROBLEM IN ONE LINE>.
Read-only: modify nothing.

## Read
<THE JOURNALS, HANDOFFS, QUEUES AND DATE RANGE TO SEARCH>

## Write (return as markdown; the moderator saves it as `incidents.md`)
- One numbered entry per CLASS of failure, not per occurrence: a bold one-line title, then what
  happened, generalized, with the real numbers (durations, counts, sizes, how often).
- Failures only. **Never describe the current mechanism, its design or its fixes.** The panel must
  design from the failures, not review today's answer. Strip names, product terms, hosts and paths.
- End with "Not observed (yet):", the failure classes someone might expect that the record does
  not show.
- Cite the source file for each entry in a separate list after the incidents. The moderator keeps
  that list; the seats never see it.
