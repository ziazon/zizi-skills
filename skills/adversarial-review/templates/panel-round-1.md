# Round 1 — your independent proposal

Write ONE concrete design. Other seats are designing independently and will attack yours in
Round 2, so make it specific enough to attack. Name the primitives, where state lives, who writes
it, how it is read, the exact recovery rules (with numbers), and the <CORE PATH, e.g. landing> path.

Your starting lens is below. Argue from it in this round; you may drop it later if beaten.
<LENS>

Required sections (≤1300 words total, markdown):
1. **Name + one-paragraph thesis.**
2. **Primitives and where state lives**, and why there, given <THE HARD ENVIRONMENT FACTS>.
3. **<PROBLEM AREA 1>**: <WHAT TO SPECIFY, INCLUDING THE STATES TO TELL APART>.
4. **<PROBLEM AREA 2>**: the full path from <START> to <END>: what is serialized, for how long,
   and what happens when it loses a race.
5. **<PROBLEM AREA 3…>**
6. **Incident table**: for each incident 1–<N>, "prevented / made cheap / not addressed" + one line.
7. **What your design gets wrong**: the two weakest points, honestly.
8. **Build cost**: rough size and moving parts.

Do not read any repository or file on disk except the brief you were pointed at. If you assert how
a tool or platform behaves, be precise (the exact flag and what it actually checks).
