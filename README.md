# encore.abdeen.dev

The site for [Encore](https://github.com/abdeen-labs/encore), local voice AI
for the Mac, at `https://encore.abdeen.dev`.

`encored` is a single Go binary (standard library only) with the page, its
stylesheet, and its images built in. It reads Encore's appcast,
`https://updates.abdeen.industries/encore/appcast.xml`, when it starts and
every 10 minutes after, so the download button always names and links the
newest release. Publishing a release never redeploys the site.

| Path | |
|---|---|
| `/` | The page, rendered again when the release changes. `no-cache`, with an ETag. |
| `/download` | A `302` to the newest DMG: a link that stays the same from release to release. `503` until the first read of the appcast works. |
| `/static/…` | Assets at content-hashed names, cached for a year. Text is gzipped. |
| `/robots.txt`, `/sitemap.xml`, `/favicon.ico`, `/apple-touch-icon.png` | Fixed paths, cached for an hour. |
| `/healthz` | `200`, for the host's healthcheck. |

The page's one other host is `stats.abdeen.industries`, the self-hosted
Umami, and its Content-Security-Policy allows that host and nothing else.
Umami counts page views and Web Vitals (`data-performance`), on
`encore.abdeen.dev` only (`data-domains`), so a local server counts nothing.
`stats.js` sends an event for each link marked `data-event` and each
not-found page, with its `data-event-*` attributes as the event's data. The
page leaves Umami out while `umamiWebsiteID` in `site.go` is empty. A link to
the DMG only ever goes to the appcast's own folder on the update host, over
HTTPS.

The page looks like Encore: cream and cocoa with a tangerine accent, light
only, set in Allo, the app's typeface. The page serves Allo itself, cut down
to what it uses (`scripts/font.sh`), with the round cut for names and
headings and the friendly cut for text. A stylesheet names the fonts and
images it uses by their plain `/static/` paths; the server points each at
its hashed name and hashes the stylesheet after.

## Layout

```
main.go, release.go, site.go   The server: appcast reading, rendering, serving.
web/templates/                 page.html, footer.html, icons.html (an icon sprite), notfound.html, stats.html (Umami's script tags).
web/static/                    site.css, stats.js, fonts/ (made by scripts/font.sh), images/ (made by scripts/images.sh), brand/ (the Abdeen Labs lockup).
web/root/                      Files served at fixed paths.
scripts/images.sh, og.swift    Make the images from Encore itself.
scripts/font.sh                Makes the font from Encore's own.
```

## Development

```sh
go run .                 # http://localhost:8080
go test ./...
```

Edits to `web/` show after a restart: the files are built into the binary.

## Images

The screenshots are the ones in Encore's README (`docs/screenshots`), drawn by
the app's snapshot mode from its fixtures. The icon is Encore's app icon. To
make them again after Encore's look changes:

```sh
ENCORE=~/Developer/encore scripts/images.sh
```

It needs ImageMagick and `cwebp` (`brew install imagemagick webp`), and Swift
for the sharing image. The font comes from Encore too:

```sh
ENCORE=~/Developer/encore scripts/font.sh
```

It needs fonttools (`brew install fonttools`).

## Deploying

Railway builds the `Dockerfile` from `main` on every push: a scratch image
with the binary and the CA certificates. The server listens on `PORT` (8080
when it's unset) and answers `/healthz` for the healthcheck; `APPCAST_URL`
overrides the feed, for testing. It needs nothing else. The service has the
custom domain `encore.abdeen.dev` and no Railway domain. To check a deploy:

```sh
curl -sI https://encore.abdeen.dev/
curl -sI https://encore.abdeen.dev/download
```

The first answers `200`, the second `302` to the DMG on
`updates.abdeen.industries`.

## Licenses

Allo is by Josh Puckett, from Inter by the Inter Project Authors, under the
SIL Open Font License 1.1; see `LICENSE-THIRD-PARTY`. The icons are from [Iconoir](https://iconoir.com), MIT License; see
`LICENSE-THIRD-PARTY`. The GitHub mark, a link to Encore's repository, is
GitHub's, from [Primer Octicons](https://github.com/primer/octicons), used as
GitHub's logo guidelines allow.
