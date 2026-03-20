import { Camera, ChevronRight, Download, Hash, Package, Pencil, Trash2, Upload } from "../icons.jsx";
import { formatRp, getCatLabel, getMonth, parseRpInput, today } from "../utils/helpers.js";
import { CatIcon } from "./ui.jsx";

export default function TabSettings({ ctx }) {
  const {
    T, dark, lang, L, setLang,
    tabAnim, loaded, headerHeight,
    themeAccent, themePrimary,
    userName, setUserName,
    showNameEdit, setShowNameEdit,
    tempName, setTempName,
    profilePhoto, profileInputRef, handleProfilePhotoChange,
    categories, setCategories,
    catForm, setCatForm,
    editCatKey, setEditCatKey,
    showCatManager, setShowCatManager,
    showBudgetLimit, setShowBudgetLimit,
    budgets, setBudgets,
    overallBudget, setOverallBudget,
    income, setIncome,
    transactions, setTransactions,
    savingsGoals, setSavingsGoals,
    notifEnabled, weeklyNotif, weeklyNotifDay,
    setWeeklyNotif, setWeeklyNotifDay,
    showNotifModal, setShowNotifModal,
    showAppearanceModal, setShowAppearanceModal,
    showDataModal, setShowDataModal,
    navbarOffset, setNavbarOffset,
    followSystem, setFollowSystem,
    darkOverride, setDarkOverride,
    saveCat, startEditCat, deleteCat,
    handleNotification,
    exportCSV, exportPDFReport,
    ICON_OPTIONS, COLOR_OPTIONS,
    streak,
    userTags, showTagModal, setShowTagModal,
  } = ctx;

  return (
        <>
          <div key="settings" className={`fi${tabAnim ? " tab-enter" : ""}`} style={{ padding:"0" }}>
            <div style={{ padding:"14px 16px 0", paddingTop:`${headerHeight + 8}px`, paddingBottom:"16px" }}>

            {/* Profile section */}
            <div style={{ background:T.card, borderRadius:20, border:`1px solid ${T.cardBorder}`, overflow:"hidden", marginBottom:12, boxShadow:`0 1px 4px ${T.cardShadow}` }}>
              <div style={{ display:"flex", alignItems:"center", gap:14, padding:"16px 16px" }}>
                <div style={{ position:"relative", flexShrink:0 }}>
                  <div style={{ width:56, height:56, borderRadius:50, border:`2.5px solid ${T.cardBorder}`, overflow:"hidden", cursor:"pointer" }}
                    onClick={() => profileInputRef.current && profileInputRef.current.click()}>
                    <img src={profilePhoto || "/meow.png"} alt="" style={{ width:56, height:56, objectFit:"cover" }}/>
                  </div>
                  <div style={{ position:"absolute", bottom:0, right:0, width:18, height:18, borderRadius:50, background:themePrimary, border:`2px solid ${T.bg}`, display:"flex", alignItems:"center", justifyContent:"center" }}>
                    <Camera size={9} color="white" strokeWidth={2.5}/>
                  </div>
                  <input ref={profileInputRef} type="file" accept="image/*" style={{ display:"none" }} onChange={handleProfilePhotoChange}/>
                </div>
                <div style={{ flex:1 }}>
                  <p style={{ fontSize:11, color:T.textSub, fontWeight:600, marginBottom:2 }}>{L.profileName}</p>
                  {showNameEdit ? (
                    <div style={{ display:"flex", gap:6, alignItems:"center" }}>
                      <input autoFocus className="inp" placeholder={L.namePlaceholder} value={tempName}
                        onChange={e => setTempName(e.target.value)}
                        onKeyDown={e => { if(e.key==="Enter"){ setUserName(tempName); setShowNameEdit(false); } }}
                        style={{ fontSize:16, fontWeight:800, color:T.text, background:"transparent", border:"none", borderBottom:`2px solid ${themeAccent}`, borderRadius:0, padding:"2px 0", width:130, outline:"none" }}/>
                      <button onClick={() => { setUserName(tempName); setShowNameEdit(false); showToast("ok:"+L.nameSaved); }}
                        style={{ background:themePrimary, border:"none", borderRadius:8, padding:"4px 10px", color:"white", fontSize:12, fontWeight:700, cursor:"pointer" }}>OK</button>
                    </div>
                  ) : (
                    <div style={{ display:"flex", alignItems:"center", gap:5, cursor:"pointer" }} onClick={() => { setTempName(userName); setShowNameEdit(true); }}>
                      <p style={{ fontSize:17, fontWeight:900, color:T.text }}>{userName || L.tapName}</p>
                      <Pencil size={12} strokeWidth={2} color={T.textSub}/>
                    </div>
                  )}
                </div>
              </div>
            </div>

            <div style={{ background:T.card, borderRadius:20, border:`1px solid ${T.cardBorder}`, overflow:"hidden", marginBottom:12, boxShadow:`0 1px 4px ${T.cardShadow}` }}>
              <button onClick={() => setShowAppearanceModal(true)}
                style={{ display:"flex", alignItems:"center", justifyContent:"space-between", padding:"14px 16px", width:"100%", ...IBN, fontFamily:"inherit" }}>
                <div style={{ textAlign:"left" }}>
                  <p style={{ fontSize:14, fontWeight:700, color:T.text }}>{L.displayMode}</p>
                  <p style={{ fontSize:11, color:T.textSub }}>{dark ? L.darkActive : L.lightActive} · {THEME_PRESETS.find(p=>p.id===themePresetId)?.label||"Custom"}</p>
                </div>
                <ChevronRight size={16} color={T.textSub} strokeWidth={2.5}/>
              </button>
            </div>

            <div style={{ background:T.card, borderRadius:20, border:`1px solid ${T.cardBorder}`, overflow:"hidden", marginBottom:12, boxShadow:`0 1px 4px ${T.cardShadow}` }}>
              <button onClick={() => setShowNotifModal(true)}
                style={{ display:"flex", alignItems:"center", justifyContent:"space-between", padding:"14px 16px", width:"100%", ...IBN, fontFamily:"inherit" }}>
                <div style={{ textAlign:"left" }}>
                  <div style={{ display:"flex", alignItems:"center", gap:6 }}>
                    <p style={{ fontSize:14, fontWeight:700, color:T.text }}>{lang==="en"?"Notifications":"Notifikasi"}</p>
                    {!notifEnabled && <div style={{ width:7, height:7, borderRadius:"50%", background:"#ef4444", flexShrink:0 }}/>}
                  </div>
                  <p style={{ fontSize:11, color:T.textSub }}>{notifEnabled ? L.notifActive : L.notifOff}</p>
                </div>
                <ChevronRight size={16} color={T.textSub} strokeWidth={2.5}/>
              </button>
            </div>


            {/* Cicilan */}
            <div style={{ background:T.card, borderRadius:20, border:`1px solid ${T.cardBorder}`, overflow:"hidden", marginBottom:12, boxShadow:`0 1px 4px ${T.cardShadow}` }}>
              <button onClick={() => setShowCicilanModal(true)}
                style={{ display:"flex", alignItems:"center", justifyContent:"space-between", padding:"14px 16px", width:"100%", ...IBN, fontFamily:"inherit" }}>
                <div style={{ display:"flex", alignItems:"center", gap:10, textAlign:"left" }}>
                  <CreditCard size={16} color={T.accentText} strokeWidth={2}/>
                  <div>
                    <p style={{ fontSize:14, fontWeight:700, color:T.text }}>{L.cicilan}</p>
                    <p style={{ fontSize:11, color:T.textSub }}>{cicilan.length > 0 ? `${cicilan.length} ${lang==="en"?"active items":"item aktif"}` : L.noCicilan}</p>
                  </div>
                </div>
                <ChevronRight size={16} color={T.textSub} strokeWidth={2.5}/>
              </button>
            </div>

            {/* Reminder */}
            <div style={{ background:T.card, borderRadius:20, border:`1px solid ${T.cardBorder}`, overflow:"hidden", marginBottom:12, boxShadow:`0 1px 4px ${T.cardShadow}` }}>
              <button onClick={() => setShowReminderModal(true)}
                style={{ display:"flex", alignItems:"center", justifyContent:"space-between", padding:"14px 16px", width:"100%", ...IBN, fontFamily:"inherit" }}>
                <div style={{ display:"flex", alignItems:"center", gap:10, textAlign:"left" }}>
                  <Bell size={16} color={T.accentText} strokeWidth={2}/>
                  <div>
                    <p style={{ fontSize:14, fontWeight:700, color:T.text }}>{L.reminderTitle}</p>
                    <p style={{ fontSize:11, color:T.textSub }}>{L.reminderDesc}</p>
                  </div>
                </div>
                <ChevronRight size={16} color={T.textSub} strokeWidth={2.5}/>
              </button>
            </div>

            {/* Kategori — 1 card: Limit + Kelola + Tag */}
            <div style={{ background:T.card, borderRadius:20, border:`1px solid ${T.cardBorder}`, overflow:"hidden", marginBottom:12, boxShadow:`0 1px 4px ${T.cardShadow}` }}>
              <button onClick={() => setShowBudgetLimit(true)}
                style={{ display:"flex", alignItems:"center", justifyContent:"space-between", padding:"14px 16px", width:"100%", ...IBN, fontFamily:"inherit", borderBottom:`1px solid ${T.cardBorder}` }}>
                <div style={{ textAlign:"left" }}>
                  <p style={{ fontSize:14, fontWeight:700, color:T.text }}>{lang==="en"?"Per-Category Limits":"Limit per Kategori"}</p>
                  <p style={{ fontSize:11, color:T.textSub }}>{L.budgetLimitDesc}</p>
                </div>
                <ChevronRight size={16} color={T.textSub} strokeWidth={2.5}/>
              </button>
              <button onClick={() => setShowCatManager(true)}
                style={{ display:"flex", alignItems:"center", justifyContent:"space-between", padding:"14px 16px", width:"100%", ...IBN, fontFamily:"inherit", borderBottom:`1px solid ${T.cardBorder}` }}>
                <div style={{ textAlign:"left" }}>
                  <p style={{ fontSize:14, fontWeight:700, color:T.text }}>{L.manageCategory}</p>
                  <p style={{ fontSize:11, color:T.textSub }}>{Object.keys(categories).length} {lang==="en"?"active categories":"kategori aktif"}</p>
                </div>
                <ChevronRight size={16} color={T.textSub} strokeWidth={2.5}/>
              </button>
              <button onClick={() => setShowTagModal(true)}
                style={{ display:"flex", alignItems:"center", justifyContent:"space-between", padding:"14px 16px", width:"100%", ...IBN, fontFamily:"inherit" }}>
                <div style={{ display:"flex", alignItems:"center", gap:10 }}>
                  <Hash size={14} color={T.accentText} strokeWidth={2}/>
                  <div style={{ textAlign:"left" }}>
                    <p style={{ fontSize:14, fontWeight:700, color:T.text }}>{L.tags}</p>
                    <p style={{ fontSize:11, color:T.textSub }}>{userTags.length > 0 ? `${userTags.length} tag` : L.noTags}</p>
                  </div>
                </div>
                <ChevronRight size={16} color={T.textSub} strokeWidth={2.5}/>
              </button>
            </div>

            {/* Data */}
            <div style={{ background:T.card, borderRadius:20, border:`1px solid ${T.cardBorder}`, overflow:"hidden", marginBottom:8, boxShadow:`0 1px 4px ${T.cardShadow}` }}>
              <button onClick={() => setShowDataModal(true)}
                style={{ display:"flex", alignItems:"center", justifyContent:"space-between", padding:"14px 16px", width:"100%", ...IBN, fontFamily:"inherit" }}>
                <div style={{ textAlign:"left" }}>
                  <p style={{ fontSize:14, fontWeight:700, color:T.text }}>Data</p>
                  <p style={{ fontSize:11, color:T.textSub }}>{lang==="en"?"Backup, restore & reset":L.dataSubtitle||"Backup, pulihkan & reset"}</p>
                </div>
                <ChevronRight size={16} color={T.textSub} strokeWidth={2.5}/>
              </button>
            </div>

          </div>
        </div>
        )}

        {/* BUDGET LIMIT MODAL */}
        {showBudgetLimit && (
          <div style={{ position:"fixed", inset:0, background:"rgba(0,0,0,0.6)", zIndex:200, display:"flex", alignItems:"flex-end", justifyContent:"center" }}
            onClick={e => { if (e.target===e.currentTarget) setShowBudgetLimit(false); }}>
            <div className="fi scroll-area modal-up" style={{ background:T.modalBg, borderRadius:"22px 22px 0 0", padding:22, paddingBottom:`22px + ${kbHeight > 0 ? kbHeight : 0}px`, width:"100%", maxHeight:"88vh", overflowY:"auto" }}>
              <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center", marginBottom:16 }}>
                <p style={{ fontSize:16, fontWeight:800, color:T.text }}>{L.budgetLimit}</p>
                <button onClick={() => setShowBudgetLimit(false)}
                  style={{ background:T.btnG, border:"none", borderRadius:10, padding:"6px 14px", cursor:"pointer", fontSize:13, fontWeight:700, color:T.btnGText }}>{L.done}</button>
              </div>
              <p style={{ fontSize:12, color:T.textSub, marginBottom:16 }}>{L.budgetLimitDesc}</p>
              <div style={{ display:"flex", flexDirection:"column", gap:12 }}>
                {Object.entries(categories).map(([k, cat]) => {
                  const spent = transactions.filter(t => t.category===k && getMonth(t.date)===currentMonth).reduce((a,t) => a+t.amount, 0);
                  const limit = budgets[k] || 0;
                  const pct = limit > 0 ? Math.min(100, Math.round(spent/limit*100)) : 0;
                  const over = limit > 0 && spent >= limit;
                  return (
                    <div key={k} style={{ background:T.card, borderRadius:16, padding:"14px 14px 12px", border:`1.5px solid ${over?"#f87171":T.cardBorder}` }}>
                      <div style={{ display:"flex", alignItems:"center", gap:10, marginBottom: limit>0 ? 10 : 0 }}>
                        <div style={{ width:36, height:36, borderRadius:12, background:cat.color+"22", display:"flex", alignItems:"center", justifyContent:"center", flexShrink:0 }}>
                          <CatIcon iconKey={cat.icon} size={17} color={cat.color}/>
                        </div>
                        <div style={{ flex:1, minWidth:0 }}>
                          <p style={{ fontSize:14, fontWeight:700, color:T.text }}>{getCatLabel(cat, lang)}</p>
                          {limit > 0 && (
                            <p style={{ fontSize:11, color: over?"#ef4444":T.textSub, fontWeight:600 }}>
                              {formatRp(spent)} / {formatRp(limit)} · {pct}%
                            </p>
                          )}
                        </div>
                        <input type="text" inputMode="numeric" placeholder={L.setLimit} value={budgetsDisplay[k]||""} onFocus={e => e.target.select()}
                          onChange={e => { const {display,raw}=parseRpInput(e.target.value); setBudgets(prev => ({ ...prev, [k]: raw })); setBudgetsDisplay(prev => ({ ...prev, [k]: display })); }}
                          style={{ width:110, padding:"8px 12px", borderRadius:12, border:`1.5px solid ${over?"#f87171":T.inpBorder}`, background:T.inp, color:T.text, fontSize:14, fontFamily:"inherit", outline:"none", textAlign:"right", fontWeight:700 }}/>
                      </div>
                      {limit > 0 && (
                        <div style={{ height:6, borderRadius:6, background:T.catBg, overflow:"hidden" }}>
                          <div style={{ height:"100%", width:`${pct}%`, background: over?"#ef4444":pct>80?"#f59e0b":themeAccent, borderRadius:6, transition:"width 0.4s ease" }}/>
                        </div>
                      )}
                    </div>
                  );
                })}
              </div>
            </div>
          </div>
        )}

        {/* CATEGORY MANAGER MODAL */}
        {showCatManager && (
          <div style={{ position:"fixed", inset:0, background:"rgba(0,0,0,0.6)", zIndex:200, display:"flex", alignItems:"flex-end", justifyContent:"center" }}
            onClick={e => { if (e.target===e.currentTarget) { setShowCatManager(false); setEditCatKey(null); setCatForm({ label:"", icon:"package", color:"#94a3b8" }); } }}>
            <div className="fi scroll-area modal-up" style={{ background:T.modalBg, borderRadius:"22px 22px 0 0", padding:22, paddingBottom:`22px + ${kbHeight > 0 ? kbHeight : 0}px`, width:"100%", maxHeight:"85vh", overflowY:"auto" }}>
              <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center", marginBottom:16 }}>
                <p style={{ fontSize:16, fontWeight:800, color:T.text }}>{L.manageCategory}</p>
                <button onClick={() => { setShowCatManager(false); setEditCatKey(null); setCatForm({ label:"", icon:"package", color:"#94a3b8" }); }}
                  style={{ background:T.btnG, border:"none", borderRadius:10, padding:"6px 14px", cursor:"pointer", fontSize:13, fontWeight:700, color:T.btnGText }}>{L.done}</button>
              </div>
              <div style={{ background:T.catBg, borderRadius:16, padding:16, marginBottom:16, border:`1.5px solid ${T.catBorder}` }}>
                <p style={{ fontSize:13, fontWeight:800, color:T.text, marginBottom:11 }}>{editCatKey ? L.editCategory : L.addCategory}</p>
                <input className="inp" placeholder={L.catName} value={catForm.label} onChange={e => setCatForm(f => ({ ...f, label: e.target.value }))} style={{ marginBottom:11, background:T.inp, border:`1.5px solid ${T.inpBorder}`, color:T.text }} />
                <p style={{ fontSize:11, fontWeight:700, color:T.textSub, marginBottom:7 }}>{L.pickIcon}</p>
                <div style={{ display:"grid", gridTemplateColumns:"repeat(7,1fr)", gap:5, marginBottom:11 }}>
                  {ICON_OPTIONS.map(ic => {
                    const Icon = LUCIDE_MAP[ic] || Package;
                    return (
                      <button key={ic} className={`icon-btn${catForm.icon===ic?" sel":""}`} onClick={() => setCatForm(f => ({ ...f, icon: ic }))}
                        style={{ background: catForm.icon===ic ? catForm.color+"22" : T.catBg, borderColor: catForm.icon===ic ? catForm.color : "transparent" }}>
                        <Icon size={16} color={catForm.icon===ic ? catForm.color : T.textSub} strokeWidth={2}/>
                      </button>
                    );
                  })}
                </div>
                <p style={{ fontSize:11, fontWeight:700, color:T.textSub, marginBottom:7 }}>{L.pickColor}</p>
                <div style={{ display:"flex", gap:8, flexWrap:"wrap", marginBottom:8 }}>
                  {COLOR_OPTIONS.map(cl => (
                    <div key={cl} className={`cdot${catForm.color===cl?" sel":""}`} style={{ background:cl }} onClick={() => setCatForm(f => ({ ...f, color: cl }))} />
                  ))}
                </div>
                <div style={{ display:"flex", alignItems:"center", gap:8, marginBottom:12 }}>
                  <input type="color" value={catForm.color} onChange={e => setCatForm(f => ({ ...f, color: e.target.value }))}
                    style={{ width:36, height:36, borderRadius:10, border:`1.5px solid ${T.cardBorder}`, cursor:"pointer", padding:2, background:T.inp }}/>
                  <p style={{ fontSize:12, color:T.textSub }}>{L.orCustom}</p>
                  <div style={{ flex:1, display:"flex", alignItems:"center", gap:8, padding:"8px 12px", borderRadius:12, background:catForm.color+"18", border:`1.5px solid ${catForm.color}44` }}>
                    {(() => { const Icon = LUCIDE_MAP[catForm.icon] || Package; return <Icon size={16} color={catForm.color} strokeWidth={2}/>; })()}
                    <p style={{ fontSize:12, fontWeight:700, color:catForm.color }}>{catForm.label || L.previewLabel}</p>
                  </div>
                </div>
                <div style={{ display:"flex", gap:8 }}>
                  <button className="btn-p" style={{ flex:1 }} onClick={saveCat}>{editCatKey ? L.save : L.add}</button>
                  {editCatKey && <button className="btn-g" style={{ flex:1, background:T.btnG, color:T.btnGText, border:`1.5px solid ${T.btnGBorder}` }} onClick={() => { setEditCatKey(null); setCatForm({ label:"", icon:"package", color:"#94a3b8" }); }}>{L.cancel}</button>}
                </div>
              </div>
              <p style={{ fontSize:12, fontWeight:700, color:T.textSub, marginBottom:8, padding:"0 4px" }}>{L.activeCategories} ({Object.keys(categories).length})</p>
              <div style={{ display:"flex", flexDirection:"column", gap:6, padding:"0 4px 4px" }}>
                {Object.entries(categories).map(([key, cat]) => (
                  <div key={key} style={{ display:"flex", alignItems:"center", gap:11, padding:"11px 13px", background:T.catItem, borderRadius:14, border:`1px solid ${T.catItemBdr}` }}>
                    <div style={{ width:34, height:34, borderRadius:10, background:cat.color+"33", display:"flex", alignItems:"center", justifyContent:"center" }}><CatIcon iconKey={cat.icon} size={16} color={cat.color}/></div>
                    <div style={{ flex:1 }}>
                      <p style={{ fontSize:13, fontWeight:700, color:T.text }}>{getCatLabel(cat, lang)}</p>
                      <p style={{ fontSize:11, color:T.textSub }}>{transactions.filter(t => t.category===key).length} {L.transactions_label}</p>
                    </div>
                    <div style={{ display:"flex", gap:6 }}>
                      <button className="btn-sm" style={{ padding:"6px 9px", background:T.btnSm, color:T.btnSmText, border:`1.5px solid ${T.btnSmBdr}`, display:"flex", alignItems:"center", justifyContent:"center" }} onClick={() => startEditCat(key)}><Pencil size={13} strokeWidth={2} color={T.btnSmText}/></button>
                      <button className="btn-d" style={{ padding:"6px 9px", background:T.btnD, color:T.btnDText, border:`1.5px solid ${T.btnDBorder}`, display:"flex", alignItems:"center", justifyContent:"center" }} onClick={() => deleteCat(key)}><Trash2 size={13} strokeWidth={2} color={T.btnDText}/></button>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}

        {/* DATA MODAL */}
        {showDataModal && (
          <div style={{ position:"fixed", inset:0, background:"rgba(0,0,0,0.6)", zIndex:200, display:"flex", alignItems:"flex-end", justifyContent:"center" }}
            onClick={e => { if (e.target===e.currentTarget) setShowDataModal(false); }}>
            <div className="fi scroll-area modal-up" style={{ background:T.modalBg, borderRadius:"22px 22px 0 0", padding:22, paddingBottom:40, width:"100%", maxWidth:480, boxSizing:"border-box" }}>
              <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center", marginBottom:20 }}>
                <p style={{ fontSize:16, fontWeight:800, color:T.text }}>Data</p>
                <button onClick={() => setShowDataModal(false)} style={{ background:T.btnG, border:"none", borderRadius:10, padding:"6px 14px", cursor:"pointer", fontSize:13, fontWeight:700, color:T.btnGText }}>{L.done}</button>
              </div>
              <div style={{ display:"flex", flexDirection:"column", gap:10 }}>
                <button onClick={() => {
                    try {
                      const b={version:1,exportedAt:new Date().toISOString(),transactions,income,goals:savingsGoals,budgets,categories};
                      const blob=new Blob([JSON.stringify(b,null,2)],{type:"application/json"});
                      const url=URL.createObjectURL(blob);
                      const a=document.createElement("a");
                      a.href=url; a.download=`meowlett-backup-${today()}.json`;
                      document.body.appendChild(a); a.click();
                      setTimeout(()=>{ document.body.removeChild(a); URL.revokeObjectURL(url); },100);
                      showToast("ok:"+L.backupOk);
                    } catch(e){ showToast("warn:Gagal backup: "+e.message); }
                  }}
                  style={{ width:"100%", padding:"14px", borderRadius:16, background:`${themeAccent}15`, border:`1.5px solid ${themeAccent}40`, color:T.accentText, fontSize:14, fontWeight:800, cursor:"pointer", display:"flex", alignItems:"center", gap:12, boxSizing:"border-box", fontFamily:"inherit" }}>
                  <div style={{ width:38, height:38, borderRadius:12, background:`${themeAccent}20`, display:"flex", alignItems:"center", justifyContent:"center", flexShrink:0 }}><Download size={18} strokeWidth={2} color={T.accentText}/></div>
                  <div style={{ textAlign:"left" }}><p style={{ fontSize:14, fontWeight:800, color:T.accentText }}>{L.backupData}</p><p style={{ fontSize:11, color:T.accentText, opacity:0.7 }}>{lang==="en"?"Download all data as JSON":"Unduh semua data sebagai JSON"}</p></div>
                </button>
                <button onClick={() => document.getElementById("restore-input").click()}
                  style={{ width:"100%", padding:"14px", borderRadius:16, background:T.catBg, border:`1.5px solid ${T.cardBorder}`, color:T.text, fontSize:14, fontWeight:800, cursor:"pointer", display:"flex", alignItems:"center", gap:12, boxSizing:"border-box", fontFamily:"inherit" }}>
                  <div style={{ width:38, height:38, borderRadius:12, ...CSN, display:"flex", alignItems:"center", justifyContent:"center", flexShrink:0 }}><Upload size={18} strokeWidth={2} color={T.text}/></div>
                  <div style={{ textAlign:"left" }}><p style={{ fontSize:14, fontWeight:800, color:T.text }}>{L.restoreBackup}</p><p style={{ fontSize:11, color:T.textSub }}>{L.restoreDesc}</p></div>
                </button>
                <input id="restore-input" type="file" accept=".json" style={{ display:"none" }} onChange={e => {
                    const file=e.target.files?.[0]; if(!file) return;
                    const reader=new FileReader();
                    reader.onload=ev => {
                      try {
                        const data=JSON.parse(ev.target.result);
                        if(!data.transactions) throw new Error("invalid");
                        const msg = lang==="en"
                          ? "Restore this backup? Current data will be replaced."
                          : "Restore backup ini? Data saat ini akan diganti.";
                        showConfirm(msg, () => {
                          isRestoringRef.current = true;
                          if(data.transactions) setTransactions(data.transactions);
                          if(data.income) setIncome(data.income);
                          if(data.goals) setSavingsGoals(data.goals);
                          if(data.budgets) setBudgets(data.budgets);
                          if(data.categories) setCategories(data.categories);
                          setTimeout(() => { isRestoringRef.current = false; }, 500);
                          showToast(lang==="en"?"ok:Backup restored!":"ok:Backup berhasil dipulihkan!");
                          setShowDataModal(false);
                        });
                      } catch(err) {
                        showToast(lang==="en"?"warn:Invalid backup file":"warn:File backup tidak valid");
                      }
                    };
                    reader.readAsText(file);
                    e.target.value="";
                  }}/>
                <div style={{ height:1, background:T.cardBorder, margin:"4px 0" }}/>
                <button onClick={() => { showConfirm(L.resetConfirm, () => { try{localStorage.clear();}catch{} setTransactions([]); setIncome(5000000); setSavingsGoals([]); setBudgets({}); setCategories(DEFAULT_CATEGORIES); showToast("ok:Data berhasil direset"); setShowDataModal(false); }); }}
                  style={{ width:"100%", padding:"14px", borderRadius:16, background:"#ef444412", border:"1.5px solid #ef444435", color:"#ef4444", fontSize:14, fontWeight:800, cursor:"pointer", display:"flex", alignItems:"center", gap:12, boxSizing:"border-box", fontFamily:"inherit" }}>
                  <div style={{ width:38, height:38, borderRadius:12, background:"#ef444420", display:"flex", alignItems:"center", justifyContent:"center", flexShrink:0 }}><Trash2 size={18} strokeWidth={2} color="#ef4444"/></div>
                  <div style={{ textAlign:"left" }}><p style={{ fontSize:14, fontWeight:800, color:"#ef4444" }}>{L.resetData}</p><p style={{ fontSize:11, color:"#ef4444", opacity:0.7 }}>{lang==="en"?"Delete all data permanently":"Hapus semua data permanen"}</p></div>
                </button>
              </div>
            </div>
          </div>
        )}
        </>
  );
}
