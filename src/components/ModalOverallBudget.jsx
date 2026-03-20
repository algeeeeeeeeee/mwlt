import { Save, Wallet, X } from "../icons.jsx";
import { formatRp, getMonth, haptic, parseRpInput } from "../utils/helpers.js";

export default function ModalOverallBudget({ ctx }) {
  const {
    T, dark, lang,
    themePrimary,
    overallBudget, setOverallBudget,
    tempOverallBudget, setTempOverallBudget,
    tempOverallBudgetDisplay, setTempOverallBudgetDisplay,
    setShowOverallBudgetModal,
    showToast, kbHeight,
    transactions,
  } = ctx;

  return (
          <div style={{ position:"fixed", inset:0, background:"rgba(0,0,0,0.6)", backdropFilter:"blur(6px)", WebkitBackdropFilter:"blur(6px)", zIndex:300, display:"flex", alignItems:"flex-end", justifyContent:"center", paddingBottom: kbHeight > 0 ? kbHeight : 0, transition:"padding-bottom 0.25s ease", boxSizing:"border-box" }}
            onClick={e => { if (e.target===e.currentTarget) setShowOverallBudgetModal(false); }}>
            <div className="modal-float" style={{ background:T.modalBg, borderRadius:"28px 28px 0 0", width:"100%", maxWidth:380, boxShadow: dark?"0 24px 80px rgba(0,0,0,0.8)":"0 24px 80px rgba(0,0,0,0.25)", overflowY:"auto", maxHeight:`calc(100svh - env(safe-area-inset-top) - 20px - ${kbHeight}px)` }}>

              {/* Colored header */}
              <div style={{ background:"linear-gradient(150deg,"+themePrimary+","+darken(themePrimary,0.3)+")", borderRadius:"28px 28px 0 0", padding:"20px 20px 22px", position:"relative", overflow:"hidden" }}>
                <div style={{ position:"absolute", right:-28, top:-28, width:110, height:110, borderRadius:"50%", background:"rgba(255,255,255,0.06)", pointerEvents:"none" }}/>
                <div style={{ position:"absolute", left:-20, bottom:-20, width:80, height:80, borderRadius:"50%", background:"rgba(255,255,255,0.04)", pointerEvents:"none" }}/>
                <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center", position:"relative" }}>
                  <div style={{ display:"flex", alignItems:"center", gap:10 }}>
                    <div style={{ width:36, height:36, borderRadius:12, background:"rgba(0,0,0,0.2)", display:"flex", alignItems:"center", justifyContent:"center" }}>
                      <Wallet size={18} color="white" strokeWidth={2}/>
                    </div>
                    <div>
                      <p style={{ fontSize:15, fontWeight:900, color:"white", marginBottom:1 }}>{lang==="en"?"Monthly Budget Limit":"Limit Budget Bulanan"}</p>
                      <p style={{ fontSize:11, color:"rgba(255,255,255,0.65)" }}>{lang==="en"?"Total spending cap per month":"Batas total pengeluaran per bulan"}</p>
                    </div>
                  </div>
                  <button onClick={() => setShowOverallBudgetModal(false)}
                    style={{ width:28, height:28, borderRadius:50, background:"rgba(0,0,0,0.2)", border:"none", display:"flex", alignItems:"center", justifyContent:"center", cursor:"pointer" }}>
                    <X size={13} color="white" strokeWidth={2.5}/>
                  </button>
                </div>
                {/* Current status chip */}
                {overallBudget > 0 && (
                  <div style={{ marginTop:14, background:"rgba(0,0,0,0.18)", borderRadius:12, padding:"10px 14px", border:"1px solid rgba(255,255,255,0.1)", position:"relative" }}>
                    <p style={{ fontSize:10, color:"rgba(255,255,255,0.5)", fontWeight:700, letterSpacing:1, marginBottom:3 }}>{(lang==="en"?"CURRENT LIMIT":"LIMIT SAAT INI")}</p>
                    <p style={{ fontSize:22, fontWeight:900, color:"white" }}>{formatRp(overallBudget)}</p>
                    {(()=>{
                      const spent = transactions.filter(t => getMonth(t.date)===currentMonth).reduce((a,t)=>a+t.amount,0);
                      const pct = Math.min(100, Math.round((spent/overallBudget)*100));
                      const over = spent > overallBudget;
                      return (
                        <div style={{ marginTop:8 }}>
                          <div style={{ height:4, borderRadius:99, background:"rgba(255,255,255,0.15)", overflow:"hidden" }}>
                            <div style={{ height:"100%", width:pct+"%", borderRadius:99, background: over?"#f87171":"rgba(255,255,255,0.8)", transition:"width 0.4s" }}/>
                          </div>
                          <p style={{ fontSize:11, color: over?"#fca5a5":"rgba(255,255,255,0.65)", marginTop:5, fontWeight:600 }}>
                            {formatRp(spent)} {lang==="en"?"spent":"terpakai"} · {over ? (lang==="en"?"Over budget!":"Melebihi limit!") : (lang==="en"?"remaining":"sisa")+" "+formatRp(overallBudget-spent)}
                          </p>
                        </div>
                      );
                    })()}
                  </div>
                )}
              </div>

              {/* Body */}
              <div style={{ padding:"20px 20px 24px" }}>
                <p style={{ fontSize:12, fontWeight:700, color:T.textSub, marginBottom:8 }}>{lang==="en"?"SET NEW LIMIT (Rp)":"SET LIMIT BARU (Rp)"}</p>
                <input
                  className="inp"
                  type="text"
                  inputMode="numeric"
                  autoFocus
                  placeholder={lang==="en"?"3.000.000":"3.000.000"}
                  value={tempOverallBudgetDisplay}
                  onChange={e => { const {display,raw}=parseRpInput(e.target.value); setTempOverallBudgetDisplay(display); setTempOverallBudget(raw); }}
                  onKeyDown={e => { if(e.key==="Enter" && tempOverallBudget > 0){ setOverallBudget(tempOverallBudget); setShowOverallBudgetModal(false); showToast(lang==="en"?"Budget limit saved!":"Limit budget disimpan!"); }}}
                  style={{ background:T.inp, border:"1.5px solid "+(dark?"rgba(255,255,255,0.1)":T.cardBorder), color:T.text, fontSize:18, fontWeight:700, marginBottom:12 }}
                />
                <div style={{ display:"flex", gap:8 }}>
                  {overallBudget > 0 && (
                    <button onClick={() => { setOverallBudget(0); setTempOverallBudget(0); setShowOverallBudgetModal(false); showToast(lang==="en"?"Budget limit removed":"Limit dihapus"); }}
                      style={{ flex:1, padding:"13px 0", borderRadius:14, background:dark?"rgba(239,68,68,0.15)":"#fef2f2", border:"1.5px solid "+dark?"rgba(239,68,68,0.3)":"#fecaca", color:"#f87171", fontSize:13, fontWeight:800, cursor:"pointer" }}>
                      {lang==="en"?"Remove":"Hapus"}
                    </button>
                  )}
                  <button onClick={() => { if(tempOverallBudget > 0){ setOverallBudget(tempOverallBudget); setShowOverallBudgetModal(false); showToast(lang==="en"?"Budget limit saved!":"Limit budget disimpan!"); haptic(); }}}
                    style={{ flex:2, padding:"13px 0", borderRadius:14, background: tempOverallBudget > 0 ? themePrimary : (dark?"rgba(255,255,255,0.08)":"#f3f4f6"), color: tempOverallBudget > 0 ? "white" : T.textSub, fontSize:13, fontWeight:800, cursor: tempOverallBudget > 0 ? "pointer":"default", border:"none", transition:"all 0.2s" }}>
                    {lang==="en"?"Save Limit":"Simpan Limit"}
                  </button>
                </div>
              </div>
            </div>
          </div>
  );
}
