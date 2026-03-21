# Meowlett 💸

Aplikasi manajemen keuangan pribadi — mobile-first PWA.

## Cara Pakai

```bash
# Install dependencies
npm install

# Development server (http://localhost:5173)
npm run dev

# Build untuk production
npm run build

# Preview hasil build
npm run preview
```

## Deploy ke Netlify

### Manual (drag & drop)
1. Jalankan `npm run build`
2. Drag folder `dist/` ke Netlify dashboard

### Auto-deploy (Git)
1. Push ke GitHub/GitLab
2. Connect repo di Netlify
3. Build command: `npm run build`
4. Publish directory: `dist`

## Fitur
- 📊 Dashboard dengan balance card, budget, & target tabungan
- 💸 Catat transaksi (tambah/edit/hapus)
- 📈 Laporan harian + budget per kategori
- 💝 Tab Date — wishlist & catat pengeluaran berdua
- 🎨 6 tema warna + custom color picker
- 🌙 Dark/light mode (+ ikuti sistem)
- 🌐 Bilingual ID/EN
- 💾 Data tersimpan otomatis (localStorage)
- 📱 Installable PWA (offline support)
