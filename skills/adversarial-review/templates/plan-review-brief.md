# Adversarial review of <PROGRAM> (before it runs further)

You are an adversarial reviewer. Find what will go wrong and which decisions are still silently
assumed, so the human can answer every question ONCE, upfront. Do not be polite; be precise.

## Read (read-only; modify nothing)
- The plan: <PATH> (items <ID..ID>, decisions <D..D>, numbers, findings).
- The design record it came from: <PATH>.
- Findings so far: <PATHS>.
- The live files it modifies: <PATHS>.
- Plans it absorbs or runs beside: <PATHS>.
- Landed so far: <COMMITS>.

## Current state (verified by the orchestrator, <DATE TIME>)
- <WHAT IS DONE, WHAT IS BEING BUILT NOW, WHAT ELSE IS EDITING THE SAME FILES>
- <WHAT IS RUNNING LIVE AND WHAT IS STOPPED>
- <AVAILABILITY FACTS (machines, sleep, uptime)>
- <EXECUTION CONSTRAINTS (who can start sessions, run caps, gate length)>

## Your output (markdown, ≤1500 words)
1. **Per item, in order.** For each: (a) the most likely way it fails or breaks something live, as a
   concrete sequence; (b) any decision it needs that the plan does not state, phrased as a question to
   the human with a recommended answer; (c) ordering or blocker errors. Write "none" where truly nothing.
2. **Whole program.** Gaps across items: rollback path, cutover with live sessions and worktrees,
   distribution of binaries and config, <PLATFORM ASSUMPTIONS TO TEST>, availability, execution
   constraints (e.g. click-gated chains), interaction with <PARALLEL PROGRAMS>, anything else.
3. **The question list.** Every question for the human, deduplicated, each with: the question, 2–3
   options, your recommendation first, and which items it affects. Mark each BLOCKING (answer before
   the next item starts) or LATER (needed before a named later item).
Verify claims against the files; mark anything you could not verify as a guess.
