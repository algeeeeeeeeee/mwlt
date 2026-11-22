# MEOWLETT — AUDIT FASE 0

- **Audit branch:** `native-swift-parity`
- **SHA yang diaudit:** `f03ed90b2fa2ac4fd50124787f9b15bb992bca5e`
- **Tanggal audit:** 22 November 2026 (WIB)
- **Batas audit:** pembacaan source/repository dan log GitHub Actions. Tidak ada source aplikasi yang diubah dalam commit audit ini.
- **Catatan lingkungan:** sesi audit berjalan di Linux; `xcodebuild` dan `xcrun` tidak tersedia. Audit simulator lokal iPhone 15/16 tidak dapat dijalankan di lingkungan ini.

## Ringkasan

1. Aplikasi native saat ini menggunakan SwiftUI; target Xcode adalah iOS 17.0, Swift language version 5.0, tanpa deklarasi SPM dependency di `ios/project.yml`.
2. Semua layar utama yang diminta mempunyai file implementasi native: Beranda, Transaksi, Laporan, Date, Settings, Splash, dan Onboarding. Keberadaan source **bukan** bukti semua tombol atau modal bekerja.
3. Token warna netral di `AppAppearance.swift` cocok dengan `buildTheme()` di PWA. Namun native belum memakai satu `MeowTheme` sebagai object environment; pengaturan warna masih berupa helper statis dan banyak pembacaan `@AppStorage`.
4. Modal sudah mempunyai koordinasi blur lintas root, tetapi pelaksanaannya masih campuran `.sheet`, `.alert`, overlay lokal, dan blur per fitur. Tidak ditemukan satu API modal konsisten untuk seluruh modal. Hanya Quick Add pada preview lama yang punya bukti screenshot blur yang dapat diperiksa.
5. Run #264 dijalankan tiga kali pada SHA yang sama. Setiap attempt gagal dengan dua test case UI berbeda/berganti; log berulang mencatat XCTest `kAXErrorCannotComplete` pada aksi `ScrollToVisible` terhadap tombol yang diposisikan fixed/overlay. Ini bukti masalah interaksi accessibility/XCTest yang kuat, tetapi **akar masalah final BELUM TERBUKTI**.
6. HEAD saat audit, `f03ed90b2fa2ac4fd50124787f9b15bb992bca5e`, mempunyai commit kandidat perbaikan untuk hit target Settings dan presenter Quick Add. Run #265 pada SHA ini dibatalkan sebelum tes UI berjalan. Perbaikan itu **BELUM TERVERIFIKASI**.
7. Tidak ada screenshot Light/Dark yang dihasilkan dari HEAD sekarang. Preview gabungan yang dapat diperiksa berasal dari Run #251 pada SHA lama `3d69e437e10b69bf82feb3d6720d204bd4f4605a`; isinya tujuh layar/keadaan (Beranda, Transaksi, Laporan, Date, Settings, Quick Add) dalam Light dan Dark, bukan seluruh modal.

---

## 1. Peta repository dan target native

### 1.1 Konfigurasi Xcode

Sumber konfigurasi: `ios/project.yml`.

| Properti | Hasil pemeriksaan |
|---|---|
| App target | `Meowlett`, type `application`, platform iOS |
| Test target | `MeowlettUITests`, type `bundle.ui-testing` |
| Deployment target | iOS 17.0 |
| Swift language version | `SWIFT_VERSION: 5.0` |
| Device family | `TARGETED_DEVICE_FAMILY: 1` (iPhone) |
| Bundle ID | `com.mwlt.meowlett` |
| Versi/build | 4.1.0 / 1 |
| Project generation | XcodeGen dari `ios/project.yml` |
| SPM packages | Tidak ada bagian `packages` atau package dependency di `ios/project.yml` |
| Info.plist | Dibangkitkan Xcode (`GENERATE_INFOPLIST_FILE: YES`) |
| Launch screen | `UILaunchScreen_Generation: YES`; tidak ada LaunchScreen storyboard/xib yang dilacak |
| Font | Resource folder `ios/Resources/Fonts`; diregistrasi saat runtime lewat CoreText |
| Asset catalog | `ios/Resources/Assets.xcassets` ditambahkan oleh project.yml; AppIcon dan MeowlettSplash dibuat oleh script saat build |

### 1.2 Versi CI yang benar-benar tercatat

Log runner Run #251 dan seluruh attempt Run #264 menunjukkan environment yang sama:

- GitHub Actions runner `2.338.2`
- Runner image `macos-15-arm64`, image release `20261118.0550.1`
- macOS `15.8.2`
- Xcode `16.4`, build `16F6`
- SDK yang muncul pada command compiler: iOS `18.5`
- Destination yang dilaporkan xcodebuild: `iPhone 16`, simulator OS `26.2`
- Project build setting: Swift language version `5.0`; compiler invocation menggunakan `-swift-version 5`

Versi compiler Swift lengkap dari output `swiftc --version` **BELUM DIPASTIKAN** dari log yang tersedia. Versi Xcode, SDK, dan simulator di atas adalah nilai yang tercatat, bukan perkiraan.

### 1.3 File Swift dan tanggung jawabnya

Semua file Swift tracked di HEAD yang diaudit:

