/* ============================================================================
   FLOW Lab — publications renderer (no dependencies, ~200 lines)
   ----------------------------------------------------------------------------
   Reads publications.bib, parses it, and fills the four lists on
   publications.html:

     @article        -> #journal-list
     @incollection   -> #chapter-list
     @inproceedings  -> #conference-list
     @misc           -> #patent-list   (patents)

   TO ADD OR EDIT A PAPER: edit publications.bib only. This file never needs
   to change for routine updates.

   Link policy (as rendered under each entry):
     doi          -> "doi:10.xxxx" link to https://doi.org/...
     pdf          -> "PDF" (publicly accessible copy, usually in assets/papers/pdf/)
     escholarship -> "eScholarship" (exact item in the UC open-access repository)
     otherwise, unless openaccess={true} or inpress={true}, a
     "Find in eScholarship" title search is linked so every non-open-access
     paper points at the public repository (https://escholarship.org/uc/ucb).

   Numbering counts DOWN (newest paper has the highest number, like the CV);
   the CSS counter is seeded per-list via an inline `counter-reset`.

   NOTE: fetch() of a local file requires the site to be served over HTTP.
   For local preview:  python3 -m http.server  (see README.md).
   ============================================================================ */
(function () {
  'use strict';

  /* ---- 1. Tiny BibTeX parser -------------------------------------------- */
  /* Handles @type{key, field = {value}, ...} with nested braces, "quoted"
     values, bare numbers, and %-comment lines. Returns
     [{ type, key, fields: {name: value} }, ...] in file order.             */
  function parseBib(text) {
    var entries = [];
    var i = 0;
    while (true) {
      var at = text.indexOf('@', i);
      if (at === -1) break;
      // Ignore an @ that sits on a %-comment line.
      var lineStart = text.lastIndexOf('\n', at) + 1;
      if (text.slice(lineStart, at).replace(/^\s+/, '').charAt(0) === '%') {
        i = at + 1; continue;
      }
      var open = text.indexOf('{', at);
      if (open === -1) break;
      var type = text.slice(at + 1, open).trim().toLowerCase();
      // Walk to the matching closing brace of the whole entry.
      var depth = 1, j = open + 1;
      while (j < text.length && depth > 0) {
        if (text[j] === '{') depth++;
        else if (text[j] === '}') depth--;
        j++;
      }
      var body = text.slice(open + 1, j - 1);
      i = j;

      var comma = body.indexOf(',');
      if (comma === -1) continue;
      var entry = { type: type, key: body.slice(0, comma).trim(), fields: {} };

      var k = comma + 1;
      while (k < body.length) {
        var eq = body.indexOf('=', k);
        if (eq === -1) break;
        var name = body.slice(k, eq).replace(/[,\s]/g, '').toLowerCase();
        var v = eq + 1;
        while (v < body.length && /\s/.test(body[v])) v++;
        var value = '', end = v;
        if (body[v] === '{') {                       // braced value
          var d = 1, m = v + 1;
          while (m < body.length && d > 0) {
            if (body[m] === '{') d++;
            else if (body[m] === '}') d--;
            if (d > 0) value += body[m];
            m++;
          }
          end = m;
        } else if (body[v] === '"') {                // quoted value
          var q = v + 1;
          while (q < body.length && body[q] !== '"') { value += body[q]; q++; }
          end = q + 1;
        } else {                                     // bare value (numbers)
          var b = v;
          while (b < body.length && body[b] !== ',') { value += body[b]; b++; }
          end = b;
        }
        if (name) entry.fields[name] = clean(value);
        var next = body.indexOf(',', end);
        if (next === -1) break;
        k = next + 1;
      }
      entries.push(entry);
    }
    return entries;
  }

  /* Normalize a BibTeX value for display: unescape \% \&, drop protective
     braces, turn TeX dashes into en/em dashes, collapse whitespace. */
  function clean(s) {
    return s
      .replace(/\\%/g, '%').replace(/\\&/g, '&')
      .replace(/[{}]/g, '')
      .replace(/---/g, '\u2014').replace(/--/g, '\u2013')
      .replace(/\s+/g, ' ').trim();
  }

  /* ---- 2. Formatting helpers -------------------------------------------- */
  /* "Mäkiharju, Simo A." -> "Mäkiharju, S.A."  (hyphens preserved: J.-M.)  */
  function fmtPerson(p) {
    p = p.trim();
    var c = p.indexOf(',');
    if (c === -1) return p;
    var last = p.slice(0, c).trim();
    var given = p.slice(c + 1).trim();
    var initials = given.split(/\s+/).map(function (tok) {
      return tok.split('-').filter(Boolean).map(function (part) {
        return part.charAt(0).toUpperCase() + '.';
      }).join('-');
    }).join('');
    return last + ', ' + initials;
  }

  function fmtAuthors(a) {
    var list = a.split(/\s+and\s+/).map(fmtPerson);
    if (list.length === 1) return list[0];
    if (list.length === 2) return list[0] + ' & ' + list[1];
    return list.slice(0, -1).join(', ') + ' & ' + list[list.length - 1];
  }

  /* Which links to show under an entry. Only links we know resolve to a real
     page are emitted: the DOI, a public PDF, and/or the exact eScholarship
     item. We deliberately do NOT emit a speculative eScholarship title-search
     for papers that aren't deposited there — that produced empty results pages
     (e.g. pre-UC work). Add `escholarship = {https://escholarship.org/uc/item/...}`
     to publications.bib as more papers are deposited. */
  function links(e) {
    var f = e.fields, out = [];
    if (f.doi) out.push(['doi:' + f.doi, 'https://doi.org/' + f.doi]);
    if (f.pdf) out.push(['PDF', f.pdf]);
    if (f.escholarship) out.push(['eScholarship', f.escholarship]);
    return out;
  }

  function el(tag, cls, text) {
    var n = document.createElement(tag);
    if (cls) n.className = cls;
    if (text != null) n.textContent = text;
    return n;
  }

  /* ---- 3. One <li> per entry -------------------------------------------- */
  function entryLi(e) {
    var f = e.fields;
    var li = el('li');

    li.appendChild(document.createTextNode(
      fmtAuthors(f.author || '') + ' (' + (f.year || 'n.d.') + '). '));
    li.appendChild(el('b', null, (f.title || '') + '.'));
    li.appendChild(document.createTextNode(' '));

    if (e.type === 'article') {
      if (f.journal) li.appendChild(el('i', null, f.journal));
      var t1 = '';
      if (f.volume) { t1 += ', ' + f.volume; if (f.number) t1 += '(' + f.number + ')'; }
      if (f.pages) t1 += ', ' + f.pages;
      li.appendChild(document.createTextNode(t1 + '. '));
    } else if (e.type === 'incollection' || e.type === 'inbook') {
      li.appendChild(document.createTextNode('In '));
      li.appendChild(el('i', null, f.booktitle || ''));
      var t2 = '';
      if (f.series && f.pages) t2 = ' (' + f.series + ', pp. ' + f.pages + ')';
      else if (f.pages) t2 = ' (pp. ' + f.pages + ')';
      t2 += '. ';
      if (f.publisher) t2 += f.publisher + '. ';
      li.appendChild(document.createTextNode(t2));
    } else if (e.type === 'inproceedings' || e.type === 'conference') {
      li.appendChild(el('i', null, f.booktitle || ''));
      var t3 = '';
      if (f.address) t3 += ', ' + f.address;
      if (f.year) t3 += ', ' + (f.month ? f.month + '/' : '') + f.year;
      li.appendChild(document.createTextNode(t3 + '. '));
    }
    /* @misc (patents): the note carries the patent numbers, added below. */

    if (f.note) li.appendChild(el('span', 'pub-note', f.note + '. '));

    var lk = links(e);
    if (lk.length) {
      var row = el('span', 'pub-links');
      lk.forEach(function (pair) {
        var a = el('a', null, pair[0]);
        a.href = pair[1];
        row.appendChild(a);
      });
      li.appendChild(row);
    }
    if (f.award) li.appendChild(el('span', 'pub-award', f.award));
    return li;
  }

  /* ---- 4. Render all lists ---------------------------------------------- */
  var TARGETS = {
    article: 'journal-list',
    incollection: 'chapter-list', inbook: 'chapter-list',
    inproceedings: 'conference-list', conference: 'conference-list',
    misc: 'patent-list', patent: 'patent-list'
  };

  function render(entries) {
    var groups = {};
    entries.forEach(function (e) {
      var id = TARGETS[e.type];
      if (!id) return;
      (groups[id] = groups[id] || []).push(e);
    });
    Object.keys(groups).forEach(function (id) {
      var ol = document.getElementById(id);
      if (!ol) return;
      var list = groups[id];
      // Newest first; the sort is stable, so file order breaks year ties.
      list.sort(function (a, b) {
        return (parseInt(b.fields.year, 10) || 0) - (parseInt(a.fields.year, 10) || 0);
      });
      // Seed the descending CSS counter: first item shows list.length.
      ol.style.counterReset = 'pub ' + (list.length + 1);
      ol.textContent = '';
      list.forEach(function (e) { ol.appendChild(entryLi(e)); });
    });
  }

  /* ---- 5. Load ----------------------------------------------------------- */
  function fail() {
    var ol = document.getElementById('journal-list');
    if (!ol) return;
    var li = el('li', 'pub-fallback',
      'The publication list could not be loaded (this page must be served over ' +
      'HTTP for the list to render \u2014 see README.md). You can ');
    var a = el('a', null, 'download publications.bib');
    a.href = 'publications.bib';
    li.appendChild(a);
    li.appendChild(document.createTextNode(' instead.'));
    ol.appendChild(li);
  }

  function load() {
    // window.__BIB__ lets a self-contained preview embed the file directly.
    if (window.__BIB__) { render(parseBib(window.__BIB__)); return; }
    fetch('publications.bib')
      .then(function (r) { if (!r.ok) throw new Error(r.status); return r.text(); })
      .then(function (text) { render(parseBib(text)); })
      .catch(fail);
  }

  if (typeof document !== 'undefined') {
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', load);
    } else {
      load();
    }
  }

  /* Exported for the Node-based smoke test in scripts/; harmless in browsers. */
  if (typeof module !== 'undefined' && module.exports) {
    module.exports = { parseBib: parseBib, fmtAuthors: fmtAuthors, links: links };
  }
})();
