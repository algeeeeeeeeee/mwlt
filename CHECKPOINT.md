# CHECKPOINT — MEOWLETT

- **Waktu:** 22 November 2026, 23:58 WIB (waktu permintaan audit)
- **Repo:** `algeeeeeeeeee/mwlt`
- **Branch:** `native-swift-parity`
- **SHA source yang diaudit:** `f03ed90b2fa2ac4fd50124787f9b15bb992bca5e`
- **SHA branch sebelum pembaruan checkpoint ini:** `bb4442201a1e943321fbee17fa51a038f08d1e62`
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
- Run #265 pada SHA source `f03ed90...` dibatalkan sebelum UI test selesai; kandidat patch belum terverifikasi.
- Run #264 tidak memiliki artifact xcresult/screenshot; job gagal di langkah UI test.
- Grep penuh pada clone source untuk WKWebView/WebKit belum bisa dilakukan. Daftar file iOS tidak menunjukkan asset HTML/JS/CSS, dan pencarian kode GitHub tidak mengembalikan hasil untuk WKWebView/import WebKit.
- Perbandingan pixel-to-pixel dengan screenshot PWA 390×844 belum dilakukan.

## Hasil CI terakhir

| Run | SHA | Hasil |
|---|---|---|
| [#265](https://github.com/algeeeeeeeeee/mwlt/actions/runs/45040518618) | `f03ed90...` | CANCELLED saat UI test; belum memverifikasi patch hit target/presenter |
| [#264](https://github.com/algeeeeeeeeee/mwlt/actions/runs/45037226035) | `8c4dddc...` | 3 attempt; semua gagal. 10 test, 6/8/6 assertion failures; dua test case gagal per attempt dan berbeda antar-attempt |
| [#262](https://github.com/algeeeeeeeeee/mwlt/actions/runs/45035794180) | `e6da3d9...` | 10 UI test lulus, workflow gagal karena splash screenshot Light menangkap Dashboard |
| [#251](https://github.com/algeeeeeeeeee/mwlt/actions/runs/45021868794) | `3d69e437...` | Full workflow sukses; 10 UI test lulus; preview Light/Dark historis tersedia |

**Diagnosis Run #264:** BELUM TERBUKTI final. Log berulang menunjukkan `kAXErrorCannotComplete` pada `ScrollToVisible` untuk tombol fixed/overlay. HEAD source memiliki kandidat perbaikan coordinate tap/hit target 44pt dan pemindahan presenter Quick Add, tetapi belum diuji pada job selesai. Tidak boleh menyebut akar masalah sudah selesai.

## Keputusan desain yang masih terbuka

- **T4 saldo/cicilan:** native saat ini menghitung `income - spent - totalCicilanMonthly`; total cicilan mengambil semua nominal monthly tanpa filter `paidMonths`. Belum diputuskan apakah sisa harus mengurangi cicilan yang belum dibayar pada bulan ini. Jangan ubah diam-diam.
- **Preset custom:** spesifikasi prompt menyebut rose, sementara `src/constants/index.js` menyebut green. Perlu keputusan eksplisit.
- Tags, Catatan Harian dan Theme Picker terpisah tetap di luar scope tanpa callsite resmi di App.jsx.

## Status K1–K9

| Kriteria | Status |
|---|---|
| K1 Tidak ada WebView/HTML bundle | PARTIAL — grep penuh source clone belum dilakukan |
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
