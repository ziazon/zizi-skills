#!/usr/bin/env bash
# lh-audit.sh — run Lighthouse headlessly against a URL and print a parsed summary.
#
# The Chrome DevTools "Lighthouse" panel is just a GUI over the Lighthouse engine,
# which also ships as a CLI. This runs that engine with a PINNED config so results
# are comparable across runs (extensions disabled — a dirty Chrome profile can tank
# performance by 40+ points and Lighthouse will warn about it, exactly as seen on a
# real staging screenshot).
#
# Usage:
#   lh-audit.sh [--runs N] [--since <ref> [--until <ref>] --paths <file> [--repo <dir>]]
#     <url> [desktop|mobile|both] [outdir]
#
# Examples:
#   lh-audit.sh https://example.invalid/ both ./.lighthouse
#   lh-audit.sh --runs 3 https://example.invalid/ both
#   lh-audit.sh --since v1 --paths watched.txt https://example.invalid/
#   lh-audit.sh --since v1 --until v2 --paths watched.txt https://example.invalid/
#   lh-audit.sh --since v1 --paths watched.txt --repo . https://example.invalid/
#   watched.txt: one prefix ending in / or whole-path shell glob per line;
#     blank lines and # comments are ignored. Options may follow positionals.
#
# --until and --repo require --since; --repo defaults to the current directory.
# Exit: 0 audited or skipped; 1 Lighthouse missing or a run failed;
#       2 usage error or bad git ref.
#
# Requires: node, Google Chrome, and the `lighthouse` CLI on PATH (install it
# yourself, e.g. `npm install -g lighthouse@13.5.0`; this script never downloads it).
# Outputs timestamped JSON + HTML per form-factor into <outdir> and prints:
#   category scores (Perf/A11y/BP/SEO), the Core Web Vitals metrics, and the top
#   opportunities/diagnostics ranked by estimated savings.

set -euo pipefail

usage() {
  echo 'usage: lh-audit.sh [--runs N] [--since <ref> [--until <ref>] --paths <file> [--repo <dir>]] <url> [desktop|mobile|both] [outdir]' >&2
  exit 2
}
RUNS=1
SINCE=
UNTIL=HEAD
PATHS=
REPO=.
has_since=0
has_paths=0
has_until=0
has_repo=0
positionals=()
while [ "$#" -gt 0 ]; do
  case "$1" in
    --runs|--since|--until|--paths|--repo)
      [ "$#" -ge 2 ] || usage
      case "$2" in ''|--*) usage ;; esac
      case "$1" in
        --runs) RUNS=$2 ;;
        --since) SINCE=$2; has_since=1 ;;
        --until) UNTIL=$2; has_until=1 ;;
        --paths) PATHS=$2; has_paths=1 ;;
        --repo) REPO=$2; has_repo=1 ;;
      esac
      shift 2 ;;
    --*) usage ;;
    *) positionals+=("$1"); shift ;;
  esac
done
case "$RUNS" in [1-9]) ;; *) usage ;; esac
[ "$has_since" -eq "$has_paths" ] || usage
if [ "$has_since" -eq 0 ] && { [ "$has_until" -eq 1 ] || [ "$has_repo" -eq 1 ]; }; then usage; fi
[ "${#positionals[@]}" -gt 0 ] || usage
set -- "${positionals[@]}"
URL="${1:?usage: lh-audit.sh <url> [desktop|mobile|both] [outdir]}"
FORM="${2:-both}"
OUTDIR="${3:-./.lighthouse}"

