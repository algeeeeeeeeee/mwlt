import { ChevronDown, CirclePlus, DiamondPlus, Hash, Image, Pencil, Plus, Repeat, Save, Search, Trash2, Wallet, X } from "../icons.jsx";
import { formatRp, dateLabel, getCatLabel, groupByDate, haptic, parseRpInput, today } from "../utils/helpers.js";
import { CatIcon, SwipeRow } from "./ui.jsx";

export default function TabTransactions({ ctx }) {
  const {
    T, dark, lang, L,
    tabAnim, loaded, headerHeight,
    transactions, categories,
    filtered, filteredTotal,
    filterPeriod, setFilterPeriod,
    filterCat, setFilterCat,
    sortOrder, setSortOrder,
    themeAccent, themePrimary,
    editItem, setEditItem,
    form, setForm,
    setShowForm,
    deleteTransaction, undoDelete,
    startEdit,
    recurForm, setRecurForm,
    recurring, setRecurring,
    showRecurPanel, setShowRecurPanel,
    editRecurId, setEditRecurId,
    showToast,
    txTags, userTags,
    txReceipts,
    setShowTagModal,
  } = ctx;

  return (
        <>
          <div key="transactions" className={`fi${tabAnim ? " tab-enter" : ""}`} style={{ padding:"0 0 0" }}>
            <div style={{ padding:"14px 16px 0", paddingTop:`${headerHeight + 8}px`, paddingBottom:"16px" }}>

            <div style={{ position:"relative",marginBottom:10 }}>
              <Search size={15} color={T.textSub} strokeWidth={2} style={{ position:"absolute",left:13,top:"50%",transform:"translateY(-50%)",pointerEvents:"none" }}/>
              <input className="inp" placeholder={L.search} value={searchQuery} onChange={e => setSearchQuery(e.target.value)} style={{ paddingLeft:38,background:T.card,border:`1.5px solid ${T.cardBorder}`,color:T.text,borderRadius:14 }}/>
              {searchQuery && <button onClick={() => setSearchQuery("")} style={{ position:"absolute",right:11,top:"50%",transform:"translateY(-50%)",background:"none",border:"none",cursor:"pointer",display:"flex" }}><X size={14} color={T.textSub}/></button>}
            </div>

            <div style={{ display:"flex", gap:5, marginBottom:10, overflowX:"auto" }}>
              {[
                { val:filterPeriod, set:setFilterPeriod, opts:[["daily",L.filterToday],["weekly",L.filterWeek],["monthly",L.filterMonth]] },
                { val:sortOrder.startsWith("amt")?sortOrder:"amt-desc", set:v=>setSortOrder(v), opts:[["amt-desc",L.sortHighest],["amt-asc",L.sortLowest]] },
                { val:sortOrder.startsWith("date")?sortOrder:"date-desc", set:v=>setSortOrder(v), opts:[["date-desc",L.sortNewest],["date-asc",L.sortOldest]] },
              ].map(({ val, set, opts }, i) => {
                const label = opts.find(([v])=>v===val)?.[1] ?? opts[0][1];
                const isActive = i===0 ? true : sortOrder.startsWith(i===1?"amt":"date");
                return (
                  <div key={i} style={{ position:"relative", flexShrink:0 }}>
                    <select value={val} onChange={e=>set(e.target.value)}
                      style={{ appearance:"none", WebkitAppearance:"none", border:"none", outline:"none", cursor:"pointer", fontFamily:"inherit",
                        background: isActive ? themePrimary : dark?"rgba(255,255,255,0.06)":"rgba(0,0,0,0.05)",
                        color: isActive ? "white" : T.textSub,
                        fontSize:12, fontWeight:700, borderRadius:99,
                        padding:"6px 24px 6px 12px" }}>
                      {opts.map(([v,l]) => <option key={v} value={v}>{l}</option>)}
                    </select>
                    <ChevronDown size={10} color={isActive?"rgba(255,255,255,0.7)":T.textSub} strokeWidth={2.5}
                      style={{ position:"absolute", right:8, top:"50%", transform:"translateY(-50%)", pointerEvents:"none" }}/>
                  </div>
                );
              })}
            </div>
            <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center", marginBottom:10 }}>
              <p style={{ fontSize:12, color:T.textSub, fontWeight:600 }}>{filtered.length} {L.transactions_label}</p>
              <p key={filteredTotal} style={{ fontSize:12, fontWeight:700, color:"#f87171", animation:"count-up 0.3s cubic-bezier(0.25,0.46,0.45,0.94) both" }}>-{formatRp(filteredTotal)}</p>
            </div>

            {filtered.length === 0 ? (
              <div className="card" style={{ padding:"48px 20px 40px",textAlign:"center",background:T.card,border:`1px solid ${T.cardBorder}` }}>
                {searchQuery ? (
                  <>
                    <div style={{ display:"flex", justifyContent:"center", marginBottom:16 }}>
                      <div style={{ width:80, height:80, borderRadius:"50%", background:`linear-gradient(135deg,${themeAccent}18,${themePrimary}14)`, border:`1.5px solid ${themeAccent}25`, display:"flex", alignItems:"center", justifyContent:"center" }}>
                        <Search size={34} color={T.accentText} strokeWidth={1.5}/>
                      </div>
                    </div>
                    <p style={{ fontSize:16,fontWeight:900,color:T.text,marginBottom:6 }}>{L.noTxFound}</p>
                    <p style={{ fontSize:13,color:T.textSub,lineHeight:1.5 }}>{L.noTxFoundDesc} "{searchQuery}"</p>
                  </>
                ) : (
                  <>
                    <div style={{ display:"flex", justifyContent:"center", marginBottom:16 }}>
                      <div className="empty-float" style={{ width:88, height:88, borderRadius:26, background:`${themeAccent}14`, border:`1.5px solid ${themeAccent}30`, display:"flex", alignItems:"center", justifyContent:"center" }}>
                        <CirclePlus size={38} color={themeAccent} strokeWidth={1.5}/>
                      </div>
                    </div>
                    <p style={{ fontSize:18,fontWeight:900,color:T.text,marginBottom:8 }}>{lang==="en"?"No transactions yet":"Belum ada transaksi"}</p>
                    <p style={{ fontSize:13,color:T.textSub,marginBottom:24,lineHeight:1.6 }}>{lang==="en"?"Start tracking your spending today.":"Yuk mulai catat pengeluaran hari ini."}</p>
                    <button className="btn-p" style={{ display:"inline-flex",alignItems:"center",gap:7,padding:"13px 28px",fontSize:14,borderRadius:16, background:`linear-gradient(135deg,${themeAccent},${themePrimary})` }}
                      onClick={() => { haptic(); setShowForm(true); setEditItem(null); }}>
                      <Plus size={16} strokeWidth={2.5}/> {lang==="en"?"Add first transaction":"Catat transaksi pertama"}
                    </button>
                  </>
                )}
              </div>
            ) : (
              <div style={{ display:"flex", flexDirection:"column", gap:0 }}>
                {groupByDate(filtered).map(([date, txns], groupIdx) => (
                  <div key={date}>
                    {/* Date group header */}
                    <div style={{ display:"flex", alignItems:"center", gap:10, marginBottom:8, marginTop: groupIdx > 0 ? 16 : 0 }}>
                      <p style={{ fontSize:12, fontWeight:800, color:T.textSub, letterSpacing:0.3, whiteSpace:"nowrap" }}>{dateLabel(date, lang).toUpperCase()}</p>
                      <div style={{ flex:1, height:1, background:T.cardBorder }}/>
                      <p style={{ fontSize:11, fontWeight:600, color:T.textSub, whiteSpace:"nowrap" }}>{txns.length} {L.transactions_label}</p>
                    </div>
                    {/* Transactions in group */}
                    <div style={{ display:"flex", flexDirection:"column", gap:8 }}>
                      {txns.map((t, idx) => {
                        const cat = getCategory(t.category);
                        const globalIdx = filtered.indexOf(t);
                        return (
                          <SwipeRow key={t.id} onDelete={() => deleteTransaction(t.id)} onSwipeLock={locked => { swipeBlocked.current = locked; }} style={{ borderRadius:16, marginBottom:0 }} hintClass={swipeHintAnim && groupIdx===0 && idx===0 ? "swipe-hint-anim" : ""}>
                          <div className="card" style={{ padding:14, background:T.card, borderTop:`1px solid ${activeCardId===t.id ? T.accentText+"66" : T.cardBorder}`, borderRight:`1px solid ${activeCardId===t.id ? T.accentText+"66" : T.cardBorder}`, borderBottom:`1px solid ${activeCardId===t.id ? T.accentText+"66" : T.cardBorder}`, borderLeft:`3px solid ${cat.color}`, boxShadow:`0 1px 4px ${T.cardShadow}`, transition:"border-color 0.2s", overflow:"hidden" }}
                            onClick={() => setActiveCardId(activeCardId === t.id ? null : t.id)}>
                            <div style={{ display:"flex", alignItems:"center", gap:11 }}>
                              <div style={{ width:40, height:40, borderRadius:12, background:cat.color+"25", display:"flex", alignItems:"center", justifyContent:"center", flexShrink:0 }}><CatIcon iconKey={cat.icon} size={22} color={cat.color}/></div>
                              <div style={{ flex:1, minWidth:0 }}>
                                <p style={{ fontSize:14, fontWeight:700, color:T.text }}>{t.description}</p>
                                <p style={{ fontSize:11, color:T.textSub, marginTop:2 }}>{getCatLabel(cat, lang)}{t.location ? ` · ${t.location}` : ""}{t.note ? ` · ${t.note}` : ""}</p>
                                {/* Tag badges */}
                                {((txTags||{})[t.id]||[]).length > 0 && (
                                  <div style={{ display:"flex", gap:4, flexWrap:"wrap", marginTop:4 }}>
                                    {((txTags||{})[t.id]||[]).map(tagId => {
                                      const tag = (userTags||[]).find(tg=>tg.id===tagId);
                                      if (!tag) return null;
                                      return (
                                        <span key={tagId} style={{ display:"inline-flex", alignItems:"center", gap:3, padding:"2px 7px", borderRadius:99, background:tag.color+"18", border:`1px solid ${tag.color}40`, fontSize:10, fontWeight:700, color:tag.color }}>
                                          <Hash size={8} color={tag.color} strokeWidth={2.5}/>{tag.name}
                                        </span>
                                      );
                                    })}
                                    {txReceipts?.[t.id] && (
                                      <span style={{ display:"inline-flex", alignItems:"center", gap:3, padding:"2px 7px", borderRadius:99, background:T.catBg, border:`1px solid ${T.cardBorder}`, fontSize:10, fontWeight:700, color:T.textSub }}>
                                        <Image size={8} color={T.textSub} strokeWidth={2}/>{L.receiptPhoto}
                                      </span>
                                    )}
                                  </div>
                                )}
                                {txReceipts?.[t.id] && !((txTags||{})[t.id]||[]).length && (
                                  <div style={{ marginTop:4 }}>
                                    <span style={{ display:"inline-flex", alignItems:"center", gap:3, padding:"2px 7px", borderRadius:99, background:T.catBg, border:`1px solid ${T.cardBorder}`, fontSize:10, fontWeight:700, color:T.textSub }}>
                                      <Image size={8} color={T.textSub} strokeWidth={2}/>{L.receiptPhoto}
                                    </span>
                                  </div>
                                )}
                              </div>
                              <div style={{ display:"flex", flexDirection:"column", alignItems:"flex-end", gap:3 }}>
                                <p style={{ fontSize:13, fontWeight:800, color:"#f87171", textAlign:"right" }}>-{formatRp(t.amount)}</p>
                                <ChevronDown size={14} color={T.textMuted} strokeWidth={2} style={{ transform: activeCardId===t.id ? "rotate(180deg)" : "rotate(0deg)", transition:"transform 0.2s" }}/>
                              </div>
                            </div>
                            {activeCardId === t.id && (
                              <div style={{ display:"flex", gap:8, marginTop:12, paddingTop:12, borderTop:`1px solid ${T.cardBorder}` }}>
                                <button onClick={e => { e.stopPropagation(); startEdit(t); setActiveCardId(null); }}
                                  style={{ flex:1, display:"flex", alignItems:"center", justifyContent:"center", gap:6, padding:"9px 0", borderRadius:12, background:T.catBg, border:`1.5px solid ${T.cardBorder}`, color:T.text, fontSize:13, fontWeight:700, cursor:"pointer" }}>
                                  <Pencil size={14} strokeWidth={2}/> Edit
                                </button>
                                <button onClick={e => { e.stopPropagation(); haptic("error"); deleteTransaction(t.id); setActiveCardId(null); }}
                                  style={{ flex:1, display:"flex", alignItems:"center", justifyContent:"center", gap:6, padding:"9px 0", borderRadius:12, background:"#ef444420", border:"1.5px solid #ef444440", color:"#f87171", fontSize:13, fontWeight:700, cursor:"pointer" }}>
                                  <Trash2 size={14} strokeWidth={2}/> {L.delete}
                                </button>
                              </div>
                            )}
                          </div>
                          </SwipeRow>
                        );
                      })}
                    </div>
                  </div>
                ))}
              </div>
            )}

            {/* ── RECURRING collapsible ── */}
            <div style={{ marginTop:12, marginBottom:12 }}>
              {(() => {
                const pendingRecurs = recurring.filter(r => r.autoApply === false);
                return (
                  <div onClick={() => setShowRecurPanel(p=>!p)} style={{ display:"flex", alignItems:"center", gap:10, marginBottom: showRecurPanel ? 12 : 0, cursor:"pointer" }}>
                    <div style={{ flex:1, height:1, background:T.cardBorder }}/>
                    <div style={{ display:"flex", alignItems:"center", gap:6 }}>
                      <DiamondPlus size={11} color={T.textSub} strokeWidth={2}/>
                      <p style={{ fontSize:11, fontWeight:800, color:T.textSub, letterSpacing:1.5, whiteSpace:"nowrap" }}>{L.recurringTx}</p>
                      {pendingRecurs.length > 0 && (
                        <div style={{ background:"#ef4444", borderRadius:99, minWidth:16, height:16, display:"flex", alignItems:"center", justifyContent:"center", padding:"0 4px" }}>
                          <p style={{ fontSize:9, fontWeight:900, color:"white" }}>{pendingRecurs.length}</p>
                        </div>
                      )}
                      <ChevronDown size={11} color={T.textSub} strokeWidth={2.5} style={{ transform: showRecurPanel?"rotate(180deg)":"rotate(0)", transition:"transform 0.2s" }}/>
                    </div>
                    <div style={{ flex:1, height:1, background:T.cardBorder }}/>
                  </div>
                );
              })()}

              {showRecurPanel && <div className="card" style={{ padding:16, marginBottom:10, ...CS }}>
                <p style={{ fontSize:13, fontWeight:800, color:T.text, marginBottom:12, display:"flex", alignItems:"center", gap:6 }}>
                  <DiamondPlus size={15} color={themeAccent} strokeWidth={2}/> {L.addRecurring}
                </p>
                <div style={{ display:"flex", flexDirection:"column", gap:9 }}>
                  <input className="inp" placeholder={L.recurNamePlaceholder} value={recurForm.description}
                    onChange={e => setRecurForm(f => ({ ...f, description: e.target.value }))}
                    style={{ background:T.inp, border:`1.5px solid ${T.inpBorder}`, color:T.text }}/>
                  <div style={{ display:"flex", gap:8 }}>
                    <input className="inp" type="text" inputMode="numeric" placeholder="1.000.000" value={recurForm.amountDisplay||""} onFocus={e => e.target.select()}
                      onChange={e => { const {display,raw}=parseRpInput(e.target.value); setRecurForm(f => ({ ...f, amount: raw, amountDisplay: display })); }}
                      style={{ flex:2, background:T.inp, border:`1.5px solid ${T.inpBorder}`, color:T.text }}/>
                    <div style={{ flex:1, display:"flex", flexDirection:"column", gap:3 }}>
                      <p style={{ fontSize:10, fontWeight:700, color:T.textSub, paddingLeft:2 }}>{L.dayLabel}</p>
                      <input className="inp" type="number" min="1" max="31" placeholder={L.recurDay} value={recurForm.day} onFocus={e => e.target.select()}
                        onChange={e => setRecurForm(f => ({ ...f, day: e.target.value }))}
                        style={{ background:T.inp, border:`1.5px solid ${T.inpBorder}`, color:T.text }}/>
                    </div>
                  </div>
                  <select className="inp" value={recurForm.category}
                    onChange={e => setRecurForm(f => ({ ...f, category: e.target.value }))}
                    style={{ background:T.inp, border:`1.5px solid ${T.inpBorder}`, color:T.text }}>
                    {Object.entries(categories).map(([k,v]) => <option key={k} value={k}>{getCatLabel(v, lang)}</option>)}
                  </select>
                  <div onClick={() => { haptic(); setRecurForm(f => ({ ...f, autoApply: !f.autoApply })); }} style={{ display:"flex", alignItems:"center", gap:10, padding:"10px 14px", background:T.catBg, borderRadius:12, cursor:"pointer", userSelect:"none" }}>
                    <div style={{ width:20, height:20, borderRadius:6, border:`2px solid ${recurForm.autoApply ? themePrimary : T.catBorder}`, background: recurForm.autoApply ? themePrimary : "transparent", display:"flex", alignItems:"center", justifyContent:"center", flexShrink:0, transition:"all 0.15s" }}>
                      {recurForm.autoApply && <svg width="12" height="12" viewBox="0 0 12 12" fill="none"><path d="M2 6l3 3 5-5" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/></svg>}
                    </div>
                    <div>
                      <p style={{ fontSize:13, fontWeight:700, color:T.text }}>{L.autoApply}</p>
                      <p style={{ fontSize:11, color:T.textSub }}>{L.autoApplyDesc}</p>
                    </div>
                  </div>
                  <button className="btn-p" style={{ padding:"10px", fontSize:13 }} onClick={() => {
                    if (!recurForm.description || !recurForm.amount) return;
                    if (editRecurId) {
                      setRecurring(prev => prev.map(x => x.id === editRecurId ? { ...recurForm, id: editRecurId } : x));
                      setEditRecurId(null);
                      haptic("success"); showToast(lang==="en" ? "ok:Recurring updated" : L.toastRecurEdit);
                    } else {
                      setRecurring(prev => [...prev, { ...recurForm, id: Date.now() }]);
                      haptic("success"); showToast(lang==="en" ? "ok:Recurring transaction added" : L.toastRecurAdd);
                    }
                    setRecurForm({ description:"", amount:"", amountDisplay:"", category:"food", day:1, autoApply:true });
                  }}>{editRecurId ? <span style={{display:"flex",alignItems:"center",gap:6,justifyContent:"center"}}><Save size={14} strokeWidth={2}/>{L.done}</span> : "+ "+L.addRecurring}</button>
                </div>
              </div>}

              {showRecurPanel && (recurring.length === 0 ? (
                <div className="card" style={{ padding:"28px 20px", textAlign:"center", ...CSN }}>
                  <div style={{ display:"flex", justifyContent:"center", marginBottom:10 }}>
                    <div style={{ width:60, height:60, borderRadius:"50%", background:`linear-gradient(135deg,${themeAccent}22,${themePrimary}18)`, border:`1.5px solid ${themeAccent}30`, display:"flex", alignItems:"center", justifyContent:"center" }}>
                      <DiamondPlus size={26} color={T.accentText} strokeWidth={1.5}/>
                    </div>
                  </div>
                  <p style={{ fontSize:13, color:T.textSub }}>{L.noRecurring}</p>
                </div>
              ) : (
                <div className="card" style={{ ...CSN, borderRadius:18, overflow:"hidden", boxShadow:`0 1px 4px ${T.cardShadow}` }}>
                  {recurring.map((r, idx) => {
                    const cat = getCategory(r.category);
                    const isManual = r.autoApply === false;
                    return (
                      <div key={r.id} style={{ display:"flex", alignItems:"center", gap:12, padding:"13px 14px", borderBottom: idx < recurring.length-1 ? `1px solid ${T.cardBorder}` : "none", border: isManual ? `1px solid rgba(251,191,36,0.25)` : undefined, borderRadius: isManual ? 14 : 0, margin: isManual ? "4px" : 0 }}>
                        <div style={{ width:40, height:40, borderRadius:12, background:cat.color+"25", display:"flex", alignItems:"center", justifyContent:"center", flexShrink:0 }}>
                          <CatIcon iconKey={cat.icon} size={20} color={cat.color}/>
                        </div>
                        <div style={{ flex:1, minWidth:0 }}>
                          <p style={{ fontSize:14, fontWeight:700, color:T.text }}>{r.description}</p>
                          <p style={{ fontSize:11, color:T.textSub, marginTop:2 }}>{getCatLabel(cat, lang)} · {L.recurDay} {r.day} {L.recurEach} {r.autoApply !== false ? <span style={{color:themeAccent,fontWeight:700}}>{lang==="en"?"· Auto":"· Otomatis"}</span> : <span style={{color:"#fbbf24",fontWeight:700}}>· Manual</span>}</p>
                        </div>
                        <div style={{ display:"flex", flexDirection:"column", alignItems:"flex-end", gap:5 }}>
                          <p style={{ fontSize:13, fontWeight:800, color:"#f87171" }}>-{formatRp(Number(r.amount))}</p>
                          <div style={{ display:"flex", gap:5 }}>
                            {isManual && (
                              <button onClick={() => {
                                haptic("light");
                                const newTx = { id: Date.now(), date: today(), amount: Number(r.amount), category: r.category, description: r.description, location:"", note:"" };
                                setTransactions(prev => [newTx, ...prev]);
                                showToast("ok:" + (lang==="en" ? "Transaction recorded" : "Transaksi dicatat"));
                              }} style={{ background:"rgba(251,191,36,0.15)", border:"1px solid rgba(251,191,36,0.4)", borderRadius:8, padding:"5px 10px", cursor:"pointer", fontSize:10, fontWeight:800, color:"#fbbf24", fontFamily:"inherit" }}>
                                {lang==="en"?"Record":"Catat"}
                              </button>
                            )}
                            <button onClick={() => { haptic(); setRecurForm({ description:r.description, amount:r.amount, amountDisplay:r.amount?Number(r.amount).toLocaleString("id-ID"):"", category:r.category, day:r.day, autoApply:r.autoApply!==false }); setEditRecurId(r.id); }}
                              style={{ background:T.btnSm, border:`1.5px solid ${T.btnSmBdr}`, borderRadius:8, padding:"5px 8px", cursor:"pointer", display:"flex", alignItems:"center", justifyContent:"center" }}>
                              <Pencil size={13} strokeWidth={2} color={T.btnSmText}/>
                            </button>
                            <button onClick={() => { haptic(); setRecurring(prev => prev.filter(x => x.id !== r.id)); showToast(lang==="en"?"del:Recurring deleted":L.toastRecurDel); }}
                              style={{ background:T.btnD, border:`1.5px solid ${T.btnDBorder}`, borderRadius:8, padding:"5px 8px", cursor:"pointer", display:"flex", alignItems:"center", justifyContent:"center" }}>
                              <Trash2 size={13} strokeWidth={2} color={T.btnDText}/>
                            </button>
                          </div>
                        </div>
                      </div>
                    );
                  })}
                </div>
              ))}
            </div>

            </div>
          </div>
        </>
  );
}
