import { getMonth, getCatLabel } from "./helpers.js";

export function exportCSV(transactions, categories, lang = "id") {
  const getCategory = (key) => categories[key] || { label: key };
  const headers = ["Tanggal", "Keterangan", "Kategori", "Lokasi", "Jumlah"];
  const rows = transactions
    .sort((a, b) => b.date.localeCompare(a.date))
    .map(t => [
      t.date,
      `"${t.description}"`,
      getCatLabel(getCategory(t.category), lang),
      t.location || "",
      t.amount,
    ]);
  const csv = [headers, ...rows].map(r => r.join(",")).join("\n");
  const blob = new Blob([csv], { type: "text/csv;charset=utf-8;" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = `meowlett-${new Date().toISOString().slice(0, 7)}.csv`;
  a.click();
  URL.revokeObjectURL(url);
}

export function exportPDFReport(transactions, categories, month, income, lang = "id") {
  const getCategory = (key) => categories[key] || { label: key, color: "#94a3b8" };
  const monthTxns = transactions
    .filter(t => getMonth(t.date) === month)
    .sort((a, b) => b.date.localeCompare(a.date));
  const total = monthTxns.reduce((s, t) => s + t.amount, 0);
  const catMap = {};
  monthTxns.forEach(t => { catMap[t.category] = (catMap[t.category] || 0) + t.amount; });

  const rows = monthTxns.map(t => `
    <tr style="border-bottom:1px solid #e5e7eb">
      <td style="padding:8px 12px;font-size:13px">${t.date}</td>
      <td style="padding:8px 12px;font-size:13px">${t.description}</td>
      <td style="padding:8px 12px;font-size:13px">${getCatLabel(getCategory(t.category), lang)}</td>
      <td style="padding:8px 12px;font-size:13px;text-align:right;color:#ef4444;font-weight:700">Rp ${t.amount.toLocaleString("id-ID")}</td>
    </tr>`).join("");

  const catRows = Object.entries(catMap).sort((a, b) => b[1] - a[1]).map(([k, v]) => `
    <tr>
      <td style="padding:6px 12px;font-size:13px">${getCatLabel(getCategory(k), lang)}</td>
      <td style="padding:6px 12px;font-size:13px;text-align:right;font-weight:700">Rp ${v.toLocaleString("id-ID")}</td>
      <td style="padding:6px 12px;font-size:13px;text-align:right;color:#6b7280">${total > 0 ? Math.round(v / total * 100) : 0}%</td>
    </tr>`).join("");

  const sisa = income - total;
  const html = `<!DOCTYPE html><html><head><meta charset="UTF-8">
  <title>Laporan ${month}</title>
  <style>
    body{font-family:Arial,sans-serif;max-width:800px;margin:40px auto;color:#111}
    h1{color:#166534;font-size:24px}h2{color:#16a34a;font-size:16px;margin-top:24px}
    table{width:100%;border-collapse:collapse}
    th{background:#f0fdf4;padding:10px 12px;text-align:left;font-size:13px;color:#166534}
    .summary{background:#f0fdf4;border-radius:12px;padding:20px;margin:20px 0;display:flex;gap:40px}
    .sum-label{font-size:11px;color:#6b7280;font-weight:700;letter-spacing:1px}
    .sum-val{font-size:22px;font-weight:900;color:#166534}
  </style></head><body>
  <h1>Laporan Keuangan</h1>
  <p style="color:#6b7280">Periode: ${month} · Dibuat: ${new Date().toLocaleDateString("id-ID")}</p>
  <div class="summary">
    <div><div class="sum-label">PEMASUKAN</div><div class="sum-val">Rp ${income.toLocaleString("id-ID")}</div></div>
    <div><div class="sum-label">PENGELUARAN</div><div class="sum-val" style="color:#ef4444">Rp ${total.toLocaleString("id-ID")}</div></div>
    <div><div class="sum-label">SISA</div><div class="sum-val" style="color:${sisa >= 0 ? "#16a34a" : "#ef4444"}">Rp ${sisa.toLocaleString("id-ID")}</div></div>
  </div>
  <h2>Breakdown Kategori</h2>
  <table><tr><th>Kategori</th><th style="text-align:right">Jumlah</th><th style="text-align:right">%</th></tr>${catRows}</table>
  <h2>Detail Transaksi (${monthTxns.length} transaksi)</h2>
  <table><tr><th>Tanggal</th><th>Keterangan</th><th>Kategori</th><th style="text-align:right">Jumlah</th></tr>${rows}</table>
  </body></html>`;

  const blob = new Blob([html], { type: "text/html;charset=utf-8;" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = `laporan-${month}.html`;
  a.click();
  URL.revokeObjectURL(url);
}
