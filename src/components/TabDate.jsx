import { CheckCircle, ChevronDown, Heart, Palette, Pencil, Plus, SlidersHorizontal, Sparkles, Trash2, X } from "../icons.jsx";
import { formatRp, getMonth, haptic, today } from "../utils/helpers.js";
import { PresetIcon } from "./ui.jsx";

export default function TabDate({ ctx }) {
  const {
    T, dark, lang, L,
    tabAnim, loaded, headerHeight,
    themeAccent, themePrimary,
    themePresetId, setThemePresetId,
    customPrimary, setCustomPrimary,
    customAccent, setCustomAccent,
    showThemePicker, setShowThemePicker,
    THEME_PRESETS,
    savingsGoals, setSavingsGoals,
    dateExpense,
    transactions, categories,
    income,
    budgets, setBudgets,

    overallBudget,
    triggerThemeChange,
    setTempOverallBudget, setTempOverallBudgetDisplay,
    setShowOverallBudgetModal,
  } = ctx;

  return (
        <>
          <div key="date" className={`fi${tabAnim ? " tab-enter" : ""}`} style={{ padding:"0" }}>
            <div style={{ padding:"14px 16px 0", paddingTop:`${headerHeight + 8}px`, paddingBottom:"16px" }}>

            {/* Budget Date card */}
            <div className="card" style={{ padding:"24px 24px 20px", marginTop:0, marginBottom:14, background: dark?"#1a0d14":"linear-gradient(135deg,#fdf2f8,#fce7f3)", border: dark?"1px solid #3d1a2e":"1px solid #f9a8d4" }}>
              <p style={{ fontSize:11, fontWeight:700, color: dark?"#f9a8d4":"#9d174d", letterSpacing:1 }}>{L.dateBudgetTitle}</p>
              <p style={{ fontSize:32, fontWeight:900, color: dark?"#f472b6":"#be185d", margin:"6px 0" }}>{formatRp(dateExpense)}</p>
              <p style={{ fontSize:12, color: dark?"#f9a8d4":"#9d174d", opacity:0.8 }}>
                {transactions.filter(t => t.category==="date" && getMonth(t.date)===currentMonth).length} {L.dateActivities}
              </p>
            </div>

            {/* Wishlist Date */}
            <div className="card" style={{ padding:"16px 18px", marginBottom:14, ...CS }}>
              <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center", marginBottom:14 }}>
                <div style={{ display:"flex", alignItems:"center", gap:7 }}>
                  <div style={{ width:28, height:28, borderRadius:9, background:"rgba(244,114,182,0.15)", display:"flex", alignItems:"center", justifyContent:"center" }}>
                    <Heart size={14} color="#f472b6" strokeWidth={2.5}/>
                  </div>
                  <p style={{ fontSize:14, fontWeight:800, color:T.text }}>{L.wishlistTitle}</p>
                </div>
                <button onClick={() => setShowWishlistForm(true)}
                  style={{ background:"none", border:"none", fontSize:12, color:"#f472b6", fontWeight:700, cursor:"pointer", display:"flex", alignItems:"center", gap:3 }}>
                  <Plus size={13} strokeWidth={2.5}/> {L.add}
                </button>
              </div>
              {dateWishlist.length === 0 ? (
                <div style={{ textAlign:"center", padding:"20px 0", display:"flex", flexDirection:"column", alignItems:"center", gap:8 }}>
                  <Sparkles size={28} color="rgba(244,114,182,0.4)" strokeWidth={1.5}/>
                  <p style={{ fontSize:13, color:T.textSub }}>{L.noWishlist}</p>
                  <p style={{ fontSize:11, color:T.textMuted }}>{L.wishlistSub}</p>
                </div>
              ) : (
                <div style={{ display:"flex", flexDirection:"column", gap:8 }}>
                  {dateWishlist.map(item => (
                    <div key={item.id} style={{ display:"flex", alignItems:"center", gap:10, padding:"10px 12px", background: dark?"rgba(244,114,182,0.07)":"rgba(244,114,182,0.06)", borderRadius:12, border:`1px solid ${dark?"rgba(244,114,182,0.15)":"rgba(244,114,182,0.2)"}` }}>
                      <button onClick={() => setDateWishlist(prev => prev.map(w => w.id===item.id ? {...w, done:!w.done} : w))}
                        style={{ width:20, height:20, borderRadius:6, border:`2px solid ${item.done?"#f472b6":dark?"rgba(255,255,255,0.2)":"rgba(0,0,0,0.15)"}`, background: item.done?"#f472b6":"transparent", display:"flex", alignItems:"center", justifyContent:"center", cursor:"pointer", flexShrink:0, padding:0 }}>
                        {item.done && <CheckCircle size={11} color="white" strokeWidth={3}/>}
                      </button>
                      <p style={{ flex:1, fontSize:13, fontWeight:600, color: item.done ? T.textSub : T.text, textDecoration: item.done ? "line-through" : "none" }}>{item.label}</p>
                      <button onClick={() => setDateWishlist(prev => prev.filter(w => w.id !== item.id))}
                        style={{ ...IBN, padding:2, display:"flex", alignItems:"center" }}>
                        <X size={13} strokeWidth={2} color={T.textSub}/>
                      </button>
                    </div>
                  ))}
                </div>
              )}
            </div>

            {/* Wishlist add modal */}
            {showWishlistForm && (
              <div style={{ position:"fixed", inset:0, background:"rgba(0,0,0,0.5)", zIndex:800, display:"flex", alignItems:"flex-end", justifyContent:"center" }} onClick={() => setShowWishlistForm(false)}>
                <div style={{ background:T.card, borderRadius:"24px 24px 0 0", padding:"22px 20px 36px", width:"100%" }} onClick={e => e.stopPropagation()}>
                  <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center", marginBottom:16 }}>
                    <p style={{ fontSize:16, fontWeight:900, color:T.text }}>{L.addWishlist}</p>
                    <button onClick={() => setShowWishlistForm(false)} style={{ ...IBN }}><X size={20} color={T.textSub}/></button>
                  </div>
                  <input className="inp" autoFocus placeholder={L.wishlistPlaceholder} value={wishlistInput}
                    onChange={e => setWishlistInput(e.target.value)}
                    onKeyDown={e => { if(e.key==="Enter" && wishlistInput.trim()){ setDateWishlist(prev => [...prev, { id:Date.now(), label:wishlistInput.trim(), done:false }]); setWishlistInput(""); setShowWishlistForm(false); showToast(L.toastWishlist); } }}
                    style={{ background:T.inp, border:"1.5px solid #f9a8d4", color:T.text, marginBottom:12 }}/>
                  <button className="btn-p" style={{ width:"100%", background:"#f472b6", fontFamily:"inherit" }}
                    onClick={() => { if(!wishlistInput.trim()) return; setDateWishlist(prev => [...prev, { id:Date.now(), label:wishlistInput.trim(), done:false }]); setWishlistInput(""); setShowWishlistForm(false); showToast(L.toastWishlist); }}>
                    {L.save}
                  </button>
                </div>
              </div>
            )}

            {/* Catat Pengeluaran Date */}
            <div className="card" style={{ padding:"16px 18px", marginBottom:14, ...CS }}>
              <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center", marginBottom:14 }}>
                <div style={{ display:"flex", alignItems:"center", gap:7 }}>
                  <div style={{ width:28, height:28, borderRadius:9, background:"rgba(244,114,182,0.15)", display:"flex", alignItems:"center", justifyContent:"center" }}>
                    <Pencil size={14} color="#f472b6" strokeWidth={2.5}/>
                  </div>
                  <p style={{ fontSize:14, fontWeight:800, color:T.text }}>{L.dateRecord}</p>
                </div>
                <button onClick={() => { haptic(); setShowForm(true); setEditItem(null); setForm({ date:today(), amount:"", category:"date", description:"", location:"" }); }}
                  style={{ background:"#f472b6", border:"none", borderRadius:10, padding:"6px 14px", fontSize:12, color:"white", fontWeight:800, cursor:"pointer", display:"flex", alignItems:"center", gap:4 }}>
                  <Plus size={12} strokeWidth={2.5}/> {L.addDateBtn.replace("+ ","")}
                </button>
              </div>
              {transactions.filter(t => t.category==="date").length === 0 ? (
                <div className="card" style={{ padding:32, textAlign:"center", background:"transparent", border:"none" }}>
                  <div style={{ display:"flex", justifyContent:"center", marginBottom:10 }}><Heart size={36} color="#f9a8d4" strokeWidth={1.5}/></div>
                  <p style={{ color:T.textSub, fontSize:13 }}>{L.noDateExp}</p>
                </div>
              ) : (
                <div style={{ display:"flex", flexDirection:"column", gap:9 }}>
                  {transactions.filter(t => t.category==="date").sort((a,b) => b.date.localeCompare(a.date)).map(t => (
                    <div key={t.id} style={{ borderRadius:12, border:`1px solid ${activeDateId===t.id ? "rgba(244,114,182,0.45)" : dark?"rgba(244,114,182,0.15)":"rgba(244,114,182,0.2)"}`, overflow:"hidden", transition:"border-color 0.2s" }}>
                      <div onClick={() => setActiveDateId(activeDateId===t.id ? null : t.id)}
                        style={{ display:"flex", alignItems:"center", gap:10, padding:"10px 12px", background: dark?"rgba(244,114,182,0.07)":"rgba(244,114,182,0.06)", cursor:"pointer" }}>
                        <div style={{ width:36, height:36, borderRadius:11, background:"rgba(244,114,182,0.15)", display:"flex", alignItems:"center", justifyContent:"center", flexShrink:0 }}>
                          <Heart size={16} color="#f472b6" strokeWidth={2}/>
                        </div>
                        <div style={{ flex:1, minWidth:0 }}>
                          <p style={{ fontSize:13, fontWeight:700, color: dark?"#f472b6":"#9d174d", whiteSpace:"nowrap", overflow:"hidden", textOverflow:"ellipsis" }}>{t.description}</p>
                          <p style={{ fontSize:11, color: dark?"#f9a8d4":"#be185d", opacity:0.8, marginTop:2 }}>{t.date}{t.location ? ` · ${t.location}` : ""}</p>
                        </div>
                        <p style={{ fontSize:13, fontWeight:800, color: dark?"#f472b6":"#be185d", flexShrink:0 }}>-{formatRp(t.amount)}</p>
                        <ChevronDown size={14} color="rgba(244,114,182,0.6)" strokeWidth={2} style={{ flexShrink:0, transform: activeDateId===t.id?"rotate(180deg)":"rotate(0deg)", transition:"transform 0.2s" }}/>
                      </div>
                      {activeDateId === t.id && (
                        <div style={{ display:"flex", gap:8, padding:"10px 12px", background: dark?"rgba(244,114,182,0.04)":"rgba(244,114,182,0.03)", borderTop:`1px solid ${dark?"rgba(244,114,182,0.12)":"rgba(244,114,182,0.15)"}` }}>
                          <button onClick={e => { e.stopPropagation(); haptic(); setEditItem(t.id); setForm({ date:t.date, amount:t.amount, amountDisplay:t.amount?Number(t.amount).toLocaleString("id-ID"):"", category:t.category, description:t.description, location:t.location||"" }); setShowForm(true); setActiveDateId(null); }}
                            style={{ flex:1, display:"flex", alignItems:"center", justifyContent:"center", gap:6, padding:"9px 0", borderRadius:12, background:"rgba(244,114,182,0.12)", border:"1.5px solid rgba(244,114,182,0.25)", color:"#f472b6", fontSize:13, fontWeight:700, cursor:"pointer" }}>
                            <Pencil size={14} strokeWidth={2}/> {lang==="en"?"Edit":"Edit"}
                          </button>
                          <button onClick={e => { e.stopPropagation(); haptic("error"); deleteTransaction(t.id); setActiveDateId(null); }}
                            style={{ flex:1, display:"flex", alignItems:"center", justifyContent:"center", gap:6, padding:"9px 0", borderRadius:12, background:"#ef444420", border:"1.5px solid #ef444440", color:"#f87171", fontSize:13, fontWeight:700, cursor:"pointer" }}>
                            <Trash2 size={14} strokeWidth={2}/> {L.delete}
                          </button>
                        </div>
                      )}
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        </div>
        )}

        {/* THEME PICKER MODAL */}
        {showThemePicker && (
          <div style={{ position:"fixed", inset:0, background:"rgba(0,0,0,0.6)", zIndex:200, display:"flex", alignItems:"flex-end", justifyContent:"center" }}
            onClick={e => { if (e.target===e.currentTarget) setShowThemePicker(false); }}>
            <div className="fi scroll-area modal-up" style={{ background:T.modalBg, borderRadius:"22px 22px 0 0", padding:22, paddingBottom:`22px + ${kbHeight > 0 ? kbHeight : 0}px`, width:"100%", maxHeight:"80vh", overflowY:"auto", }}>
              <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center", marginBottom:18 }}>
                <div style={{ display:"flex", alignItems:"center", gap:8 }}>
                  <Palette size={16} color={T.primaryText} strokeWidth={2}/>
                  <p style={{ fontSize:16, fontWeight:800, color:T.text }}>{L.colorTheme}</p>
                </div>
                <button onClick={() => setShowThemePicker(false)} style={{ background:T.btnG, border:"none", borderRadius:10, padding:"6px 14px", cursor:"pointer", fontSize:13, fontWeight:700, color:T.btnGText }}>{L.done}</button>
              </div>

              {/* Preset grid */}
              <p style={{ fontSize:11, fontWeight:700, color:T.textSub, letterSpacing:1, marginBottom:10 }}>{L.themePreset}</p>
              <div style={{ display:"grid", gridTemplateColumns:"repeat(3,1fr)", gap:10, marginBottom:20 }}>
                {THEME_PRESETS.filter(p => p.id !== "custom").map(preset => {
                  const isSelected = themePresetId === preset.id;
                  return (
                    <button key={preset.id} onClick={() => { haptic(); triggerThemeChange(() => setThemePresetId(preset.id)); }}
                      style={{
                        border: isSelected ? `2.5px solid ${preset.accent}` : `1.5px solid ${T.cardBorder}`,
                        borderRadius:14, padding:"12px 8px", cursor:"pointer",
                        background: isSelected ? `${preset.primary}22` : T.card,
                        display:"flex", flexDirection:"column", alignItems:"center", gap:6, }}>
                      {/* Color swatch */}
                      <div style={{ display:"flex", gap:4 }}>
                        <div style={{ width:18, height:18, borderRadius:6, background:preset.primary }} />
                        <div style={{ width:18, height:18, borderRadius:6, background:preset.accent }} />
                      </div>
                      <div style={{ display:"flex", alignItems:"center", gap:4 }}>
                        <PresetIcon name={preset.icon} size={12} color={isSelected ? preset.accent : T.textSub} strokeWidth={2.5}/>
                        <span style={{ fontSize:12, fontWeight:700, color: isSelected ? preset.accent : T.textSub }}>{L[THEME_LABELS[preset.id]]||preset.label}</span>
                      </div>
                      {isSelected && <span style={{ fontSize:10, color:preset.accent, fontWeight:700, display:"flex", alignItems:"center", gap:3 }}><CheckCircle size={10} color={preset.accent} strokeWidth={2.5}/> {L.active}</span>}
                    </button>
                  );
                })}
              </div>

              {/* Custom color picker */}
              <div style={{ background:T.catBg, borderRadius:16, padding:16, border:`1.5px solid ${T.catBorder}` }}>
                <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center", marginBottom:14 }}>
                  <div style={{ display:"flex", alignItems:"center", gap:6 }}>
                    <SlidersHorizontal size={13} color={T.primaryText} strokeWidth={2}/>
                    <p style={{ fontSize:13, fontWeight:800, color:T.text }}>{L.colorCustom}</p>
                  </div>
                  <button onClick={() => { haptic(); triggerThemeChange(() => setThemePresetId("custom")); }}
                    style={{ background: themePresetId==="custom" ? themePrimary : T.btnG, color: themePresetId==="custom" ? "white" : T.btnGText, border:"none", borderRadius:10, padding:"6px 12px", cursor:"pointer", fontSize:12, fontWeight:700 }}>
                    {themePresetId==="custom" ? <span style={{ display:"flex", alignItems:"center", gap:4 }}><CheckCircle size={12} strokeWidth={2.5}/> {L.active}</span> : L.use}
                  </button>
                </div>
                <div style={{ display:"grid", gridTemplateColumns:"1fr 1fr", gap:12 }}>
                  <div>
                    <p style={{ fontSize:11, fontWeight:700, color:T.textSub, marginBottom:6 }}>{L.primaryFull}</p>
                    <div style={{ display:"flex", alignItems:"center", gap:8 }}>
                      <div style={{ width:36, height:36, borderRadius:10, background:customPrimary, border:`2px solid ${T.cardBorder}`, flexShrink:0 }} />
                      <input type="color" value={customPrimary}
                        onChange={e => { triggerThemeChange(() => { setCustomPrimary(e.target.value); setThemePresetId("custom"); }); }}
                        style={{ width:"100%", height:36, borderRadius:10, border:`1.5px solid ${T.inpBorder}`, cursor:"pointer", background:"transparent", padding:2 }} />
                    </div>
                    <p style={{ fontSize:10, color:T.textSub, marginTop:4 }}>{customPrimary}</p>
                  </div>
                  <div>
                    <p style={{ fontSize:11, fontWeight:700, color:T.textSub, marginBottom:6 }}>{L.accentFull}</p>
                    <div style={{ display:"flex", alignItems:"center", gap:8 }}>
                      <div style={{ width:36, height:36, borderRadius:10, background:customAccent, border:`2px solid ${T.cardBorder}`, flexShrink:0 }} />
                      <input type="color" value={customAccent}
                        onChange={e => { triggerThemeChange(() => { setCustomAccent(e.target.value); setThemePresetId("custom"); }); }}
                        style={{ width:"100%", height:36, borderRadius:10, border:`1.5px solid ${T.inpBorder}`, cursor:"pointer", background:"transparent", padding:2 }} />
                    </div>
                    <p style={{ fontSize:10, color:T.textSub, marginTop:4 }}>{customAccent}</p>
                  </div>
                </div>
                {/* Preview */}
                <div style={{ marginTop:14, borderRadius:12, overflow:"hidden", border:`1.5px solid ${T.cardBorder}` }}>
                  <div style={{ background: themePresetId==="custom" ? customPrimary : themePrimary, padding:"10px 14px", display:"flex", justifyContent:"space-between", alignItems:"center" }}>
                    <span style={{ fontSize:12, fontWeight:800, color:"white" }}>Preview Header</span>
                    <div style={{ width:20, height:20, borderRadius:6, background: themePresetId==="custom" ? customAccent : themeAccent }} />
                  </div>
                  <div style={{ background:T.card, padding:"10px 14px", display:"flex", gap:8 }}>
                    <div style={{ flex:1, background: themePresetId==="custom" ? customAccent+"22" : themeAccent+"22", borderRadius:8, padding:"8px 10px" }}>
                      <p style={{ fontSize:10, color:T.textSub, fontWeight:700 }}>SALDO</p>
                      <p style={{ fontSize:14, fontWeight:800, color: themePresetId==="custom" ? customPrimary : themePrimary }}>Rp 500.000</p>
                    </div>
                    <button style={{ background:`linear-gradient(135deg,${themePresetId==="custom"?customAccent:themeAccent},${themePresetId==="custom"?customPrimary:themePrimary})`, color:"white", border:"none", borderRadius:8, padding:"8px 14px", fontSize:12, fontWeight:700, cursor:"default" }}>+ Tambah</button>
                  </div>
                </div>
              </div>
            </div>
          </div>
        )}
        </>
  );
}
