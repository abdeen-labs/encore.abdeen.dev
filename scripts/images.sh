#!/bin/bash
# Makes the page's images from Encore itself: the screenshots in its README
# (docs/screenshots, drawn by the app's snapshot mode), its app icon, and the
# favicons and sharing image made from those.
#
#   scripts/images.sh
#
# Needs a checkout of Encore (ENCORE, default ~/Developer/encore),
# ImageMagick, and cwebp. Writes web/static/images and
# web/root/{favicon.ico,apple-touch-icon.png}.

set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
encore="${ENCORE:-$HOME/Developer/encore}"
shots="$encore/docs/screenshots"
icon="$encore/Encore/Assets.xcassets/AppIcon.appiconset/icon_512x512@2x.png"
out="$root/web/static/images"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

for tool in magick cwebp; do
  command -v "$tool" >/dev/null || { echo "error: $tool isn't installed (brew install imagemagick webp)" >&2; exit 1; }
done
[[ -f "$shots/studio.webp" && -f "$icon" ]] || { echo "error: no Encore checkout at $encore (set ENCORE)" >&2; exit 1; }

rm -rf "$out"
mkdir -p "$out"

# Each screen at 1180 and 2360 pixels wide: the screenshots are 2360 wide, a
# window at 2x, so the larger is the original size and nothing is upscaled.
for screen in studio clone design conversations changer transcribe voices history models; do
  magick "$shots/$screen.webp" "$work/$screen.png"
  for width in 1180 2360; do
    cwebp -quiet -q 82 -m 6 -sharp_yuv -resize "$width" 0 "$work/$screen.png" -o "$out/$screen-$width.webp"
  done
done

# The icon, and what's made from it.
for size in 128 256 512; do
  cwebp -quiet -q 90 -alpha_q 100 -resize "$size" "$size" "$icon" -o "$out/icon-$size.webp"
done
magick "$icon" -resize 64x64 -strip "$out/icon-64.png"
magick "$icon" -resize 180x180 -strip "$root/web/root/apple-touch-icon.png"
magick "$icon" -define icon:auto-resize=48,32,16 -strip "$root/web/root/favicon.ico"

# The sharing image: the icon and the name over the Studio, 1200 by 630, in
# Encore's own faces, which every Mac has. ImageMagick takes a collection's
# first face: Bodoni 72 Book, and Avenir Book (Avenir Next's first is Bold).
display="/System/Library/Fonts/Supplemental/Bodoni 72.ttc"
text="/System/Library/Fonts/Avenir.ttc"
magick -size 1200x630 xc:'#0e0c0b' \
  \( "$work/studio.png" -resize 1040x \) -geometry +80+250 -composite \
  \( "$icon" -resize 132x132 \) -geometry +72+60 -composite \
  -font "$display" -pointsize 76 -fill '#f4ede4' -annotate +232+142 'Encore' \
  -font "$text" -pointsize 27 -fill '#a99e92' -annotate +236+188 'Local voice AI for the Mac' \
  -quality 86 -sampling-factor 4:2:0 -strip "$out/og.jpg"

echo "Wrote $(ls "$out" | wc -l | tr -d ' ') images to web/static/images"