| File | Tanggung jawab yang ditemukan dari source |
|---|---|
| `ios/Sources/MeowlettApp.swift` | Entry point `@main`, RootView, pilihan onboarding/main, splash, preferred color scheme |
| `ios/Sources/Features/Main/MainTabView.swift` | Enum/state tab, header, avatar, tombol Settings, FAB, bottom navigation, ModalBlurCoordinator |
| `ios/Sources/Features/Main/NativeSplashView.swift` | Tampilan splash, progres 2,7 detik, shimmer, mode hold untuk UI test/preview |
| `ios/Sources/Features/Onboarding/OnboardingView.swift` | Onboarding empat langkah: bahasa, nama, pemasukan, tampilan/tema |
| `ios/Sources/Features/Dashboard/DashboardView.swift` | Beranda, saldo, ringkasan mingguan, streak, skor finansial, prediksi, budget, goal, cicilan, pemasukan dan modal dashboard |
| `ios/Sources/Features/Transactions/TransactionsView.swift` | Daftar transaksi, pencarian, periode, sort, filter metode bayar, grouping tanggal, empty state, editor dan undo |
| `ios/Sources/Features/Transactions/TransactionRow.swift` | Tampilan row transaksi |
| `ios/Sources/Features/Transactions/TransactionEditorSheet.swift` | Tambah/edit transaksi, field transaksi/struk, metode bayar, kalkulator nominal, pemilih kamera |
| `ios/Sources/Features/Transactions/NativeCameraPicker.swift` | Bridge kamera native untuk lampiran foto |
| `ios/Sources/Features/Transactions/RecurringTransactionsSection.swift` | Form/daftar pengeluaran rutin dan pemasukan rutin serta aksi catat/edit/hapus |
| `ios/Sources/Features/Transactions/SplitBillsSheet.swift` | Form dan daftar Patungan/Split Bills |
| `ios/Sources/Features/Date/DateTabView.swift` | Budget Date, Wishlist Date, daftar transaksi kategori date, edit/hapus/undo |
| `ios/Sources/Features/Reports/ReportsView.swift` | Laporan kategori, tren, ringkasan, CSV, export report, ShareLink, WhatsApp, story card |
| `ios/Sources/Features/Settings/SettingsView.swift` | Root Settings, profil, routing submenu, Appearance, Notifications, Category, Data, backup/restore/reset dan model backup |
| `ios/Sources/Features/Settings/SettingsFeatureSheets.swift` | Sheet Appearance, Notifications, pengingat, menu kategori, Cicilan dan fitur pengaturan tambahan |
| `ios/Sources/Features/Settings/SettingsBudgetSheet.swift` | Batas pengeluaran per kategori |
| `ios/Sources/Features/Settings/SettingsCategoryManagerSheet.swift` | Kelola kategori |
| `ios/Sources/Models/MeowlettTransaction.swift` | Model transaksi Codable, formatter tanggal, definisi kategori dan pemetaan ikon |
| `ios/Sources/Services/FinanceStore.swift` | ObservableObject store transaksi, load/save JSON di Application Support, CRUD dan seed preview |
| `ios/Sources/Services/MeowlettReminderScheduler.swift` | Penjadwalan notifikasi pengingat |
| `ios/Sources/Services/RecurringTransactionAutomation.swift` | Pemrosesan item pengeluaran rutin saat app aktif |
| `ios/Sources/Theme/AppAppearance.swift` | Palette, preset, helper lighten/darken/luminance dan warna netral Light/Dark |
| `ios/Sources/Theme/MeowlettTypography.swift` | Registrasi dan pemilihan font Plus Jakarta Sans |
| `ios/Tests/MeowlettUITests.swift` | 10 XCUITest untuk splash, tab, Quick Add, Date Wishlist dan submenu Settings |

Resource non-Swift:
- `ios/Resources/Fonts/PlusJakartaSans-Regular.ttf`
- `ios/Resources/Fonts/PlusJakartaSans-Medium.ttf`
- `ios/Resources/Fonts/PlusJakartaSans-SemiBold.ttf`
- `ios/Resources/Fonts/PlusJakartaSans-Bold.ttf`
- `ios/Resources/Fonts/PlusJakartaSans-ExtraBold.ttf`
- `ios/Resources/Fonts/OFL.txt`
- `ios/Resources/Images/meow-avatar.jpg.b64`
- `ios/Scripts/GenerateAppIcon.sh`
- `public/meow.png` sebagai input pembuatan AppIcon dan image set splash

### 1.4 Pemetaan layar/modal referensi ke native

Sumber referensi resmi yang dipakai: `src/App.jsx`, `src/utils/theme.js`, `src/constants/index.js`, `src/constants/lang.js`, `src/utils/helpers.js`, `src/utils/notifications.js`, `src/utils/export.js`, dan `index.html`.

| Layar/modal referensi | Implementasi native | Status source |
|---|---|---|
| Splash | `NativeSplashView.swift`, `MeowlettApp.swift` | ADA |
| Onboarding 4 langkah | `OnboardingView.swift` | ADA |
| Header, FAB, 4 tab, Settings header | `MainTabView.swift` | ADA |
| Beranda/dashboard | `DashboardView.swift` | ADA |
| Edit pemasukan | Sheet di `DashboardView.swift` | ADA |
| Budget bulanan keseluruhan | Sheet di `DashboardView.swift` | ADA |
| Target tabungan/goal | `DashboardView.swift` | ADA |
| Transaksi (cari/filter/sort/grouping) | `TransactionsView.swift` | ADA |
| Tambah/Edit transaksi | `TransactionEditorSheet.swift` | ADA |
| Kalkulator nominal | `TransactionEditorSheet.swift` | ADA |
| Transaksi rutin + pemasukan rutin | `RecurringTransactionsSection.swift` | ADA |
| Cicilan | `SettingsFeatureSheets.swift` dan model cicilan di file yang sama | ADA; integrasi/alur keseluruhan BELUM TERVERIFIKASI |
| Patungan/Split Bills | `SplitBillsSheet.swift` | ADA |
| Laporan/tren/ringkasan | `ReportsView.swift` | ADA |
| Ekspor CSV | `ReportsView.swift` | ADA |
| Ekspor laporan | `ReportsView.swift` | ADA, tetapi saat ini output HTML, bukan PDF native |
| Bagikan/share sheet | `ReportsView.swift` | ADA |
| Story card | `ReportsView.swift` | ADA |
| Budget Date | `DateTabView.swift` | ADA |
| Wishlist Date | `DateTabView.swift` | ADA |
| Edit/hapus transaksi Date | `DateTabView.swift` + `TransactionEditorSheet.swift` | ADA |
| Settings root/profil | `SettingsView.swift` | ADA |
| Tampilan/tema | `SettingsView.swift` + `SettingsFeatureSheets.swift` | ADA |
| Notifikasi/pengingat transaksi | `SettingsView.swift` + `SettingsFeatureSheets.swift` + `MeowlettReminderScheduler.swift` | ADA; perilaku mingguan/teks jam belum sesuai |
| Batas pengeluaran kategori | `SettingsBudgetSheet.swift` | ADA |
| Kelola kategori | `SettingsCategoryManagerSheet.swift` | ADA |
| Backup/restore/reset | `SettingsView.swift` | ADA |
| Konfirmasi reset/restore | `SettingsView.swift` | ADA |
| Menu Tags dari file ekstraksi | TIDAK ADA | Sengaja tidak dijadikan scope: tidak terhubung di App.jsx |
| Modal Catatan Harian dari daftar ekstraksi | TIDAK ADA | Tidak ditemukan pemicu resmi di App.jsx |
| Theme Picker terpisah | TIDAK ADA sebagai modal terpisah | Preset warna tersedia di Appearance; jangan menambah modal terpisah tanpa callsite referensi |

