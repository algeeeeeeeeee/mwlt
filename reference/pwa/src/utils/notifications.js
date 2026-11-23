export async function requestNotificationPermission() {
  if (!("Notification" in window)) return "unsupported";
  if ("serviceWorker" in navigator) {
    try {
      const reg = await navigator.serviceWorker.ready;
      if (reg) return await Notification.requestPermission();
    } catch {}
  }
  return await Notification.requestPermission();
}

export async function sendLocalNotification(title, body) {
  if (Notification.permission !== "granted") return;
  try {
    const reg = await navigator.serviceWorker.ready;
    await reg.showNotification(title, {
      body,
      icon: "/meow.png",
      badge: "/meow.png",
      tag: "daily-reminder",
      renotify: true,
    });
  } catch {
    try { new Notification(title, { body, icon: "/meow.png" }); } catch {}
  }
}

export function scheduleSmartReminder({ hour = 21, minute = 0, days = [1,2,3,4,5], smart = true, lang = "id", getTransactions = null }) {
  // Cancel existing
  if (window._reminderTimeout) clearTimeout(window._reminderTimeout);

  const fire = () => {
    // Smart: skip if already has transaction today
    if (smart && getTransactions) {
      const today = new Date().toISOString().split("T")[0];
      const txs = getTransactions();
      if (txs.some(t => t.date === today)) {
        scheduleSmartReminder({ hour, minute, days, smart, lang, getTransactions });
        return;
      }
    }
    // Check day of week
    const dayOfWeek = new Date().getDay(); // 0=Sun 1=Mon...
    if (!days.includes(dayOfWeek)) {
      scheduleSmartReminder({ hour, minute, days, smart, lang, getTransactions });
      return;
    }
    const title = "Meowlett";
    const body = lang === "en"
      ? "💸 Haven't logged expenses today! Don't forget to record your transactions 🐱"
      : "💸 Belum catat pengeluaran hari ini! Jangan lupa input transaksi 🐱";
    sendLocalNotification(title, body);
    scheduleSmartReminder({ hour, minute, days, smart, lang, getTransactions });
  };

  const now = new Date();
  const next = new Date();
  next.setHours(hour, minute, 0, 0);
  if (now >= next) next.setDate(next.getDate() + 1);
  window._reminderTimeout = setTimeout(fire, next - now);
}

// Legacy compat
export function scheduleLocalReminder() {
  scheduleSmartReminder({});
}