if [ "$has_since" -eq 1 ]; then
  if [ ! -f "$PATHS" ] || [ ! -r "$PATHS" ]; then usage; fi
  changed_dir=$(mktemp -d "${TMPDIR:-/tmp}/lh-audit-paths.XXXXXX")
  trap 'rm -rf "$changed_dir"' EXIT
  git -C "$REPO" diff --name-only -z "$SINCE..$UNTIL" > "$changed_dir/paths" || exit 2
  patterns=()
  while IFS= read -r pattern || [ -n "$pattern" ]; do
    case "$pattern" in ''|\#*) continue ;; esac
    patterns+=("$pattern")
  done < "$PATHS"
  matched=()
  while IFS= read -r -d '' path; do
    [ -n "$path" ] || continue
    # Bash 3.2 with nounset cannot expand an empty array.
    if [ "${#patterns[@]}" -gt 0 ]; then
      for pattern in "${patterns[@]}"; do
        case "$pattern" in
          */)
            case "$path" in "$pattern"*) matched+=("$path"); break ;; esac ;;
          *)
            # The file deliberately supplies whole-path shell globs.
            # shellcheck disable=SC2254
            case "$path" in $pattern) matched+=("$path"); break ;; esac ;;
        esac
      done
    fi
  done < "$changed_dir/paths"
  count=${#matched[@]}
  if [ "$count" -eq 0 ]; then
    echo "lh-audit: no watched path changed in $SINCE..$UNTIL; skipping"
    exit 0
  fi
  echo "lh-audit: watched paths changed in $SINCE..$UNTIL:"
  for ((i=0; i<count && i<20; i++)); do
    printf '  %s\n' "${matched[i]}"
  done
  if [ "$count" -gt 20 ]; then printf '  … and %s more\n' "$((count - 20))"; fi
fi

command -v lighthouse >/dev/null 2>&1 || {
  echo "lh-audit.sh: the lighthouse CLI is not on PATH; install it first (e.g. npm install -g lighthouse@13.5.0)" >&2
  exit 1
}

STAMP="$(date +%Y%m%d-%H%M%S)"
SLUG="$(printf '%s' "$URL" | sed -E 's#https?://##; s#[^a-zA-Z0-9]+#-#g; s#-+$##')"
mkdir -p "$OUTDIR"

run_one() {
  local preset="$1"          # desktop | mobile
  local base="${OUTDIR}/${STAMP}_${SLUG}_${preset}"
  echo "▶ Lighthouse ${preset}: ${URL}"
  local k run_base
  local reports=()
  for ((k=1; k<=RUNS; k++)); do
    run_base="$base"
    if [ "$RUNS" -gt 1 ]; then run_base="${base}_run${k}"; fi
    reports+=("$run_base")
    # Desktop uses its preset; omitting it keeps the default mobile profile.
    local flags=("--only-categories=performance,accessibility,best-practices,seo,agentic-browsing"
                 --output=json --output=html
                 --output-path="${run_base}"
                 --chrome-flags="--headless=new --no-extensions --no-sandbox"
                 --quiet)
    if [ "$preset" = "desktop" ]; then flags+=(--preset=desktop); fi
    lighthouse "$URL" "${flags[@]}" >/dev/null || exit 1
  done

  # Lighthouse writes <base>.report.json / <base>.report.html per run.
  node - "$preset" "${reports[@]}" <<'NODE'
const fs = require('fs');
const [preset, ...bases] = process.argv.slice(2);
const reports = bases.map(base => JSON.parse(fs.readFileSync(base + '.report.json', 'utf8')));
const median = values => {
  const sorted = values.slice().sort((a, b) => a - b);
  const mid = Math.floor(sorted.length / 2);
  return sorted.length % 2 ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2;
};
const ranked = reports.map((r, i) => ({r, base: bases[i]}))
  .sort((a, b) => a.r.categories.performance.score - b.r.categories.performance.score);
const {r, base} = ranked[Math.floor((ranked.length - 1) / 2)];
const pct = c => {
  if (reports.length === 1) return r.categories[c] ? Math.round(r.categories[c].score * 100) : 'n/a';
  const scores = reports.map(report => report.categories[c]?.score);
  return scores.every(score => typeof score === 'number') ? Math.round(median(scores) * 100) : 'n/a';
};
const line = (l, v) => console.log('  ' + l.padEnd(16) + v);
console.log(`\n═══ ${preset.toUpperCase()} — ${r.finalDisplayedUrl || r.finalUrl}${reports.length > 1 ? ` — median of ${reports.length}` : ''} ═══`);
line('Performance', pct('performance'));
line('Accessibility', pct('accessibility'));
line('Best Practices', pct('best-practices'));
line('SEO', pct('seo'));
line('Agentic Brows.', pct('agentic-browsing'));
const m = id => {
  if (reports.length === 1) return (r.audits[id] && r.audits[id].displayValue) || '—';
  const values = reports.map(report => report.audits[id]?.numericValue);
  if (!values.every(value => typeof value === 'number')) return '—';
  const value = median(values);
  return id === 'cumulative-layout-shift' ? value.toFixed(3) : `${Math.round(value)} ms`;
};
console.log('  Core Web Vitals / metrics:');
line('  LCP', m('largest-contentful-paint'));
line('  TBT', m('total-blocking-time'));
line('  CLS', m('cumulative-layout-shift'));
line('  FCP', m('first-contentful-paint'));
line('  Speed Index', m('speed-index'));
line('  TTI', m('interactive'));
if ((r.runWarnings || []).length) {
  console.log('  ⚠ warnings:');
  r.runWarnings.forEach(w => console.log('    - ' + w));
}
// Top opportunities + diagnostics, ranked by estimated ms/byte savings.
const items = Object.values(r.audits)
  .filter(a => a.details && (a.details.type === 'opportunity' || a.numericValue) &&
               a.score !== null && a.score < 0.9 &&
               a.scoreDisplayMode !== 'informative' && a.scoreDisplayMode !== 'notApplicable')
  .map(a => ({
    title: a.title,
    ms: (a.details && a.details.overallSavingsMs) || 0,
    kb: (a.details && a.details.overallSavingsBytes) ? Math.round(a.details.overallSavingsBytes / 1024) : 0,
    val: a.displayValue || '',
  }))
  .sort((a, b) => b.ms - a.ms || b.kb - a.kb)
  .slice(0, 12);
if (items.length) {
  console.log('  Top failing audits (by est. savings):');
  items.forEach(i => {
    const save = [i.ms ? `~${Math.round(i.ms)}ms` : '', i.kb ? `~${i.kb}KB` : ''].filter(Boolean).join(' ');
    console.log(`    • ${i.title}${save ? '  (' + save + ')' : ''}${i.val ? '  [' + i.val + ']' : ''}`);
  });
}
console.log(`  Reports: ${base}.report.html  |  ${base}.report.json`);
// One-line row for a post-release baseline log (see web-performance.md, Regression gate).
console.log('  ROW| ' + [preset, pct('performance'), pct('accessibility'), pct('best-practices'),
  pct('seo'), m('largest-contentful-paint'), m('total-blocking-time'),
  m('cumulative-layout-shift')].join(' | '));
NODE
}

case "$FORM" in
  desktop) run_one desktop ;;
  mobile)  run_one mobile ;;
  both)    run_one desktop; run_one mobile ;;
  *) echo "form must be desktop|mobile|both (got: $FORM)" >&2; exit 2 ;;
esac
