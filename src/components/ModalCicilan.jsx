import React from "react";
import { CreditCard, Pencil, Plus, Trash2, X } from "../icons.jsx";
import { formatRp, haptic, parseRpInput } from "../utils/helpers.js";

function emptyForm() {
  return { name: "", total: "", totalDisplay: "", monthly: "", monthlyDisplay: "", dueDay: "5", startMonth: "", duration: "" };
}

export default function ModalCicilan({ ctx }) {
  const {
    T, dark, lang, L,
    themeAccent, themePrimary,
    cicilan, setCicilan,
    showCicilanModal, setShowCicilanModal,
    showToast,
  } = ctx;

  const [editId, setEditId] = React.useState(null);
  const [form, setForm] = React.useState(emptyForm());
  const [showForm, setShowForm] = React.useState(false);
  const [detail, setDetail] = React.useState(null);

  const currentMonth = new Date().toISOString().slice(0, 7);

  const totalMonthly = cicilan.reduce((s, c) => s + Number(c.monthly || 0), 0);

  function openAdd() { setEditId(null); setForm(emptyForm()); setShowForm(true); setDetail(null); }
  function openEdit(c) { setEditId(c.id); setForm({ ...c, totalDisplay: Number(c.total).toLocaleString("id-ID"), monthlyDisplay: Number(c.monthly).toLocaleString("id-ID") }); setShowForm(true); setDetail(null); }
  function openDetail(c) { setDetail(c); setShowForm(false); }

  function save() {
    if (!form.name || !form.monthly) return;
    const item = {
      id: editId || Date.now(),
      name: form.name,
      total: Number(String(form.total).replace(/\./g, "")),
      monthly: Number(String(form.monthly).replace(/\./g, "")),
      dueDay: form.dueDay || "5",
      startMonth: form.startMonth || currentMonth,
      duration: Number(form.duration) || 12,
      paidMonths: editId ? (cicilan.find(c => c.id === editId)?.paidMonths || []) : [],
    };
    if (editId) setCicilan(p => p.map(c => c.id === editId ? item : c));
    else setCicilan(p => [...p, item]);
    showToast(L.cicilanSaved);
    setShowForm(false); haptic("success");
  }

  function del(id) { setCicilan(p => p.filter(c => c.id !== id)); showToast(L.cicilanDeleted); setDetail(null); }

  function markPaid(c) {
    if (c.paidMonths?.includes(currentMonth)) { showToast("info:" + L.cicilanAlreadyPaid); return; }
    setCicilan(p => p.map(x => x.id === c.id ? { ...x, paidMonths: [...(x.paidMonths || []), currentMonth] } : x));
    showToast(L.cicilanPaidToast); haptic("success");
    setDetail(prev => prev ? { ...prev, paidMonths: [...(prev.paidMonths || []), currentMonth] } : prev);
  }

  function getPaidCount(c) { return (c.paidMonths || []).length; }
  function getProgress(c) { return c.duration ? Math.round(getPaidCount(c) / c.duration * 100) : 0; }
  function isPaidThisMonth(c) { return (c.paidMonths || []).includes(currentMonth); }

  if (!showCicilanModal) return null;

  return (
    <div style={{ position:"fixed", inset:0, background:"rgba(0,0,0,0.55)", backdropFilter:"blur(6px)", WebkitBackdropFilter:"blur(6px)", zIndex:300, display:"flex", alignItems:"flex-end", justifyContent:"center" }}
      onClick={e => { if (e.target===e.currentTarget) setShowCicilanModal(false); }}>
      <div style={{ background:T.modalBg, borderRadius:"24px 24px 0 0", width:"100%", maxWidth:420, maxHeight:"90dvh", display:"flex", flexDirection:"column", overflow:"hidden" }}>
        <div style={{ width:36, height:4, background:T.cardBorder, borderRadius:99, margin:"12px auto 0", flexShrink:0 }}/>

        {/* Header */}
        <div style={{ display:"flex", alignItems:"center", justifyContent:"space-between", padding:"12px 20px 14px", borderBottom:`1px solid ${T.cardBorder}`, flexShrink:0 }}>
          <div style={{ display:"flex", alignItems:"center", gap:9 }}>
            <CreditCard size={18} color={themeAccent} strokeWidth={2}/>
            <p style={{ fontSize:16, fontWeight:900, color:T.text }}>{L.cicilan}</p>
          </div>
          <div style={{ display:"flex", gap:8, alignItems:"center" }}>
            {!showForm && !detail && (
              <button onClick={openAdd} style={{ background:`linear-gradient(135deg,${themeAccent},${themePrimary})`, border:"none", borderRadius:10, padding:"6px 12px", color:"white", fontSize:12, fontWeight:800, cursor:"pointer", display:"flex", alignItems:"center", gap:5, fontFamily:"inherit" }}>
                <Plus size={13} strokeWidth={2.5}/>{L.addCicilan}
              </button>
            )}
            <button onClick={() => { setShowCicilanModal(false); setShowForm(false); setDetail(null); }} style={{ width:30, height:30, borderRadius:"50%", background:T.card2, border:"none", cursor:"pointer", display:"flex", alignItems:"center", justifyContent:"center" }}>
              <X size={14} color={T.textSub} strokeWidth={2}/>
            </button>
          </div>
        </div>

        <div style={{ overflowY:"auto", flex:1 }}>
          {/* FORM */}
          {showForm && (
            <div style={{ padding:16, display:"flex", flexDirection:"column", gap:10 }}>
              <p style={{ fontSize:13, fontWeight:800, color:T.text }}>{editId ? L.editCicilan : L.addCicilan}</p>
              <input className="inp" placeholder={L.cicilanName} value={form.name} onChange={e=>setForm(f=>({...f,name:e.target.value}))} style={{ background:T.inp, border:`1.5px solid ${T.inpBorder}`, color:T.text }}/>
              <div style={{ display:"flex", gap:8 }}>
                <div style={{ flex:1 }}>
                  <p style={{ fontSize:10, fontWeight:700, color:T.textSub, marginBottom:4 }}>{L.cicilanMonthly}</p>
                  <input className="inp" type="text" inputMode="numeric" placeholder="750.000" value={form.monthlyDisplay||""} onFocus={e=>e.target.select()}
                    onChange={e=>{ const {display,raw}=parseRpInput(e.target.value); setForm(f=>({...f,monthly:raw,monthlyDisplay:display})); }}
                    style={{ background:T.inp, border:`1.5px solid ${T.inpBorder}`, color:T.text }}/>
                </div>
                <div style={{ flex:1 }}>
                  <p style={{ fontSize:10, fontWeight:700, color:T.textSub, marginBottom:4 }}>{L.cicilanDue}</p>
                  <input className="inp" type="number" min="1" max="31" placeholder="5" value={form.dueDay} onChange={e=>setForm(f=>({...f,dueDay:e.target.value}))} style={{ background:T.inp, border:`1.5px solid ${T.inpBorder}`, color:T.text }}/>
                </div>
              </div>
              <div style={{ display:"flex", gap:8 }}>
                <div style={{ flex:1 }}>
                  <p style={{ fontSize:10, fontWeight:700, color:T.textSub, marginBottom:4 }}>{L.cicilanTotal}</p>
                  <input className="inp" type="text" inputMode="numeric" placeholder="18.000.000" value={form.totalDisplay||""} onFocus={e=>e.target.select()}
                    onChange={e=>{ const {display,raw}=parseRpInput(e.target.value); setForm(f=>({...f,total:raw,totalDisplay:display})); }}
                    style={{ background:T.inp, border:`1.5px solid ${T.inpBorder}`, color:T.text }}/>
                </div>
                <div style={{ flex:1 }}>
                  <p style={{ fontSize:10, fontWeight:700, color:T.textSub, marginBottom:4 }}>{L.cicilanDuration}</p>
                  <input className="inp" type="number" min="1" placeholder="24" value={form.duration} onChange={e=>setForm(f=>({...f,duration:e.target.value}))} style={{ background:T.inp, border:`1.5px solid ${T.inpBorder}`, color:T.text }}/>
                </div>
              </div>
              <div style={{ display:"flex", gap:8, marginTop:4 }}>
                <button onClick={save} style={{ flex:1, padding:"12px 0", borderRadius:14, background:`linear-gradient(135deg,${themeAccent},${themePrimary})`, border:"none", color:"white", fontSize:13, fontWeight:800, cursor:"pointer", fontFamily:"inherit" }}>{L.save}</button>
                <button onClick={()=>setShowForm(false)} style={{ flex:0.5, padding:"12px 0", borderRadius:14, background:T.btnG, border:`1.5px solid ${T.btnGBorder}`, color:T.btnGText, fontSize:13, fontWeight:700, cursor:"pointer", fontFamily:"inherit" }}>{L.cancel}</button>
              </div>
            </div>
          )}

          {/* DETAIL */}
          {detail && !showForm && (
            <div>
              <div style={{ background:`linear-gradient(135deg,${themePrimary},${themeAccent}88)`, padding:"18px 20px 20px" }}>
                <p style={{ fontSize:10, fontWeight:800, color:"rgba(255,255,255,0.6)", letterSpacing:1.5, marginBottom:4 }}>{L.cicilan.toUpperCase()}</p>
                <p style={{ fontSize:18, fontWeight:900, color:"white" }}>{detail.name}</p>
                <div style={{ display:"flex", gap:20, marginTop:12 }}>
                  <div>
                    <p style={{ fontSize:16, fontWeight:900, color:"white" }}>{formatRp(detail.monthly)}</p>
                    <p style={{ fontSize:10, color:"rgba(255,255,255,0.6)", fontWeight:600 }}>{lang==="en"?"per month":"per bulan"}</p>
                  </div>
                  <div>
                    <p style={{ fontSize:16, fontWeight:900, color:"white" }}>{getPaidCount(detail)}/{detail.duration}</p>
                    <p style={{ fontSize:10, color:"rgba(255,255,255,0.6)", fontWeight:600 }}>{lang==="en"?"months paid":"bulan dibayar"}</p>
                  </div>
                  <div>
                    <p style={{ fontSize:16, fontWeight:900, color:"white" }}>tgl {detail.dueDay}</p>
                    <p style={{ fontSize:10, color:"rgba(255,255,255,0.6)", fontWeight:600 }}>{lang==="en"?"due date":"jatuh tempo"}</p>
                  </div>
                </div>
              </div>

              {/* Progress */}
              <div style={{ padding:"14px 20px", borderBottom:`1px solid ${T.cardBorder}` }}>
                <div style={{ display:"flex", justifyContent:"space-between", fontSize:12, color:T.textSub, fontWeight:600, marginBottom:8 }}>
                  <span>{L.cicilanProgress}</span>
                  <span>{getProgress(detail)}%</span>
                </div>
                <div style={{ height:8, borderRadius:99, background:T.card2, overflow:"hidden" }}>
                  <div style={{ height:"100%", width:`${getProgress(detail)}%`, background:`linear-gradient(90deg,${themeAccent},${themePrimary})`, borderRadius:99, transition:"width 0.6s ease" }}/>
                </div>
                <div style={{ display:"flex", justifyContent:"space-between", marginTop:6, fontSize:11, color:T.textSub }}>
                  <span>{lang==="en"?"Paid:":"Sudah bayar:"} {formatRp(getPaidCount(detail) * detail.monthly)}</span>
                  <span>{lang==="en"?"Remaining:":"Sisa:"} {formatRp((detail.duration - getPaidCount(detail)) * detail.monthly)}</span>
                </div>
              </div>

              {/* Actions */}
              <div style={{ padding:"14px 20px", display:"flex", gap:8, borderBottom:`1px solid ${T.cardBorder}` }}>
                <button onClick={()=>markPaid(detail)} style={{ flex:1, padding:"11px 0", borderRadius:12, background: isPaidThisMonth(detail) ? T.card2 : `linear-gradient(135deg,${themeAccent},${themePrimary})`, border: isPaidThisMonth(detail) ? `1.5px solid ${T.cardBorder}` : "none", color: isPaidThisMonth(detail) ? T.textSub : "white", fontSize:12, fontWeight:800, cursor:"pointer", fontFamily:"inherit" }}>
                  {isPaidThisMonth(detail) ? "✓ "+L.cicilanAlreadyPaid : L.cicilanMarkPaid}
                </button>
                <button onClick={()=>openEdit(detail)} style={{ width:42, height:42, borderRadius:12, background:T.catBg, border:`1.5px solid ${T.cardBorder}`, cursor:"pointer", display:"flex", alignItems:"center", justifyContent:"center" }}>
                  <Pencil size={15} color={T.text} strokeWidth={2}/>
                </button>
                <button onClick={()=>del(detail.id)} style={{ width:42, height:42, borderRadius:12, background:"#ef444418", border:"1.5px solid #ef444435", cursor:"pointer", display:"flex", alignItems:"center", justifyContent:"center" }}>
                  <Trash2 size={15} color="#f87171" strokeWidth={2}/>
                </button>
              </div>
              <button onClick={()=>setDetail(null)} style={{ display:"block", margin:"12px 20px", width:"calc(100% - 40px)", padding:"10px 0", borderRadius:12, background:T.card2, border:`1.5px solid ${T.cardBorder}`, color:T.textSub, fontSize:13, fontWeight:700, cursor:"pointer", fontFamily:"inherit" }}>← {lang==="en"?"Back":"Kembali"}</button>
            </div>
          )}

          {/* LIST */}
          {!showForm && !detail && (
            <div>
              {cicilan.length === 0 ? (
                <div style={{ padding:"48px 20px", textAlign:"center" }}>
                  <div style={{ width:72, height:72, borderRadius:22, background:themeAccent+"18", border:`1.5px solid ${themeAccent}30`, display:"flex", alignItems:"center", justifyContent:"center", margin:"0 auto 14px" }}>
                    <CreditCard size={32} color={T.accentText} strokeWidth={1.5}/>
                  </div>
                  <p style={{ fontSize:15, fontWeight:800, color:T.text, marginBottom:6 }}>{L.noCicilan}</p>
                  <p style={{ fontSize:12, color:T.textSub }}>{L.cicilanDesc}</p>
                </div>
              ) : (
                <>
                  {/* Total card */}
                  <div style={{ margin:"14px 16px 0", padding:"14px 16px", background:T.card2, border:`1px solid ${T.cardBorder}`, borderRadius:16, display:"flex", justifyContent:"space-between", alignItems:"center" }}>
                    <div>
                      <p style={{ fontSize:11, fontWeight:700, color:T.textSub, marginBottom:3 }}>{L.cicilanTotal2}</p>
                      <p style={{ fontSize:20, fontWeight:900, color:"#f87171" }}>-{formatRp(totalMonthly)}</p>
                    </div>
                    <div style={{ textAlign:"right" }}>
                      <p style={{ fontSize:11, fontWeight:700, color:T.textSub, marginBottom:3 }}>{cicilan.length} {lang==="en"?"items":"item aktif"}</p>
                      <p style={{ fontSize:11, color:T.textSub }}>{L.cicilanDesc}</p>
                    </div>
                  </div>

                  {cicilan.map((c, i) => (
                    <div key={c.id} onClick={()=>openDetail(c)} style={{ display:"flex", alignItems:"center", gap:12, padding:"14px 16px", borderBottom: i<cicilan.length-1 ? `1px solid ${T.cardBorder}` : "none", cursor:"pointer" }}>
                      <div style={{ width:44, height:44, borderRadius:14, background:themeAccent+"18", display:"flex", alignItems:"center", justifyContent:"center", flexShrink:0 }}>
                        <CreditCard size={20} color={T.accentText} strokeWidth={1.5}/>
                      </div>
                      <div style={{ flex:1, minWidth:0 }}>
                        <p style={{ fontSize:14, fontWeight:700, color:T.text }}>{c.name}</p>
                        <p style={{ fontSize:11, color:T.textSub, marginTop:2 }}>
                          {lang==="en"?"Instalment":"Cicilan"} {getPaidCount(c)}/{c.duration} · {lang==="en"?"due":"jatuh tempo"} tgl {c.dueDay}
                        </p>
                        <div style={{ height:3, borderRadius:99, background:T.card2, overflow:"hidden", marginTop:6, maxWidth:120 }}>
                          <div style={{ height:"100%", width:`${getProgress(c)}%`, background:`linear-gradient(90deg,${themeAccent},${themePrimary})`, borderRadius:99 }}/>
                        </div>
                      </div>
                      <div style={{ textAlign:"right", flexShrink:0 }}>
                        <p style={{ fontSize:14, fontWeight:800, color:"#f87171" }}>-{formatRp(c.monthly)}</p>
                        <p style={{ fontSize:10, color: isPaidThisMonth(c) ? "#4ade80" : T.textSub, marginTop:2, fontWeight: isPaidThisMonth(c) ? 700 : 500 }}>
                          {isPaidThisMonth(c) ? "✓ "+L.cicilanPaid : (c.duration - getPaidCount(c))+" "+L.cicilanRemain}
                        </p>
                      </div>
                    </div>
                  ))}
                </>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
