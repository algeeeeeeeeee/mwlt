# CHECKPOINT — MEOWLETT

- **Waktu:** 22 November 2026, 23:58 WIB (checkpoint sesi audit)
- **Repo:** `algeeeeeeeeee/mwlt`
- **Branch:** `native-swift-parity`
- **SHA terbaru:** `ae61832d7c86cd7eca56c3d07411ddc0fc939c8e`
- **SHA source yang terakhir diaudit:** `f03ed90b2fa2ac4fd50124787f9b15bb992bca5e`
- **Prioritas aktif:** P0 — stabilitas, bukti, dan akar masalah CI
- **Fase:** Fase 0 audit source/repo + diagnosis Run #264
- **Source aplikasi diubah pada checkpoint ini:** TIDAK. Commit baru hanya dokumentasi.

## Selesai (+ bukti)

1. **Repo map Swift/Xcode** — konfigurasi iOS 17, Swift 5.0, XcodeGen, file Swift, resource font, store, fitur dan target test tercatat di `AUDIT.md`.
2. **Pemetaan PWA → Swift** — screen/modal dirutekan ke file implementasi yang benar. File ekstraksi Tab*/Modal* yang tidak digunakan oleh App.jsx ditandai bukan acuan.
3. **Audit sumber tema/helper/export/notifikasi** — token netral, kategori, preset, format uang/tanggal dan payload backup dibandingkan dengan source referensi.
4. **Run #264 diinspeksi 3 attempt pada SHA sama** — detail test case gagal, assertion/stack line, durasi, environment dan error accessibility tersedia di `AUDIT.md`.
5. **Bukti visual historis** — Run #251, SHA `3d69e437e10b69bf82feb3d6720d204bd4f4605a`, mempunyai artifact gabungan Light/Dark untuk Dashboard, Transactions, Reports, Date, Settings dan Quick Add. Ini bukan bukti HEAD saat ini.
6. **Dokumentasi pertama dibuat tanpa mengubah aplikasi** — commit `ae61832d7c86cd7eca56c3d07411ddc0fc939c8e`, file `AUDIT.md`.

## Item sedang dikerjakan

- P0: verifikasi kandidat perbaikan hit target/coordinate tap dan host sheet Quick Add pada SHA `f03ed90...` di CI.
- P0: tentukan akar masalah Run #264 setelah hasil run pada HEAD terbaru ada.
- P0: simpan xcresult dan screenshot saat tes gagal untuk diagnosa berikutnya.

## Terblokir / belum ada bukti

- **Simulator lokal:** BELUM DILAKUKAN. Runtime sesi audit adalah Linux; `xcodebuild` dan `xcrun` tidak tersedia.
- **Screenshot dari HEAD terbaru:** BELUM ADA. Preview terbaru yang dapat diperiksa adalah Run #251 pada SHA lama.
- **Run #264:** tidak menghasilkan artifact xcresult/screenshot karena gagal pada step UI test.
- **HEAD source fix:** Run #265 pada SHA `f03ed90...` dibatalkan sebelum UI test selesai. Jadi coordinate tap/hit target 44pt dan perpindahan presenter Quick Add belum terbukti.
- **Audit K1 penuh:** daftar file iOS tidak memperlihatkan asset HTML/JS/CSS dan pencarian kode WKWebView/WebKit tidak memberi hasil, tetapi grep menyeluruh pada clone lokal belum bisa dijalankan.
- **Visual PWA vs native 390×844:** belum dapat dibandingkan pixel-to-pixel karena tidak ada screenshot PWA referensi dalam sesi audit.

## Hasil CI terakhir

