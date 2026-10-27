# PostgreSQL tuning & scaling reference

General, engine-level PostgreSQL knowledge distilled from external write-ups (not
project-specific — measured project wins live in `LEARNINGS.md` beside this skill, when
your copy keeps one). Numbers are starting points — always
`EXPLAIN (ANALYZE, BUFFERS)` and measure on real data before trusting them.

## Contents

- Bloat & dead tuples (MVCC's tax)
- Bulk operations
- Scaling reads & writes (OpenAI @ 800M users)
- Sources

## Bloat & dead tuples (MVCC's tax)

Every UPDATE/DELETE leaves a dead tuple until VACUUM reclaims it; mass deletes/updates
without vacuum ⇒ table+index bloat ⇒ slower scans and wasted disk.

- **Detect:** dead-tuple ratio `n_dead_tup / NULLIF(n_live_tup,0)` from
  `pg_stat_user_tables`. **>30–40% = severe bloat.**

  ```sql
  SELECT relname, n_live_tup, n_dead_tup,
         round(n_dead_tup::numeric / NULLIF(n_live_tup,0) * 100, 1) AS dead_pct,
         last_vacuum, last_autovacuum, last_analyze
  FROM pg_stat_user_tables ORDER BY n_dead_tup DESC;
  ```

- **Fix (mild):** `VACUUM (ANALYZE) tbl`. **Fix (severe, VACUUM not keeping up):** rebuild
  — `CREATE TABLE new (LIKE old INCLUDING ALL)` → reload via `COPY` → `DROP old; ALTER
  TABLE new RENAME`. One real case freed ~1.5TB (~60% disk) and cut query time ~250%.
  `REINDEX` (or `pg_repack` for online) for index bloat.
- **Autovacuum tuning:** lower `autovacuum_vacuum_scale_factor` /
  `autovacuum_analyze_scale_factor` on large, frequently-updated tables (the default 20%
  means a billion-row table waits for 200M dead rows). Don't disable autovacuum globally;
  disabling per-table is a targeted-only escape hatch.

## Bulk operations

- **Load with `COPY`, not row-by-row INSERT** — ~3× faster than JDBC/batch inserts in
  practice (≈15min vs ≈40min for 250M rows), and atomic. Disable/defer constraints & FK
  checks during load, re-enable + `ANALYZE` after.
- **Batched deletes must vacuum between batches.** A multi-billion-row delete loop with no
  interleaved VACUUM guarantees catastrophic bloat (one case hit 44% dead tuples). Pattern:
  delete N (e.g. 100k) → COMMIT → `VACUUM (ANALYZE)` → repeat.

## Scaling reads & writes (OpenAI @ 800M users)

- **Ban long-running queries on the primary.** A query >1s persistently blocks autovacuum
  and queues schema changes behind it. Set `idle_in_transaction_session_timeout` and
  `statement_timeout`; move slow/analytical queries to replicas or optimize them. Idle
  open transactions are the silent killer (hold xmin → block vacuum → bloat).

## Sources

- [Diagnosing & fixing critical PostgreSQL performance issues (dev.to / Pedro Gonçalves)](https://dev.to/pedrohgoncalves/diagnosing-and-fixing-critical-postgresql-performance-issues-a-deep-dive-3jj)
- [Scaling PostgreSQL to power 800M ChatGPT users (OpenAI)](https://openai.com/index/scaling-postgresql/)