**Peringatan sumber referensi:** `src/components/Tab*.jsx` dan `src/components/Modal*.jsx` adalah ekstraksi yang tidak diimpor oleh `src/App.jsx`; App.jsx mengimpor `AnimatedNumber` dan `DonutChart` sebagai komponen. Untuk perilaku, App.jsx menang. `ModalTags.jsx`/fitur `txTags` tidak boleh dijadikan dasar implementasi native.

---

## 2. Audit sumber referensi dan token

### 2.1 Tema dan kategori

`src/utils/theme.js` (`buildTheme`) diperiksa penuh. Token netral Light/Dark yang digunakan di native `AppAppearance.swift` cocok:
- Dark: `#0a0a0a`, `#141414`, `#1c1c1c`, `#272727`, `#1a1a1a`, `#303030`, teks `#fff/#9ca3af/#6b7280`, modal `#111111`.
- Light: `#f4f4f4`, `#fff`, `#f9f9f9`, `#e8e8e8`, input `#f4f4f4/#e0e0e0`, teks `#111/#6b7280/#9ca3af`, modal `#fff`.
- Preset green, blue, purple, rose, orange dan teal mempunyai pasangan primary/accent yang sama di `src/constants/index.js` dan `AppAppearance.swift`.
- Kategori default di `src/constants/index.js` memuat sembilan kategori sesuai key dan warna yang disampaikan di spesifikasi.

**Keputusan desain final pengguna (23 November 2026):** preset `custom` memakai nilai awal rose primary/accent `#881337 / #fb7185`. Nilai green dari constants lama tidak dipakai sebagai default native.

Native memakai `enum AppAppearance` dengan helper statis, bukan `struct MeowTheme` Equatable yang diinjeksi lewat environment. Perhitungan readable primary/accent sudah ada, tetapi arsitektur tema tunggal yang diminta belum ada.

### 2.2 Font dan ikon

- PWA memuat Plus Jakarta Sans 400/500/600/700/800/900 melalui CSS.
- Native membundel lima file Regular/Medium/SemiBold/Bold/ExtraBold dan mendaftarkan font via `CTFontManagerRegisterFontsForURL`.
- Tidak ditemukan file font weight 900 terpisah; mapping weight default/black native diarahkan ke ExtraBold.
- Splash native masih memakai `.system(...)` untuk judul/subjudul, bukan `MeowlettTypography`.
- Ikon tab native memakai custom Shape untuk kucing, garis Transaksi/Laporan dan hati Date. Ikon layar lainnya memakai SF Symbols; tidak ditemukan bundle set SVG lucide khusus.
- Keputusan implementasi saat ini: SF Symbols/custom Shape. Kesamaan stroke dan glyph terhadap Lucide belum dibandingkan screenshot per ikon.

### 2.3 Format dan tanggal PWA

`src/utils/helpers.js` diperiksa:
- `formatRp` menghasilkan `Rp\u00a0` + `toLocaleString("id-ID")`.
- `today()`, `getWeek()`, dan `dateLabel()` menggunakan `toISOString()` (UTC).
- `getWeek()` menghitung Senin sebagai awal minggu.
- PWA memformat string tanggal sebagai `yyyy-MM-dd`.

Native `MeowlettDateFormat` menggunakan DateFormatter `yyyy-MM-dd` dengan timezone lokal, dan layar transaksi/dashboard menggunakan `Calendar.current`. Minggu dimulai Senin di kalkulasi yang diperiksa. Clock injection dan test timezone deterministik belum ditemukan.

### 2.4 Backup, export, dan notifikasi referensi

- `src/utils/notifications.js` menjadwalkan reminder melalui timeout web dan mengecek transaksi ketika timeout fire.
- `src/utils/export.js` membuat CSV dan dokumen laporan HTML yang dinamai .html (bukan PDF native).
- Payload backup yang diminta: `version`, `exportedAt`, `transactions`, `income`, `goals`, `budgets`, `categories`, `dailyNotes`.

Native Data Settings memiliki model payload dengan field tersebut. Decoder transaksi menerima `id` string atau angka, tanggal string atau timestamp, dan default `paymentMethod = cash`. Native export memakai tanggal lokal `yyyy-MM-dd` dan ID string. Struktur ini tampak disiapkan untuk kompatibilitas, tetapi round-trip aktual terhadap file backup web **BELUM DIUJI**.

---

## 3. Tabel selisih UI/perilaku (temuan source dan bukti yang tersedia)

Format status:
- **SOURCE MATCH/PARTIAL**: ada implementasi yang mengarah ke spesifikasi.
- **GAP**: selisih dapat dibuktikan dari source.
- **BELUM DIVERIFIKASI**: butuh simulator/screenshot atau tes interaksi.

