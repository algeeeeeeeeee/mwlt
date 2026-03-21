import React from "react";
import { Hash, Pencil, Plus, Trash2, X } from "../icons.jsx";
import { formatRp, haptic } from "../utils/helpers.js";

const TAG_COLORS = ["#f87171","#fb923c","#fbbf24","#4ade80","#34d399","#60a5fa","#818cf8","#c084fc","#f472b6","#94a3b8"];

function emptyTag() { return { name: "", color: "#60a5fa" }; }

export default function ModalTags({ ctx }) {
  const {
    T, lang, L,
    themeAccent, themePrimary,
    userTags, setUserTags,
    txTags,
    transactions,
    showTagModal, setShowTagModal,
    showToast,
  } = ctx;

  const [editId, setEditId] = React.useState(null);
  const [form, setForm] = React.useState(emptyTag());
  const [showForm, setShowForm] = React.useState(false);

  if (!showTagModal) return null;

  function openAdd() { setEditId(null); setForm(emptyTag()); setShowForm(true); }
  function openEdit(t) { setEditId(t.id); setForm({ name: t.name, color: t.color }); setShowForm(true); }

  function save() {
    if (!form.name.trim()) return;
    if (editId) {
      setUserTags(p => p.map(t => t.id === editId ? { ...t, ...form } : t));
    } else {
      setUserTags(p => [...p, { id: Date.now(), ...form }]);
      showToast(L.tagAdded);
    }
    setShowForm(false); haptic("success");
  }

  function del(id) {
    setUserTags(p => p.filter(t => t.id !== id));
    showToast(L.tagDeleted); haptic();
  }

  // Get tag usage stats
  function tagCount(tagId) {
    return Object.values(txTags || {}).filter(tags => (tags || []).includes(tagId)).length;
  }
  function tagTotal(tagId) {
    const txIds = Object.entries(txTags || {}).filter(([,tags]) => (tags||[]).includes(tagId)).map(([id]) => Number(id));
    return (transactions || []).filter(t => txIds.includes(t.id)).reduce((s,t) => s + Number(t.amount||0), 0);
  }

  const SUGGESTED = lang === "en"
    ? ["holiday","wedding","lebaran","monthly","date","work","family","health"]
    : ["liburan","kondangan","lebaran","bulanan","date","kerja","keluarga","kesehatan"];

  return (
    <div style={{ position:"fixed", inset:0, background:"rgba(0,0,0,0.55)", backdropFilter:"blur(6px)", WebkitBackdropFilter:"blur(6px)", zIndex:300, display:"flex", alignItems:"flex-end", justifyContent:"center" }}
      onClick={e => { if (e.target===e.currentTarget) setShowTagModal(false); }}>
      <div style={{ background:T.modalBg, borderRadius:"24px 24px 0 0", width:"100%", maxWidth:420, maxHeight:"90dvh", display:"flex", flexDirection:"column", overflow:"hidden" }}>
        <div style={{ width:36, height:4, background:T.cardBorder, borderRadius:99, margin:"12px auto 0", flexShrink:0 }}/>

        <div style={{ display:"flex", alignItems:"center", justifyContent:"space-between", padding:"12px 20px 14px", borderBottom:`1px solid ${T.cardBorder}`, flexShrink:0 }}>
          <div style={{ display:"flex", alignItems:"center", gap:9 }}>
            <Hash size={18} color={themeAccent} strokeWidth={2}/>
            <p style={{ fontSize:16, fontWeight:900, color:T.text }}>{L.tags}</p>
          </div>
          <div style={{ display:"flex", gap:8, alignItems:"center" }}>
            {!showForm && (
              <button onClick={openAdd} style={{ background:`linear-gradient(135deg,${themeAccent},${themePrimary})`, border:"none", borderRadius:10, padding:"6px 12px", color:"white", fontSize:12, fontWeight:800, cursor:"pointer", display:"flex", alignItems:"center", gap:5, fontFamily:"inherit" }}>
                <Plus size={13} strokeWidth={2.5}/>{L.addTag}
              </button>
            )}
            <button onClick={()=>{ setShowTagModal(false); setShowForm(false); }} style={{ width:30, height:30, borderRadius:"50%", background:T.card2, border:"none", cursor:"pointer", display:"flex", alignItems:"center", justifyContent:"center" }}>
              <X size={14} color={T.textSub} strokeWidth={2}/>
            </button>
          </div>
        </div>

        <div style={{ overflowY:"auto", flex:1 }}>
          {/* Form */}
          {showForm && (
            <div style={{ padding:16, display:"flex", flexDirection:"column", gap:12 }}>
              <p style={{ fontSize:13, fontWeight:800, color:T.text }}>{editId ? L.editTag : L.addTag}</p>
              <input className="inp" placeholder={L.tagPlaceholder} value={form.name}
                onChange={e => setForm(f => ({ ...f, name: e.target.value }))}
                style={{ background:T.inp, border:`1.5px solid ${T.inpBorder}`, color:T.text }}
                autoFocus/>

              <div>
                <p style={{ fontSize:11, fontWeight:700, color:T.textSub, marginBottom:8 }}>{lang==="en"?"Color":"Warna"}</p>
                <div style={{ display:"flex", gap:8, flexWrap:"wrap" }}>
                  {TAG_COLORS.map(col => (
                    <div key={col} onClick={() => setForm(f => ({ ...f, color: col }))}
                      style={{ width:32, height:32, borderRadius:50, background:col, cursor:"pointer", border: form.color===col ? `3px solid white` : "3px solid transparent", boxShadow: form.color===col ? `0 0 0 2px ${col}` : "none", transition:"all 0.15s" }}/>
                  ))}
                </div>
              </div>

              {/* Preview */}
              {form.name && (
                <div>
                  <p style={{ fontSize:11, fontWeight:700, color:T.textSub, marginBottom:6 }}>{lang==="en"?"Preview":"Preview"}</p>
                  <div style={{ display:"inline-flex", alignItems:"center", gap:5, padding:"6px 12px", borderRadius:99, background:form.color+"18", border:`1.5px solid ${form.color}50` }}>
                    <Hash size={11} color={form.color} strokeWidth={2.5}/>
                    <span style={{ fontSize:12, fontWeight:700, color:form.color }}>{form.name}</span>
                  </div>
                </div>
              )}

              <div style={{ display:"flex", gap:8 }}>
                <button onClick={save} style={{ flex:1, padding:"12px 0", borderRadius:14, background:`linear-gradient(135deg,${themeAccent},${themePrimary})`, border:"none", color:"white", fontSize:13, fontWeight:800, cursor:"pointer", fontFamily:"inherit" }}>{L.save}</button>
                <button onClick={()=>setShowForm(false)} style={{ flex:0.5, padding:"12px 0", borderRadius:14, background:T.btnG, border:`1.5px solid ${T.btnGBorder}`, color:T.btnGText, fontSize:13, fontWeight:700, cursor:"pointer", fontFamily:"inherit" }}>{L.cancel}</button>
              </div>
            </div>
          )}

          {/* List */}
          {!showForm && (
            <div>
              {userTags.length === 0 ? (
                <div>
                  <div style={{ padding:"36px 20px", textAlign:"center" }}>
                    <div style={{ width:64, height:64, borderRadius:20, background:themeAccent+"18", border:`1.5px solid ${themeAccent}30`, display:"flex", alignItems:"center", justifyContent:"center", margin:"0 auto 12px" }}>
                      <Hash size={28} color={T.accentText} strokeWidth={1.5}/>
                    </div>
                    <p style={{ fontSize:15, fontWeight:800, color:T.text, marginBottom:6 }}>{L.noTags}</p>
                    <p style={{ fontSize:12, color:T.textSub }}>{lang==="en"?"Add tags to group your transactions":"Tambah tag untuk kelompokkan transaksi"}</p>
                  </div>

                  {/* Suggestions */}
                  <div style={{ padding:"0 16px 20px" }}>
                    <p style={{ fontSize:11, fontWeight:700, color:T.textSub, marginBottom:10, letterSpacing:0.5 }}>{L.tagSuggestions.toUpperCase()}</p>
                    <div style={{ display:"flex", flexWrap:"wrap", gap:6 }}>
                      {SUGGESTED.map((s, i) => (
                        <button key={s} onClick={() => { setForm({ name:s, color: TAG_COLORS[i % TAG_COLORS.length] }); setShowForm(true); }}
                          style={{ display:"inline-flex", alignItems:"center", gap:5, padding:"7px 12px", borderRadius:99, background:TAG_COLORS[i%TAG_COLORS.length]+"15", border:`1.5px solid ${TAG_COLORS[i%TAG_COLORS.length]}40`, cursor:"pointer", fontFamily:"inherit" }}>
                          <Hash size={10} color={TAG_COLORS[i%TAG_COLORS.length]} strokeWidth={2.5}/>
                          <span style={{ fontSize:12, fontWeight:700, color:TAG_COLORS[i%TAG_COLORS.length] }}>{s}</span>
                        </button>
                      ))}
                    </div>
                  </div>
                </div>
              ) : (
                <div>
                  {userTags.map((tag, i) => (
                    <div key={tag.id} style={{ display:"flex", alignItems:"center", gap:12, padding:"13px 16px", borderBottom: i<userTags.length-1 ? `1px solid ${T.cardBorder}` : "none" }}>
                      <div style={{ width:40, height:40, borderRadius:12, background:tag.color+"20", border:`1.5px solid ${tag.color}40`, display:"flex", alignItems:"center", justifyContent:"center", flexShrink:0 }}>
                        <Hash size={18} color={tag.color} strokeWidth={2}/>
                      </div>
                      <div style={{ flex:1, minWidth:0 }}>
                        <p style={{ fontSize:14, fontWeight:700, color:T.text }}>#{tag.name}</p>
                        <p style={{ fontSize:11, color:T.textSub, marginTop:1 }}>
                          {tagCount(tag.id)} {L.tagTx}
                          {tagCount(tag.id) > 0 ? ` · ${formatRp(tagTotal(tag.id))}` : ""}
                        </p>
                      </div>
                      <div style={{ display:"flex", gap:6 }}>
                        <button onClick={() => openEdit(tag)} style={{ width:34, height:34, borderRadius:10, background:T.catBg, border:`1.5px solid ${T.cardBorder}`, cursor:"pointer", display:"flex", alignItems:"center", justifyContent:"center" }}>
                          <Pencil size={13} color={T.text} strokeWidth={2}/>
                        </button>
                        <button onClick={() => del(tag.id)} style={{ width:34, height:34, borderRadius:10, background:"#ef444418", border:"1.5px solid #ef444435", cursor:"pointer", display:"flex", alignItems:"center", justifyContent:"center" }}>
                          <Trash2 size={13} color="#f87171" strokeWidth={2}/>
                        </button>
                      </div>
                    </div>
                  ))}

                  {/* Summary by tag */}
                  {userTags.some(t => tagCount(t.id) > 0) && (
                    <div style={{ padding:"14px 16px", borderTop:`1px solid ${T.cardBorder}` }}>
                      <p style={{ fontSize:11, fontWeight:700, color:T.textSub, marginBottom:10, letterSpacing:0.5 }}>{L.tagStats.toUpperCase()}</p>
                      <div style={{ display:"grid", gridTemplateColumns:"1fr 1fr", gap:8 }}>
                        {userTags.filter(t => tagCount(t.id) > 0).map(tag => (
                          <div key={tag.id} style={{ background:T.card2, border:`1px solid ${T.cardBorder}`, borderRadius:14, padding:12 }}>
                            <p style={{ fontSize:12, fontWeight:700, color:tag.color, marginBottom:4 }}>#{tag.name}</p>
                            <p style={{ fontSize:15, fontWeight:900, color:T.text }}>{formatRp(tagTotal(tag.id))}</p>
                            <p style={{ fontSize:11, color:T.textSub, marginTop:2 }}>{tagCount(tag.id)} {L.tagTx}</p>
                          </div>
                        ))}
                      </div>
                    </div>
                  )}
                </div>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
