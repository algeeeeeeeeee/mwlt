import { Calculator2, Calendar, Hash, ImagePlus, Image, Trash2, X, ZoomIn } from "../icons.jsx";
import { getCatLabel, haptic, today } from "../utils/helpers.js";
import { darken } from "../utils/theme.js";
import React from "react";
import { CatIcon } from "./ui.jsx";

export default function ModalAddTransaction({ ctx }) {
  const {
    T, dark, lang, L,
    themeAccent, themePrimary,
    categories, transactions,
    form, setForm,
    editItem, setEditItem,
    showForm, setShowForm,
    setShowCalc,
    submitForm,
    kbHeight,
    txReceipts, setTxReceipts,
    txTags, setTxTags,
    userTags,
  } = ctx;

  return (
          <div style={{ position:"fixed", inset:0, background:"rgba(0,0,0,0.55)", backdropFilter:"blur(6px)", WebkitBackdropFilter:"blur(6px)", zIndex:300, display:"flex", alignItems:"flex-end", justifyContent:"center", boxSizing:"border-box" }}
            onClick={e => { if (e.target===e.currentTarget) { setShowForm(false); setEditItem(null); } }}>
            <div className="modal-float" style={{ background:T.modalBg, borderRadius:"24px 24px 0 0", width:"100%", maxWidth:400, boxShadow: dark ? "0 24px 60px rgba(0,0,0,0.8)" : "0 12px 40px rgba(0,0,0,0.2)", overflow:"hidden", maxHeight: kbHeight > 0 ? `calc(100dvh - ${kbHeight}px - env(safe-area-inset-top))` : "88dvh", display:"flex", flexDirection:"column", marginBottom: kbHeight > 0 ? kbHeight : 0, transition:"margin-bottom 0.25s ease, max-height 0.25s ease" }}>

              {/* Header strip */}
              <div style={{ background:`linear-gradient(135deg,${themePrimary},${darken(themePrimary,0.25)})`, padding:"14px 16px 12px", display:"flex", alignItems:"center", justifyContent:"space-between" }}>
                <p style={{ fontSize:14, fontWeight:900, color:"white" }}>{editItem ? L.editTx : L.newTx}</p>
                <button onClick={() => { setShowForm(false); setEditItem(null); }}
                  style={{ width:26, height:26, borderRadius:50, background:"rgba(0,0,0,0.2)", border:"none", display:"flex", alignItems:"center", justifyContent:"center", cursor:"pointer" }}>
                  <X size={12} color="white" strokeWidth={2.5}/>
                </button>
              </div>

              {/* Body */}
              <div style={{ padding:"14px 16px 16px", display:"flex", flexDirection:"column", gap:10, overflowY:"auto", flex:1 }}>

                {/* Amount row */}
                <div style={{ display:"flex", gap:8, alignItems:"stretch" }}>
                  <div style={{ flex:1, position:"relative", display:"flex", alignItems:"center" }}>
                    <span style={{ position:"absolute", left:14, fontSize:14, fontWeight:800, color:T.textSub, pointerEvents:"none", zIndex:2, userSelect:"none" }}>Rp.</span>
                    <input
                      type="text" inputMode="numeric" placeholder="0"
                      value={form.amountDisplay || ""}
                      onChange={e => {
                        const raw = e.target.value.replace(/\./g,"").replace(/[^0-9]/g,"");
                        const formatted = raw ? Number(raw).toLocaleString("id-ID") : "";
                        setForm(f => ({ ...f, amount: raw ? Number(raw) : "", amountDisplay: formatted }));
                      }}
                      autoFocus
                      style={{ width:"100%", background:T.inp, border:`1.5px solid ${T.inpBorder}`, borderRadius:12, padding:"10px 14px 10px 44px", fontSize:22, fontWeight:900, color:T.text, outline:"none", fontFamily:"inherit", letterSpacing:-0.5, minWidth:0 }}
                    />
                  </div>
                  <button onClick={() => setShowCalc(true)} style={{ width:42, height:42, borderRadius:12, background:T.catBg, border:`1.5px solid ${T.cardBorder}`, cursor:"pointer", display:"flex", alignItems:"center", justifyContent:"center", flexShrink:0 }}>
                    <Calculator2 size={16} color={T.textSub} strokeWidth={2}/>
                  </button>
                </div>

                {/* Date row - full width */}
                <div style={{ position:"relative" }}>
                  <Calendar size={14} color={T.accentText} strokeWidth={2} style={{ position:"absolute", left:12, top:"50%", transform:"translateY(-50%)", pointerEvents:"none", zIndex:2 }}/>
                  <input type="date" value={form.date} onChange={e => setForm(f => ({ ...f, date: e.target.value }))}
                    style={{ width:"100%", boxSizing:"border-box", background:T.inp, border:`1.5px solid ${T.inpBorder}`, borderRadius:12, padding:"10px 12px 10px 32px", fontSize:13, color:T.text, outline:"none", fontFamily:"inherit", colorScheme: dark?"dark":"light" }}/>
                </div>

                {/* Kategori chips — scrollable, touch-isolated */}
                <div
                  style={{ display:"flex", gap:6, overflowX:"auto", paddingBottom:2, scrollbarWidth:"none", WebkitOverflowScrolling:"touch", touchAction:"pan-x" }}
                  onTouchStart={e => e.stopPropagation()}
                  onTouchMove={e => e.stopPropagation()}
                >
                  {Object.entries(categories).map(([k, v]) => {
                    const isSel = form.category === k;
                    return (
                      <button key={k} onMouseDown={e => e.preventDefault()} onClick={() => setForm(f => ({ ...f, category: k }))}
                        style={{ display:"flex", alignItems:"center", gap:5, padding:"6px 11px", borderRadius:20, flexShrink:0,
                          background: isSel ? v.color+"22" : T.catBg,
                          border: isSel ? `2px solid ${v.color}` : `1.5px solid ${T.cardBorder}`,
                          cursor:"pointer", transition:"all 0.15s" }}>
                        <CatIcon iconKey={v.icon} size={11} color={isSel ? v.color : T.textSub}/>
                        <span style={{ fontSize:11, fontWeight: isSel ? 700 : 500, color: isSel ? v.color : T.textSub, whiteSpace:"nowrap" }}>{getCatLabel(v, lang)}</span>
                      </button>
                    );
                  })}
                </div>

                {/* Keterangan */}
                <input className="inp" placeholder={L.descPlaceholder} value={form.description}
                  onChange={e => setForm(f => ({ ...f, description: e.target.value }))}
                  style={{ background:T.inp, border:`1.5px solid ${T.inpBorder}`, color:T.text }} />

                {/* Lokasi & Catatan — satu baris */}
                <div style={{ display:"flex", gap:8 }}>
                  <input className="inp" placeholder={L.locPlaceholder} value={form.location||""}
                    onChange={e => setForm(f => ({ ...f, location: e.target.value }))}
                    style={{ flex:1, background:T.inp, border:`1.5px solid ${T.inpBorder}`, color:T.text }} />
                  <input className="inp" placeholder={L.notePlaceholder} value={form.note||""}
                    onChange={e => setForm(f => ({ ...f, note: e.target.value }))}
                    style={{ flex:1, background:T.inp, border:`1.5px solid ${T.inpBorder}`, color:T.text }} />
                </div>


                {/* Tags */}
                {(() => {
                  const itemTags = (txTags && editItem ? txTags[editItem.id] : form._tags) || [];
                  const setItemTags = tags => {
                    if (editItem) setTxTags(p => ({ ...p, [editItem.id]: tags }));
                    else setForm(f => ({ ...f, _tags: tags }));
                  };
                  return (
                    <div>
                      <div style={{ display:"flex", gap:6, flexWrap:"wrap" }}>
                        {(userTags||[]).map(tag => {
                          const active = itemTags.includes(tag.id);
                          return (
                            <button key={tag.id} onClick={() => setItemTags(active ? itemTags.filter(x=>x!==tag.id) : [...itemTags, tag.id])}
                              style={{ display:"flex", alignItems:"center", gap:4, padding:"5px 10px", borderRadius:99, border: active ? `1.5px solid ${tag.color}88` : `1.5px solid ${T.cardBorder}`, background: active ? tag.color+"18" : T.catBg, cursor:"pointer", transition:"all 0.15s" }}>
                              <Hash size={10} color={active ? tag.color : T.textSub} strokeWidth={2.5}/>
                              <span style={{ fontSize:11, fontWeight:700, color: active ? tag.color : T.textSub }}>{tag.name}</span>
                            </button>
                          );
                        })}
                        {(userTags||[]).length === 0 && (
                          <p style={{ fontSize:11, color:T.textMuted }}>{L.noTags}</p>
                        )}
                      </div>
                    </div>
                  );
                })()}

                {/* Foto Struk */}
                {(() => {
                  const receiptKey = editItem ? editItem.id : "_new";
                  const receipt = txReceipts?.[receiptKey];
                  const [showFull, setShowFull] = React.useState(false);
                  return (
                    <div>
                      {receipt ? (
                        <div style={{ position:"relative", borderRadius:14, overflow:"hidden" }}>
                          <img src={receipt} alt="struk" style={{ width:"100%", maxHeight:180, objectFit:"cover", borderRadius:14, display:"block" }} onClick={() => setShowFull(true)}/>
                          <div style={{ position:"absolute", top:8, right:8, display:"flex", gap:6 }}>
                            <button onClick={() => setShowFull(true)} style={{ width:32, height:32, borderRadius:50, background:"rgba(0,0,0,0.65)", border:"none", cursor:"pointer", display:"flex", alignItems:"center", justifyContent:"center" }}>
                              <ZoomIn size={14} color="white" strokeWidth={2}/>
                            </button>
                            <button onClick={() => setTxReceipts(p => { const n={...p}; delete n[receiptKey]; return n; })} style={{ width:32, height:32, borderRadius:50, background:"rgba(239,68,68,0.7)", border:"none", cursor:"pointer", display:"flex", alignItems:"center", justifyContent:"center" }}>
                              <Trash2 size={13} color="white" strokeWidth={2}/>
                            </button>
                          </div>
                          {showFull && (
                            <div onClick={() => setShowFull(false)} style={{ position:"fixed", inset:0, background:"rgba(0,0,0,0.9)", zIndex:999, display:"flex", alignItems:"center", justifyContent:"center", padding:20 }}>
                              <img src={receipt} alt="struk" style={{ maxWidth:"100%", maxHeight:"90vh", borderRadius:16, objectFit:"contain" }}/>
                            </div>
                          )}
                        </div>
                      ) : (
                        <label style={{ display:"flex", alignItems:"center", gap:10, padding:"11px 14px", borderRadius:12, border:`1.5px dashed ${T.cardBorder}`, cursor:"pointer", background:T.catBg }}>
                          <ImagePlus size={16} color={T.textSub} strokeWidth={2}/>
                          <span style={{ fontSize:12, color:T.textSub, fontWeight:600 }}>{L.receiptUpload}</span>
                          <input type="file" accept="image/*" capture="environment" style={{ display:"none" }} onChange={e => {
                            const file = e.target.files?.[0];
                            if (!file) return;
                            const reader = new FileReader();
                            reader.onload = ev => {
                              setTxReceipts(p => ({ ...p, [receiptKey]: ev.target.result }));
                              showToast(L.receiptAdded);
                            };
                            reader.readAsDataURL(file);
                          }}/>
                        </label>
                      )}
                    </div>
                  );
                })()}

                {/* Actions */}
                <div style={{ display:"flex", gap:8, marginTop:2 }}>
                  <button className="btn-p" style={{ flex:1, fontSize:13, padding:"12px 0",
                    background:`linear-gradient(135deg,${themeAccent},${themePrimary})`,
                    boxShadow:`0 4px 14px ${themeAccent}44` }} onClick={submitForm}>
                    {editItem ? L.save : `+ ${L.add}`}
                  </button>
                  <button className="btn-g" style={{ flex:0.4, background:T.btnG, color:T.btnGText, border:`1.5px solid ${T.btnGBorder}`, fontSize:13, padding:"12px 0" }}
                    onClick={() => { setShowForm(false); setEditItem(null); }}>{L.cancel}</button>
                </div>
              </div>
            </div>
          </div>
  );
}