| ID | Layar/area | Referensi/spesifikasi | Native saat audit | Bukti dan status |
|---|---|---|---|---|
| UI-01 | Tema netral | Token Light/Dark persis | Nilai neutral palette di AppAppearance sama dengan buildTheme | SOURCE MATCH; visual per komponen BELUM DIVERIFIKASI |
| UI-02 | Arsitektur tema | Satu MeowTheme diinjeksi environment | AppAppearance static helpers + AppStorage; belum ada MeowTheme | GAP |
| UI-03 | Font | Plus Jakarta Sans 400–900 di seluruh UI | 5 file hingga ExtraBold; splash masih system font | GAP/PARTIAL |
| UI-04 | Custom preset | Spesifikasi prompt menyebut default rose | PWA constants menyebut green; native default rose | KONFLIK SUMBER; keputusan diperlukan |
| UI-05 | Splash | Tampilan sama dengan LaunchScreen statis, progress 2,7 dtk, fade 0,4 dtk | SwiftUI splash memiliki logo 72x72, bar 160x4, animasi 2,7 dtk dan root fade 0,4 dtk; LaunchScreen hanya generated | PARTIAL; flicker awal belum diuji |
| UI-06 | Onboarding | 4 langkah, ID/EN, nama, income, tema | Ada 4 langkah pada OnboardingView | SOURCE MATCH; alur lengkap belum diuji |
| UI-07 | Navigasi | 4 tab + FAB + Settings header + swipe tab | Custom nav, FAB, header Settings, avatar, active state; tidak ditemukan handler DragGesture untuk swipe-tab di MainTabView | PARTIAL/GAP untuk swipe |
| UI-08 | Modal | Semua modal blur + dim konsisten dan nonaktifkan konten belakang | ModalBlurCoordinator memicu blur root 8pt; sheet/alert/overlay lokal bervariasi; tidak ada overlay dim/API modal seragam yang dipakai semua modal | GAP |
| UI-09 | Quick Add | Modal fokus di atas backdrop blur | TransactionEditorSheet memakai .sheet; root blur terhubung melalui showQuickAdd. Run #251 memperlihatkan backdrop Quick Add blur pada Light dan Dark | PARTIAL; bukti lama, bukan HEAD |
| UI-10 | Beranda/saldo | Sisa mempertimbangkan kewajiban cicilan bulan berjalan | `remaining = income - spent - totalCicilanMonthly`; total mengambil nominal monthly dari semua item cicilan dan tidak memfilter paidMonths saat menghitung | GAP/keputusan T4 belum final |
| UI-11 | Beranda/fitur | Streak, sparkline, health, prediksi, budget, goal, transaksi terbaru, donut, metode bayar | Struktur/source untuk komponen tersebut ada di DashboardView | SOURCE MATCH; seluruh angka/UI belum diuji manual |
| UI-12 | Transaksi | Search, period, sort, payment filter, grouping, edit/delete/undo | Komponen search/period/sort/payment/grouping dan editor/undo ada di TransactionsView | SOURCE MATCH; tes interaksi lengkap BELUM |
| UI-13 | Transaksi/swipe | Swipe-to-delete tidak wajib di referensi; card detail edit/delete wajib | Native card action tersedia; tidak ditemukan `.swipeActions` pada TransactionsView | PARTIAL; pertahankan Edit/Hapus lewat card |
| UI-14 | Struk edit | Struk mengikuti id transaksi yang benar | Receipt disimpan/dimuat memakai `transaction.id.uuidString` dan ID yang sama saat save | SOURCE MATCH (T3 sudah ditangani pada model native) |
| UI-15 | Laporan | Ekspor laporan PDF native | ReportsView mengatur content type .html dan data reportHTML untuk tombol Export report | GAP; butuh PDF native |
| UI-16 | Date edit | Seluruh field transaksi, termasuk metode bayar/note, dibawa ke edit | DateTabView mengirim seluruh object transaction ke TransactionEditorSheet; constructor editor mengisi lokasi, note, paymentMethod dan struk | SOURCE MATCH (T10) |
| UI-17 | Notifikasi | Reminder sesuai jam terpilih; weekly summary terjadwal | Label/status UI dan confirmation text masih hardcode jam 9 malam; scheduler memakai hour terpilih untuk trigger harian satu kali per tanggal | GAP (T7) |
| UI-18 | Weekly summary | Toggle/hari harus benar-benar menjadwalkan notifikasi | Settings menyimpan weekly toggle/hari; tidak ditemukan pemanggilan scheduler mingguan atau UNCalendarNotificationTrigger untuk summary | GAP (T6) |
| UI-19 | Rutin | AutoApply mencakup pengeluaran dan pemasukan, saat launch/foreground | Automation membaca `gm_recurring` pengeluaran saja; pemasukan rutin hanya aksi manual Catat | GAP (T6) |
| UI-20 | Backup | Dua arah kompatibel web/native | Bentuk payload dan decoder menangani ID angka/string serta tanggal string/timestamp | PARTIAL; round-trip belum dicoba dengan file nyata |
| UI-21 | Bahasa | Satu dictionary/String Catalog | LANG tersedia pada PWA; native memakai banyak string inline ID/EN dalam view dan AppStorage `gm_lang` | GAP arsitektur; bahasa tersedia di banyak view |
| UI-22 | Tanggal/zona waktu | Calendar lokal dan test WIB/UTC deterministik | Model formatter lokal dan Calendar.current dipakai; launch arg fixed-date/clock injection belum ada | PARTIAL; S12 belum dites |
| UI-23 | Kategori/popup | Semua modal/settings sheet konsisten | Settings submenus ada, tetapi sejumlah sheet punya blur local berbeda dan sheet navigation tertunda 0,4 dtk | PARTIAL; perlu tes per modal |

### 3.1 Bukti screenshot yang tersedia

**Run #251 — [workflow](https://github.com/algeeeeeeeeee/mwlt/actions/runs/45021868794), SHA `3d69e437e10b69bf82feb3d6720d204bd4f4605a`.**
Artifact `Meowlett-Native-Preview-Light-Dark` (artifact id `14755295040`) berisi satu gambar gabungan yang dapat diperiksa. Pasangan Light/Dark yang terlihat: Dashboard, Transactions, Reports, Date, Settings, Quick Add. Quick Add menunjukkan latar belakang blur. Gambar ini adalah bukti visual historis untuk SHA tersebut saja, bukan untuk HEAD `f03ed90b2fa2ac4fd50124787f9b15bb992bca5e`, dan tidak mencakup semua modal.

**Run #262 — [workflow](https://github.com/algeeeeeeeeee/mwlt/actions/runs/45035794180), SHA `e6da3d9781ea807de7925481c158c5591bbcae5b`.**
Build simulator, 10 UI test, dan device build lulus. Tahap preview gagal karena `light-01-splash.png` berisi teks Dashboard (OCR log), bukan splash. Workflow berhenti pada validasi; tidak ada artifact preview dari run ini.

**Run #264 — [workflow](https://github.com/algeeeeeeeeee/mwlt/actions/runs/45037226035), SHA `8c4dddcfd4ae1f7954003acd084cc1fc0e6ca306`.**
Ketiga attempt diuji pada SHA yang sama. Tidak ada screenshot/xcresult artifact yang tersimpan pada run tersebut.

---

## 4. Daftar fitur mati, perilaku belum terhubung, dan hal yang jangan diport

### 4.1 Kesenjangan yang dapat dibuktikan

1. **AutoApply pemasukan rutin belum berjalan.** `RecurringTransactionAutomation.processDueItems` hanya membaca `gm_recurring`; `gm_recurring_income` tidak diproses otomatis. Form dan tombol Catat manual untuk pemasukan ada.
2. **Weekly Summary hanya menyimpan preferensi.** UI menyimpan toggle dan hari, tetapi scheduler yang dibaca hanya mengatur reminder harian.
3. **Copy jam notifikasi salah.** Status row dan notifikasi konfirmasi masih menyebut pukul 21.00/9 malam, walaupun scheduler memakai `hour` pilihan pengguna.
4. **Export Report native masih HTML.** Tombol laporan mengekspor `reportHTML` dengan `UTType.html`; belum PDF native.
5. **Swipe antar-tab horizontal belum ditemukan** pada MainTabView.
6. **Belum ada launch args lengkap untuk reset, skip onboarding/splash, appearance, locale, fixed-date** seperti yang disyaratkan di prompt. Yang ditemukan antara lain `--mwlt-preview-mode`, `--mwlt-preview-tab=`, `--mwlt-preview-splash`, `--mwlt-test-splash`, `--mwlt-preview-quick-add`, `--mwlt-preview-seed-data`.
7. **Tes UI belum mencakup matriks semua modal Light/Dark**, S1–S14, locale dan timezone.

