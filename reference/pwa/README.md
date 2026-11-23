# PWA reference snapshot — read-only

This directory is an exact source snapshot for native/PWA parity work. Treat it as read-only: do not patch, reformat, or "improve" this copy. The PWA is the sole UI/behavior source of truth.

- Repository: `algeeeeeeeeee/mwlt`
- Source ref: `native-swift-parity`
- Source commit: `4449c4bac5331468a91b100199e7993644a07929`
- Package: `meowlett` version `4.0.0`
- Runtime: React `18.2.0`, Vite `5.1.4`, lucide-react `^0.469.0`
- App entry: `src/App.jsx` (monolith)

Copied entry/runtime source:
- `package.json` — blob `0c9bb9c519435b5a9e378391c1ccfba9bdb513a4`
- `index.html` — blob `bd1c647b2cc32fdc257e6a14d727f84d7cf7a697`
- `vite.config.js` — blob `25230f739630b74e0ace346d054550b1a9fce5ba`
- `public/_redirects` — blob `7797f7c6a7356b0d451d11a49925df854c22e978`
- `public/gundam.png` — blob `0649604d93dbe7bc2aae5f54b445617f81b01556`
- `public/icon.svg` — blob `e3dd9d988e56b0ff3f343728faf96aa485a49a60`
- `public/manifest.json` — blob `9018a32e6c0b1d709ac16f12f0fea2c7609a185c`
- `public/meow.png` — blob `0649604d93dbe7bc2aae5f54b445617f81b01556`
- `public/sw.js` — blob `e16c942fc7d13fab3d5a696d7110ff5207340f43`
- `src/App.jsx` — blob `0ae42141e3b8100eab5628700af6da8388ed7f05`
- `src/main.jsx` — blob `e73a48470f4e126cd800b77b3fc295c13609c628`
- `src/icons.jsx` — blob `cebb3e5a4fde304be174b348fd6dee720091b669`
- `src/constants/index.js` — blob `f9f3b701b5a19cb7269563ee42dc1d13a2eff897`
- `src/constants/lang.js` — blob `fada734918c29bdccffcdd4cc537a09b6ad31ef6`
- `src/utils/export.js` — blob `aa143e68822e2bcf11d03145746b9be284a676fd`
- `src/utils/helpers.js` — blob `989c1e7b0c9b88a9212b3da2f79ef16d6ce64627`
- `src/utils/notifications.js` — blob `d42779acfd52fcaca3e3829716d5a76af787d9af`
- `src/utils/theme.js` — blob `fa2ee51dca0f11f3df771dc1c481108c19c29d4f`
- `src/components/AnimatedNumber.jsx` — blob `562f60afbcbca98f425eeb18ccca5ca9639a71fa`
- `src/components/DonutChart.jsx` — blob `855df8eb1ed6790ccef1b0346593e3f984be7eb6`

The snapshot includes `index.html`, `vite.config.js`, all `public/` files, the App entrypoint, its direct local imports, and the constants/icons those imports require.

Deliberately excluded from this snapshot:
- `src/components/Tab*.jsx` and `src/components/Modal*.jsx`: these are not used by the monolithic `src/App.jsx` entrypoint and must not be treated as parity references.
- `src/App_test.jsx` and `src/components/ui.jsx`: not imported by the runtime entrypoint copied here.

To update this baseline later, make an explicit, separately checkpointed source-snapshot refresh from the agreed PWA commit. Do not edit this copy in normal native parity tasks.
