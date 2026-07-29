/* FLOW Lab — minimal site JS (no dependencies).
   1. Mobile navigation toggle
   2. Scroll-reveal for elements with class "reveal" (respects reduced motion)
   3. Auto-updating footer year
   The site works fully without JavaScript; everything here is enhancement. */

document.documentElement.classList.add('js');

/* 1 — Mobile nav ---------------------------------------------------------- */
const toggle = document.querySelector('.nav-toggle');
const nav = document.getElementById('site-nav');
if (toggle && nav) {
  toggle.addEventListener('click', () => {
    const open = nav.classList.toggle('is-open');
    toggle.setAttribute('aria-expanded', open ? 'true' : 'false');
    toggle.textContent = open ? 'Close' : 'Menu';
  });
}

/* 2 — Scroll reveal ------------------------------------------------------- */
const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
const revealItems = document.querySelectorAll('.reveal');
if (!prefersReducedMotion && 'IntersectionObserver' in window && revealItems.length) {
  const io = new IntersectionObserver((entries) => {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        entry.target.classList.add('is-in');
        io.unobserve(entry.target);
      }
    });
  }, { threshold: 0.12 });
  revealItems.forEach((el) => io.observe(el));
} else {
  revealItems.forEach((el) => el.classList.add('is-in'));
}

/* 3 — Footer year --------------------------------------------------------- */
const yearEl = document.getElementById('year');
if (yearEl) yearEl.textContent = new Date().getFullYear();