### 4.2 Bukan acuan / jangan implementasikan

- `src/components/Tab*.jsx` dan `Modal*.jsx` yang tidak diimpor oleh App.jsx.
- `ModalTags.jsx`/txTags yang tidak terhubung.
- Modal Catatan Harian yang tidak ditemukan pemicunya di App.jsx.
- Theme Picker terpisah yang tidak dipanggil. Pengaturan preset yang benar-benar ada ada di Appearance.
- Jangan menyimpulkan tombol lain mati hanya karena belum diuji; interaksi tombol satu per satu **BELUM DIPERIKSA** di simulator.

### 4.3 T4 — saldo dan cicilan (keputusan final pengguna, 23 November 2026)

`Sisa` = pemasukan − pengeluaran bulan ini − cicilan bulan berjalan yang belum ditandai lunas. Cicilan bulan berjalan dianggap belum lunas bila `paidMonths` tidak memuat kunci bulan lokal berjalan. UI harus memberi label jelas. Tes wajib mencakup cicilan bulan berjalan yang sudah lunas (tidak mengurangi Sisa) dan yang belum lunas (mengurangi Sisa).

### 4.4 T8/T9

- Bug operator-precedence pada border tombol Hapus versi PWA tidak otomatis relevan di Swift. Di `SettingsBudgetSheet.swift` tidak ditemukan tombol Hapus dengan ekspresi string-border JavaScript yang sama; tidak ada perubahan diperlukan hanya untuk meniru bug PWA.
- Tags, Catatan Harian dan Theme Picker terpisah tidak menjadi scope tanpa callsite resmi.

---

## 5. Audit CI — Run #264

### 5.1 Identitas run dan environment

- Run #264: `45037226035`, workflow `Meowlett Native iOS Build`, SHA `8c4dddcfd4ae1f7954003acd084cc1fc0e6ca306`.
- Attempt 1 job: `137253648395`.
- Attempt 2 job: `137258634862`.
- Attempt 3 job: `137265921349`.
- Ketiga attempt memakai runner image `macos-15-arm64 20261118.0550.1`, macOS 15.8.2, Xcode 16.4 (16F6), SDK iOS 18.5, destination iPhone 16 / simulator OS yang dilaporkan 26.2.
- Run #251 (success terakhir seluruh workflow) memakai image/Xcode/destination yang sama. Perbedaan versi runner/Xcode/simulator **tidak tampak** antara run success tersebut dan #264.

### 5.2 Hasil tiga attempt SHA yang sama

| Attempt | Hasil xcodebuild test | Test case yang gagal | Assertion/log utama | Durasi test case |
|---|---:|---|---|---:|
| 1 | 10 test, 6 assertion failures | `testSettingsMainSubmenusAndNestedCategoryFlowsOpenAndDismiss`; `testSettingsResetRequiresConfirmationAndCanBeCancelled` | `MeowlettUITests.swift:139` screen Settings tidak muncul; `:143` Missing Settings row `mwlt.settings.appearance`; `:144` no matching button. Reset gagal menemukan `mwlt.settings.data` pada `:33, :36, :37`. | 31.912s; 30.529s |
| 2 | 10 test, 8 assertion failures | `testQuickAddSavesTransactionAndShowsItInTransactionsList`; `testSettingsResetRequiresConfirmationAndCanBeCancelled` | `:280` “Quick Add should present the transaction editor”; `:288–292` field/amount tidak ditemukan. Reset kembali kehilangan row Data pada `:33, :36, :37`. | 48.033s; 28.152s |
| 3 | 10 test, 6 assertion failures | `testSettingsNotificationsShowSystemPermissionStatus`; `testSettingsRestoreActionRequestsImport` | Notifications tidak menemukan layar/row `mwlt.settings.notifications` pada `:118, :121, :122`. Restore tidak menemukan screen/row Data pada `:33, :36, :37`. | 40.479s; 28.136s |

Test lain pada tiap attempt lulus; test case yang sama ada yang lulus dan gagal di attempt berbeda. Jadi hasil antar-attempt **campuran**, tetapi seluruh attempt tetap gagal. Ringkasan test duration: attempt 1 = 328.812s; attempt 2 = 328.550s; attempt 3 = 359.632s.

### 5.3 Bukti mekanisme interaksi

Log xctest berulang mencatat kegagalan:
- `kAXErrorCannotComplete performing AXAction kAXScrollToVisibleAction` pada tombol fixed header `mwlt.header.settings` (frame sekitar `{298,73,34,34}`).
- Pada attempt 3, error sejenis juga tercatat saat XCTest meminta scroll-to-visible untuk tombol FAB `mwlt.quickAdd` (frame sekitar `{25.7,739,54,54}`).
- Setelah kegagalan aksesibilitas itu, accessibility hierarchy yang dicetak tetap memperlihatkan Dashboard (misalnya tombol Settings header, Camera, dan Lihat Semua), bukan row Settings yang diminta tes.

Ini mendukung hipotesis H5 bahwa automatic accessibility scrolling/hit-testing pada control yang fixed/overlay berkontribusi. Namun log saja belum membuktikan apakah penyebab final berada di test automation, hit target/layout aplikasi, atau kombinasi keduanya.

### 5.4 Perbandingan commit dan workflow