| Run | SHA | Hasil |
|---|---|---|
| [#265](https://github.com/algeeeeeeeeee/mwlt/actions/runs/45040518618) | `f03ed90...` | CANCELLED saat UI test; belum membuktikan perubahan hit-target/presenter |
| [#264](https://github.com/algeeeeeeeeee/mwlt/actions/runs/45037226035) | `8c4dddc...` | 3 attempt; masing-masing 10 tests dengan 6/8/6 assertion failures. Failure berpindah antar test case |
| [#262](https://github.com/algeeeeeeeeee/mwlt/actions/runs/45035794180) | `e6da3d9...` | UI test 10/10 lulus, tetapi workflow gagal pada validasi splash preview (screenshot menampilkan Dashboard) |
| [#251](https://github.com/algeeeeeeeeee/mwlt/actions/runs/45021868794) | `3d69e437...` | Full workflow sukses; 10 UI test lulus dan artifact Light/Dark preview tersedia |

**Diagnosis Run #264:** BELUM TERBUKTI final. Log memberi bukti kuat masalah `kAXErrorCannotComplete` ketika XCTest mencoba ScrollToVisible tombol fixed/overlay. Patch kandidat pada HEAD memperbesar hit target dan memakai coordinate tap, serta memindah sheet Quick Add ke persistent dock. Wajib uji ulang pada SHA tersebut tanpa menghapus atau melonggarkan assertion.

## Keputusan desain yang belum ditutup

- **T4 saldo/cicilan:** saat ini `remaining = income - spent - totalCicilanMonthly`; nominal monthly seluruh item dijumlahkan tanpa filter paidMonths. Belum diputuskan apakah definisi final harus mengurangi cicilan yang belum dibayar bulan ini. Jangan mengubah diam-diam.
- **Preset custom:** spesifikasi prompt menyebut custom default rose; `src/constants/index.js` menyebut green. Perlu keputusan eksplisit.
- Tags, Catatan Harian dan Theme Picker terpisah tetap di luar scope selama tidak ada callsite resmi di App.jsx.

## Status K1–K9

| Kriteria | Status checkpoint |
|---|---|
| K1 WebView/HTML bundle tidak ada | PARTIAL — perlu grep penuh pada source clone |
| K2 Semua layar/modal dan tombol bekerja | BELUM TERVERIFIKASI |
| K3 Semua modal blur | PARTIAL — hanya Quick Add pada preview lama yang punya bukti |
| K4 Token/radius/font cocok | PARTIAL — neutral token cocok, font/arsitektur/modal/visual belum lengkap |
| K5 S1–S11 Light + Dark | BELUM TERVERIFIKASI |
| K6 ≥5 CI hijau pada SHA berbeda + root cause #264 | BELUM TERVERIFIKASI |
| K7 Backup JSON dua arah | PARTIAL — struktur ada, round-trip nyata belum diuji |
| K8 S1–S14 tanpa crash dan timezone benar | BELUM TERVERIFIKASI |
| K9 PREVIEW.png semua layar/modal otomatis dan di PR | PARTIAL — artifact lama Run #251 saja |

## Langkah konkret untuk melanjutkan

1. Baca `AUDIT.md` dan file ini sebelum mengulang pemeriksaan.
2. Pastikan branch HEAD masih sesuai checkpoint.
3. Jalankan ulang workflow pada HEAD terbaru `f03ed90...` setelah audit/checkpoint commit; jangan ubah source saat run aktif.
4. Pastikan tes Settings header memakai coordinate tap dan 44pt hit target benar-benar membuka Settings; pastikan Quick Add benar-benar membuka TransactionEditorSheet dari dock.
5. Jika gagal, upload xcresult + screenshot test walau job gagal; jangan menambah retry buta atau melonggarkan assertion.
6. Tuntaskan P0 dengan hasil tes dan preview yang terbukti sebelum pindah ke P1. Jangan buat klaim UI 100% sama tanpa perbandingan screenshot Light/Dark dengan referensi.

## Batasan kerja

Jangan ubah `main` langsung, jangan merge, jangan force-push/rebase, jangan hapus branch/file/workflow/test. Semua perubahan berikutnya tetap pada branch `native-swift-parity` dan harus berupa commit kecil berprefix `audit:`, `fix:`, `feat:`, `test:`, `ci:` atau `docs:`.
