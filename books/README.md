# books/

Drop any `.epub` (and PDFs / CBZs that Readium supports) into this folder.
After they're here, run `../open-book.ps1 -List` from the repo root to get a
URL you can paste into the browser.

Personal / commercial books are excluded by `.gitignore` — only the IDPF
sample (`accessible_epub_3.epub`) is tracked in git.

## About the bundled sample

`accessible_epub_3.epub` comes from the
[IDPF / W3C EPUB 3 Samples Project](https://github.com/IDPF/epub3-samples)
and is included here strictly to verify that the reader pipeline works
end-to-end. Refer to that repository for the sample's original metadata and
license terms.