- Run #251 SHA `3d69e437e10b69bf82feb3d6720d204bd4f4605a`: 10 UI test, 0 failure; device build, preview validation, dan upload preview/IPA sukses.
- Run #262 SHA `e6da3d9781ea807de7925481c158c5591bbcae5b`: 10 UI test, 0 failure; run keseluruhan gagal di preview validation karena screenshot splash Light menangkap Dashboard. Log OCR: `light-01-splash.png does not contain its expected screen title/content`; teks yang terdeteksi justru Dashboard.
- Run #264 SHA `8c4dddc...`: test gagal seperti tabel di atas.
- Perbandingan Run #251 → SHA Run #264 menunjukkan 13 commit tambahan dan perubahan pada workflow, app root/splash, MainTabView, Settings, project build, test dan script app icon. Runner/Xcode tidak berubah.
- Sesudah #264, HEAD bergerak ke `f03ed90b2fa2ac4fd50124787f9b15bb992bca5e` melalui commit `Stabilize native modal presentation and header hit targets`. Diff commit tersebut hanya mengubah `MainTabView.swift` (+11/-4) dan `MeowlettUITests.swift` (+19/-4): sheet Quick Add dipindahkan dari host Dashboard ke persistent dock, hit target Settings dibuat 44pt, dan test helper menggunakan coordinate tap.
- Run #265 pada SHA `f03ed90b2fa2ac4fd50124787f9b15bb992bca5e` dibatalkan saat UI test berjalan; test step berakhir `cancelled`. Karena itu patch tersebut **belum diuji** pada SHA HEAD.

### 5.5 Hipotesis H1–H7

| Hipotesis | Hasil pemeriksaan | Kesimpulan untuk Run #264 |
|---|---|---|
| H1 Splash/onboarding tidak ditunggu | Tes normal memakai `--mwlt-preview-mode` untuk bypass onboarding. Splash tetap ada, tetapi main controls disembunyikan dari accessibility sampai splash selesai; tes menunggu tab tersedia. | Tidak ada bukti splash/onboarding menyebabkan kegagalan yang tercatat. BELUM TERBUKTI sebagai penyebab. |
| H2 Locale angka/tanggal | Tes gagal pada navigasi Settings/Quick Add, bukan assertion string angka/tanggal. Tidak ada tes locale id_ID/en_US di suite sekarang. | Tidak menjelaskan error Run #264 yang terlihat. |
| H3 Appearance Light/Dark | Suite tidak menjalankan matriks appearance Light dan Dark atau launch arg appearance. | Coverage kurang; tidak ada bukti sebagai penyebab Run #264. |
| H4 Timezone UTC/WIB | PWA `today()` memang memakai UTC. Native memakai Calendar/DateFormatter lokal; belum ada fixed-date/timezone injection. Test Run #264 yang gagal tidak menguji tanggal. | Gap coverage; tidak menjelaskan navigasi gagal yang tercatat. |
| H5 Accessibility/overlay/animasi/hit target | `kAXErrorCannotComplete` berulang saat XCTest melakukan `ScrollToVisible` pada header/FAB fixed overlay. Patch HEAD memperbesar hit target dan memakai coordinate tap. | Dukungan bukti paling kuat, tetapi belum cukup untuk memvonis akar masalah final sampai patch HEAD lulus tes berulang. |
| H6 Persistensi antar tes | FinanceStore menyimpan transaksi ke Application Support; settings menggunakan UserDefaults. Tidak ditemukan launch arg reset state di suite. | State isolation memang kurang; belum ada bukti itulah penyebab row Settings hilang. |
| H7 Versi Xcode/simulator | Run #251, #262, dan #264 memakai runner image, macOS, Xcode, SDK dan destination yang sama. Tidak ada local simulator di sesi audit Linux. | Tidak ada indikasi perubahan environment antara success baseline dan failure. Reproduksi lokal BELUM DILAKUKAN. |

### 5.6 Kesimpulan wajib: PENYEBAB → KLASIFIKASI → PERBAIKAN

**PENYEBAB:** BELUM TERBUKTI secara final. Bukti paling kuat adalah automatic accessibility scroll gagal pada tombol fixed/overlay (error `kAXErrorCannotComplete`) dan accessibility hierarchy tetap di Dashboard. Tes yang sama berganti lulus/gagal pada attempt SHA sama. Patch setelah Run #264 mengatasi area tersebut dengan coordinate tap/hit target 44pt; patch belum pernah dites karena Run #265 dibatalkan. Quick Add juga punya kandidat isu competing sheet presenter; sheet-nya dipindahkan di HEAD, tetapi perubahan belum diuji.

**KLASIFIKASI:** indikasi kombinasi **test automation/accessibility interaction** dan potensi **hit-testing/presentation host aplikasi**. Belum boleh diklaim “flaky murni”, “bug app murni”, atau “konfigurasi CI” tanpa hasil run pada HEAD terbaru dan bukti screenshot/xcresult.

**PERBAIKAN yang diusulkan:**
1. Jalankan tes pada SHA HEAD `f03ed90b2fa2ac4fd50124787f9b15bb992bca5e` tanpa mengubah assertion: verifikasi coordinate tap + hit-target 44pt benar-benar membuka Settings pada CI.
2. Verifikasi Quick Add dari dock setelah pemindahan sheet presenter; periksa layar editor dan field yang tampil, bukan hanya build.
3. Pada run berikut, simpan `.xcresult` dan screenshot/attachment test pada `if: always()` agar kegagalan berikutnya punya hierarchy/screenshot, bukan hanya log.
4. Tambahkan isolation launch arg `-uitest-reset` dan uji agar data tidak bocor antartest; jangan mengganti atau menghapus assertion yang ada.
5. Jalankan test case yang terdampak berulang pada SHA yang sama dan kemudian ≥5 run sukses pada SHA berbeda untuk K6. Jangan tandai selesai sebelum bukti tersedia.

---

## 6. PERTAHANKAN dan PERBAIKI

### PERTAHANKAN (source/bukti tersedia)

- Struktur aplikasi SwiftUI native; jangan diganti WebView.
- Implementasi layar utama yang sudah ada: Dashboard, Transactions, Reports, Date dan Settings.
- Neutral palette Light/Dark di AppAppearance yang sesuai theme.js.
- Bundled font Plus Jakarta Sans; pertahankan resource dan registrasi, lalu lengkapi pemetaan bobot.
- Bottom navigation custom, cat-shaped Dashboard icon, heart Date icon, FAB dan header Settings.
- TransactionEditorSheet sebagai satu editor tambah/edit; modelnya membawa date, category, location, note, paymentMethod dan receipt.
- Receipt disimpan berdasarkan UUID transaksi sebenarnya.
- FinanceStore Codable JSON transaction persistence dan fungsi CRUD; lakukan migrasi hati-hati.
- Date formatter lokal `yyyy-MM-dd`; jangan mundur ke UTC `toISOString()`.
- Backup JSON yang sudah memakai field utama web dan decoder ID numerik/string.
- Tes XCUITest yang ada; jangan hapus atau melonggarkan assertion untuk membuat CI hijau.

### PERBAIKI (urutan prioritas)

