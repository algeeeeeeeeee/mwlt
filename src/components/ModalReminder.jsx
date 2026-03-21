import { AlarmClock, Bell, BellOff, BellRing, X } from "../icons.jsx";
import { haptic } from "../utils/helpers.js";
import { scheduleSmartReminder, sendLocalNotification, requestNotificationPermission } from "../utils/notifications.js";

export default function ModalReminder({ ctx }) {
  const {
    T, lang, L,
    themeAccent, themePrimary,
    notifEnabled, setNotifEnabled,
    reminderHour, setReminderHour,
    reminderDays, setReminderDays,
    reminderSmart, setReminderSmart,
    showReminderModal, setShowReminderModal,
    transactions,
    showToast,
  } = ctx;

  if (!showReminderModal) return null;

  const DAY_LABELS_ID = ["Min","Sen","Sel","Rab","Kam","Jum","Sab"];
  const DAY_LABELS_EN = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"];
  const dayLabels = lang === "en" ? DAY_LABELS_EN : DAY_LABELS_ID;

  function toggleDay(d) {
    setReminderDays(prev => prev.includes(d) ? prev.filter(x=>x!==d) : [...prev,d]);
  }

  async function toggleReminder() {
    if (notifEnabled) {
      setNotifEnabled(false);
      if (window._reminderTimeout) clearTimeout(window._reminderTimeout);
      showToast(L.reminderOff); haptic();
    } else {
      const perm = await requestNotificationPermission();
      if (perm !== "granted") { showToast("err:" + (lang==="en"?"Notification permission denied":"Izin notifikasi ditolak")); return; }
      setNotifEnabled(true);
      scheduleSmartReminder({ hour: reminderHour, minute: 0, days: reminderDays, smart: reminderSmart, lang, getTransactions: () => transactions });
      await sendLocalNotification("Meowlett", lang==="en" ? "Reminder activated! You'll be notified at the set time." : "Pengingat aktif! Kamu akan diingatkan sesuai jadwal.");
      showToast(L.reminderOn); haptic("success");
    }
  }

  function saveSettings() {
    if (notifEnabled) {
      scheduleSmartReminder({ hour: reminderHour, minute: 0, days: reminderDays, smart: reminderSmart, lang, getTransactions: () => transactions });
    }
    showToast("ok:" + (lang==="en"?"Settings saved":"Pengaturan disimpan"));
    setShowReminderModal(false);
  }

  const padTime = h => String(h).padStart(2,"0") + ":00";

  return (
    <div style={{ position:"fixed", inset:0, background:"rgba(0,0,0,0.55)", backdropFilter:"blur(6px)", WebkitBackdropFilter:"blur(6px)", zIndex:300, display:"flex", alignItems:"flex-end", justifyContent:"center" }}
      onClick={e => { if (e.target===e.currentTarget) setShowReminderModal(false); }}>
      <div style={{ background:T.modalBg, borderRadius:"24px 24px 0 0", width:"100%", maxWidth:420, maxHeight:"90dvh", display:"flex", flexDirection:"column", overflow:"hidden" }}>
        <div style={{ width:36, height:4, background:T.cardBorder, borderRadius:99, margin:"12px auto 0", flexShrink:0 }}/>

        <div style={{ display:"flex", alignItems:"center", justifyContent:"space-between", padding:"12px 20px 14px", borderBottom:`1px solid ${T.cardBorder}`, flexShrink:0 }}>
          <div style={{ display:"flex", alignItems:"center", gap:9 }}>
            <Bell size={18} color={themeAccent} strokeWidth={2}/>
            <p style={{ fontSize:16, fontWeight:900, color:T.text }}>{L.reminderTitle}</p>
          </div>
          <button onClick={()=>setShowReminderModal(false)} style={{ width:30, height:30, borderRadius:"50%", background:T.card2, border:"none", cursor:"pointer", display:"flex", alignItems:"center", justifyContent:"center" }}>
            <X size={14} color={T.textSub} strokeWidth={2}/>
          </button>
        </div>

        <div style={{ overflowY:"auto", flex:1 }}>
          {/* Hero */}
          <div style={{ margin:"14px 16px", padding:"16px", background:`linear-gradient(135deg,${themeAccent}18,${themePrimary}28)`, border:`1px solid ${themeAccent}25`, borderRadius:16, display:"flex", alignItems:"center", gap:14 }}>
            <div style={{ width:50, height:50, borderRadius:16, background:`linear-gradient(135deg,${themeAccent},${themePrimary})`, display:"flex", alignItems:"center", justifyContent:"center", flexShrink:0 }}>
              <BellRing size={22} color="white" strokeWidth={2}/>
            </div>
            <div>
              <p style={{ fontSize:14, fontWeight:800, color:T.text }}>{L.reminderTitle}</p>
              <p style={{ fontSize:12, color:T.textSub, marginTop:3, lineHeight:1.5 }}>{L.reminderDesc}</p>
            </div>
          </div>

          {/* Master toggle */}
          <div onClick={toggleReminder} style={{ display:"flex", alignItems:"center", justifyContent:"space-between", padding:"14px 20px", borderBottom:`1px solid ${T.cardBorder}`, cursor:"pointer" }}>
            <div style={{ display:"flex", alignItems:"center", gap:12 }}>
              <div style={{ width:38, height:38, borderRadius:12, background:T.card2, display:"flex", alignItems:"center", justifyContent:"center" }}>
                {notifEnabled ? <Bell size={18} color={themeAccent} strokeWidth={2}/> : <BellOff size={18} color={T.textSub} strokeWidth={2}/>}
              </div>
              <div>
                <p style={{ fontSize:14, fontWeight:700, color:T.text }}>{L.notifications}</p>
                <p style={{ fontSize:11, color:T.textSub, marginTop:1 }}>{notifEnabled ? L.notifActive : L.notifOff}</p>
              </div>
            </div>
            <div style={{ width:46, height:26, borderRadius:99, background: notifEnabled ? `linear-gradient(135deg,${themeAccent},${themePrimary})` : T.card2, border: notifEnabled ? "none" : `1.5px solid ${T.cardBorder}`, position:"relative", cursor:"pointer", transition:"background 0.2s", flexShrink:0 }}>
              <div style={{ position:"absolute", width:20, height:20, borderRadius:"50%", background:"white", top:3, left: notifEnabled ? "calc(100% - 23px)" : 3, transition:"left 0.2s cubic-bezier(0.34,1.1,0.64,1)", boxShadow:"0 2px 6px rgba(0,0,0,0.3)" }}/>
            </div>
          </div>

          {/* Time */}
          <div style={{ display:"flex", alignItems:"center", justifyContent:"space-between", padding:"14px 20px", borderBottom:`1px solid ${T.cardBorder}` }}>
            <div style={{ display:"flex", alignItems:"center", gap:12 }}>
              <div style={{ width:38, height:38, borderRadius:12, background:T.card2, display:"flex", alignItems:"center", justifyContent:"center" }}>
                <AlarmClock size={18} color={T.textSub} strokeWidth={2}/>
              </div>
              <div>
                <p style={{ fontSize:14, fontWeight:700, color:T.text }}>{L.reminderTime}</p>
                <p style={{ fontSize:11, color:T.textSub, marginTop:1 }}>{lang==="en"?"Notification sent at this time":"Notif dikirim jam ini"}</p>
              </div>
            </div>
            <select value={reminderHour} onChange={e=>setReminderHour(Number(e.target.value))}
              style={{ background:T.card2, border:`1.5px solid ${T.cardBorder}`, borderRadius:10, padding:"8px 12px", color:themeAccent, fontSize:16, fontWeight:900, cursor:"pointer", fontFamily:"inherit", outline:"none" }}>
              {[6,7,8,9,10,12,15,18,19,20,21,22].map(h => <option key={h} value={h}>{padTime(h)}</option>)}
            </select>
          </div>

          {/* Days */}
          <div style={{ padding:"14px 20px", borderBottom:`1px solid ${T.cardBorder}` }}>
            <p style={{ fontSize:12, fontWeight:700, color:T.textSub, marginBottom:10 }}>{L.reminderDays}</p>
            <div style={{ display:"flex", gap:6 }}>
              {[0,1,2,3,4,5,6].map(d => (
                <div key={d} onClick={()=>toggleDay(d)}
                  style={{ flex:1, height:38, borderRadius:10, display:"flex", alignItems:"center", justifyContent:"center", fontSize:11, fontWeight:800, cursor:"pointer", transition:"all 0.15s",
                    background: reminderDays.includes(d) ? themeAccent+"20" : T.card2,
                    border: reminderDays.includes(d) ? `1.5px solid ${themeAccent}50` : `1.5px solid ${T.cardBorder}`,
                    color: reminderDays.includes(d) ? themeAccent : T.textSub }}>
                  {dayLabels[d]}
                </div>
              ))}
            </div>
          </div>

          {/* Smart toggle */}
          <div onClick={()=>setReminderSmart(p=>!p)} style={{ display:"flex", alignItems:"center", justifyContent:"space-between", padding:"14px 20px", borderBottom:`1px solid ${T.cardBorder}`, cursor:"pointer" }}>
            <div style={{ display:"flex", alignItems:"center", gap:12 }}>
              <div style={{ width:38, height:38, borderRadius:12, background:T.card2, display:"flex", alignItems:"center", justifyContent:"center" }}>
                <BellRing size={18} color={T.textSub} strokeWidth={2}/>
              </div>
              <div>
                <p style={{ fontSize:14, fontWeight:700, color:T.text }}>{L.reminderSmart}</p>
                <p style={{ fontSize:11, color:T.textSub, marginTop:1 }}>{L.reminderSmartDesc}</p>
              </div>
            </div>
            <div style={{ width:46, height:26, borderRadius:99, background: reminderSmart ? `linear-gradient(135deg,${themeAccent},${themePrimary})` : T.card2, border: reminderSmart ? "none" : `1.5px solid ${T.cardBorder}`, position:"relative", cursor:"pointer", transition:"background 0.2s", flexShrink:0 }}>
              <div style={{ position:"absolute", width:20, height:20, borderRadius:"50%", background:"white", top:3, left: reminderSmart ? "calc(100% - 23px)" : 3, transition:"left 0.2s cubic-bezier(0.34,1.1,0.64,1)", boxShadow:"0 2px 6px rgba(0,0,0,0.3)" }}/>
            </div>
          </div>

          {/* Preview */}
          <div style={{ margin:"14px 16px" }}>
            <p style={{ fontSize:11, fontWeight:700, color:T.textSub, marginBottom:8, letterSpacing:0.5 }}>{L.reminderPreview.toUpperCase()}</p>
            <div style={{ background:T.card2, border:`1px solid ${T.cardBorder}`, borderRadius:16, padding:14 }}>
              <div style={{ display:"flex", alignItems:"center", gap:8, marginBottom:8 }}>
                <div style={{ width:28, height:28, borderRadius:8, background:`linear-gradient(135deg,${themeAccent},${themePrimary})`, display:"flex", alignItems:"center", justifyContent:"center", fontSize:14 }}>🐱</div>
                <p style={{ fontSize:11, fontWeight:700, color:T.textSub }}>Meowlett</p>
                <p style={{ fontSize:11, color:T.textMuted, marginLeft:"auto" }}>{padTime(reminderHour)}</p>
              </div>
              <p style={{ fontSize:13, fontWeight:800, color:T.text, marginBottom:3 }}>{L.reminderNotifTitle}</p>
              <p style={{ fontSize:12, color:T.textSub, lineHeight:1.4 }}>{L.reminderNotifBody}</p>
            </div>
          </div>

          <button onClick={saveSettings} style={{ display:"block", margin:"0 16px 24px", width:"calc(100% - 32px)", padding:"14px 0", borderRadius:14, background:`linear-gradient(135deg,${themeAccent},${themePrimary})`, border:"none", color:"white", fontSize:14, fontWeight:800, cursor:"pointer", fontFamily:"inherit" }}>
            {lang==="en"?"Save Settings":"Simpan Pengaturan"}
          </button>
        </div>
      </div>
    </div>
  );
}
