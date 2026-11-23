# CHECKPOINT — MEOWLETT

- **Waktu pembaruan:** 23 November 2026, WIB
- **Repo:** `algeeeeeeeeee/mwlt`
- **Branch:** `native-swift-parity`
- **SHA source yang diaudit:** `f03ed90b2fa2ac4fd50124787f9b15bb992bca5e`
- **SHA dasar saat pembaruan dokumen (sebelum commit checkpoint ini):** `5586a03e27cc65e820668f9be021778efcf23200`
- **PR:** [#2 — Draft Meowlett native SwiftUI parity](https://github.com/algeeeeeeeeee/mwlt/pull/2), base `main`, head `native-swift-parity`, masih Draft dan belum di-merge.
- **Prioritas aktif:** R1a — build PWA dan screenshot Beranda Light/Dark.
- **Source aplikasi diubah dalam sesi audit ini:** TIDAK. Semua commit sesi audit hanya menambah/memperbarui `AUDIT.md` dan `CHECKPOINT.md`.

## Selesai (+ bukti)

1. Peta repo, target Xcode, file Swift, resource font dan tanggung jawab screens — `AUDIT.md`.
2. Pemetaan PWA App.jsx ke native SwiftUI dan pengecualian file ekstraksi yang tidak dipakai — `AUDIT.md`.
3. Pemeriksaan token theme, font, tanggal, backup, export, notifikasi dan model data — `AUDIT.md`.
4. Pemeriksaan Run #264 sebanyak 3 attempt pada SHA yang sama, termasuk test case, assertion, lokasi file, durasi dan environment — `AUDIT.md`.
5. Commit pertama audit tanpa kode aplikasi: `ae61832d7c86cd7eca56c3d07411ddc0fc939c8e` (`audit: dokumentasikan peta repo dan diagnosis CI #264`).
6. Checkpoint dan Draft PR #2 dibuat; PR belum di-merge.

## Sedang dikerjakan

- P0: membuktikan kandidat perbaikan hit target Settings/coordinate tap dan host sheet Quick Add pada SHA source `f03ed90...`.
- P0: membuktikan akar masalah Run #264 dari hasil run terbaru dan bukti xcresult/screenshot.
- P0: menjaga artifact xcresult dan screenshot saat test gagal.

## Terblokir / belum ada bukti

- Simulator lokal tidak tersedia: runtime sesi Linux; `xcodebuild` dan `xcrun` tidak tersedia.
- Screenshot Light/Dark dari HEAD source `f03ed90...` belum ada.
- Run #267 pada SHA `f326632...` gagal 6 test case (5 Settings karena predicate header `hittable == true` timeout; satu Quick Add editor missing). Run #269 memuat patch diagnostik, tetapi status terakhir stale in_progress tanpa artifact.
- Run #264 tidak memiliki artifact xcresult/screenshot; job gagal di langkah UI test.
- K1 sudah diverifikasi melalui Git tree dan scan 23 file Swift, `ios/project.yml`, serta path di bawah `ios/`; hasil lengkap ada di AUDIT.md §9.2.
- Perbandingan pixel-to-pixel dengan screenshot PWA 390×844 belum dilakukan.

## Hasil CI terakhir

| Run | SHA | Hasil |
|---|---|---|
| [#269](https://github.com/algeeeeeeeeee/mwlt/actions/runs/45048943679) | `86d8b3a...` | Build simulator success; UI smoke tests in_progress; hasil/artifact BELUM TERVERIFIKASI |
| [#268](https://github.com/algeeeeeeeeee/mwlt/actions/runs/45048770667) | `5961b24...` | gagal sebelum job dibuat akibat YAML indentation; diperbaiki di #269 |
| [#267](https://github.com/algeeeeeeeeee/mwlt/actions/runs/45047595111) | `f326632...` | build simulator sukses; UI test gagal 10 assertions / 6 test cases; 5 Settings header not hittable + Quick Add editor missing |
| [#266](https://github.com/algeeeeeeeeee/mwlt/actions/runs/45047506498) | `bb44422...` | cancelled di Build simulator; UI tests skipped; tidak ada artifact |
| [#265](https://github.com/algeeeeeeeeee/mwlt/actions/runs/45040518618) | `f03ed90...` | CANCELLED saat UI test; belum memverifikasi patch hit target/presenter |
| [#264](https://github.com/algeeeeeeeeee/mwlt/actions/runs/45037226035) | `8c4dddc...` | 3 attempt; semua gagal. 10 test, 6/8/6 assertion failures; dua test case gagal per attempt dan berbeda antar-attempt |
| [#262](https://github.com/algeeeeeeeeee/mwlt/actions/runs/45035794180) | `e6da3d9...` | 10 UI test lulus, workflow gagal karena splash screenshot Light menangkap Dashboard |
| [#251](https://github.com/algeeeeeeeeee/mwlt/actions/runs/45021868794) | `3d69e437...` | Full workflow sukses; 10 UI test lulus; preview Light/Dark historis tersedia |

**Diagnosis Run #264:** BELUM TERBUKTI final. Log berulang menunjukkan `kAXErrorCannotComplete` pada `ScrollToVisible` untuk tombol fixed/overlay. HEAD source memiliki kandidat perbaikan coordinate tap/hit target 44pt dan pemindahan presenter Quick Add, tetapi belum diuji pada job selesai. Tidak boleh menyebut akar masalah sudah selesai.

## Keputusan desain final (23 November 2026)

- **T4 — Sisa:** pemasukan − pengeluaran bulan ini − cicilan bulan berjalan yang belum ditandai lunas (`paidMonths` tidak memuat kunci bulan lokal berjalan). Label UI harus eksplisit; tes cicilan sudah lunas dan belum lunas.
- **Preset custom:** nilai awal rose `#881337 / #fb7185`.
- **Swipe-to-delete:** boleh ditambahkan; Edit/Hapus melalui kartu terbuka wajib tetap tersedia.
- **Tags/Catatan Harian:** jangan dibuat kecuali benar-benar ada di native; audit tidak menemukan implementasi native.

## Status K1–K9

| Kriteria | Status |
|---|---|
| K1 Tidak ada WebView/HTML bundle | **VERIFIED** — 23 Swift files + project.yml + asset paths scanned |
| K2 Semua layar/modal & semua tombol | BELUM TERVERIFIKASI |
| K3 Semua modal blur | PARTIAL — Quick Add pada preview historis saja |
| K4 Token/radius/font | PARTIAL — neutral palette cocok; theme architecture/font/modal/visual belum |
| K5 S1–S11 Light dan Dark | BELUM TERVERIFIKASI |
| K6 ≥5 CI hijau di SHA berbeda + root cause #264 | BELUM TERVERIFIKASI |
| K7 Backup dua arah | PARTIAL — model ada, round-trip aktual belum |
| K8 S1–S14 tanpa crash/timezone | BELUM TERVERIFIKASI |
| K9 PREVIEW.png per layar/modal | PARTIAL — hanya artifact lama Run #251 untuk 7 screen-state |

## Langkah berikutnya

1. Baca `AUDIT.md` dan `CHECKPOINT.md` sebelum mengulang pemeriksaan.
2. Periksa status run PR #2/current branch. Fokus pada test Settings, Quick Add dan Data.
3. Jalankan test pada source SHA terbaru yang memuat hit target 44pt + coordinate tap dan presenter Quick Add dari dock. Jangan ubah source saat run berjalan.
4. Jika gagal, unggah `.xcresult` dan screenshot test pada kondisi failure; jangan hapus/skip test atau melonggarkan assertion.
5. Tuntaskan P0 dengan tes dan preview yang terbukti sebelum pindah ke P1.
6. Perbarui checklist PR #2 hanya saat ada bukti yang mendukung.

## Batasan kerja

Jangan ubah `main` langsung, jangan merge, jangan force-push/rebase, jangan hapus branch/file/workflow/test. Semua perubahan berikutnya hanya pada `native-swift-parity`, commit kecil berprefix `audit:`, `fix:`, `feat:`, `test:`, `ci:` atau `docs:`.

## Follow-up checkpoint — 23 November 2026

### Selesai dengan bukti
1. **K1 VERIFIED:** 23 Swift files pada target, project.yml, dan asset path di bawah ios dipindai. Rincian di AUDIT.md §9.2.
2. **#266:** cancelled pada Build simulator; UI test skipped; artifact kosong. Pembatalan konsisten dengan concurrency cancel-in-progress ketika PR run #267 mulai.
3. **#267:** build simulator success; 4 test lulus; 6 test case dilaporkan gagal. Pada 5 test Settings, predicate header hittable timeout tetapi coordinate tap tetap disintesis, heading Settings muncul dan alur row/sheet berjalan; kegagalan ada pada assertion metadata XCTest. Satu test Quick Add editor missing. Tidak ada xcresult/screenshot artifact.
4. **#268:** gagal sebelum jobs dibuat akibat YAML step indentation. Diperbaiki pada commit 86d8b3a.
5. Keputusan final T4, preset custom rose, swipe-to-delete optional, serta batasan Tags/Catatan Harian tercatat di atas.
6. Commit 5961b246 menambahkan snapshot diagnostics dan upload xcresult if: always(); commit 86d8b3a memperbaiki YAML.

### P0 — belum selesai
- Header Settings terdaftar di accessibility dan coordinate tap pada #267 berhasil membuka Settings; yang gagal adalah predicate hittable XCTest. Elemen penutup fisik/overlay BELUM TERBUKTI dan tidak ada bukti ia memblokir aksi. Test helper perlu mencatat property itu, tetapi memvalidasi hasil navigasi yang nyata.
- Quick Add sheet failure root cause BELUM TERBUKTI.
- Run #269 sudah Build simulator success dan terakhir in_progress pada Run native UI smoke tests; artifact xcresult belum tersedia. Hasil BELUM TERVERIFIKASI.
- Jangan membuat tag checkpoint/p0-done sampai P0 benar-benar terbukti.

### Status K1–K9
| Kriteria | Status |
|---|---|
| K1 | **VERIFIED** |
| K2 | BELUM TERVERIFIKASI |
| K3 | PARTIAL |
| K4 | PARTIAL |
| K5 | BELUM TERVERIFIKASI |
| K6 | BELUM TERVERIFIKASI — perlu 5 run hijau di SHA berbeda |
| K7 | PARTIAL |
| K8 | BELUM TERVERIFIKASI |
| K9 | BELUM TERVERIFIKASI — PREVIEW.png per layar/modal belum tersedia |

### Langkah berikutnya
1. Periksa hasil #269: UI test log, xcresult, device build dan preview.
2. Baca attachment hierarchy untuk cari alasan header non-hittable dan Quick Add editor gagal muncul.
3. Selesaikan P0 dengan bukti; baru buat tag checkpoint/p0-done.
4. Setelah P0, kerjakan satu prioritas P1 secara penuh: kode + test + screenshot Light/Dark sebelum pindah ke prioritas lain.
5. Buat artifact otomatis PREVIEW.png per layar/modal untuk Light/Dark dengan kolom Referensi bila tersedia; K9 tetap belum dicentang sampai artifact terbaru ada.

PR #2 tetap Draft; jangan merge, force-push, atau hapus branch/file/workflow/test.
## Follow-up checkpoint — 23 November 2026 (HEAD `1e5c0df`)

### Selesai (bukti)
- #269/#273 menunjukkan Settings header berukuran 44×44, label/identifier/enabled benar, tidak ada sheet/alert/keyboard, dan coordinate tap membuka Settings. `isHittable` berubah-ubah untuk frame yang sama: klasifikasi Settings **B** (predicate XCTest mismatch/intermiten), bukan app frame salah atau overlay terbukti.
- Review diff `f03ed90`: Quick Add presenter dipindah ke dock; tidak ditemukan auto-close oleh `onDisappear` atau perubahan tab. Dashboard/Transactions/Settings memiliki presenter terpisah.
- Celah isolasi test terkonfirmasi: sebelumnya tidak ada `-uitest-reset`; FinanceStore memakai `Application Support/Meowlett/transactions.json` dan UserDefaults/AppStorage persisten.
- Commit `2a0454a` menambahkan reset storage per launch, hit-point diagnostics dan timestamp presenter logs. Commit `1e5c0df` memindahkan dua paired tests ke level class; method test kini 12.

### Belum terverifikasi
- `.tap()` vs coordinate untuk Settings dan FAB dalam paired tests: **BELUM TERVERIFIKASI**.
- Reset `-uitest-reset` pada setiap test: code sudah ada; log runner belum tersedia.
- Quick Add showQuickAdd true, content onAppear/onDisappear, presenter lain aktif/tidak, serta jalur dismiss aktual: **BELUM TERVERIFIKASI**.
- #276/#277 pada SHA `1e5c0df`: Build simulator success; UI tests masih in_progress pada saat checkpoint ini. #274/#275 dibatalkan ketika koreksi posisi test dikirim; artifact diagnostiknya parsial.

### Status K1–K9
| Kriteria | Status |
|---|---|
| K1 | **VERIFIED** |
| K2 | BELUM TERVERIFIKASI |
| K3 | PARTIAL |
| K4 | PARTIAL |
| K5 | BELUM TERVERIFIKASI |
| K6 | BELUM TERVERIFIKASI — perlu 5 run hijau atau reruns terpisah dengan catatan |
| K7 | PARTIAL |
| K8 | BELUM TERVERIFIKASI |
| K9 | BELUM TERVERIFIKASI — PREVIEW.png per layar/modal belum ada |

### Langkah berikutnya
1. Ambil log dan `.xcresult` #277/#276. Catat jumlah test yang benar-benar ditemukan (target 12).
2. Ambil `[MeowlettHitPoint]`, `[MeowlettTapComparison]`, `[MeowlettTapStrategy]`, `[MeowlettUITestReset]`, `[MeowlettQuickAdd]`, `[MeowlettPresenter]` dari log.
3. Putuskan hasil normal `.tap()` vs coordinate untuk kedua kontrol; pastikan header tetap membuka Settings dan FAB membuka editor.
4. Pastikan Quick Add presenter state/lifecycle dan tidak ada presenter lain yang aktif bersamaan; jika test isolasi gagal, perbaiki sebelum app UI.
5. Hanya setelah P0 stabil, jalankan lima verifikasi hijau (atau reruns terpisah dengan catatan), baru tag `checkpoint/p0-done`.
6. Setelah P0: mulai P1 satu prioritas penuh, lalu otomatisasi PREVIEW.png Light/Dark per layar/modal.

PR #2 tetap Draft; tidak di-merge dan tidak force-push. Tidak ada pekerjaan P1 yang dimulai.

## Follow-up checkpoint — 23 November 2026 (pemeriksaan sampai HEAD `5586a03`)

### Git log setelah `86d8b3a`

Commit berikut masuk ke `native-swift-parity` setelah `86d8b3aab771ec078554218bfe6411cd5bfbba6e`:

1. `1d39c07c6d28368802ff3cedc35509f14e6ddf5f` — `docs: record P0 diagnostics and final design decisions`
2. `93c323ffbc9e5f8247e959b9576e6218b1da5e23` — `docs: correct Settings hit-testing diagnosis from run 267`
3. `2648f21170352b86c74347830b78e81e8a6201b7` — `docs: refresh P0 workflow checkpoint status`
4. `2a0454a12d94d341e1d64bf6f72567cc24062a33` — `test: isolate UI state and trace fixed-control presenters`
5. `1e5c0df9bfbbca84cd8e3d2338349e79af114820` — `test: register fixed-control tap comparisons`
6. `b881e36f70aac931ce3195ebdfcbf039ea731e68` — `docs: checkpoint P0 hit-testing and presenter diagnostics`
7. `5586a03e27cc65e820668f9be021778efcf23200` — `test: verify dashboard return via selected tab state`

Tidak ada commit aplikasi atau perubahan P1 dalam rentang commit tersebut; perubahan kode adalah instrumentasi/perubahan UI test. Sisanya dokumentasi.

### CI #269 dan semua run sesudahnya

| Run | SHA | Status / hasil | Link |
|---|---|---|---|
| #269 | `86d8b3a` | **failure** — build simulator sukses, UI test gagal | https://github.com/algeeeeeeeeee/mwlt/actions/runs/45048943679 |
| #270 | `86d8b3a` | cancelled | https://github.com/algeeeeeeeeee/mwlt/actions/runs/45048948747 |
| #271 | `1d39c07` | cancelled | https://github.com/algeeeeeeeeee/mwlt/actions/runs/45049365636 |
| #272 | `93c323f` | cancelled | https://github.com/algeeeeeeeeee/mwlt/actions/runs/45050095292 |
| #273 | `2648f21` | **failure** — build simulator sukses, UI tests gagal | https://github.com/algeeeeeeeeee/mwlt/actions/runs/45050210655 |
| #274 | `2a0454a` | cancelled | https://github.com/algeeeeeeeeee/mwlt/actions/runs/45052431641 |
| #275 | `2a0454a` | cancelled | https://github.com/algeeeeeeeeee/mwlt/actions/runs/45052435437 |
| #276 | `1e5c0df` | cancelled setelah pengujian berjalan; diagnostic log tersimpan | https://github.com/algeeeeeeeeee/mwlt/actions/runs/45052948878 |
| #277 | `1e5c0df` | cancelled ketika paired test Quick Add sedang berjalan; artifact parsial | https://github.com/algeeeeeeeeee/mwlt/actions/runs/45052955026 |
| #278 | `b881e36` | cancelled sebelum test case mulai; artifact hanya log bootstrap/scheduling | https://github.com/algeeeeeeeeee/mwlt/actions/runs/45054056046 |
| #279 | `5586a03` | **in_progress** saat pemeriksaan; tidak menunggu hasil | https://github.com/algeeeeeeeeee/mwlt/actions/runs/45054430735 |
| #280 | `5586a03` | **in_progress** saat pemeriksaan; tidak menunggu hasil | https://github.com/algeeeeeeeeee/mwlt/actions/runs/45054435413 |

### Artifact diagnostik `.xcresult`

**ADA.** Workflow upload artifact `Meowlett-UI-Test-Diagnostics` dari `$RUNNER_TEMP/MeowlettUITests.xcresult`. Artifact tersedia untuk #269 (160.668.376 bytes), #273 (129.745.096 bytes), #274/#275 (parsial), #276 (26.876.112 bytes), #277 (20.538.580 bytes), dan #278 (5.191 bytes). #279/#280 belum memiliki artifact pada pemeriksaan ini.

Snapshot yang paling baru dan masih memiliki rekaman test interaksi untuk Settings/FAB adalah #276. Artifact #278 lebih baru secara waktu upload, tetapi isinya hanya session bootstrap (tidak ada `Test Case`, `MeowlettHitPoint`, atau paired-test snapshot). #279/#280 masih berjalan dan tidak ditunggu.

### Kutipan snapshot #276

**Settings** — `testSettingsHeaderStandardTapVersusCoordinateTap`:
- `exists=true`: elemen Button ditemukan melalui accessibility query dengan identifier.
- `label=Pengaturan`, `identifier=mwlt.header.settings`, `enabled=true`.
- `hittable=false` pada snapshot sebelum standard tap.
- `frame=(288.0, 69.0, 44.0, 44.0)`; `center=(310.0, 91.0)`.
- `overlays.sheet=false, alert=false, keyboard=false`.
- Pada dua snapshot lain pada run #276, identifier dan frame yang sama mencatat `hittable=true`.
- Debug description memuat Button dan Image `gearshape` pada frame 44×44. Candidate list juga berisi container/ancestor layar penuh dan ScrollView; tidak mengidentifikasi satu elemen overlay tertentu yang menutupi titik tengah.

**Perbandingan Settings:** pada paired test, `button.tap()` memulai gesture tetapi XCTest menghitung hit point `(-1, -1)`, mencatat `Element not hittable`, lalu gagal pada `kAXErrorCannotComplete` / `kAXScrollToVisibleAction` (assertion di `MeowlettUITests.swift:495`). Test berhenti di jalur standard tap itu; coordinate leg pada paired test **tidak tercapai**. Secara terpisah pada run yang sama, helper memakai coordinate-center fallback saat identifier ada dan enabled, dan test `testSettingsBackupActionBuildsAndRequestsExport` lulus. Jadi ada bukti coordinate fallback pada Settings berhasil dalam alur test lain, tetapi bukan hasil paired A/B yang tuntas.

**FAB / Quick Add** — paired test `testQuickAddStandardTapVersusCoordinateTap`:
- `exists=true`, `label=Tambah transaksi`, `identifier=mwlt.quickAdd`, `enabled=true`, `hittable=true`.
- `frame=(25.6667, 739.0, 54.0, 54.0)`; `center=(52.6667, 766.0)`.
- `overlays.sheet=false, alert=false, keyboard=false`.
- `button.tap()` menghasilkan `opened=true`; setelah relaunch, `coordinate(center)` juga menghasilkan `opened=true`. Paired test lulus.

### Kesimpulan berbasis bukti (tidak mengubah source/test)

- **Settings: bukti lebih mendukung B — predicate/hit-point XCTest tidak cocok secara konsisten untuk fixed header/container.** Frame 44×44, identifier, label dan enabled benar; `hittable` berubah false/true pada frame yang sama; coordinate fallback pada test Settings lain dapat menyelesaikan alur Backup. Tidak ada bukti spesifik bahwa overlay fisik menutupi tombol. Penyebab lebih dalam dari kegagalan AX `ScrollToVisible` (misalnya perilaku hosting/container SwiftUI) **BELUM TERBUKTI**.
- **Quick Add: bukan gejala hittable yang sama pada run #276.** FAB hittable dan kedua metode tap membuka editor pada paired test. Ini tidak dengan sendirinya menjelaskan historical failure #267; akar penyebab kegagalan lama Quick Add **BELUM TERBUKTI**.
- **Perbandingan paired Settings A/B belum lengkap** karena standard `.tap()` gagal lebih dahulu sehingga coordinate leg tidak dijalankan dalam paired test. Jangan menyatakan bahwa paired comparison Settings sudah lulus.
- P0 belum selesai; belum ada lima run hijau yang memenuhi K6. Tidak ada tag `checkpoint/p0-done`.

### Batas perubahan pada checkpoint ini

Hanya `CHECKPOINT.md` yang diperbarui. Tidak ada perubahan app source, test/helper, workflow, atau konfigurasi. PR #2 tetap Draft dan belum di-merge. Tidak ada pekerjaan P1 atau PREVIEW.png yang dimulai.


## Follow-up checkpoint — paired Settings test independence

- Basis: checkpoint 7ec57ce was read first. The branch already contained 7e2c829 (test: complete Settings tap comparison after AX failure), whose paired test still allowed the first leg's assertion/failure behavior to interfere with completion of the coordinate leg.
- Changed only: ios/Tests/MeowlettUITests.swift — testSettingsHeaderStandardTapVersusCoordinateTap; and this checkpoint document.
- The standard and coordinate legs now run in separate XCTContext.runActivity blocks. The app is relaunched between legs, so each begins from a fresh dashboard regardless of the first leg's result.
- Each leg waits for the existing Dashboard tab identifier and `value == selected` (Dashboard does not expose `mwlt.screen.dashboard`), plus the Settings button identifier. It logs `hittable` before/after the wait, tap attempt, `opened=true/false`, and ISO-8601 timestamps.
- The standard `.tap()` leg uses a non-strict expected-failure matcher for only `kAXErrorCannotComplete` + `kAXScrollToVisibleAction` when the Button reports `isHittable=false`; other failures remain failures. Coordinate navigation is always required; standard-tap navigation is required when XCTest reports the Button hittable. The regular Settings helper still asserts the actual destination after whichever gesture it selects.
- No app source, Quick Add paired test, other tests, workflow, or P1 files were changed.
- Next run inspection: confirm both activity logs are present even if standard .tap() reports an AX failure; compare each leg's pre/post-wait hittable values; verify opened=true independently for both; check that both timestamps and hit-point snapshots are attached. CI was not awaited as requested.
- Not yet verified: compilation and CI execution of this change; both paired Settings legs passing on a runner.


## CI check — SHA `c3c09c6` / Run #285 (23 November 2026)

- Run: [#285 — Meowlett Native iOS Build](https://github.com/algeeeeeeeeee/mwlt/actions/runs/45056786313), head SHA `c3c09c6c7dc86c3f36cafbf5786b37264cbbd846`.
- Status at the single check: **completed / cancelled**. Job `Build Meowlett for iOS` also completed with conclusion `cancelled`.
- Step `Build simulator`: **success**. Step `Run native UI smoke tests`: **cancelled**. The job log shows `xcodebuild test` starting and creates the result-bundle path at `18:46:50Z`; cancellation occurs at `18:47:22.6321520Z` while Swift compilation is still running. No `Test Case` or `[MeowlettTapComparison]` records appear in the job log.
- Diagnostic artifact [Meowlett-UI-Test-Diagnostics-45056786313-1](https://github.com/algeeeeeeeeee/mwlt/actions/runs/45056786313/artifacts/14767658682) uploaded, but its reported size is only **394 bytes**. It is not a usable test-result snapshot; no paired-leg diagnostics were captured.

### Paired Settings result — classification (c)

**BELUM TERBUKTI.** Neither leg has a recorded `hittable` value before/after readiness wait, `opened=true/false`, nor timestamp. The UI test step was cancelled before the test case produced its paired-leg output. Therefore this run supports neither (a) timing/stability nor (b) predicate/hit-point. Do not infer either cause from this run.

No test, app source, workflow, or PR setting was changed in this check. This checkpoint update records the cancelled run only; it does not claim that the paired Settings comparison passed. The branch had advanced to `f110feeb40b2b3d28a0436c5f049083f29d63a98` after the run's head SHA; this documentation change is based on that current branch head. PR #2 remains Draft; no CI polling or rerun was performed.


## Workflow trigger correction — Run #285 cancellation and single push run

- Checked the Actions run list once for starts before `2026-11-22T18:47:22Z`. Run [#287](https://github.com/algeeeeeeeeee/mwlt/actions/runs/45057036595) (`pull_request`, head SHA `f110feeb40b2b3d28a0436c5f049083f29d63a98`) started at `18:47:09Z`, before Run #285's cancellation at `18:47:22Z`. #287 is the likely cancelling run: both are `pull_request` runs for PR #2 and therefore share the concurrency group generated from the same `github.ref` (`refs/pull/2/merge`) while `cancel-in-progress: true` is enabled.
- Run [#286](https://github.com/algeeeeeeeeee/mwlt/actions/runs/45057031629) used the same head SHA `f110feeb40b2b3d28a0436c5f049083f29d63a98` but was event `push`, started at `18:47:06Z`. Its `github.ref` is the branch ref, so it uses a different concurrency group from the PR run and is not the likely cause of #285 cancellation. #285 is [here](https://github.com/algeeeeeeeeee/mwlt/actions/runs/45056786313), head SHA `c3c09c6...`.
- Workflow change in this commit: push trigger now uses `paths-ignore` with `**.md` and `docs/**`, so a push consisting only of Markdown/docs changes does not start the iOS workflow. GitHub Actions does not permit `paths` and `paths-ignore` together for the same event, so the former positive push allowlist was replaced; consequently non-Markdown, non-doc pushes to the configured branches can trigger the workflow.
- To keep this workflow-only commit to a single run, the `pull_request.paths` list no longer includes `.github/workflows/ios-native.yml`; this commit therefore triggers through the `push` event, while the PR path filter remains for `ios/**` and `public/meow.png` changes.
- `concurrency.group` and `cancel-in-progress: true` are unchanged.
- Both workflow and checkpoint are included in this single `ci:` commit before push. The resulting push run is the run to inspect; do not push follow-up documentation or any other commit until the run has been evaluated.


## CI diagnosis — Runs #289 and #290 on SHA `c70cc91` (23 November 2026)

### Workflow phase and aggregate result

| Run | Event | Build simulator | Run native UI smoke tests | Result |
|---|---|---|---|---|
| [#289](https://github.com/algeeeeeeeeee/mwlt/actions/runs/45057702642) | push | **success** | **failure** | failure |
| [#290](https://github.com/algeeeeeeeeee/mwlt/actions/runs/45057706796) | pull_request | **success** | **failure** | failure |

Both runs built the simulator successfully. The failing step was specifically `Run native UI smoke tests`, step 8; the subsequent device build and preview steps were skipped.

Exact aggregate lines:

- #289: `Executed 12 tests, with 1 failure (0 unexpected) in 693.233 (693.342) seconds`
- #290: `Executed 12 tests, with 1 failure (0 unexpected) in 451.897 (451.911) seconds`

### Test results — Run #289

| Test | Result |
|---|---|
| `testDatePreviewLaunchStartsOnDateTab` | passed |
| `testDateWishlistSheetCanBeOpened` | passed |
| `testMainTabsQuickAddAndCalculatorPresentation` | **failed** |
| `testNativeOpeningSplashAppearsAndDismisses` | passed |
| `testQuickAddSavesTransactionAndShowsItInTransactionsList` | passed |
| `testQuickAddStandardTapVersusCoordinateTap` | passed |
| `testSettingsBackupActionBuildsAndRequestsExport` | passed |
| `testSettingsHeaderStandardTapVersusCoordinateTap` | passed (see paired-leg caveat below) |
| `testSettingsMainSubmenusAndNestedCategoryFlowsOpenAndDismiss` | passed |
| `testSettingsNotificationsShowSystemPermissionStatus` | passed |
| `testSettingsResetRequiresConfirmationAndCanBeCancelled` | passed |
| `testSettingsRestoreActionRequestsImport` | passed |

Exact failure line:

```text
2026-11-22T19:02:37.5131770Z /Users/runner/work/mwlt/mwlt/ios/Tests/MeowlettUITests.swift:54: error: -[MeowlettUITests.MeowlettUITests testMainTabsQuickAddAndCalculatorPresentation] : Failed to get matching snapshot: No matches found for Elements matching predicate '"mwlt.screen.settings" IN identifiers' from input {(
```

The diagnostic hierarchy immediately following begins with Dashboard labels (`Selamat malam`, `Isi namamu`, `Beranda`, `NOV 2026`) rather than a Settings heading. This is evidence that the expected Settings identifier was absent from the captured hierarchy when the snapshot query failed.

### Test results — Run #290

| Test | Result |
|---|---|
| `testDatePreviewLaunchStartsOnDateTab` | passed |
| `testDateWishlistSheetCanBeOpened` | passed |
| `testMainTabsQuickAddAndCalculatorPresentation` | passed |
| `testNativeOpeningSplashAppearsAndDismisses` | passed |
| `testQuickAddSavesTransactionAndShowsItInTransactionsList` | passed |
| `testQuickAddStandardTapVersusCoordinateTap` | passed |
| `testSettingsBackupActionBuildsAndRequestsExport` | passed |
| `testSettingsHeaderStandardTapVersusCoordinateTap` | passed (see paired-leg caveat below) |
| `testSettingsMainSubmenusAndNestedCategoryFlowsOpenAndDismiss` | **failed** |
| `testSettingsNotificationsShowSystemPermissionStatus` | passed |
| `testSettingsResetRequiresConfirmationAndCanBeCancelled` | passed |
| `testSettingsRestoreActionRequestsImport` | passed |

Exact failure line:

```text
2026-11-22T19:12:59.6334850Z /Users/runner/work/mwlt/mwlt/ios/Tests/MeowlettUITests.swift:54: error: -[MeowlettUITests.MeowlettUITests testSettingsMainSubmenusAndNestedCategoryFlowsOpenAndDismiss] : Failed to get matching snapshot: No matches found for Elements matching predicate '"mwlt.screen.settings" IN identifiers' from input {(
```

The captured hierarchy again starts with Dashboard labels (`Selamat malam`, `Isi namamu`, `Beranda`, `NOV 2026`) rather than the expected Settings heading.

### Paired Settings log evidence

Run #289 contains this exact record:

```text
2026-11-22T19:06:34.3324740Z [MeowlettTapComparison] control=settings leg=standard phase=pre-tap dashboardReady=true headerExists=true hittableBeforeWait=false hittableAfterWait=false timestamp=2026-11-22T19:06:34Z
```

Run #290 contains:

```text
2026-11-22T19:11:49.2398370Z [MeowlettTapComparison] control=settings leg=standard phase=pre-tap dashboardReady=true headerExists=true hittableBeforeWait=false hittableAfterWait=false timestamp=2026-11-22T19:11:49Z
```

After those lines, both logs record the standard tap failing with the same AX signature. For example, #289:

```text
Failed: Failed to scroll to visible (by AX action) Button, {{288.0, 69.0}, {44.0, 44.0}}, identifier: 'mwlt.header.settings', label: 'Pengaturan', error: Error kAXErrorCannotComplete performing AXAction kAXScrollToVisibleAction
```

Both runs then show `XCTExpectFailure: matcher accepted Assertion Failure` and the corresponding `MeowlettUITests.swift:554: Expected failure` record, followed directly by `Tear Down` and a Test Case `passed` record. **There are no Settings log records for standard `opened`, no coordinate-leg start/result, and no coordinate timestamp in either run.** The paired Settings test was reported as passed by XCTest, but the requested A/B comparison did not complete. Why execution leaves the test immediately after the matched expected failure is **BELUM TERBUKTI** from the job logs alone.

Therefore:
- `hittableBeforeWait=false` and `hittableAfterWait=false` are proven in both runs.
- Settings `opened=true/false` after the standard tap is **BELUM TERBUKTI** (no post-tap record).
- Coordinate Settings `opened=true/false` is **BELUM TERBUKTI** (coordinate leg did not produce a log).
- The evidence does **not** satisfy classification (a) or (b). Final paired Settings classification: **(c) / BELUM TERBUKTI**.

### Are the failures the same?

No. #289 failed `testMainTabsQuickAddAndCalculatorPresentation`; #290 failed `testSettingsMainSubmenusAndNestedCategoryFlowsOpenAndDismiss`. Each had 11 passing tests and one failure, but the failing test case differed.

### Artifact evidence

Both runs uploaded the diagnostics artifact from `$RUNNER_TEMP/MeowlettUITests.xcresult` successfully:

| Run | Artifact | Size |
|---|---|---:|
| #289 | [Meowlett-UI-Test-Diagnostics-45057702642-1](https://github.com/algeeeeeeeeee/mwlt/actions/runs/45057702642/artifacts/14768736855) | **100,976,263 bytes** |
| #290 | [Meowlett-UI-Test-Diagnostics-45057706796-1](https://github.com/algeeeeeeeeee/mwlt/actions/runs/45057706796/artifacts/14768721980) | **119,964,242 bytes** |

The job logs show the source path for the upload as `$RUNNER_TEMP/MeowlettUITests.xcresult`; both artifact uploads completed successfully.

### Failure classification against #267 / #276

1. **#289 — `testMainTabsQuickAddAndCalculatorPresentation`: OLD test-case instability, new failure signature.** The same test case failed in #276 with the different assertion `XCTAssertTrue failed - The dashboard screen heading did not appear after selecting its navigation item.` It passed in #267. In #289, the failure instead reports a missing `mwlt.screen.settings` identifier while the diagnostic hierarchy is still Dashboard. Thus the failing test case is not new, but this exact line-54 snapshot-query error is not established in the older evidence. Exact root cause: **BELUM TERBUKTI**.

2. **#290 — `testSettingsMainSubmenusAndNestedCategoryFlowsOpenAndDismiss`: OLD test-case instability, new failure signature.** This test already failed in #267 with `Asynchronous wait failed: Exceeded timeout of 5 seconds, with unfulfilled expectations: "Expect predicate `hittable == 1` for object "mwlt.header.settings" Button".` In #290, the new recorded error is the line-54 missing Settings identifier/snapshot query, and the hierarchy shows Dashboard. So the test case is a recurrence, but the exact failure mechanism differs from #267. Whether the app navigation failed before the snapshot helper or the helper itself obscured the original assertion is **BELUM TERBUKTI**.

3. **Paired Settings standard-tap AX error:** the `kAXErrorCannotComplete` / `kAXScrollToVisibleAction` failure is **OLD**, already present in #276 for the same fixed 44×44 Settings header. In #289/#290, `hittable` remained false after the readiness wait. The absent coordinate leg is a **new/incomplete paired-test result** for the current test implementation; it cannot be counted as evidence that coordinate tap succeeded.

4. **Quick Add:** `testQuickAddSavesTransactionAndShowsItInTransactionsList` and `testQuickAddStandardTapVersusCoordinateTap` passed in both #289 and #290. Their historical Quick Add failure in #267 was not reproduced in these two runs; this does not by itself prove all Quick Add presenter edge cases fixed.

No app source or workflow changes are implied by this diagnosis. P0 remains open; K6 (five green validations) remains **BELUM TERVERIFIKASI**. Do not create `checkpoint/p0-done`. PR #2 remains Draft.


## Paired Settings test correction — no expected failure

- Replaced the body of only `testSettingsHeaderStandardTapVersusCoordinateTap` in `ios/Tests/MeowlettUITests.swift`. No app source, other test, helper outside this test, or workflow was changed.
- Removed `XCTExpectFailure` entirely. The test temporarily sets `continueAfterFailure = true` and restores the previous value with `defer`. This lets XCTest record a failure from `button.tap()` without aborting the test method before the independent coordinate activity executes.
- The standard and coordinate legs each run in their own `XCTContext.runActivity`, start from a fresh app launch, use the Settings accessibility identifier, record hit-testing before the header wait and immediately before tap, then record `opened` using `waitForExistence(timeout: 3)` plus an ISO-8601 timestamp.
- Immediately before each tap, the test logs 15 lines around the Settings button in the app accessibility hierarchy, a `debugDescription` for the target, and all `descendants(matching: .any)` whose frame contains the required midpoint `(310, 91)`, with element type and identifier.
- Final assertions occur only after both activities. Both standard and coordinate gestures are required to open `mwlt.screen.settings`; a standard AX failure cannot be converted to a passing result.
- Next run: verify both activity blocks are present even if standard `.tap()` fails, check both pre-wait/pre-tap `hittable` values, inspect the 15-line hierarchy context and midpoint-covering elements for both legs, and require `opened=true` independently for each. No CI was awaited in this commit.
- **Not yet verified:** Swift compilation and simulator execution of the revised paired test; both legs passing.


## ANTRIAN TUGAS — PRIORITAS PARITAS (aktif)

Antrian lama R0–R6 versi sebelumnya ditunda; hasil kerja lama tetap menjadi riwayat. Sumber kebenaran UI/perilaku adalah snapshot read-only `reference/pwa/`. Deviasi tambahan selain dua yang disetujui memerlukan persetujuan pemilik.

R0 Cari sumber PWA di repo (package.json bernama "meowlett" dengan vite). Bila ada, salin ke reference/pwa/ (read-only). Bila tidak ada: laporkan dan BERHENTI (pemilik akan mengunggah). **SELESAI — lihat hasil R0 di bawah.**

R1a (sekarang) — Build PWA dan potret hanya Beranda Light+Dark. Verifikasi kelengkapan snapshot dan lockfile; npm install + npm run build; patch safe-area pada salinan dist (top 47px, bottom 34px); bundel Plus Jakarta Sans lokal/OFL; Playwright Chromium dengan viewport 390×844, DPR 3, mobile/touch, timezone Asia/Pontianak, hanya page.clock.setFixedTime('2026-11-15T12:00:00+07:00'); fixture minimal; tunggu melewati splash; screenshot fullPage Beranda Light/Dark; artifact CI.

R1b — Lengkapi fixture `reference/fixtures/meowlett-demo.json`: data demo penuh transaksi bulan ini + 3 bulan lalu, income 5.000.000, 2 goals, budgets, overall budget, cicilan, splitbills, recurring expense/income, wishlist, streak 5. Jangan pindah layar sebelum fixture diverifikasi.

R1c — Perluas harness untuk screenshot layar Beranda, Transaksi, Laporan, Date, Settings dalam Light+Dark dengan fixture penuh. Output ref/<layar>-<light|dark>.png sebagai artifact.

R1d — Screenshot onboarding empat langkah, splash, dan setiap modal dengan pembukaan melalui klik nyata. Jangan memakai URL/state injection untuk membuka modal; semua modal diuji lewat interaksi yang terlihat.

R2 Ikon: ekstrak SVG lucide dari versi terpasang di PWA untuk semua ikon dari icons.jsx, LUCIDE_MAP, GOAL_ICONS, PRESET_ICONS, ICON_OPTIONS, nav/header, plus 8 SVG inline di icons.jsx. Buat enum Swift + path SVG (primitive path/circle/rect/line/polyline/polygon/ellipse), parser kecil atau dependency SPM yang diaudit, render Shape dengan stroke/size/warna parametrik (strokeWidth PWA 1.5–2.5), helper MeowIcon(key:size:color:strokeWidth:), tanpa Image(systemName:) langsung. Unit test tiap key; DEBUG key hilang = kotak merah + log.

R3 Peta menu dan UI test dari App.jsx: header (toggle dark, gear→Settings, avatar→foto); Beranda (tap income→Edit Pemasukan, pensil/Set Budget→Budget Bulanan, +Tambah/pensil goal→Target, Tambah tabungan inline, Lihat Semua→Transaksi); Transaksi (kartu→Edit/Hapus, Cicilan/Patungan/Transaksi Rutin/Pemasukan Rutin); Laporan (export/share/WhatsApp/Story card); Date (wishlist+, catat); Settings (Tampilan, Notifikasi→Pengingat Transaksi, Kategori→Batas/Kelola, Data); Quick Add→Kalkulator. Setiap baris satu UI test button.tap() biasa, tanpa coordinate tap/XCTExpectFailure. Perbaiki penyebab aktual pada source native (overlay/hit-testing/z-order/dua sheet/aksi kosong). Lanjutkan audit statis B1a bila belum selesai.

R4 Pipeline banding: native pada simulator iPhone 14 (390×844) dengan fixture sama (`-uitest-fixture`, `-uitest-fixed-date 2026-11-15T12:00:00+07:00`, `-uitest-timezone Asia/Pontianak`, `-uitest-appearance`, skip splash/onboarding kecuali saat diuji). Output `out/<layar>-<mode>-{ref,native,diff}.png`, montage "ref | native | diff", report.md dengan % piksel beda per layar, artifact `parity-report`.

R5 Loop per layar, satu layar per giliran, Light+Dark, sampai selisih hanya anti-aliasing/rendering font: chrome (header+pill navbar+FAB) → Beranda → Transaksi → Laporan → Date → Settings → tiap modal. Lampirkan montage di CHECKPOINT.md. Plus Jakarta Sans wajib terbundel (bukan fallback SF); background sampai safe-area tanpa strip.

R6 Setelah chrome+Beranda lulus, dan setelah tiap kelompok layar berikutnya: commit dengan pesan `ci: IPA rcN-preview [ipa]` (workflow IPA terpicu commit, bukan tag).

## Status deviasi yang disetujui
1. Semua modal memburamkan latar: blur 6 + dim 0.55; Story card blur 8 + dim 0.75.
2. Perhitungan "hari ini/minggu/bulan" menggunakan zona waktu lokal perangkat.

Tidak ada deviasi lain yang disetujui. Khusus kartu saldo: pemasukan − pengeluaran bulan ini, tanpa cicilan. Ikuti kejanggalan PWA yang disebut pemilik; jangan tambah swipe-to-delete, Tags, atau Catatan Harian.



## Hasil giliran T0 — 23 November 2026 (basis `4ca24ab`)

### Pemeriksaan awal yang diwajibkan
- Run #292 untuk commit `4ca24ab0126993894cc7d27ec4add125c6127f35`: saat pemeriksaan tunggal berstatus `in_progress`; belum ada hasil akhir test maupun kutipan test failure yang dapat dicatat. Tidak dilakukan polling.
- `ios-native.yml` menggunakan `runs-on: macos-15`, `brew install xcodegen`, `xcodegen generate --spec project.yml`, `xcodebuild -list -project ios/Meowlett.xcodeproj`, dan `-scheme Meowlett`. Build workflow menjalankan target app `Meowlett` serta UI test target `MeowlettUITests` pada job native.
- Workflow tersebut tidak mem-pin versi Xcode. File hanya menyatakan runner `macos-15`; catatan AUDIT dari run lama merekam Xcode 16.4 (build 16F6), bukan deklarasi versi di YAML.
- `ios/project.yml` menyebut `name: Meowlett`, app target `Meowlett`, test target `MeowlettUITests`, deployment iOS 17.0, Swift 5.0, bundle ID `com.mwlt.meowlett`, version/build `4.1.0 / 1`.
- Trigger native: `push.branches` hanya `main` dan `native-swift-parity`; `pull_request.branches` hanya `main`. Tidak ada filter `push.tags`; karena push filter native membatasi branch, tag `rc*` tidak memicu workflow UI native. Tidak perlu mengubah workflow yang sudah ada.
- Source app saat ini membaca argumen `-uitest-reset` melalui `ProcessInfo.processInfo.arguments` tanpa guard `DEBUG`; ini hanya dilaporkan pada IPA RC dan tidak diubah di T0.

### Perubahan T0
- Ditambahkan `.github/workflows/ios-ipa-rc.yml`: tag `rc*` + `workflow_dispatch(rc_label)`, concurrency `ipa-rc-${{ github.ref }}` dan `cancel-in-progress: false`. Job hanya membuat Xcode project, menjalankan unsigned Release archive dengan fallback build, verifikasi metadata dan WebKit, mengemas IPA, serta upload artifact 14 hari. Tidak ada perintah UI test.
- Ditambahkan `IPA-RC.md` berstatus preview, bukan paritas UI; P0 terbuka; berisi cara trigger, instalasi Sideloadly/AltStore dan catatan expiry 7 hari Apple ID gratis.
- Pemeriksaan metadata wajib: `CFBundleIdentifier`, `CFBundleShortVersionString`, `CFBundleVersion`, dan executable app. Dependensi WebKit diperiksa untuk setiap Mach-O di bundle dengan `otool -L`; salah satu temuan membuat job gagal.
- Font Plus Jakarta Sans dan `UIAppFonts` serta string `-uitest-*` hanya dilaporkan, tidak menggagalkan job.
- `ios-native.yml` tidak diubah.

### Verifikasi / status T0
- File workflow dan dokumentasi telah disiapkan, tetapi belum dieksekusi oleh GitHub Actions pada saat penulisan checkpoint.
- Build IPA, validasi Info.plist/WebKit, deteksi font/flag dan ukuran/hash artifact: **BELUM TERVERIFIKASI** sampai workflow RC selesai.
- Tag `rc1-preview` dan run IPA yang dipicunya: **BELUM TERVERIFIKASI**.
- Tidak ada perubahan app source, test, atau status PR #2. PR #2 tetap Draft.

### Status K1–K9 (tetap)
| Kriteria | Status |
|---|---|
| K1 | VERIFIED |
| K2 | BELUM TERVERIFIKASI |
| K3 | PARTIAL |
| K4 | PARTIAL |
| K5 | BELUM TERVERIFIKASI |
| K6 | BELUM TERVERIFIKASI |
| K7 | PARTIAL |
| K8 | BELUM TERVERIFIKASI |
| K9 | BELUM TERVERIFIKASI |

## T0 follow-up — build IPA lewat push commit `[ipa]` (23 November 2026)

### Pemeriksaan run commit sebelumnya
- Pada pemeriksaan tunggal sebelum perubahan, HEAD sebelumnya `3b2517ee9f4aa289e1cbc453d39ff09f5004cc9a` memiliki native run #294 (event `push`) dan #295 (event `pull_request`), keduanya `in_progress`. Tidak ada run IPA untuk commit itu. Tidak dilakukan polling.

### Perubahan dalam tugas tunggal ini
- `.github/workflows/ios-ipa-rc.yml`: trigger `push.branches: native-swift-parity` ditambahkan, trigger tag `rc*` dan `workflow_dispatch(rc_label)` dipertahankan.
- Job-level `if` gate: `github.event_name != 'push' || startsWith(github.ref, 'refs/tags/') || contains(github.event.head_commit.message, '[ipa]')`. Push biasa di branch tanpa `[ipa]` tidak menjalankan job; push tag dan workflow_dispatch tetap dapat menjalankan job.
- Concurrency tetap terisolasi pada `ipa-rc-${{ github.ref }}` dengan `cancel-in-progress: false`; tidak berbagi group dengan workflow UI test.
- Label push branch dipetik dari pola `rcN-preview` dalam pesan commit (untuk commit ini `rc1-preview`); tag memakai nama tag, sedangkan workflow_dispatch memakai input `rc_label`.
- Build Release unsigned, archive/fallback build, pemeriksaan Info.plist dan WebKit, pelaporan font/`UIAppFonts`/`-uitest-*`, packaging IPA, summary SHA/version/build/size, serta artifact retention 14 hari dipertahankan. Tidak ada UI test di workflow IPA.
- `IPA-RC.md` diperbarui dengan contoh trigger `git commit -m "ci: build IPA rc1-preview [ipa]"` lalu push ke `native-swift-parity`.
- `ios-native.yml`, source app, test, dan branch `main` tidak diubah.

### Bukti / batas verifikasi
- Branch awal sebelum commit tugas ini: `3b2517ee9f4aa289e1cbc453d39ff09f5004cc9a`.
- Workflow hanya diverifikasi dari perubahan file; eksekusi runner dan hasil build IPA belum dapat disimpulkan sebelum run GitHub Actions dibuat.
- Hasil pemicu run IPA setelah push commit ini akan dicatat melalui pemeriksaan tunggal. Jika tidak ditemukan, penyebabnya akan dinyatakan apa adanya.
- **Build IPA, pemeriksaan runtime Info.plist/WebKit, font/flag Release, dan artifact: BELUM TERVERIFIKASI** sampai workflow dijalankan dan selesai.
- K1: VERIFIED. K2: BELUM TERVERIFIKASI. K3: PARTIAL. K4: PARTIAL. K5: BELUM TERVERIFIKASI. K6: BELUM TERVERIFIKASI. K7: PARTIAL. K8: BELUM TERVERIFIKASI. K9: BELUM TERVERIFIKASI.
- PR #2 tetap Draft; tidak merge, force-push, atau ubah `main`.

## R0 selesai — snapshot sumber PWA (23 November 2026)

### Hasil pemeriksaan sebelumnya
- Run IPA #1 untuk commit `4449c4bac5331468a91b100199e7993644a07929`: **completed / success**. Archive, pemeriksaan metadata/WebKit, packaging, dan upload artifact berhasil. Artifact `Meowlett-IPA-RC-1` tersedia; ini catatan hasil sebelumnya, bukan bagian dari verifikasi R0.

### Penemuan sumber
- HEAD sumber yang disalin: `4449c4bac5331468a91b100199e7993644a07929` pada branch `native-swift-parity`.
- `package.json`: `"name": "meowlett"`, version `4.0.0`, `vite: 5.1.4`, React/ReactDOM `18.2.0`, `lucide-react: ^0.469.0`.
- `src/App.jsx` ditemukan (monolit, 388,505 bytes pada blob Git) dan mengimpor helpers/theme/export/notifications, constants/lang, AnimatedNumber, serta DonutChart.
- `src/utils/theme.js`, `src/constants/index.js`, dan `src/constants/lang.js` ada.
- Tree snapshot root PWA memuat 99 tracked paths; tidak ada `reference/pwa/` sebelumnya.

### Snapshot yang disimpan
- Menyalin entrypoint dan runtime dependencies ke `reference/pwa/`: `package.json`, `index.html`, `vite.config.js`, semua file `public/`, `src/App.jsx`, `src/main.jsx`, `src/icons.jsx`, `src/constants/*`, `src/utils/*`, `src/components/AnimatedNumber.jsx`, dan `src/components/DonutChart.jsx`.
- Salinan memakai blob Git yang sama dengan sumber (SHA dicatat di `reference/pwa/README.md`), sehingga isi sumber tidak ditulis ulang atau diformat.
- `src/components/Tab*.jsx`, `src/components/Modal*.jsx`, `src/App_test.jsx`, dan `src/components/ui.jsx` sengaja tidak disalin: tidak dipakai oleh runtime entrypoint monolit yang dijadikan referensi.
- `reference/pwa/README.md` menetapkan snapshot ini read-only dan mencatat commit sumber serta daftar blob.

### Bukti / batasan
- Bukti R0: identitas package, Vite version, entrypoint dan seluruh file dependency terpilih diverifikasi lewat repository tree dan blob SHA; copy ditambahkan pada commit tugas ini.
- Tidak ada app source native, test, workflow lama, atau `ios-native.yml` yang diubah.
- Tidak ada test build yang dijalankan pada giliran R0; build screenshot harness adalah tugas R1. Build PWA dari snapshot: **BELUM TERVERIFIKASI** sampai R1.
- Antrian R0–R6 di atas menjadi prioritas aktif. R1 adalah tugas berikutnya; berhenti setelah R0.

## R1a — PWA build + Beranda Light/Dark harness (23 November 2026)

### Pemeriksaan run sebelumnya (`1123b1d`)
- Ref-shots run #1: **completed / failure** — [run #1](https://github.com/algeeeeeeeeee/mwlt/actions/runs/45117779789).
- `npm install --no-audit --no-fund --no-package-lock`: **SUCCESS**, 62 packages added in 7s.
- `npm run build`: **SUCCESS**, Vite 5.1.4, 1,590 modules transformed, JS bundle 297.13 kB (gzip 66.48 kB), completed in 2.45s. Service-worker cache key was stamped.
- Patch copied build for fixed safe-area values and local font: **SUCCESS**.
- Playwright package install: **SUCCESS**, 2 packages added.
- Chromium installation: **FAILURE**. Exact log:
  `BEWARE: your OS is not officially supported by Playwright; installing dependencies for ubuntu26.04-x64 as a fallback.`
  `Cannot install dependencies for ubuntu26.04-x64 with Playwright 1.56.1!`
  `ERROR: Playwright does not support chromium on ubuntu26.04-x64`
- Because Chromium did not install, Vite preview and screenshot capture were skipped. The artifact upload step failed with:
  `No files were found with the provided path: .../ref/*.png. No artifacts will be uploaded.`
- Artifact name/size: **none**; no artifact was produced.

### Snapshot completeness
All requested paths exist under `reference/pwa/`:
- `package.json`, `vite.config.js`, `index.html`
- `src/main.jsx`, `src/App.jsx`, `src/icons.jsx`
- `src/utils/export.js`, `helpers.js`, `notifications.js`, `theme.js`
- `src/constants/index.js`, `lang.js`
- `src/components/AnimatedNumber.jsx`, `DonutChart.jsx`
- All `public/*`: `_redirects`, `gundam.png`, `icon.svg`, `manifest.json`, `meow.png`, `sw.js`.
- Missing required paths: **none**.
- No npm/yarn/pnpm lockfile is present; `npm install` is therefore used instead of `npm ci`.

### Changes in this follow-up commit
1. `.github/workflows/ios-native.yml`: removed the `pull_request` trigger completely. Kept the existing `push` branches and exactly these `paths-ignore` patterns: `'**.md'`, `'docs/**'`, `'reference/**'`. The `concurrency` stanza (including `cancel-in-progress: true`) and all job contents are unchanged.
2. `reference/harness/capture-home.mjs`: added font diagnostics:
   - capture URL + HTTP status for `fonts.googleapis.com` and `fonts.gstatic.com` resources requested during initial load; Google CSS is probed and its referenced gstatic font URLs are probed separately.
   - capture every `document.fonts` entry (family, weight, status).
   - capture `getComputedStyle(document.body)` and computed `fontFamily`/`fontWeight` for the greeting (`Selamat pagi/siang/sore/malam`) and the monthly expense amount.
   - print diagnostic JSON to Actions log and write `ref/font-diagnostics.json`.
   - upload artifact now includes both PNG screenshots and `font-diagnostics.json`.
   - Existing local font, page-clock setup, 4.1-second splash wait, viewport, context options, screenshot commands, and screenshot filenames are unchanged. Google Fonts page requests remain aborted; diagnostic requests run separately after the screenshot so they do not alter font selection/rendering.
3. No screenshot result is claimed from the failed Run #1. Diagnostics are **not yet executed**; no conclusions about Google Font response status or actual runtime font weight are claimed.

### Font weight 900
- The official variable font metadata indicates a native `wght` axis of 200–800, while PWA CSS requests up to 900.
- Whether Chromium renders the 900 request through synthetic weight, fallback, or another face in the actual screenshot remains **BELUM TERVERIFIKASI**. The next successful diagnostics run is required before drawing any conclusion.

### Status
- R1a PWA install/build: **VERIFIED successful**.
- R1a Chromium capture and Beranda Light/Dark screenshots: **BELUM TERVERIFIKASI**.
- Artifact name/size: **none** for run #1.
- The next verification run must fix the runner/browser compatibility before R1a can be called complete.
- R1b–R1d remain queued; this commit does not start them.
- PR #2 remains Draft; native app source and UI tests remain unchanged.



## R1a follow-up — build vs PWA live Beranda (23 November 2026)

- **Acuan utama paritas: https://mwlt.pages.dev.** Snapshot `reference/pwa/` hanya pembanding build; kesetaraannya dengan live tidak diasumsikan.
- Penyebab ref-shots #1: runner `ubuntu-latest` menggunakan Ubuntu 26.04; Playwright 1.56.1 menolak instalasi Chromium pada `ubuntu26.04-x64`. npm install dan build PWA sebelumnya sukses.
- Workflow ref-shots dipatok ke `ubuntu-24.04`; Playwright tetap **1.56.1** dan browser dipasang dengan `npx playwright install --with-deps chromium`. Log menampilkan `/etc/os-release` dan versi Playwright.
- Harness menambah target live `https://mwlt.pages.dev` dengan fixture localStorage yang sama seperti target build, viewport 390×844, DPR 3, mobile/touch, `Asia/Pontianak`, `serviceWorkers: 'block'`, serta hanya `page.clock.setFixedTime('2026-11-15T12:00:00+07:00')`. Tidak memakai `clock.install()` atau `pauseAt()`.
- Google Fonts pada target live tidak diblokir; URL/status HTTP diambil dari respons halaman aktual. Build tetap memakai font lokal dan Google Fonts diblokir pada screenshot build; URL/status font eksternal build dikumpulkan lewat probe setelah screenshot.
- Diagnostik kedua target: semua FontFace (family/weight/status), computed font family/weight pada judul sapaan dan nominal pengeluaran, serta `document.fonts.check('900 16px "Plus Jakarta Sans"')`.
- Target live hanya menerima penggantian safe-area pada respons JS/CSS yang dicegat di runner (top 47px, bottom 34px); deployment live tidak diubah. Log mencatat setiap respons yang benar-benar diubah.
- Output: `ref/beranda-{light,dark}.png`, `ref-live/beranda-{light,dark}.png`, `ref-diff/beranda-{light,dark}-diff.png`, report JSON, dan dua file diagnostik font. Perbandingan menghitung persentase piksel berbeda; jika >1%, log menulis **SNAPSHOT MUNGKIN TIDAK SAMA DENGAN LIVE** serta pita baris piksel berbeda untuk ditinjau. Tidak ada pemilihan otomatis mana yang benar.
- Artifact mengunggah seluruh direktori `ref/`, `ref-live/`, dan `ref-diff/`. Workflow native mengabaikan tambahan path `.github/workflows/ref-shots.yml`; bagian lain `ios-native.yml` dipertahankan.
- **Bobot 900: BELUM TERBUKTI** sampai diagnostics run selesai. Tidak menarik kesimpulan font sebelum hasil run.
- Scope giliran ini hanya capture Beranda Light/Dark untuk build dan live; R1b–R1d tetap antre. Tidak mengubah aplikasi live, source native, test, atau PR #2; PR #2 tetap Draft.


## Run ref-shots #3 — diagnosis and comparison fix (23 November 2026)

### Bukti run #3
- Run ID `45120348084`, commit `03316a6586bc0d23b1ade1119e349a17047e5e06`, **completed / failure**. Job: `Build PWA and capture Home (Light + Dark)`.
- Step yang gagal: `Capture Beranda in Light and Dark`. Step Setup Node, harness dependencies, npm install PWA, Vite build, build patch, Playwright Chromium install, dan Vite preview semuanya **SUCCESS**.
- Build screenshot Beranda Light berhasil disimpan: `ref/beranda-light.png`; live screenshot Light berhasil disimpan: `ref-live/beranda-light.png`. Proses berhenti saat perbandingan Light, sebelum mode Dark dijalankan.
- Log persis: `Error: Screenshot dimensions differ: build 1170x5946, live 1170x5949`. Ini dilempar oleh pemeriksaan dimensi pada fungsi `compare()`, bukan oleh pemeriksaan persentase piksel.
- Klasifikasi: build PWA berhasil; screenshot target build berhasil (Light); screenshot target live berhasil (Light); perbandingan piksel **belum tuntas**; Dark **belum dijalankan**.

### Isi artifact run #3
- Artifact `pwa-reference-build-live-home`, 1,518,784 bytes (1.45 MB), ID `14793890184`.
- `ref/beranda-light.png`: 794,820 bytes.
- `ref-live/beranda-light.png`: 793,706 bytes.
- Tidak ada file diff atau report dalam artifact tersebut karena eksekusi berhenti sebelum fungsi perbandingan menulis output diff.

### Diagnosis yang dibuktikan
- Penyebab kegagalan: fungsi `compare()` menganggap perbedaan dimensi 3 piksel sebagai exception fatal. Target build berukuran 1170×5946; target live 1170×5949.
- Jalur `comparison.thresholdExceeded` (>1%) hanya memanggil `console.log` untuk peringatan; tidak memanggil `process.exit(1)` atau melempar exception. Jadi bukan penyebab exit code 1.
- Step upload artifact pada `.github/workflows/ref-shots.yml` sudah menggunakan `if: always()`; konfigurasi itu dipertahankan tanpa perubahan.

### Perbaikan terbatas dalam commit ini
- Hanya `reference/harness/capture-home.mjs` diubah pada fungsi perbandingan: perbandingan kini memakai kanvas gabungan berdimensi maksimum, tanpa mengubah screenshot sumber atau menskalakannya.
- Piksel yang hanya ada di salah satu screenshot dihitung sebagai perbedaan dan ditampilkan magenta pada tepi gambar diff; area kosong di luar kedua screenshot tidak ikut denominator. Report menyimpan dimensi masing-masing target dan `dimensionsMatch`, serta log mencatat perbedaan dimensi namun melanjutkan capture.
- Ambang >1% tetap merupakan peringatan log saja dan tidak menggagalkan job.
- Tidak mengubah workflow, `ios-native.yml`, versi Playwright, package, fixture, aplikasi/PWA, maupun konfigurasi artifact. Step upload tetap `if: always()`.
- Verifikasi eksekusi perbaikan, capture Light/Dark, pixel percentages, dan artifact run setelah commit ini: **BELUM TERVERIFIKASI** sampai workflow berikutnya berjalan. Tidak menunggu CI.


## R1a — layout/font metrics sebelum screenshot (23 November 2026)

### Pembacaan checkpoint dan audit
- Membaca `CHECKPOINT.md` terbaru di branch `native-swift-parity`; R1a masih mencakup capture Beranda build/live Light+Dark, dan hasil pembandingan setelah perbaikan dimensi pada commit sebelumnya belum tercatat pada saat checkpoint ini.
- Membaca `AUDIT.md` (Audit Fase 0, addendum sampai P0 diagnostics). Audit membahas parity SwiftUI/PWA, status P0 yang belum selesai, serta K1–K9; pekerjaan pada giliran ini dibatasi ke harness referensi, tanpa mengubah aplikasi native.
 
### Verifikasi trigger commit 1aa1ae1
- `.github/workflows/ref-shots.yml` mempunyai trigger `push` khusus branch `native-swift-parity` dengan filter path `reference/**`.
- Commit `1aa1ae199e74ec59742b0a79a8fbfdc389df499c` mengubah `reference/harness/capture-home.mjs`, sehingga cocok dengan filter path. Workflow benar-benar terpicu: ref-shots **run #4**, ID `45121186257`, event `push`, **completed / success** — https://github.com/algeeeeeeeeee/mwlt/actions/runs/45121186257.
- Run lain yang tampak pada commit yang sama adalah IPA RC run #6 dengan kesimpulan `skipped`; bukan ref-shots.

### Perubahan tugas tunggal ini
- Pada fungsi `typography(page)`, untuk masing-masing target build dan live, setelah `await document.fonts.ready` harness menunggu 1500 ms sebelum mengambil ukuran/layout dan daftar font.
- Data ditambahkan ke report per target/mode: `headerOffsetHeight` (offsetHeight ancestor header fixed yang berisi sapaan; null bila tidak ditemukan), `documentScrollHeight`, dan semua `document.fonts` entries (family, weight, status).
- Pengukuran dilakukan sebelum screenshot sehingga report dan screenshot memakai tahap tunggu yang sama untuk kedua target. Pengaturan waktu Playwright tetap hanya `page.clock.setFixedTime(...)`; tidak menambah `clock.install()` atau `pauseAt()`.
- Tidak mengubah workflow, versi Playwright, aplikasi/PWA, fixture, atau file native. Commit ini hanya mengubah harness dan checkpoint.

### Status verifikasi
- Trigger untuk commit `1aa1ae1`: **VERIFIED**, ref-shots run #4 completed/success.
- Eksekusi pengukuran baru dan nilai layout/font dari run commit ini: **BELUM TERVERIFIKASI** sampai workflow berikutnya dijalankan. Tidak menunggu CI.


## R1a-lanjutan — DOM structure dan pemeriksaan bundle live (23 November 2026)

### Basis dan batas tugas
- Membaca \`CHECKPOINT.md\` (blob sebelum perubahan: \`c005764a895fb314bb0447985b4ac6bad27c37f3\`) dan \`AUDIT.md\` (blob: \`b6049a77c56c752b48e2069f0376e55705b38db0\`) pada branch \`native-swift-parity\`; HEAD awal \`e236b58889e9fd6f1efa387304025a1c0e415174\`.
- R1a masih membandingkan hasil build PWA dengan acuan live \`https://mwlt.pages.dev\`. Scope ini hanya memperluas harness referensi; tidak mengubah source aplikasi/PWA, aplikasi native, test, atau workflow native.
- Mode yang dipakai untuk struktur DOM adalah **Light** untuk kedua target (build dan live); pengukuran dilakukan di fungsi typography setelah \`document.fonts.ready\` dan jeda 1500 ms yang telah ada.

### Perubahan harness
- Untuk setiap target, \`#root.querySelectorAll("*")\` direkam dalam urutan DOM. Setiap record menyimpan indeks, tag, 20 karakter pertama teks yang dinormalisasi, serta \`top\`, \`left\`, \`width\`, dan \`height\` dari \`getBoundingClientRect()\` yang dibulatkan ke 0,01 px.
- Snapshot juga menyimpan jumlah descendant element (tidak menghitung elemen \`#root\` itu sendiri) dan panjang \`outerHTML\` dari \`#root\`.
- JSON per target ditulis sebagai \`ref/beranda-light-dom.json\` dan \`ref-live/beranda-light-dom.json\`; keduanya masuk ke artifact yang sudah mencakup folder tersebut.
- \`ref-diff/comparison-report.json\` menambahkan jumlah elemen dan panjang outerHTML build/live, 10 perbedaan \`top\` pertama yang melampaui 0,5 px (urut DOM), elemen pertama yang \`height\`-nya berbeda lebih dari 0,5 px beserta nilai build/live, serta pemeriksaan elemen yang hanya ada pada salah satu target. Identitas keberadaan menggunakan multiset \`tag + 20 karakter teks\`; geometri disejajarkan dalam urutan DOM.
- Sebagai pemeriksaan read-only tambahan, harness mengambil URL script JavaScript utama dari halaman live, mengunduh bundle tersebut, menyimpan salinannya di \`ref-live/live-main-bundle.js\`, dan mencatat hasil pemeriksaan string \`FINANCIAL HEALTH\`, \`gm_recurring_income\`, \`ge-indicator\`, dan \`Patungan\` di \`ref-live/live-main-bundle-check.json\` serta comparison report. Tidak ada request write ke deployment live.

### Verifikasi
- Perubahan file yang direncanakan: hanya \`reference/harness/capture-home.mjs\` dan \`CHECKPOINT.md\`.
- Sintaks harness diperiksa sebelum commit. Push dilakukan satu kali; nomor run ref-shots akan dicek satu kali setelah push.
- Hasil capture DOM, perbedaan build/live, URL/status/ukuran bundle, keberadaan empat string, artifact, dan kesimpulan workflow: **BELUM TERVERIFIKASI** sampai workflow menghasilkan artifact/log. Tidak menunggu CI.
- R1b–R1d tetap antre. PR #2 tetap Draft dan tidak di-merge.


## R3 — native interaction inventory, hit-testing audit, dan UI smoke coverage (23 November 2026)

### Basis audit
- Membaca checkpoint ini (blob sebelum R3: \`104ec6e750ff0031d82d9178a9141b1e90f4ce4c\`) dan \`AUDIT.md\` (blob \`b6049a77c56c752b48e2069f0376e55705b38db0\`) pada branch \`native-swift-parity\`; HEAD awal \`a8a9d78367ad714d5b407bc5247bbc20ae83cd6e\`.
- Inventaris dipetakan dari SwiftUI source pada HEAD tersebut; ini peta source-to-action, bukan klaim semua alur sudah lulus simulator.

### Inventaris menu dan tombol native

| Area / kontrol | File Swift | Aksi |
|---|---|---|
| Header — mode terang/gelap | \`MainTabView.swift\` | Mematikan Follow System lalu mengubah \`darkOverride\` |
| Header — gear Settings | \`MainTabView.swift\` | Mengatur tab aktif menjadi Settings |
| Header — foto profil | \`MainTabView.swift\` | Membuka PhotosPicker; foto pilihan dimuat lalu disimpan sebagai base64 |
| Bottom tab Beranda / Transaksi / Laporan / Date | \`MainTabView.swift\` | Memanggil \`selectTab(tab)\` |
| FAB + | \`MainTabView.swift\` | Menyetel \`showQuickAdd = true\` dan membuka editor transaksi |
| Beranda — edit pemasukan | \`DashboardView.swift\` | Membuka editor pemasukan |
| Beranda — set/edit budget bulanan | \`DashboardView.swift\` | Membuka \`NativeMoneyEntrySheet\`; Simpan menulis nilai budget |
| Beranda — hapus/tambah budget kategori | \`DashboardView.swift\` | ✕ menghapus limit; tombol persentase menambah limit Rp50.000 |
| Beranda — tambah/edit/hapus target tabungan | \`DashboardView.swift\` | Membuka editor, memperbarui goal, atau menghapus goal |
| Beranda — tambah nominal goal | \`DashboardView.swift\` | Input inline; Simpan menambah saldo tersimpan, Batal menutup input |
| Beranda — Lihat Semua / Catat Sekarang / Lihat Lebih | \`DashboardView.swift\` | Ke Transaksi / callback Quick Add / menambah lima item recent |
| Transaksi — clear pencarian | \`TransactionsView.swift\` | Mengosongkan query |
| Transaksi — filter periode | \`TransactionsView.swift\` | Mengubah periode harian, mingguan, bulanan |
| Transaksi — sort tanggal/jumlah | \`TransactionsView.swift\` | Mengubah urutan tanggal/jumlah ascending/descending |
| Transaksi — filter metode pembayaran | \`TransactionsView.swift\` | Mengubah \`filterPayment\` |
| Transaksi — tambah transaksi | \`TransactionsView.swift\` | Membuka editor transaksi baru |
| Transaksi — expand/Edit/Hapus/Undo | \`TransactionsView.swift\` | Membuka detail, editor, hapus dengan toast, atau memulihkan transaksi |
| Cicilan | \`RecurringTransactionsSection.swift\`, \`TransactionsView.swift\`, \`SettingsFeatureSheets.swift\` | Membuka daftar; tambah/edit, tandai lunas, hapus; editor simpan/batal |
| Patungan | \`RecurringTransactionsSection.swift\`, \`TransactionsView.swift\`, \`SplitBillsSheet.swift\` | Membuka daftar; tambah/edit, toggle pembayaran anggota, hapus; editor simpan/batal |
| Transaksi rutin — expand/tambah/simpan/batal | \`RecurringTransactionsSection.swift\` | Toggle daftar; validasi dan simpan/perbarui draft atau batalkan |
| Pemasukan rutin — expand/tambah/simpan | \`RecurringTransactionsSection.swift\` | Toggle daftar dan menambah/memperbarui pemasukan rutin |
| Laporan — mode Bar/Line | \`ReportsView.swift\` | Mengubah \`trendMode\`; kini Button standar |
| Laporan — tanggal laporan | \`ReportsView.swift\` | DatePicker mengubah \`reportDate\` |
| Laporan — ekspor CSV/HTML | \`ReportsView.swift\` | Menyiapkan Data dan membuka file exporter |
| Laporan — Bagikan ringkasan/WhatsApp | \`ReportsView.swift\` | ShareLink atau membuka URL wa.me berisi ringkasan |
| Laporan — ekspor gambar | \`ReportsView.swift\` | Membuka story modal; Download membentuk gambar dengan ImageRenderer |
| Date — tambah/checklist/hapus wishlist | \`DateTabView.swift\` | Membuka sheet, toggle status selesai, atau menghapus item |
| Date — Catat pengeluaran | \`DateTabView.swift\` | Membuka editor transaksi kategori date |
| Date — expand/Edit/Hapus/Undo | \`DateTabView.swift\` | Membuka detail, edit, hapus dengan Undo, atau pulihkan |
| Settings — Mode Tampilan / Notifikasi / Kategori / Data | \`SettingsView.swift\` | Membuka sheet masing-masing |
| Settings — edit nama profil | \`SettingsView.swift\` | Membuka editor inline; OK menyimpan nama |
| Appearance — close, Follow System, mode, bahasa, preset, custom theme | \`SettingsView.swift\` | Menutup sheet atau mengubah preferensi Appearance |
| Notifications — close, toggle, hari, reminder, buka Settings iPhone, OK | \`SettingsView.swift\`, \`SettingsFeatureSheets.swift\` | Mengubah preferensi/izin, membuka reminder sheet, deep-link OS Settings atau menutup alert |
| Reminder — hari/jam/smart/save/close | \`SettingsFeatureSheets.swift\` | Mengubah jadwal; Simpan menjadwalkan notifikasi bila aktif |
| Category menu — Budget/Kelola/Tutup | \`SettingsView.swift\` | Membuka manager budget/kategori atau menutup menu |
| Budget kategori — Done | \`SettingsBudgetSheet.swift\` | Menutup sheet; input mengubah limit kategori |
| Category manager — tambah/edit/hapus, ikon/warna, simpan/reset draft | \`SettingsCategoryManagerSheet.swift\` | Mengelola definisi kategori dan urutan |
| Data — Backup/Restore/Reset/Done | \`SettingsView.swift\` | Ekspor JSON, impor dan konfirmasi restore, konfirmasi reset, atau tutup |
| Quick Add — Kalkulator | \`TransactionEditorSheet.swift\` | Membuka kalkulator; angka/operator mengubah hitungan, Gunakan hasil menerapkan nilai |
| Quick Add — Camera/Upload/Hapus receipt | \`TransactionEditorSheet.swift\` | Membuka kamera/PhotosPicker atau menghapus receipt |
| Quick Add — kategori/metode/tanggal | \`TransactionEditorSheet.swift\` | Mengubah field draft transaksi |
| Quick Add — Simpan/Batal/close | \`TransactionEditorSheet.swift\` | Memvalidasi dan menyimpan transaksi atau menutup editor |
| Kalkulator — angka/operator/C/backspace/Cancel/Gunakan hasil | \`TransactionEditorSheet.swift\` | Mengubah kalkulasi, menerapkan hasil, atau menutup |
| Cicilan editor — Save/Cancel | \`SettingsFeatureSheets.swift\` | Menyimpan atau membatalkan detail cicilan |
| Patungan editor — Save/Cancel | \`SplitBillsSheet.swift\` | Menyimpan atau membatalkan detail patungan |
| Story modal — backdrop/Cancel/Download | \`ReportsView.swift\` | Backdrop/Cancel menutup; Download membentuk file gambar |
| Konfirmasi restore/reset — backdrop/Cancel/Done | \`SettingsView.swift\` | Backdrop/Cancel membatalkan; Done melakukan restore/reset |

**Aksi kosong:** pemindaian deklarasi Button pada file layar/modal utama tidak menemukan closure kosong yang bisa dikonfirmasi sebagai tombol mati. PhotosPicker, DatePicker, ColorPicker, ShareLink, Toggle, dan Picker memakai aksi/binding native. Perilaku runtime per kontrol tetap **BELUM TERVERIFIKASI** sebelum test/device dijalankan.

### Temuan audit struktur modal dan hit-testing
1. **Presenter Transaksi tersebar di parent/child:** \`TransactionsView\` sebelumnya memasang sheet editor, sedangkan child \`RecurringTransactionsSection\` memasang sheet Cicilan/Patungan. Ketiga modal kini dipilih oleh satu enum dan satu \`.sheet(item:)\` pada parent; child hanya mengirim callback.
2. **Modal kedua pada Notifications:** \`SettingsNotificationsSheet\` mempunyai satu \`.sheet\` Reminder dan satu \`.alert\` izin. State keduanya terpisah; alert menutup jalur interaksi ke sheet parent dan tidak ada pemicu source yang menyalakan keduanya bersamaan. Tidak ada bukti konflik runtime.
3. **Presenter bertingkat lain:** \`TransactionEditorSheet\` memiliki sheet kalkulator/kamera; \`SettingsCicilanSheet\` dan \`NativeSplitBillsSheet\` masing-masing memiliki sheet editor item. Itu child flow yang terbuka dari modal induk.
4. **Gesture kontrol non-Button:** Bar/Line di \`ReportsView.swift\` dan swatch warna goal di \`DashboardView.swift\` sebelumnya memakai \`onTapGesture\`; kini Button standar. Backdrop story-card dan konfirmasi Data tetap memakai tap-dismiss yang hanya dipasang pada backdrop.
5. **Overlay dekoratif:** border filter Transaksi, badge header, outline mode Laporan/export, checklist dan tombol Date, serta ring ikon/warna category manager diberi \`allowsHitTesting(false)\`. Backdrop dismiss yang interaktif tidak dinonaktifkan.
6. **Urutan header:** \`MainTabView.topHeader\` memiliki \`zIndex(10)\`, di atas konten scroll; dipertahankan. Splash root tetap \`zIndex(1000)\`.
7. **Gesture induk:** tidak ditemukan \`highPriorityGesture\`, \`simultaneousGesture\`, atau modifier \`.gesture(...)\` pada screen files yang dipindai. Dua \`onTapGesture\` tersisa adalah backdrop dismiss pada Reports story dan Settings confirmation; bukan gesture parent seluruh screen.
8. **View tak terhubung:** \`QuickTransactionSheet\` di \`MainTabView.swift\` dan \`SettingsPlaceholderSheet\` di \`SettingsView.swift\` adalah private view declarations tanpa presenter/call site pada file pemiliknya. Tidak dihapus; aksinya tidak terjangkau dari menu native yang aktif.

### UI test ditambahkan
- \`testPrimaryMenusAndHeaderUseStandardButtonTap\`: Beranda, Transaksi, Laporan, Date, toggle header dan gear Settings memakai \`button.tap()\`.
- \`testDashboardBudgetEditorUsesStandardButtonTap\`: Set Budget → editor → Cancel.
- \`testReportStoryExportModalUsesStandardButtonTap\`: Export Image → modal story → Cancel.
- \`testInstallmentsMenuUsesStandardButtonTap\`: Cicilan → sheet → Close.
- \`testSplitBillsMenuUsesStandardButtonTap\`: Patungan → sheet → Close.
- Test terdahulu tetap mencakup Quick Add/kalkulator, Settings Appearance/Notifications/Category/Budgets/Category Manager/Data/Backup/Restore/Reset, serta Date Wishlist.

### Verifikasi / batas
- Simulator lokal tidak tersedia, sehingga test/build lokal **BELUM TERVERIFIKASI**.
- Test baru, suite penuh, build simulator/device, dan kestabilan tap header gear **BELUM TERVERIFIKASI** hingga CI.
- Tidak mengubah \`main\`, tidak merge PR #2, tidak menghapus file/branch/workflow. PR #2 tetap Draft.


## R3 compile repair — syntax damage from commit 1074fc7 (23 November 2026)

### Basis and diagnosis
- Basis branch HEAD: `1074fc7023ff2e9ceceee4fada03d8c88df70ed2`; Run #303 (`ios-native.yml`) failed during `SwiftCompile` before any UI test executed.
- Opened the commit diff against parent `a8a9d78367ad714d5b407bc5247bbc20ae83cd6e` for the eight affected Swift files.
- The diff showed duplicated fragments inserted mid-expression: orphan `.buttonStyle` / `.accessibilityIdentifier` chains, extra closing braces, one stray `VStack` opener, placeholder empty Buttons, and duplicate parent padding blocks. The errors in the Run #303 compiler log were cascading consequences of these malformed hunks.

### Minimal corrections (no full or partial file revert)
- `DashboardView.swift`: removed the stray `VStack` opener/duplicate spacer; kept the income edit accessibility ID on its existing Button.
- `DateTabView.swift`: attached the wishlist Save ID to its existing Button and removed the duplicate closure/padding fragment.
- `MainTabView.swift`: moved appearance and profile-photo IDs onto their existing controls; removed the malformed placeholder Button and duplicate header closures.
- `RecurringTransactionsSection.swift`: attached Cicilan/Patungan IDs to the existing standard Buttons; removed two orphan separator/closure fragments. The child presenter remains removed.
- `ReportsView.swift`: attached export/cancel/download IDs to their real Buttons; removed the malformed duplicate export-card container, placeholder action Button, and malformed Text fragment.
- `SettingsFeatureSheets.swift`: attached Reminder Save and Cicilan Add/Close IDs to their original Buttons; removed the empty placeholder Button and duplicate header closure.
- `SettingsView.swift`: attached the reminder-row ID to its original Button; removed the duplicate parent-stack closure/modifier fragment.
- `SplitBillsSheet.swift`: attached Patungan Add/Close IDs to their original Buttons; removed the empty placeholder Button and duplicate header closure.
- No feature, data flow, action handler, or user-visible business logic was added or changed. No file was reverted.

### Pre-push validation
| Swift file | `{` count | `}` count |
|---|---:|---:|
| `DashboardView.swift` | 379 | 379 |
| `DateTabView.swift` | 108 | 108 |
| `MainTabView.swift` | 117 | 117 |
| `RecurringTransactionsSection.swift` | 144 | 144 |
| `ReportsView.swift` | 311 | 311 |
| `SettingsFeatureSheets.swift` | 160 | 160 |
| `SettingsView.swift` | 309 | 309 |
| `SplitBillsSheet.swift` | 90 | 90 |

- All eight raw brace counts match.
- `.allowsHitTesting(false)` counts are unchanged from the R3 commit in every affected file: DashboardView.swift 2→2; DateTabView.swift 3→3; MainTabView.swift 5→5; RecurringTransactionsSection.swift 0→0; ReportsView.swift 4→4; SettingsFeatureSheets.swift 0→0; SettingsView.swift 0→0; SplitBillsSheet.swift 0→0.
- The single `.sheet(item: $activeSheet)` remains in `TransactionsView.swift` (count 1); `RecurringTransactionsSection.swift` has no sheet presenter (count 0).
- Empty placeholder dismiss Buttons in the eight files: none.
- A local Swift toolchain is available. `swiftc -parse` passed on a syntax fixture containing the repaired Button/modifier/container patterns. Parsing the eight complete repository files locally: **BELUM TERVERIFIKASI** because repository connector source content was not available as local source files in this runtime.
- Commit/push workflow lookup: pending one post-push check; no CI polling or waiting.

PR #2 remains Draft; no merge, rebase, force-push, branch deletion, or workflow change.


## R3b diagnosis navigasi tab & splash (23 November 2026)

### Basis dan batas kerja
- Basis: branch `native-swift-parity`, HEAD `444a80de0427fec45d8ed6a86fced16a5bbf9766`; Run #304 (`ios-native.yml`) build simulator **SUCCESS**, step `Run native UI smoke tests` **FAILURE**; 17 test case dijalankan, 12 lulus dan 5 gagal. XCTest mencatat 14 assertion failures. Artifact diagnostik tersimpan: https://github.com/algeeeeeeeeee/mwlt/actions/runs/45134122284/artifacts/14801190385.
- Tidak mengubah `MainTabView.swift`, `MeowlettApp.swift`, atau `NativeSplashView.swift`; tidak mengubah perilaku aplikasi. Perubahan kode hanya diagnostik UI test.
- Semua 17 test method dipertahankan; tidak ada test yang dihapus.

### 1. Audit struktur dan lapisan dari source

**MainTabView root**
`MainTabView.swift` membentuk hierarki:
1. `GeometryReader`.
2. Root `ZStack`: background aplikasi paling bawah, lalu inner `ZStack(alignment: .top)`.
3. Inner ZStack berisi selected screen Group (Dashboard / Transactions / Reports / Date / Settings) dengan frame selebar/setinggi geometry.
4. `topHeader` setelah Group, diberi `.zIndex(10)`.
5. Di luar GeometryReader, `.overlay(alignment: .bottom) { bottomNavigation }` menaruh dock/FAB/tab di bawah konten.
6. `.blur(radius: ...)` diterapkan ke hasil MainTabView ketika Quick Add atau modal blur aktif.

Explicit zIndex dalam MainTabView: hanya `topHeader = 10`. Background, page Group, dan bottomNavigation tidak diberi nilai zIndex eksplisit. Splash berada di RootView dan memiliki `zIndex(1000)`.

**Lapisan full-screen / hit-testing**
- Page Group memang full-screen sebagai konten aktif; itu bukan lapisan transparan tambahan.
- Tidak ditemukan overlay/loading full-screen tambahan di `MainTabView.swift`, dan file tersebut tidak menyisipkan NativeSplashView.
- Header blur dibuat oleh `topHeader.background { Rectangle().fill(.ultraThinMaterial) ... }`; ukurannya mengikuti HStack header, bukan ukuran layar. Parent topHeader tidak memakai `allowsHitTesting(false)`, karena berisi tombol aktif. Decoration kecil (badge gear/photo serta outline/fill dock) memakai `allowsHitTesting(false)`.
- Bottom dock ada sebagai outer bottom overlay. Gradient background-nya mengikuti area dock/navbar, bukan seluruh tinggi layar. Background bukan foreground overlay penutup konten.
- Modifier `.blur(...)` pada MainTabView hanya memblur hasil komposit view; bukan view baru yang ditumpuk, dan tidak dengan sendirinya menonaktifkan hit-testing.
- Splash RootView adalah pengecualian: overlay NativeSplashView memenuhi area root, diletakkan pada zIndex 1000 dan tidak memakai `allowsHitTesting(false)`. RootView secara eksplisit menyembunyikan accessibility konten di bawahnya selama splash aktif.

**Splash lifecycle**
- `RootView` menginisialisasi `@State showNativeSplash = true`.
- `RootView.overlay` membuat NativeSplashView hanya dalam cabang `if showNativeSplash`; callback onFinish mengubah state ke false di dalam `withAnimation` (.4s normal, .18s Reduce Motion), dengan `.transition(.opacity)`. Karena cabangnya kondisional, setelah transisi selesai NativeSplashView dikeluarkan dari hierarchy, bukan sekadar dibuat transparan.
- Pada launch normal, `NativeSplashView.task` mengisi progress lalu memanggil `onFinish()` setelah 2.7s (atau 0.45s saat Reduce Motion). Pada `--mwlt-test-splash` ia sengaja menahan splash dan memperlihatkan tombol Continue; Continue memanggil onFinish. Pada `--mwlt-preview-splash` splash juga ditahan untuk capture.
- Kebenaran lifecycle pada perangkat/simulator tetap perlu dibaca dari diagnostik runtime baru: **BELUM TERVERIFIKASI**.

**Gesture dalam MainTabView**
- Tidak ada `.onTapGesture`, `TapGesture`, `DragGesture`, `.gesture(...)`, `.highPriorityGesture`, atau `.simultaneousGesture` pada `MainTabView.swift`.
- Yang ditemukan hanya lifecycle hooks: `.onAppear` pada MainTabView (baris 253) dan konten Quick Add (baris 514), serta `.onChange` untuk Quick Add, selected, dan selectedHeaderPhoto (baris 257, 260, 264). Ini bukan gesture input.

**Tombol navigasi**
- Keempat tab dock dibuat dengan SwiftUI `Button` di dalam `ForEach` (bukan gesture). Identifier-nya `mwlt.tab.<rawValue>`; accessibilityValue adalah `selected` saat `selected == tab && !showQuickAdd`, selain itu `not-selected`.
- Action Button memanggil `selectTab(tab)`. Fungsi tersebut menulis `selected = tab` langsung ketika Reduce Motion aktif; jika tidak, menulis state yang sama di dalam `withAnimation(.timingCurve(... duration: 0.22))`.
- Tombol Settings di header juga Button standar dengan identifier `mwlt.header.settings`; action menulis `selected = .settings` di dalam spring animation.
- Cabang judul Dashboard di header hanya menampilkan greeting dan nama pengguna; identifier `mwlt.screen.<tab>` ditempel pada judul untuk cabang tab non-Dashboard. Tidak ditemukan identifier `mwlt.screen.dashboard` pada repo. Dengan demikian helper test `tapTab("dashboard")` yang mengharuskan `mwlt.screen.dashboard` berpotensi false-negative walaupun Dashboard sudah terpilih.

### 2. Diagnostik UI test yang ditambahkan
- `capturePostSplashNavigationDiagnostics(_:) ` memeriksa splash `mwlt.splash.title` setelah launch. Jika terlihat, ia menunggu predicate `exists == false`; jika tidak terlihat, ia menunggu tombol Dashboard menjadi ada. Status hasil tunggu dicetak.
- Setelah itu, helper mencetak seluruh `app.debugDescription`, lalu `isExists` dan `isHittable` untuk `mwlt.tab.dashboard`, `mwlt.tab.transactions`, `mwlt.tab.report`, `mwlt.tab.date`, dan `mwlt.header.settings`. Debug description menjadi snapshot hierarki/frame untuk inspeksi; tidak menggunakan API `elementAtPoint`.
- Helper dipanggil setiap launch biasa melalui `launchUITestApp`. Untuk test yang sengaja menahan splash (`--mwlt-test-splash` / `--mwlt-preview-splash`), helper dipanggil setelah Continue; test splash tidak dihapus.
- Jumlah test method tetap 17; semua test lama tetap ada. Hasil diagnostik runtime dari workflow baru: **BELUM TERVERIFIKASI**.

### 3. Kandidat penyebab, urutan awal (semua runtime BELUM TERVERIFIKASI)
1. **Assertion Dashboard memakai identifier yang tidak dibuat oleh UI:** kode header Dashboard memakai greeting/nama dan tidak memberi `mwlt.screen.dashboard`; sementara `tapTab("dashboard")` mengharuskan staticText identifier itu. Ini menjelaskan kegagalan pada awal `testPrimaryMenusAndHeaderUseStandardButtonTap` tanpa membuktikan tap Dashboard gagal.
2. **Tap Button tab / pembaruan accessibilityValue untuk Transactions dan Reports:** kode menggunakan Button standar dan `selectTab` menulis state dengan benar secara eksplisit. Run #304 gagal menunggu value `selected` untuk Transactions/Report. Karena MainTabView tidak memiliki parent gesture, perlu bandingkan debugDescription, keberadaan dan isHittable pasca-splash untuk melihat apakah kontrol ada dan dapat ditap; sumber masalah event delivery vs XCTest accessibility snapshot masih **BELUM TERVERIFIKASI**.
3. **AX action Settings pada fixed header:** tombol punya frame 44×44, contentShape Rectangle, identifier stabil dan action Button standar. Error #304 adalah `kAXErrorCannotComplete` pada `kAXScrollToVisibleAction`, bukan bukti bahwa kode action Settings tidak berjalan. Hubungan dengan container/header SwiftUI perlu bukti snapshot baru; **BELUM TERVERIFIKASI**.
4. **Timing splash/visibility:** RootView memakai overlay full-screen zIndex 1000 dan `.accessibilityHidden(showNativeSplash)`; test helper sebelumnya tidak menunggu splash hilang secara eksplisit. Ini kandidat timing yang layak dikendalikan, tetapi tab query di test sebelumnya sudah menggunakan waitForExistence; race sebagai akar kegagalan **BELUM TERVERIFIKASI**.
5. **Header material / bottom dock backgrounds:** material header hanya mengikuti tinggi header; dock gradient mengikuti area bawah; overlay dekoratif diberi `allowsHitTesting(false)`. Dari source, tidak terlihat view full-screen transparan yang menutupi tab setelah splash hilang. Dugaan intercept oleh blur/header/background **BELUM TERVERIFIKASI** dan kurang didukung kode.

### Batas verifikasi
- Tidak ada perubahan pada behavior/source app, tidak ada test dihapus, tidak ada perubahan workflow atau PR state.
- UI test baru hanya mencetak state dan hierarki. Belum ada hasil simulator dari commit diagnostik ini.
- Commit/push dilakukan satu kali; nomor/status workflow pasca-push akan dilaporkan di percakapan setelah satu pemeriksaan. Hasil build/test baru tetap **BELUM TERVERIFIKASI**.


## R3c — Dashboard selector and Settings header tap comparison (23 November 2026)

### Basis and Run #305
- Basis: `7b283a8ac7ef090d4f42c8532582e0f57433e88b`; Run #305: https://github.com/algeeeeeeeeee/mwlt/actions/runs/45138519257.
- CI: Build simulator passed; UI smoke test step failed. 15 passed, 2 failed out of 17: `testPrimaryMenusAndHeaderUseStandardButtonTap`, `testSettingsHeaderStandardTapVersusCoordinateTap`.
- Run #305 DebugDescription confirms `mwlt.tab.dashboard` exists with value `selected`; `mwlt.dashboard.income.edit` also exists. The hierarchy does not contain a Dashboard title identified as `mwlt.screen.dashboard`.
- Dashboard failure came from `tapTab("dashboard")`, whose helper requires `app.staticTexts["mwlt.screen.dashboard"]`. Source puts `mwlt.screen.<rawValue>` only on the non-Dashboard title branch; the Dashboard branch presents greeting and username. This is a test selector mismatch, not proof the Dashboard tap failed.
- Run #305 hierarchy reports Appearance frame `{{247.0, 74.0}, {34.0, 34.0}}` and Settings frame `{{288.0, 69.0}, {44.0, 44.0}}`. Both are present as Buttons.

### Changes — UI tests and checkpoint only
- `testPrimaryMenusAndHeaderUseStandardButtonTap` now verifies `mwlt.tab.dashboard` has accessibility value `selected` and checks the real Dashboard button `mwlt.dashboard.income.edit`. It no longer expects the nonexistent `mwlt.screen.dashboard`. Transactions, Reports, Date and header checks remain.
- `testSettingsHeaderStandardTapVersusCoordinateTap` logs `exists`, `isHittable`, and `frame` for `mwlt.header.appearance` and `mwlt.header.settings` before the tap sequence. It attempts Appearance with `button.tap()`, waits for the accessibility value to change, and records whether it succeeded. It then records Settings hittability/frame again immediately before calling Settings `button.tap()`.
- Source comparison: both are sibling standard Buttons in the header HStack. Appearance is a 34×34 Image button with circular background, plain style, accessibility identifier and value. Settings is a 44×44 ZStack button with rectangular content shape and plain style; its red notification badge decoration is `allowsHitTesting(false)`. Their source modifiers, label hierarchies, and dimensions differ as described; the exact reason for XCTest's AX scroll failure on Settings is **BELUM TERVERIFIKASI** until the new runtime logs are available.
- All 17 test methods remain. No application source, visual layout, action, behavior, or workflow was changed.

### Verification
- Static inspection confirms the Dashboard test now targets real accessibility elements; test count is unchanged at 17.
- Raw braces in UI test source: `{`=67, `}`=67 (textual count includes braces in interpolation and string literals).
- Compilation and runtime behavior of this revision: **BELUM TERVERIFIKASI** pending CI.
- Whether Appearance `button.tap()` succeeds, and the exact pre-tap `isHittable`/frame comparison in the simulator: **BELUM TERVERIFIKASI**.

## R2-audit — SF Symbols inventory and PWA/native icon comparison (23 November 2026)

### Scope and evidence
- Basis: native-swift-parity HEAD 6a483a8bcf230e6de515ef141ef9587acd2984de (Run #306 completed SUCCESS).
- Audited tracked Swift sources under ios/Sources for Image(systemName:), Label(systemImage:), and finite symbol-name maps feeding dynamic icon calls.
- PWA sources: reference/pwa/src/App.jsx, reference/pwa/src/icons.jsx, reference/pwa/src/constants/index.js.
- Live image evidence: successful PWA Reference Screenshots Run #6 at commit a8a9d78367ad714d5b407bc5247bbc20ae83cd6e; artifact pwa-reference-build-live-home; image ref-live/beranda-light.png.
- Only CHECKPOINT.md and ios/Tests/MeowlettUITests.swift change. No app UI, screen layout, app behavior, PWA source, or workflow file is changed.
- The diagnostic is in the existing MeowlettUITests target, does not interact with the app, and has no XCTAssert calls. UIImage(systemName:) nil/zero-sized results are logged and do not fail the test.
- The test prints NAMA | file:baris | nil atau ada for each recorded location and attaches the full report as SF Symbol availability inventory with keepAlways lifetime.
- ios-native.yml already uploads the .xcresult in an if: always() step with 14-day retention, so the attachment is included without workflow edits.
- Arbitrary user-provided persisted category icon strings cannot be enumerated statically; all finite built-in mappings and direct source callsites are listed.

### PWA icons by screen/modal and native comparison
Legend: BEDA BENTUK = same broad role, different Lucide/SF glyph; SALAH = semantic mismatch; LEBIH = native-only icon at a corresponding screen/state; HILANG = only when runtime returns nil or size 0×0. Actual HILANG findings remain BELUM TERVERIFIKASI until CI output is inspected.

| Screen / state | PWA icons, size and condition | Native counterpart | Assessment |
|---|---|---|---|
| Shared header | Sun/Moon 15 for current mode; Settings 15; Camera 5 on avatar; Date title Heart 18 | MainTabView.swift:295,307,323,360 | BEDA BENTUK; availability BELUM TERVERIFIKASI |
| Bottom navigation / FAB | Cat 18 active / 22 inactive; Transactions/Report custom list SVG 18/22; Date custom heart SVG 18/22; FAB inline plus 22 | MainTabView custom Shapes; SF plus :425 | BEDA BENTUK; compare custom native tab shapes visually later |
| Beranda — balance/status/insights | Pencil 7; AlertCircle 14/11 for warnings; Flame 13; DiamondPlus 11 at streak ≥3; Zap 13; HeartPulse 14; TrendingUp 16; AlertTriangle or CheckCircle 11 by budget status | DashboardView.swift:289,363,496,519,550,619,639,663 | BEDA BENTUK; native calendar at :519 is LEBIH for short streak where PWA shows text only |
| Beranda — budget/goals | Wallet 20; SlidersHorizontal 13; Pencil 13; PiggyBank 13; Rocket 36; Plus 13/14; GOAL_ICONS 13; CheckCircle 10 when goal reached | DashboardView.swift:739,778,787,944,958,983,1004,1041,1060,1066; goal map :1653–1670 | BEDA BENTUK; SALAH: native maps piggybank goal to banknote, PWA uses PiggyBank |
| Beranda — categories/recent activity/payment | CatIcon 13/21; Receipt 13; ArrowRight 13; HandCoins 32; Wallet 13; DollarSign/QrCode/Landmark 8; ImagePlus 8 only when receipt exists | DashboardView.swift:837,1272,1295–1301,1467,1479,1504,1594,1620,1903 | BEDA BENTUK; dynamic category/payment mappings differ; runtime values BELUM TERVERIFIKASI |
| Beranda — Rincian Kategori | ChartPie variable at App.jsx:3092, size 13; icons.jsx resolves ChartPie as _ChartPie || BarChart2 | DashboardView.swift:1352 uses chart.pie | SALAH — live screenshot shows three vertical bars (BarChart2), not a pie wedge |
| Transaksi — search/filter/empty state | Search 15 and 34 for empty search; X 14; ChevronDown 10/14; filter custom SVG 11; CirclePlus 38 when list empty; Plus 16; CatIcon 11/20/22; DollarSign/QrCode/Landmark 8; ImagePlus 8 with receipt | TransactionsView.swift:231,240,264,320–334,358,381,398,490,508,523,537 | BEDA BENTUK; native plus.circle vs PWA CirclePlus; line.3.horizontal vs custom filter SVG |
| Transaksi — recurring entries | CreditCard 11; Users 11; Repeat 11/15/26; ChevronDown 11; Banknote 11/15; DiamondPlus 11/15/20; Save 14; Pencil/Trash2 13 | RecurringTransactionsSection.swift:127,156,180,194,208,217,247,253,267,275,416,451,493,519; TransactionsView.swift:554,568,598 | BEDA BENTUK for matched concepts |
| Laporan — overview/trends | AlertCircle 18; LayoutList 13; CatIcon 11/14/17; Zap 13; TrendingUp 11/16/13; BarChart2 13/12; AlertTriangle/CheckCircle 11 conditionally; Ban 28 for no data; Calculator2 11 | ReportsView.swift:215,245,287,347,371,486,499,520,538,721,755,801,870,884,906,920,1125 | BEDA BENTUK; native nosign differs from PWA Ban |
| Laporan — export/share | Download 14/15; Share2 15; MessageCircle 16; Calendar 13 | ReportsView.swift:570,584,594,609,621,657,998 | BEDA BENTUK: native tablecells/doc.text/square.and.arrow.up/message.fill/arrow.down.to.line/calendar differ from PWA glyphs |
| Date — main/wishlist | Heart 14/36/16; Plus 13/12; Sparkles 28; CheckCircle 11 only when done; X 13/20; Pencil 14; ChevronDown 14; Trash2 14 | DateTabView.swift:133,143,154,178,191,216,226,239,275,293,312,325,347,411,454 | BEDA BENTUK |
| Settings root | Camera 9; Pencil 12; ChevronRight 16; BadgeDollarSign 18; Settings 18; CatIcon 17; edit/delete 13; Download/Upload/Trash2 18 on Data cards | SettingsView.swift:183,223,273,386,411,435,460,528,837,1082,1096,1177,1190,1205,1428; SettingsCategoryManagerSheet.swift:142,170,192,236,284; SettingsBudgetSheet.swift:90 | BEDA BENTUK; category/data symbols differ between Lucide and SF |
| Settings — Appearance/theme modal | Moon/Sun 18; custom SunMoon SVG 18; Globe 18; Palette 18; PresetIcon 11/12 (Leaf, Waves, Grape, Apple, Citrus, Wind, PaintbrushVertical); PaintbrushVertical 12; CheckCircle 10/12; X 16 | SettingsView.swift:324,335,367,386,411,435,460,470,528,586–594 | BEDA BENTUK; SALAH mappings: PWA Purple=Grape, Rose=Apple, Orange=Citrus, Custom=PaintbrushVertical; native substitutes sparkles, heart, sun.max and wind |
| Settings — Notifications/Reminder modal | Bell/BellOff 18; X 16; BadgeInfo 18; BellRing 18; ChevronRight 16; Reminder title Bell 18, hero Bell 22, row Bell 18, close X 14 | SettingsView.swift:715,723,742,774,823,837; SettingsFeatureSheets.swift:40,49,143,183,287 | BEDA BENTUK; enabled/disabled concept retained with bell.fill/bell.slash.fill |
| Settings — Category menu/budget | ChevronRight 16; BadgeDollarSign 18; Settings 18; CatIcon 17; ICON_OPTIONS picker 16 | SettingsView.swift:1046,1060,1082,1096; SettingsBudgetSheet.swift:90; SettingsCategoryManagerSheet.swift:142,236,284 | BEDA BENTUK; SALAH: native Other category uses square.grid.2x2.fill vs PWA Package |
| Modal — Quick Add/editor/calculator | Calculator2 alias→Calculator 16; Calendar 14; CatIcon 11; Trash2 13; Camera 14; ImagePlus 14; X 12 | TransactionEditorSheet.swift:140,175,190,212,242,281,293,306 | SALAH: native function glyph is not PWA Calculator; common controls BEDA BENTUK |
| Modal — Cicilan | CreditCard 18/32/20; Plus 13; X 14; Pencil 15; Trash2 15 | SettingsFeatureSheets.swift:40–630; RecurringTransactionsSection.swift:127,247,267,451 | BEDA BENTUK |
| Modal — Split Bills/Patungan | Users 18/32; Plus 13; X 18; Equal 14; CheckCheck 16; User 16; Pencil 15; Trash2 15 | SplitBillsSheet.swift:43,50,60,77,147,166,183,209,218 | BEDA BENTUK; native checkmark.circle.fill/circle paid state differs from PWA CheckCheck |
| Modal — Income edit | Smile 17; X 20 while editor is visible | Native Dashboard money-entry flow has no corresponding Smile icon call | PWA-only decorative icon; not an SF nil result |
| Modal — Goal editor/quick savings | X 12/20; Plus 11/14; GOAL_ICONS 13; Pencil 12; CheckCircle 10 | DashboardView.swift:983,1004,1041,1060,1066,1186; goal map :1653–1670 | BEDA BENTUK; SALAH for piggybank→banknote |
| Modal — Date Wishlist/Record Spending | X 13/20; Heart 14/36/16; Plus 12; Pencil 14; Trash2 14; CheckCircle 11; ChevronDown 14 | DateTabView.swift:143–454 | BEDA BENTUK |
| Modal — Category Manager | ICON_OPTIONS/LUCIDE_MAP 16; CatIcon 16; Pencil/Trash2 13 | SettingsCategoryManagerSheet.swift:39–53,142,170,192,236,284; MeowlettTransaction.swift:63–114 | BEDA BENTUK generally; SALAH for piggybank→banknote and Other→square.grid.2x2.fill |
| Modal — Data/Backup/Restore/Reset | Download/Upload/Trash2 18 | SettingsView.swift:1177,1190,1205 (dataAction size 18) | BEDA BENTUK |
| Modal — Overall monthly budget | Wallet 18; X 13 | DashboardView.swift:1272,1378 | BEDA BENTUK |
| Modal — Story card | Download 15 on download action | ReportsView.swift:998 | BEDA BENTUK |
| Modal — Daily Note | Book 18 while PWA Daily Note modal is shown | No corresponding native Daily Note presenter found in current audit | PWA-only feature; not an SF availability failure |

### SF Symbol probe
- Added testSFSymbolAvailabilityInventory to the existing MeowlettUITests target. It checks direct literal calls and finite built-in map values with UIImage(systemName:).
- Static inventory contains 116 unique symbol names and 277 source-location records.
- Each location prints NAMA | file:baris | nil/ada; a zero-size image is separately reported as 0x0. Each unique name is passed once to UIImage(systemName:).
- No assertion is used, so nil does not fail the test. The complete report is an XCTAttachment in the .xcresult.
- ios-native.yml already uploads the .xcresult with if: always() and 14-day retention. Runtime values and new artifact contents remain BELUM TERVERIFIKASI until CI is inspected.

### Live screenshot decision — Rincian Kategori
- App.jsx:3092 uses ChartPie at size 13; icons.jsx resolves it as _ChartPie || BarChart2.
- The actual ref-live/beranda-light.png from PWA Reference Screenshots Run #6 was opened and its Rincian Kategori glyph enlarged: it consists of three vertical bars, not a pie wedge.
- Browser-live therefore renders BarChart2. Native DashboardView.swift:1352 uses chart.pie, so this mapping is SALAH. This is screenshot-based, not inferred from the JSX identifier.

### Verification boundary
- Static changes only. Simulator compilation/execution, actual nil/available results and the new diagnostics artifact contents remain BELUM TERVERIFIKASI.
- No app screen, app source outside the existing test, PWA source, workflow, main branch or PR status was changed. PR #2 remains Draft. No merge, rebase, force-push or deletion.