# FLOW Lab website — static HTML/CSS/JS

Nine-page site for flow.berkeley.edu. No build system, no CMS: plain HTML,
one commented stylesheet, two small JS files. Any page can be edited in a
text editor and uploaded.

## Layout

```
index.html … applying-to-join.html   the nine pages (slugs match the old WordPress URLs)
css/style.css                        all styling; design tokens at the top
js/main.js                           nav toggle, scroll reveal, footer year (optional)
js/publications.js                   renders publications.html from publications.bib
publications.bib                     THE publication database — edit this, not the HTML
assets/img/                          logo, emblem, favicon, sponsors/
assets/people/                       portraits + group photo
assets/papers/                       homepage figure images (+ pdf/ for paper PDFs)
assets/research/  assets/towing-tank/  assets/outreach/    page media
scripts/fetch_assets.sh              asset localization: download + relink (see below)
```

## Images: works now, self-contained later

Out of the box the pages load photos, videos, sponsor logos and paper PDFs
from the current WordPress server (flow.berkeley.edu), so the site renders
correctly the moment you unzip it. Before WordPress is decommissioned, make
it fully self-contained by running once:

    bash scripts/fetch_assets.sh

On Windows (no bash needed), use the PowerShell version instead:

    powershell -ExecutionPolicy Bypass -File scripts\fetch_assets.ps1

The script downloads all 32 assets into the assets/ subfolders and rewrites
the HTML + publications.bib to point at the local copies. Per-file and
idempotent: anything it cannot download is left pointing at the live site
and reported, and re-running is always safe.

The publications page loads publications.bib with `fetch()`, which browsers
block on `file://`. To view it locally, serve the folder:

    python3 -m http.server        # then open http://localhost:8000

(When deployed on any web server this just works.)

## Editing recipes

- **Add a paper** → paste its BibTeX entry at the top of the matching section
  in `publications.bib`. Field conventions (doi / pdf / escholarship /
  openaccess / inpress / award) are documented at the top of that file.
  Every entry gets a DOI link; anything not marked `openaccess = {true}`
  also gets an eScholarship link (an exact item URL if you provide
  `escholarship = {...}`, otherwise a title search). Numbering matches the
  CV: newest paper carries the highest number.
- **Feature a paper on the homepage** → copy one `<article class="paper-card">`
  block in index.html, drop the key figure into `assets/papers/`, update the
  img src/alt, title, DOI, and the one-sentence note. Keep ~6 cards.
- **Add/remove a person** → copy a `<article class="person">` block in
  people.html; portrait goes in `assets/people/`.
- **Add a semester** → one `<tr>` at the top of the tbody in courses.html.
- **Change colors/fonts** → design tokens at the top of css/style.css.
- Header and footer are duplicated verbatim on every page; edit all nine
  (or `sed -i` across `*.html`).

## Accessibility & campus compliance (dap.berkeley.edu)

Built against the Berkeley Digital Accessibility Program website
requirements (WCAG 2.1 AA):

- Footer on every page carries the required **Accessibility** link
  (→ DAP "report an issue" page) plus Nondiscrimination and Privacy links.
- Semantic landmarks, one h1 per page, skip link, keyboard-visible focus
  ring (≥3:1 contrast on every surface), `aria-current` nav state,
  `aria-expanded` menu toggle, `scope="col"` table headers, alt text on all
  images, titles on YouTube embeds, silent video labeled as such, no
  autoplay, animations disabled under `prefers-reduced-motion`.
- All text colors meet ≥4.5:1 contrast (footer/legal ≈9:1, gold on navy ≈8:1).
- No accessibility overlay widgets (prohibited by campus policy).

**Still on you (campus admin, not code):** register flow.berkeley.edu in
**Siteimprove** (required for public berkeley.edu subdomains — see the DAP
page for the request form), and skim the DAP checklist after any major
content additions.

## Notes

- The one accepted-but-unpublished paper (Orun & Mäkiharju, JFM) is marked
  `inpress = {true}`; add its `doi` when the article goes online.
- eScholarship links are exact item URLs, added only for papers actually
  deposited there (10 so far, found by searching escholarship.org). Papers
  not on eScholarship show only their DOI — no dead search links. As you
  deposit more, add `escholarship = {https://escholarship.org/uc/item/...}`
  to the entry in publications.bib.
- Placeholder SVGs in assets/papers/ mark the six homepage figure slots —
  swap in each paper's actual key figure (keep filenames or update the src).
- The full logo (assets/img/flow-lab-logo.png / .webp) is available if you
  ever want it in place of the emblem + text wordmark in the header.
