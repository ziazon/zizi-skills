# Lenses (one per seat; a seat may drop hers once beaten)

<SEAT A>: CORRECTNESS FIRST. Treat this as a <DOMAIN> correctness problem (<THE FAILURE MODES THAT
DOMAIN NAMES, e.g. fencing, leases, split-brain>). Find the minimum set of guarantees that kills every
incident class, then the cheapest substrate that provides them.

<SEAT B>: FEWEST MOVING PARTS. The best design is the one an agent that just lost its context can
follow, and that has nothing to leak. Prefer removing the need for coordination (smaller scopes,
idempotency, designing the problem out) over building coordination.

<SEAT C>: USE THE SUBSTRATE. Build on <THE PLATFORM ALREADY IN PLAY>'s own primitives. No extra
service unless the substrate provably cannot do it.

<SEAT D>: CONTRARIAN. Argue that <THE OBVIOUS PRIMITIVE> is the wrong primitive, and that most of
this should be <THE ALTERNATIVE FAMILY>, with at most one tiny serialization point. Be contrarian
against any design built on the obvious primitive.
