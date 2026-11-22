# CHECKPOINT — MEOWLETT

- **Waktu pembaruan:** 23 November 2026, WIB
- **Repo:** `algeeeeeeeeee/mwlt`
- **Branch:** `native-swift-parity`
- **SHA source yang diaudit:** `f03ed90b2fa2ac4fd50124787f9b15bb992bca5e`
- **SHA dasar saat pembaruan dokumen (sebelum commit checkpoint ini):** `5586a03e27cc65e820668f9be021778efcf23200`
- **PR:** [#2 — Draft Meowlett native SwiftUI parity](https://github.com/algeeeeeeeeee/mwlt/pull/2), base `main`, head `native-swift-parity`, masih Draft dan belum di-merge.
- **Prioritas aktif:** P0 — stabilitas, bukti, dan akar masalah CI.
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
