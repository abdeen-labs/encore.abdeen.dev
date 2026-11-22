#!/bin/bash
# Makes the page's typeface: Allo, Encore's own, from the variable font Encore
# bundles. It keeps all three axes over the ranges the page uses (weight 400 to
# 900, optical size 12 to 32, roundness from the friendly cut to the round one)
# and only the characters it uses (Latin, punctuation and a few symbols).
#
#   scripts/font.sh
#
# Needs a checkout of Encore (ENCORE, default ~/Developer/encore) and
# fonttools with WOFF2 support (brew install fonttools). Writes
# web/static/fonts/allo.woff2.

set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
encore="${ENCORE:-$HOME/Developer/encore}"
source="$encore/Encore/Resources/Fonts/AlloVariable.ttf"
out="$root/web/static/fonts/allo.woff2"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

for tool in fonttools pyftsubset; do
  command -v "$tool" >/dev/null || { echo "error: $tool isn't installed (brew install fonttools)" >&2; exit 1; }
done
[[ -f "$source" ]] || { echo "error: no Encore checkout at $encore (set ENCORE)" >&2; exit 1; }

mkdir -p "$(dirname "$out")"
fonttools varLib.instancer "$source" wght=400:900 opsz=12:32 ROND=50:100 -q -o "$work/allo.ttf"
pyftsubset "$work/allo.ttf" \
  --output-file="$out" \
  --flavor=woff2 \
  --unicodes="U+0020-007E,U+00A0-00FF,U+0131,U+0152-0153,U+02C6,U+02DA,U+02DC,U+2000-206F,U+2190-2193,U+21A9,U+21E7,U+2212,U+2318,U+2713,U+FEFF,U+FFFD" \
  --layout-features+=tnum,case \
  --no-hinting \
  --desubroutinize

echo "Wrote web/static/fonts/allo.woff2 ($(du -k "$out" | cut -f1) KB)"