1. **P0:** jalankan/diagnosis patch HEAD pada CI, buktikan navigasi fixed control dan Quick Add; simpan xcresult saat failure; isolation test state.
2. **P1:** MeowTheme satu sumber; putuskan konflik preset custom; font mapping/weight dan splash typography; launch screen statis; kamus ID/EN tunggal; modal blur+dim seragam untuk semua modal.
3. **P2:** definisi T4 cicilan yang dibayar/belum dibayar; test perhitungan dashboard; cari/filter/sort/edit/delete/undo dengan identifier.
4. **P3:** autoApply pemasukan rutin, scheduler weekly summary, jadwal reminder dinamis dan teks jam sesuai; verifikasi deep link/pengingat; export laporan PDF native; round-trip backup PWA/native.
5. **P4:** screenshot Light/Dark per modal/layar dari HEAD, perbandingan visual PWA 390×844, haptic/animasi/aksesibilitas, ukuran iPhone SE dan besar.

---

## 7. Checklist K1–K9 saat audit

| Kriteria | Status | Alasan |
|---|---|---|
| K1 Tidak ada WebView/HTML bundle | **VERIFIED** | Git tree + seluruh 23 file Swift target iOS dan `ios/project.yml` diperiksa. Tidak ditemukan WKWebView, import WebKit, SFSafariViewController, HTML loader, atau asset .html/.htm/.js/.css di bawah ios. UTType.html hanya dipakai untuk ekspor dokumen laporan. |
| K2 Semua layar/modal dan 0 tombol tanpa aksi | **BELUM TERVERIFIKASI** | Source screens terpetakan; belum ada uji klik seluruh tombol/menu. |
| K3 Semua modal blur | **BELUM TERVERIFIKASI** | Blur coordinator ada; satu bukti Quick Add lama saja, belum tiap modal Light/Dark. |
| K4 Token/radius/font cocok | **PARTIAL** | Neutral palette cocok; arsitektur MeowTheme, system font splash, bobot 900, radius/ikon dan visual penuh belum tervalidasi; konflik preset custom belum diputuskan. |
| K5 S1–S11 Light & Dark | **BELUM TERVERIFIKASI** | CI test suite saat ini tidak menjalankan seluruh skenario dua appearance secara terpisah. |
| K6 5 run hijau pada SHA berbeda dan root cause #264 | **BELUM TERVERIFIKASI** | Run #264 3 attempt semua gagal; HEAD run #265 dibatalkan. |
| K7 Backup JSON dua arah | **PARTIAL** | Struktur dan decoder terlihat kompatibel; belum ada bukti impor-ekspor round-trip memakai file web nyata. |
| K8 S1–S14 tanpa crash dan timezone benar | **BELUM TERVERIFIKASI** | Belum ada test matrix tanggal/zona waktu, data besar dan semua alur. |
| K9 PREVIEW.png per layar otomatis dan di PR | **PARTIAL** | Run #251 punya gambar gabungan lama untuk 7 screen-state, bukan semua modal; belum dari HEAD dan belum disimpan di `docs/preview/PREVIEW.png`. |

---

## 8. Status pekerjaan dan batas audit

- **Tidak ada perubahan source aplikasi** dibuat selama Fase 0.
- Tidak ada test dihapus, di-skip atau assertion dilonggarkan.
- Tidak ada branch, file, workflow atau history dihapus.
- Tidak ada run baru yang sengaja dimulai dari audit ini.
- Tidak ada simulator lokal: environment saat ini Linux dan tidak memiliki `xcodebuild`/ `xcrun`.
- Tidak ada screenshot PWA dari viewport 390×844 yang bisa dibandingkan pixel-to-pixel dalam sesi ini.
- Screenshot Run #251 adalah bukti visual historis, bukan bukti keadaan HEAD terbaru.
- Semua item yang belum punya tes/screenshot diberi status **BELUM TERVERIFIKASI**, bukan “selesai”.

---

## 9. Addendum verifikasi lanjutan — 23 November 2026

### 9.1 Keputusan desain final

- T4: Sisa = pemasukan − pengeluaran bulan ini − cicilan bulan berjalan yang belum ditandai lunas. Periksa paidMonths terhadap kunci bulan lokal berjalan; beri label UI jelas; uji cicilan lunas dan belum lunas.
- Preset custom: default rose #881337 / #fb7185.
- Swipe-to-delete diizinkan sebagai tambahan, tetapi Edit/Hapus melalui kartu terbuka tetap wajib.
- Tags dan Catatan Harian tidak boleh dibuat kecuali sudah benar-benar ada di native; audit tidak menemukan implementasi native.

### 9.2 K1 — hasil pencarian penuh target iOS

Scan dilakukan pada Git tree branch native-swift-parity, isi seluruh 23 file Swift di ios/Sources + ios/Tests, ios/project.yml, serta path inventory ios/.

| Pola / pemeriksaan | Hasil |
|---|---|
| WKWebView | 0 hit di 23 file Swift |
| import WebKit | 0 hit di 23 file Swift |
| SFSafariViewController | 0 hit di 23 file Swift |
| HTML load/navigation APIs | 0 hit |
| Asset .html/.htm/.js/.css di bawah ios/ | 0 file |
| Source/resource target ios/project.yml | Sources, Resources/Assets.xcassets, Resources/Fonts, Resources/Images; test target Tests |
| UTType.html | Hanya ekspor laporan: ReportsView.swift:19, :570, :1134 |

index.html berada di root PWA, bukan target iOS; workflow menyebutnya hanya sebagai path trigger. Kesimpulan K1: VERIFIED untuk target native pada branch yang diperiksa.

### 9.3 Run #266, #267, #268, #269

