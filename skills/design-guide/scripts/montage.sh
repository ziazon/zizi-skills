#!/usr/bin/env bash
# Render labelled SVG candidates beside references on light and dark backgrounds.
# Usage: montage.sh [--size N] [--font <file>] [--ref <file.png|file.svg>]... <out.png> <option.svg>...
# Relative inputs beginning with - are passed to tools with a ./ prefix.
# Example: montage.sh --size 64 --ref existing.svg comparison.png round.svg square.svg
# Font: --font <file>, then MONTAGE_FONT, then the first readable file from:
# /System/Library/Fonts/Supplemental/Arial.ttf, /System/Library/Fonts/Helvetica.ttc,
# /Library/Fonts/Arial.ttf, /usr/share/fonts/truetype/dejavu/DejaVuSans.ttf,
# /usr/share/fonts/dejavu/DejaVuSans.ttf. Otherwise use ImageMagick's default.
# MONTAGE_FONT_CANDIDATES overrides that list (colon-separated paths).
# Exit codes: 0 success; 1 rendering/composition or temporary-directory failure;
#             2 invalid arguments or unreadable input; 4 missing required tool.
set -euo pipefail
usage() {
  echo 'Usage: montage.sh [--size N] [--font <file>] [--ref <file.png|file.svg>]... <out.png> <option.svg>...' >&2
  exit 2
}
size=256
font=${MONTAGE_FONT:-}
font_explicit=false
inputs=()
labels=()
while [ "$#" -gt 0 ]; do
  case "$1" in
    --size)
      [ "$#" -ge 2 ] || usage
      size=$2
      # Bound the string before arithmetic, avoiding overflow and octal parsing.
      [[ "$size" =~ ^[0-9]{2,4}$ ]] || usage
      size=$((10#$size))
      if [ "$size" -lt 16 ] || [ "$size" -gt 2048 ]; then usage; fi
      shift 2
      ;;
    --font)
      [ "$#" -ge 2 ] || usage
      font=$2
      font_explicit=true
      shift 2
      ;;
    --ref)
      [ "$#" -ge 2 ] || usage
      case "$2" in *.png|*.svg) ;; *) usage ;; esac
      inputs+=("$2")
      name=${2##*/}
      labels+=("ref: ${name%.*}")
      shift 2
      ;;
    --) shift; break ;;
    -*) usage ;;
    *) break ;;
  esac
done
[ "$#" -ge 2 ] || usage
out=$1
shift
for input in "$@"; do
  case "$input" in *.svg) ;; *) usage ;; esac
  inputs+=("$input")
  name=${input##*/}
  labels+=("${name%.*}")
done
for input in "${inputs[@]}"; do
  if [ ! -f "$input" ] || [ ! -r "$input" ]; then
    echo "montage: unreadable input: $input" >&2
    exit 2
  fi
done
if [ "$font_explicit" = true ] || [ -n "$font" ]; then
  if [ ! -f "$font" ] || [ ! -r "$font" ]; then
    echo "montage: unreadable font: $font" >&2
    exit 2
  fi
else
  candidates=${MONTAGE_FONT_CANDIDATES-/System/Library/Fonts/Supplemental/Arial.ttf:/System/Library/Fonts/Helvetica.ttc:/Library/Fonts/Arial.ttf:/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf:/usr/share/fonts/dejavu/DejaVuSans.ttf}
  IFS=: read -r -a font_candidates <<< "$candidates"
  for candidate in "${font_candidates[@]}"; do
    if [ -f "$candidate" ] && [ -r "$candidate" ]; then
      font=$candidate
      break
    fi
  done
fi
rsvg=${RSVG_CONVERT:-rsvg-convert}
magick=${MAGICK:-magick}
for tool in "$rsvg" "$magick"; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "montage: missing tool: $tool; brew install librsvg imagemagick" >&2
    exit 4
  fi
done
work=$(mktemp -d "${TMPDIR:-/tmp}/montage.XXXXXX") || exit 1
trap 'rm -rf "$work"' EXIT
tiles=()
rendered=0
for input in "${inputs[@]}"; do
  case "$input" in -*) input="./$input" ;; esac
  if [[ "$input" = *.svg ]]; then
    tile="$work/$rendered.png"
    "$rsvg" -h "$size" -o "$tile" "$input" || exit 1
    rendered=$((rendered + 1))
  else
    tile=$input
  fi
  tiles+=("$tile")
done
count=${#tiles[@]}
for row in light dark; do
  if [ "$row" = light ]; then bg='#ffffff'; fg='#1f2328';
  else bg='#1f2328'; fg='#ffffff'; fi
  args=(montage -background "$bg" -fill "$fg")
  if [ -n "$font" ]; then args+=(-font "$font"); fi
  for ((i = 0; i < count; i++)); do
    args+=(-label "${labels[$i]}" "${tiles[$i]}")
  done
  "$magick" "${args[@]}" -geometry +16+16 -tile "${count}x1" "$work/$row.png" || exit 1
done
"$magick" "$work/light.png" "$work/dark.png" -append "$out" || exit 1
printf 'montage: %s (%s tiles × light/dark)\n' "$out" "$count"
