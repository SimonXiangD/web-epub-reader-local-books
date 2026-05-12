# web-epub-reader-local-books

Run [Thorium Web](https://github.com/edrlab/thorium-web) — the Readium-based,
browser-only EPUB reader — against **your own local `.epub` files** with two
PowerShell commands.

This repository does **not** vendor Thorium Web or any reader code. It is a
small set of Windows / PowerShell glue scripts that:

1. Clone Thorium Web and install its dependencies.
2. Download the official [Readium CLI](https://github.com/readium/cli) Windows
   binary.
3. Start both servers locally.
4. Translate an `.epub` filename in `./books/` into the exact URL that opens
   the book in Thorium Web.

If you've ever wondered "Thorium Web has a `/read/manifest/...` route, how do
I point it at a file on my hard drive?" — that's the entire problem this repo
solves.

---

## Why this is non-trivial

Thorium Web does **not** read `.epub` files directly. It reads a
[Readium Web Publication Manifest](https://readium.org/webpub-manifest/) — a
JSON document that describes the publication and links to its resources.

To open a local `.epub`, you therefore need three pieces:

1. **A publication server** that turns an `.epub` on disk into a manifest URL
   on the fly. The Readium CLI's `serve` command does exactly this.
2. **A running Thorium Web** instance (or any Readium-compatible web reader).
3. **A URL** of the form
   `http://localhost:3000/read/manifest/<percent-encoded manifest URL>`
   where the manifest URL itself is
   `http://localhost:15080/webpub/<base64url(filename)>/manifest.json`.

The last part — two layers of encoding nested in one URL — is what
`open-book.ps1` does for you.

---

## Prerequisites

| Tool   | Version       | Install                                                   |
|--------|---------------|-----------------------------------------------------------|
| Git    | any recent    | https://git-scm.com/download/win                          |
| Node   | ≥ 20 (22 ideal) | https://nodejs.org/ (Thorium pins v22 via `.nvmrc`)     |
| pnpm   | ≥ 10          | `npm install -g pnpm`                                     |
| PowerShell | 5.1+      | shipped with Windows                                      |

Everything else (Thorium source, Readium CLI binary) is fetched by
`setup.ps1`.

> Windows-only out of the box. The same approach works on macOS / Linux —
> replace each `.ps1` with the obvious shell equivalent and grab the
> `readium_darwin_*` or `readium_linux_*` release asset instead.

---

## Quick start

```powershell
git clone https://github.com/simonxiangd/web-epub-reader-local-books.git
cd web-epub-reader-local-books
./setup.ps1            # one-time: clones thorium-web, installs deps, downloads readium CLI
./start.ps1            # opens two windows: publication-server + thorium-web dev server
./open-book.ps1 -List  # prints the URL for every book in ./books/
```

Paste the URL into your browser. You're reading the book.

To verify the pipeline before adding your own books, the IDPF
`accessible_epub_3.epub` sample is already in `./books/`.

---

## Adding your own books

1. Drop a `.epub` (or any format the Readium CLI supports — PDF, CBZ) into
   `./books/`. No registration step, no metadata file.
2. Re-run `./open-book.ps1 -List` to get its URL.
3. Open the URL in any modern browser.

Open one directly without listing:

```powershell
./open-book.ps1 -Name "My Book.epub" -Open
```

Files dropped into `./books/` are git-ignored by default; only the IDPF
sample is tracked. Personal / purchased books stay private to your machine.

---

## What the URL looks like, and why

Given `./books/accessible_epub_3.epub`, the chain is:

| Layer | Value |
|---|---|
| filename on disk | `accessible_epub_3.epub` |
| base64url of filename | `YWNjZXNzaWJsZV9lcHViXzMuZXB1Yg` |
| manifest URL served by Readium CLI | `http://localhost:15080/webpub/YWNjZXNzaWJsZV9lcHViXzMuZXB1Yg/manifest.json` |
| percent-encoded manifest URL | `http%3A%2F%2Flocalhost%3A15080%2Fwebpub%2F…%2Fmanifest.json` |
| final URL passed to Thorium Web | `http://localhost:3000/read/manifest/http%3A%2F%2Flocalhost%3A15080%2Fwebpub%2F…%2Fmanifest.json` |

Why two different encodings?

- The **inner** base64url is Readium CLI's URL scheme — it treats the
  `{path}` between `/webpub/` and `/manifest.json` as a base64url-encoded
  resource locator. With `--file-directory` set, that locator is simply the
  filename relative to the directory.
- The **outer** percent-encoding is required because Next.js dynamic routes
  match a single path segment, so all `/` and `:` characters in the manifest
  URL must be `%2F` and `%3A`.

---

## What's actually running

Two HTTP servers on your machine:

| Component | Port  | What it does |
|---|---|---|
| Readium CLI `serve`         | `15080` | Wraps `./books/` as a Readium Web Publication API. Browser fetches the manifest and every page/image/font through this. CORS open (`Access-Control-Allow-Origin: *`). |
| Thorium Web (Next.js dev)   | `3000`  | The reader UI itself. Pulls the manifest URL from the route param, hydrates a Publication, renders the EPUB. |

Both bind to `localhost` only; nothing is exposed to your LAN unless you go
out of your way to change `-a` / `-Address` flags.

`/read/manifest/...` is gated behind a dev-only check in production builds
(`MANIFEST_ROUTE_FORCE_ENABLE`). The dev server we use here has it on by
default.

---

## Troubleshooting

**"Failed to construct 'URL': Invalid base URL" in the browser console.**
The route parameter must be a *percent-encoded* manifest URL, not base64
or anything else. Always copy URLs from `./open-book.ps1` instead of
constructing them by hand.

**`pnpm install` fails with "Cannot install with frozen-lockfile".**
You're on Node < 20. Upgrade Node or remove `--frozen-lockfile` from the
command line.

**`./start.ps1` says "execution of scripts is disabled".**
PowerShell's default ExecutionPolicy. Either start it the way `start.ps1`
launches its children (`powershell.exe -ExecutionPolicy Bypass -File …`) or
relax the policy once:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

**The Thorium dev server is slow on the first click.** Next.js's Turbopack
compiles `/read/manifest/[manifest]` on first hit; expect 5-10 s. Subsequent
loads are fast.

**Port already in use.** Pass different ports to the scripts:

```powershell
./open-book.ps1 -ServerPort 25080 -ThoriumPort 4000 -List
```

(You'll need to also start the servers on those ports — edit `start-server.ps1`
or pass flags to `readium serve` / `pnpm dev`.)

**Want to expose this on your LAN.** Don't, unless you've thought hard about
it. The publication server has open CORS and an open-access mode by default;
the CLI itself warns about this. If you must, run `readium serve` with `-m jwt`
and a shared secret.

---

## How it differs from running Thorium Web alone

Cloning `edrlab/thorium-web` and running `pnpm dev` gives you a working reader
that points at a curated list of demo books on a remote server. There is no
"open file" UI for local EPUBs.

This repo adds the missing piece: a co-located publication server plus a tiny
URL builder, so you can use Thorium Web with the books you already have on
disk.

Nothing here patches Thorium Web. The upstream project is used unmodified.

---

## Layout

```
web-epub-reader-local-books/
├─ setup.ps1            # one-time setup (clones thorium-web, downloads readium CLI)
├─ start.ps1            # launches both servers in two new PowerShell windows
├─ start-server.ps1     # publication server only
├─ start-thorium.ps1    # Thorium Web dev server only
├─ open-book.ps1        # generate / open Thorium URLs for books in ./books/
├─ books/               # drop .epub files here (git-ignored except sample)
├─ thorium-web/         # cloned by setup.ps1 (git-ignored)
└─ tools/readium/       # downloaded by setup.ps1 (git-ignored)
```

---

## Licenses and attribution

The glue scripts in this repository are MIT-licensed — see [LICENSE](./LICENSE).

The components that `setup.ps1` fetches are governed by their own licenses,
which travel with their respective directories:

- [Thorium Web](https://github.com/edrlab/thorium-web) — BSD-3-Clause,
  © EDRLab.
- [Readium CLI](https://github.com/readium/cli) — BSD-3-Clause, © Readium
  Foundation.
- The bundled [IDPF EPUB 3 sample](https://github.com/IDPF/epub3-samples)
  in `./books/accessible_epub_3.epub` ships under its original terms; this
  repo redistributes it for testing purposes only.

This project is not affiliated with, endorsed by, or sponsored by EDRLab, the
Readium Foundation, or the W3C / IDPF.