- #266 (https://github.com/algeeeeeeeeee/mwlt/actions/runs/45047506498), SHA bb4442201a1e943321fbee17fa51a038f08d1e62: cancelled pada Build simulator; UI test dan langkah berikutnya skipped; tidak ada artifact. Log tepat: 2026-11-22T17:07:07.9199000Z ##[error]The operation was canceled.
- Pembatalan #266: #266 dibuat 17:05:59Z, #267 untuk PR #2 dibuat 17:06:54Z, dan #266 berakhir 17:07:16Z. Workflow memakai concurrency group dari github.ref dengan cancel-in-progress: true. Ini konsisten dengan #267 menggantikan #266; bukan diagnosis UI.
- #267 (https://github.com/algeeeeeeeeee/mwlt/actions/runs/45047595111), SHA f3266323ad66874df6d3e973a63acb0b9aab1d95: build simulator lulus; UI tests gagal; device build dan preview skipped. Total 10 UI tests, 10 assertion failures.
- Lulus: testDatePreviewLaunchStartsOnDateTab; testDateWishlistSheetCanBeOpened; testMainTabsQuickAddAndCalculatorPresentation; testNativeOpeningSplashAppearsAndDismisses.
- Gagal: testQuickAddSavesTransactionAndShowsItInTransactionsList — line 295 editor tidak muncul, kemudian assertions field 303–305 dan tap amount 307 gagal.
- Gagal: testSettingsBackupActionBuildsAndRequestsExport; testSettingsMainSubmenusAndNestedCategoryFlowsOpenAndDismiss; testSettingsNotificationsShowSystemPermissionStatus; testSettingsResetRequiresConfirmationAndCanBeCancelled; testSettingsRestoreActionRequestsImport. Kelima test gagal di tapSettingsHeader line 34: asynchronous wait 5 detik untuk predicate hittable == true pada mwlt.header.settings timeout.
- Tidak ada snapshot atau xcresult artifact dari #267. Predicate hittable timeout tercatat, namun overlay/elemen penutup spesifik tidak diketahui.
- #268 (https://github.com/algeeeeeeeeee/mwlt/actions/runs/45048770667), SHA 5961b24614eb77a3ef024da8402d00e0e7fdc03c: gagal langsung sebelum job dibuat (0 jobs) akibat YAML indentation pada step Build iPhone device. Sudah diperbaiki pada commit 86d8b3aab771ec078554218bfe6411cd5bfbba6e.
- #269 (https://github.com/algeeeeeeeeee/mwlt/actions/runs/45048943679), SHA 86d8b3aab771ec078554218bfe6411cd5bfbba6e: YAML terbaca dan job berjalan; pemeriksaan terakhir menunjukkan Build simulator in_progress sejak 17:21:08Z tanpa pembaruan status maupun artifact. Hasil keseluruhan BELUM TERVERIFIKASI.

### 9.4 Bukti kegagalan #264: accessibility/hit-testing/presentasi

- Saat kegagalan Settings, hierarchy XCTest masih menunjukkan Dashboard, mwlt.header.settings dan mwlt.quickAdd; row Settings yang dicari tidak muncul.
- Log mencatat kAXErrorCannotComplete saat XCTest meminta kAXScrollToVisibleAction pada tombol header fixed dengan frame {{298.0, 73.0}, {34.0, 34.0}}.
- Run #267 menambah bukti: tombol header tidak memenuhi hittable == true dalam 5 detik pada kelima test Settings.
- #264 tidak merekam isHittable dan tidak memiliki xcresult/screenshot. #267 juga tidak memiliki artifact diagnostik. Elemen spesifik yang menutupi tombol (overlay/modal/keyboard/animasi) BELUM TERBUKTI.
- Quick Add editor gagal muncul pada satu test di #264 dan #267; apakah FAB hittable atau presenter sheet tertutup overlay BELUM TERBUKTI.

### 9.5 H1–H7

| Hipotesis | Status | Bukti |
|---|---|---|
| H1 Splash/onboarding | TERBANTAH untuk kegagalan navigasi Settings #264/#267 | Tes memakai --mwlt-preview-mode dan hierarchy #264 sudah menampilkan kontrol main app. |
| H2 Locale angka/tanggal | TERBANTAH sebagai penyebab failure yang diamati | Assertions mencari accessibility identifier, bukan teks angka/tanggal. Matriks locale tetap belum ada. |
| H3 Appearance Light/Dark | BELUM TERBUKTI | #264/#267 tidak menjalankan matriks Light/Dark terpisah. |
| H4 Timezone UTC/WIB | TERBANTAH untuk perpindahan tab/presentasi Quick Add | Assertion gagal terkait navigasi Settings dan sheet Quick Add, bukan tanggal. Ketepatan timezone tetap belum diuji. |
| H5 Accessibility/overlay/animasi/hit target | TERBUKTI pada gejala AX/hittable; penyebab akhir BELUM TERBUKTI | #264 mencatat kAXErrorCannotComplete; #267 gagal predicate hittable pada Settings header. Tidak ada bukti overlay spesifik. |
| H6 Persistensi antar tes | BELUM TERBUKTI | Store/UserDefaults persisten dan reset test belum ada, tetapi tidak ada bukti state menyebabkan header tidak hittable. |
| H7 Versi Xcode/simulator | TERBANTAH sebagai perubahan environment | Run sukses #251 dan #264 memakai runner image/macOS/Xcode/SDK/destination yang sama. Reproduksi lokal belum dilakukan. |

### 9.6 PENYEBAB → KLASIFIKASI → PERBAIKAN

- PENYEBAB: gejala terbukti: fixed Settings header muncul di hierarchy namun tidak menjadi hittable pada #267; #264 juga mencatat AX ScrollToVisible gagal. Penyebab mengapa elemen tidak hittable (overlay, layout, hosting, atau test runner) BELUM TERBUKTI. Quick Add editor gagal muncul pada satu test, root cause sheet BELUM TERBUKTI.
- KLASIFIKASI: masalah interaksi accessibility/hit-testing pada kontrol fixed, kandidat isu layout SwiftUI atau koordinasi presenter. Belum cukup bukti menyebut bug aplikasi murni atau flaky CI murni.
- PERBAIKAN: helper lama mensyaratkan hittable == true terlebih dulu; #267 membuktikan predicate itu gagal, jadi coordinate fallback tidak berjalan. Commit 5961b246 menambahkan snapshot exists/hittable/enabled/frame, debugDescription, sheet/alert/keyboard saat failure dan upload .xcresult dengan if: always(). Run #269 memuat patch diagnostik namun hasil BELUM TERVERIFIKASI.

### 9.7 Status K1–K9

| Kriteria | Status |
|---|---|
| K1 — no WebView/HTML bundle pada target native | VERIFIED |
| K2 — semua tombol/layar/modal | BELUM TERVERIFIKASI |
| K3 — blur/dim seragam untuk semua modal | PARTIAL |
| K4 — tema/font/radius parity | PARTIAL |
| K5 — S1–S11 Light + Dark | BELUM TERVERIFIKASI |
| K6 — root cause P0 + 5 run hijau pada SHA berbeda | BELUM TERVERIFIKASI |
| K7 — backup web/native round-trip | PARTIAL |
| K8 — S1–S14, timezone, data stress, no crash | BELUM TERVERIFIKASI |
| K9 — PREVIEW.png per layar/modal dari SHA terbaru | BELUM TERVERIFIKASI |
