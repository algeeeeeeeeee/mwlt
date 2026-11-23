# Meowlett PWA reference screenshot harness

R1a captures only the PWA Beranda screen in Light and Dark.

- Runner: Ubuntu via `.github/workflows/ref-shots.yml`
- Runtime: Node 20, Playwright Chromium
- Viewport: 390×844 CSS px, deviceScaleFactor 3, mobile + touch
- Timezone: Asia/Pontianak
- Time source: `page.clock.setFixedTime('2026-11-15T12:00:00+07:00')`; timers remain real and continue to run.
- Local font: `reference/fonts/PlusJakartaSans[wght].ttf`; Google Fonts requests are blocked in Chromium.
- Fixture: `reference/fixtures/meowlett-demo.json`
- Output: `ref/beranda-light.png`, `ref/beranda-dark.png` (workflow artifact only).

The runner executes `npm install` and `npm run build` from `reference/pwa`, patches a copy of `dist/` for fixed safe-area insets and the bundled font, then serves it with `vite preview`.

R1a intentionally captures only Beranda. Full fixture and other screen/modal coverage are split into R1b–R1d.
