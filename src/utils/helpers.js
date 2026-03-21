export const formatRp = (n) => "Rp\u00a0" + Number(n || 0).toLocaleString("id-ID");

export const today = () => new Date().toISOString().split("T")[0];

export const getWeek = (d) => {
  const date = new Date(d);
  const day = date.getDay();
  const diff = date.getDate() - day + (day === 0 ? -6 : 1);
  const mon = new Date(date.setDate(diff));
  return mon.toISOString().split("T")[0];
};

export const getMonth = (d) => d.slice(0, 7);

export const fmtDate = (d, lang = "id") => {
  const dt = new Date(d + "T00:00:00");
  return dt.toLocaleDateString(lang === "en" ? "en-GB" : "id-ID", {
    weekday: "long", day: "numeric", month: "long", year: "numeric",
  });
};

export function groupByDate(txns) {
  const groups = {};
  txns.forEach(t => {
    if (!groups[t.date]) groups[t.date] = [];
    groups[t.date].push(t);
  });
  return Object.entries(groups).sort((a, b) => b[0].localeCompare(a[0]));
}

export function dateLabel(dateStr, lang = "id") {
  const todayStr = new Date().toISOString().split("T")[0];
  const yesterday = new Date(Date.now() - 86400000).toISOString().split("T")[0];
  if (dateStr === todayStr) return lang === "en" ? "Today" : "Hari ini";
  if (dateStr === yesterday) return lang === "en" ? "Yesterday" : "Kemarin";
  const d = new Date(dateStr);
  return d.toLocaleDateString(lang === "en" ? "en-GB" : "id-ID", {
    weekday: "long", day: "numeric", month: "long",
  });
}

export const getCatLabel = (cat, lang) => {
  if (!cat) return "";
  return lang === "id" ? (cat.labelId || cat.label) : cat.label;
};

export const haptic = (type = "light") => {
  try {
    if (!navigator.vibrate) return;
    if (type === "success") navigator.vibrate([40, 30, 80]);
    else if (type === "error") navigator.vibrate([80, 40, 80, 40, 80]);
    else if (type === "warning") navigator.vibrate([60, 30, 60]);
    else navigator.vibrate(50);
  } catch (e) {}
};

export const parseRpInput = (val) => {
  const raw = String(val).replace(/\./g, "").replace(/[^0-9]/g, "");
  const num = raw ? parseInt(raw, 10) : 0;
  const display = raw ? num.toLocaleString("id-ID") : "";
  return { display, raw: num };
};

export const rpInputProps = (displayVal, onChangeFn) => ({
  type: "text",
  inputMode: "numeric",
  value: displayVal,
  onChange: (e) => {
    const { display, raw } = parseRpInput(e.target.value);
    onChangeFn(display, raw);
  },
});
