import { BarChart2, Bell, BellOff, Sun, X } from "../icons.jsx";

export default function ModalNotif({ ctx }) {
  const {
    T, dark, lang, L,
    themeAccent, themePrimary,
    notifEnabled,
    weeklyNotif, setWeeklyNotif,
    weeklyNotifDay, setWeeklyNotifDay,
    setShowNotifModal,
    handleNotification,
  } = ctx;

  return (
          <div style={{ position:"fixed", inset:0, background:"rgba(0,0,0,0.55)", backdropFilter:"blur(4px)", WebkitBackdropFilter:"blur(4px)", zIndex:300, display:"flex", flexDirection:"column", justifyContent:"flex-end" }}
            onClick={e => { if(e.target===e.currentTarget) setShowNotifModal(false); }}>
            <div className="modal-up" style={{ background:T.card, borderRadius:"28px 28px 0 0", paddingBottom:"0px" }}>
              <div style={{ width:36, height:4, background:T.cardBorder, borderRadius:99, margin:"12px auto 0" }}/>
              <div style={{ display:"flex", alignItems:"center", justifyContent:"space-between", padding:"16px 20px 12px" }}>
                <div style={{ display:"flex", alignItems:"center", gap:10 }}>
                  <div style={{ width:36, height:36, borderRadius:12, background:T.catBg, display:"flex", alignItems:"center", justifyContent:"center" }}>
                    {notifEnabled ? <Bell size={18} color={themeAccent} strokeWidth={2}/> : <BellOff size={18} color={T.accentText} strokeWidth={2}/>}
                  </div>
                  <p style={{ fontSize:17, fontWeight:900, color:T.text }}>{lang==="en"?"Notifications":"Notifikasi"}</p>
                </div>
                <button onClick={() => setShowNotifModal(false)} style={{ background:T.catBg, border:"none", borderRadius:50, width:32, height:32, cursor:"pointer", display:"flex", alignItems:"center", justifyContent:"center" }}>
                  <X size={16} color={T.textSub} strokeWidth={2.5}/>
                </button>
              </div>
              <div style={{ padding:"0 20px 28px", display:"flex", flexDirection:"column", gap:0 }}>
                {/* Daily reminder toggle */}
                <div style={{ display:"flex", alignItems:"center", justifyContent:"space-between", padding:"14px 0", borderBottom:`1px solid ${T.cardBorder}` }}>
                  <div style={{ display:"flex", alignItems:"center", gap:12 }}>
                    <div style={{ width:36, height:36, borderRadius:12, background:T.catBg, display:"flex", alignItems:"center", justifyContent:"center" }}>
                      {notifEnabled ? <Bell size={18} color={T.inpFocus} strokeWidth={2}/> : <BellOff size={18} color={T.accentText} strokeWidth={2}/>}
                    </div>
                    <div>
                      <p style={{ fontSize:14, fontWeight:700, color:T.text }}>{L.dailyReminder}</p>
                      <p style={{ fontSize:11, color:T.textSub }}>{notifEnabled ? L.notifActive : L.notifOff}</p>
                    </div>
                  </div>
                  <div onClick={handleNotification} style={{ width:48, height:28, borderRadius:50, background: notifEnabled ? themePrimary : T.catBorder, cursor:"pointer", position:"relative", flexShrink:0 }}>
                    <div style={{ position:"absolute", top:4, left: notifEnabled ? 24 : 4, width:20, height:20, borderRadius:50, background:"white", boxShadow:"0 2px 6px rgba(0,0,0,0.2)" }}/>
                  </div>
                </div>
                {/* Weekly summary */}
                <div style={{ padding:"14px 0", borderBottom: weeklyNotif ? `1px solid ${T.cardBorder}` : "none" }}>
                  <div style={{ display:"flex", alignItems:"center", justifyContent:"space-between" }}>
                    <div style={{ display:"flex", alignItems:"center", gap:12 }}>
                      <div style={{ width:36, height:36, borderRadius:12, background:T.catBg, display:"flex", alignItems:"center", justifyContent:"center" }}>
                        <BarChart2 size={18} color={weeklyNotif ? T.inpFocus : T.textSub} strokeWidth={2}/>
                      </div>
                      <div>
                        <p style={{ fontSize:14, fontWeight:700, color:T.text }}>{lang==="en"?"Weekly Summary":"Ringkasan Mingguan"}</p>
                        <p style={{ fontSize:11, color:T.textSub }}>{weeklyNotif ? (lang==="en"?`Every ${["Sun","Mon","Tue","Wed","Thu","Fri","Sat"][weeklyNotifDay]}`:["Min","Sen","Sel","Rab","Kam","Jum","Sab"][weeklyNotifDay]+" tiap minggu") : (lang==="en"?"Off":"Nonaktif")}</p>
                      </div>
                    </div>
                    <div onClick={() => setWeeklyNotif(v => !v)} style={{ width:48, height:28, borderRadius:50, background: weeklyNotif ? themePrimary : T.catBorder, cursor:"pointer", position:"relative", flexShrink:0, transition:"background 0.2s" }}>
                      <div style={{ position:"absolute", top:4, left: weeklyNotif ? 24 : 4, width:20, height:20, borderRadius:50, background:"white", boxShadow:"0 2px 6px rgba(0,0,0,0.2)", transition:"left 0.2s" }}/>
                    </div>
                  </div>
                </div>
                {weeklyNotif && (
                  <div style={{ paddingTop:12, display:"flex", gap:6, flexWrap:"wrap" }}>
                    {(lang==="en"?["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]:["Min","Sen","Sel","Rab","Kam","Jum","Sab"]).map((d,i) => (
                      <button key={i} onClick={() => setWeeklyNotifDay(String(i))} style={{ padding:"6px 14px", borderRadius:50, border:"none", cursor:"pointer", fontSize:12, fontWeight:700, fontFamily:"inherit", transition:"all 0.18s",
                        background: weeklyNotifDay===String(i) ? themePrimary : T.btnG, color: weeklyNotifDay===String(i) ? "white" : T.textSub }}>
                        {d}
                      </button>
                    ))}
                  </div>
                )}
              </div>
            </div>
          </div>
  );
}
