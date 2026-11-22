# Meowlett IPA Release Candidate

> **Status: preview, bukan paritas UI; P0 terbuka.**

Workflow `.github/workflows/ios-ipa-rc.yml` menghasilkan IPA Release untuk perangkat iOS tanpa signing certificate atau provisioning profile dari CI. Workflow ini tidak menjalankan UI test dan tidak mengubah status PR #2 yang tetap Draft.

## Cara memicu

Dari commit yang sudah ada di branch `native-swift-parity`, buat dan push tag RC:

```sh
git tag rcN-preview <sha>
git push origin rcN-preview
```

Contoh untuk RC pertama:

```sh
git tag rc1-preview <sha>
git push origin rc1-preview
```

Alternatifnya, buka **Actions → Meowlett IPA Release Candidate → Run workflow** dan isi input `rc_label`.

Setelah job selesai, ambil artifact `Meowlett-IPA-RC-<run>`. Artifact disimpan selama 14 hari. Nama file memakai format `Meowlett-<label>-<short-sha>.ipa`.

## Instalasi IPA unsigned

IPA dari CI **belum ditandatangani** dan tidak bisa dipasang langsung dengan mengetuk file. Sideloadly atau AltStore menggunakan Apple ID untuk menandatangani ulang IPA pada proses sideload.

### Sideloadly

1. Unduh Sideloadly dari [situs resminya](https://sideloadly.io/), lalu buka di komputer.
2. Hubungkan iPhone ke komputer dengan kabel USB dan pilih perangkat yang terdeteksi.
3. Masukkan file IPA ke jendela Sideloadly, lalu lakukan sideload dengan Apple ID milik sendiri.
4. Pada iOS 16 atau lebih baru, Developer Mode mungkin perlu diaktifkan melalui **Settings → Privacy & Security → Developer Mode**. Setelah pemasangan pertama, bila muncul peringatan developer belum dipercaya, buka **Settings → General → VPN & Device Management** dan percayai profil yang sesuai.

Panduan resmi: [Sideloadly FAQ](https://sideloadly.io/faq.html).

### AltStore Classic

1. Pasang AltServer pada komputer mengikuti [panduan resmi AltServer](https://faq.altstore.io/altstore-classic/altserver).
2. Hubungkan iPhone melalui USB atau pastikan komputer dan iPhone berada pada jaringan Wi-Fi yang sama; gunakan AltServer untuk memasang AltStore pada iPhone.
3. Buka AltStore → **My Apps** → tombol **+**, lalu pilih file IPA yang sudah diunduh.
4. Biarkan AltServer tersedia agar AltStore dapat mencoba memperbarui tanda tangan aplikasi secara otomatis.

Panduan: [AltStore Classic](https://faq.altstore.io/altstore-classic/your-altstore).

## Batas masa berlaku Apple ID gratis

Aplikasi yang ditandatangani dengan Personal Team / Apple ID gratis memiliki provisioning profile yang berlaku **7 hari**; setelah kedaluwarsa aplikasi perlu ditandatangani dan dipasang ulang. Sideloadly dan AltStore juga mendokumentasikan batas 7 hari ini. Batas ini berasal dari ketentuan signing Apple, bukan dari workflow Meowlett.

Referensi:
- [Apple Developer — Developer account overview](https://developer.apple.com/help/account/basics/about-your-developer-account/)
- [Sideloadly — FAQ: sideloaded app validity](https://sideloadly.io/faq.html)
- [AltStore — Getting Started](https://faq.altstore.io/altstore-classic/your-altstore)

## Apa yang diverifikasi oleh workflow

Job akan gagal jika `Info.plist` tidak memuat `CFBundleIdentifier`, `CFBundleShortVersionString`, atau `CFBundleVersion`, atau jika salah satu binary Mach-O di dalam app bundle menautkan WebKit berdasarkan `otool -L`.

Keberadaan file font Plus Jakarta Sans, pendaftarannya di `UIAppFonts`, dan string argumen `-uitest-*` dalam executable Release hanya dilaporkan di job summary; ketiganya tidak menggagalkan build. Build Release juga tidak menjalankan UI test.
