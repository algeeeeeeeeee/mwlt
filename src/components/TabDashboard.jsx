import { AlertCircle, AlertTriangle, ArrowRight, Flame, PiggyBank, Plus, Pencil, Save, TrendingUp, Wallet, Zap, CheckCircle, X, BarChart2 } from "../icons.jsx";
import { formatRp, dateLabel, getCatLabel, getMonth, haptic, parseRpInput, today } from "../utils/helpers.js";
import { darken } from "../utils/theme.js";
import AnimatedNumber from "./AnimatedNumber.jsx";
import DonutChart from "./DonutChart.jsx";
import { CatIcon } from "./ui.jsx";

export default function TabDashboard({ ctx }) {
  const {
    T, dark, lang, L,
    tabAnim, loaded, headerHeight,
    income, totalExpense, balance, savePct, monthlySave,
    balanceCardRef,
    themeAccent, themePrimary,
    transactions, categories, recentTxns, recentCount, setRecentCount,
    donutData, catBreakdown, sparkline7, monthPrediction, avgMonthlySaved,
    streak, weeklyInsight,
    savingsGoals, setSavingsGoals,
    overallBudget,
    quickAddGoalId, setQuickAddGoalId,
    quickAddAmtDisplay, setQuickAddAmtDisplay, setQuickAddAmt,
    setShowOverallBudgetModal,
    setEditingGoal, setGoalForm,
    setEditItem, setForm, setShowForm,
    setTempIncome, setTempIncomeDisplay,
    setIncomeAdj, setIncomeAdjDisplay, setEditIncome,
    setTempOverallBudget, setTempOverallBudgetDisplay,
    setBudgets, setBudgetsDisplay,
    changeTab,
  } = ctx;

  return (
        <>
          <div key="dashboard" className={`fi${tabAnim ? " tab-enter" : ""}`} style={{ padding:"16px 16px 0", paddingTop:`${headerHeight + 16}px`, paddingBottom:"16px" }}>
            {!loaded && (
              <div style={{ display:"flex",flexDirection:"column",gap:12 }}>
                {[120,80,80,80].map((h,i) => <div key={i} className="skeleton" style={{ height:h,background:T.card,borderRadius:20 }}/>)}
              </div>
            )}

            {/* Balance card — Minimal */}
            {(() => {
              const realSisa = income - totalExpense;
              const isNegative = realSisa < 0;
              const sisaUang = Math.max(0, realSisa);
              const expPct = income > 0 ? Math.min(100, Math.round((totalExpense / income) * 100)) : 0;
              const budgetPct = Math.max(0, 100 - expPct);
              const barColor = isNegative || expPct >= 100 ? "#f87171" : expPct > 85 ? "#f87171" : expPct > 65 ? "#fbbf24" : "rgba(255,255,255,0.85)";
              const now2 = new Date();
              const tglLabel = now2.toLocaleDateString(lang==="en"?"en-GB":"id-ID", { weekday:"short", day:"numeric", month:"short", year:"numeric" });
              return (
                <div ref={balanceCardRef} className="card-pop" style={{ animationDelay:"0ms", background:`linear-gradient(135deg,${darken(themePrimary,0.5)},${darken(themePrimary,0.25)},${themePrimary})`, borderRadius:22, padding:"24px 24px 20px", marginBottom:14, position:"relative", overflow:"hidden", boxShadow:`0 2px 8px rgba(0,0,0,0.22),0 0 0 1px rgba(255,255,255,0.06)` }}>

                  {/* Full shape decorations */}
                  {(() => { const [pr,pg,pb] = [parseInt(themePrimary.slice(1,3),16),parseInt(themePrimary.slice(3,5),16),parseInt(themePrimary.slice(5,7),16)]; const [ar,ag,ab] = [parseInt(themeAccent.slice(1,3),16),parseInt(themeAccent.slice(3,5),16),parseInt(themeAccent.slice(5,7),16)]; return (<>
                    <div style={{ position:"absolute", bottom:-65, right:-65, width:240, height:240, borderRadius:"50%", background:`rgba(${pr},${pg},${pb},0.55)`, pointerEvents:"none" }}/>
                    <div style={{ position:"absolute", top:-55, right:-15, width:160, height:250, borderRadius:52, transform:"rotate(-22deg)", background:`rgba(${ar},${ag},${ab},0.18)`, pointerEvents:"none" }}/>
                    <div style={{ position:"absolute", top:-40, left:-40, width:145, height:145, borderRadius:"50%", background:`rgba(${ar},${ag},${ab},0.1)`, pointerEvents:"none" }}/>
                    <div style={{ position:"absolute", top:"36%", left:"33%", width:90, height:90, borderRadius:"50%", background:`rgba(${pr},${pg},${pb},0.25)`, pointerEvents:"none" }}/>
                  </>); })()}

                  {/* Top: pemasukan kiri (tap edit), tanggal kanan */}
                  <div style={{ display:"flex", justifyContent:"space-between", alignItems:"flex-start", marginBottom:20, position:"relative" }}>
                    <div style={{ cursor:"pointer" }} onClick={() => { setTempIncome(income); setTempIncomeDisplay(income ? income.toLocaleString("id-ID") : ""); setIncomeAdj(""); setIncomeAdjDisplay(""); setEditIncome(true); }}>
                      <div style={{ display:"flex", alignItems:"center", gap:4, marginBottom:3 }}>
                        <p style={{ fontSize:7, color:"rgba(255,255,255,0.38)", fontWeight:700, letterSpacing:1, textTransform:"uppercase" }}>{L.income}</p>
                        <Pencil size={7} color="rgba(255,255,255,0.38)" strokeWidth={2.5}/>
                      </div>
                      <p style={{ fontSize:13, fontWeight:900, color:"rgba(255,255,255,0.88)", lineHeight:1 }}><AnimatedNumber value={income} format={formatRp}/></p>
                    </div>
                    <div style={{ textAlign:"right" }}>
                      <p style={{ fontSize:7, color:"rgba(255,255,255,0.35)", fontWeight:700, letterSpacing:1, textTransform:"uppercase" }}>{now2.toLocaleString(lang==="en"?"en-GB":"id-ID",{month:"short",year:"numeric"})}</p>
                      <p style={{ fontSize:22, fontWeight:900, color:"rgba(255,255,255,0.7)", lineHeight:1 }}>{now2.getDate()}</p>
                    </div>
                  </div>

                  {/* Main amount */}
                  <p style={{ fontSize:8, color:"rgba(255,255,255,0.42)", fontWeight:600, letterSpacing:1.2, textTransform:"uppercase", marginBottom:2, position:"relative" }}>{L.monthlyExpense}</p>
                  <p style={{ fontSize:32, fontWeight:900, color:"white", letterSpacing:-1.5, lineHeight:1, marginBottom:4, position:"relative" }}>
                    {loaded ? <AnimatedNumber value={totalExpense} format={formatRp}/> : "Rp ···"}
                  </p>

                  {/* Daily expense */}
                  <p style={{ fontSize:10, color:"rgba(255,255,255,0.35)", marginBottom:20, position:"relative" }}>
                    {L.today} <span style={{ color:"rgba(255,255,255,0.65)", fontWeight:600 }}>{formatRp(transactions.filter(t => t.date === today()).reduce((s,t) => s+t.amount, 0))}</span>
                  </p>

                  {/* Progress bar */}
                  <div style={{ background:"rgba(255,255,255,0.12)", borderRadius:99, height:3, overflow:"hidden", marginBottom:12, position:"relative" }}>
                    <div style={{ height:"100%", width:`${expPct}%`, background: barColor, borderRadius:99, transition:"width 0.6s cubic-bezier(0.34,1.2,0.64,1)", boxShadow:"0 0 6px rgba(255,255,255,0.3)" }}/>
                  </div>

                  {/* Bottom: sisa kiri, % kanan */}
                  <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center", position:"relative" }}>
                    <p style={{ fontSize:10, color:"rgba(255,255,255,0.38)" }}>
                      {L.remaining} <span style={{ color: barColor, fontWeight:700 }}>{formatRp(sisaUang)}</span>
                    </p>
                    <p style={{ fontSize:10, color: barColor, fontWeight:700 }}>{budgetPct}% {L.budgetLeft}</p>
                  </div>

                  {/* Negative balance warning */}
                  {isNegative && (
                    <div style={{ marginTop:12, background:"rgba(239,68,68,0.2)", borderRadius:12, padding:"9px 12px", display:"flex", alignItems:"center", gap:8, position:"relative" }}>
                      <AlertCircle size={14} color="#fca5a5" strokeWidth={2.5} style={{ flexShrink:0 }}/>
                      <p style={{ fontSize:11, color:"#fca5a5", fontWeight:700, lineHeight:1.4 }}>
                        {lang==="en" ? `Spending exceeds income by ${formatRp(Math.abs(realSisa))}` : `Pengeluaran melebihi pemasukan sebesar ${formatRp(Math.abs(realSisa))}`}
                      </p>
                    </div>
                  )}
                </div>
              );
            })()}

            {/* ── Streak + Weekly Insight ── */}
            <div style={{ display:"flex", gap:10, marginBottom:14 }}>
              {/* Streak card */}
              <div className="card" style={{ flex:1, padding:"14px 14px", ...CS, display:"flex", flexDirection:"column", gap:4 }}>
                <div style={{ display:"flex", alignItems:"center", gap:6, marginBottom:4 }}>
                  <div style={{ width:26, height:26, borderRadius:8, background:`${themeAccent}22`, display:"flex", alignItems:"center", justifyContent:"center" }}>
                    <Flame size={13} color={themeAccent} strokeWidth={2.5}/>
                  </div>
                  <p style={{ fontSize:11, fontWeight:800, color:T.textSub, letterSpacing:0.3 }}>{lang==="en"?"STREAK":"STREAK"}</p>
                </div>
                <p style={{ fontSize:28, fontWeight:900, color:T.text, lineHeight:1 }}>{streak.count}<span style={{ fontSize:13, fontWeight:700, color:T.textSub, marginLeft:2 }}>{lang==="en"?" days":" hari"}</span></p>
                <p style={{ fontSize:10, color:T.textSub, display:"flex", alignItems:"center", gap:4, marginBottom:6 }}>
                  {streak.count >= 7 ? <><Flame size={11} color={themeAccent} strokeWidth={2}/>{lang==="en"?"On fire!":"Konsisten!"}</> : streak.count >= 3 ? <><TrendingUp size={11} color="#4ade80" strokeWidth={2}/>{lang==="en"?"Keep going!":"Teruskan!"}</> : <>{lang==="en"?"Open daily":"Buka tiap hari"}</>}
                </p>
                {/* Fun facts harian */}
                {(() => {
                  const fi=["ATM pertama dipasang London 1967.","Uang kertas pertama dari Tiongkok abad ke-7.","'Salary' dari Latin — Romawi digaji garam.","Warren Buffett beli saham pertama usia 11 tahun.","Koin pertama dicetak di Lydia (Turki) ~600 SM.","Orang 12-18% lebih boros bayar kartu vs tunai.","Belanja pengalaman lebih membahagiakan dari beli barang.","Simbol '$' dari singkatan peso Spanyol.","Penny AS biaya produksi > nilai nominalnya.","Uang Monopoly dicetak lebih banyak dari dolar asli.","Swedia hampir jadi negara cashless pertama.","Bunga majemuk = keajaiban ke-8 dunia (Einstein).","Dana darurat ideal 3-6 bulan pengeluaran.","Aturan 50/30/20: kebutuhan/keinginan/tabungan.","Inflasi 5%/tahun buat Rp1jt jadi Rp614rb dalam 10 tahun.","Aturan 72: bagi 72 dgn bunga = tahun uang berlipat.","Jeff Bezos mulai Amazon dari garasi, modal $250rb.","Bitcoin pertama ditambang 3 Januari 2009.","Bursa saham pertama di Amsterdam tahun 1602.","Pasar saham global tak pernah rugi dalam 20 tahun mana pun.","1,7 miliar orang dewasa dunia tak punya rekening bank.","Rata-rata orang kaya punya 7 sumber pendapatan.","Index fund kalahkan fund aktif 85% waktu dalam 15 tahun.","Dollar Cost Averaging lebih baik dari timing pasar.","Stres finansial = penyebab konflik #1 dalam hubungan.","Kaya bukan soal berapa banyak kamu hasilkan tapi yang disimpan.","Waktu terbaik investasi: 20 tahun lalu. Kedua: sekarang.","Orang kaya beli aset, bukan liabilitas.","Dana pensiun Indonesia rata-rata hanya cukup 3-5 tahun.","QRIS diluncurkan Bank Indonesia tahun 2019."];
                  const fe=["First ATM installed London 1967.","Paper money originated China 7th century.","'Salary' from Latin — Romans paid in salt.","Warren Buffett bought first stock at age 11.","World's first coin minted Lydia (Turkey) ~600 BC.","People spend 12-18% more paying by card vs cash.","Experiences bring more happiness than buying things.","'$' symbol from Spanish peso abbreviation.","US penny costs more to make than its face value.","More Monopoly money printed annually than real dollars.","Sweden close to becoming first cashless society.","Compound interest = 8th wonder of world (Einstein).","Ideal emergency fund: 3-6 months expenses.","50/30/20 rule: needs/wants/savings.","5% annual inflation turns $1,000 into $614 over 10 years.","Rule of 72: divide 72 by rate = years to double.","Jeff Bezos started Amazon in garage with $250k.","Bitcoin first mined January 3, 2009.","World's first stock exchange founded Amsterdam 1602.","Global stock market never lost money over any 20-year period.","1.7 billion adults worldwide lack bank accounts.","Average wealthy person has 7 income streams.","Index funds beat active funds 85% of the time.","Dollar Cost Averaging beats market timing consistently.","Financial stress = #1 cause of relationship conflict.","Wealth is not how much you earn but how much you keep.","Best time to invest: 20 years ago. Second best: now.","Rich people buy assets, not liabilities.","FOMO is one of the leading causes of poor investment decisions.","Paying yourself first is the #1 wealth-building habit."];
                  const facts=lang==="en"?fe:fi;
                  const tip=facts[(new Date().getDate()+new Date().getMonth()*31+streak.count)%facts.length];
                  return <p style={{fontSize:9,color:T.textSub,lineHeight:1.4,marginTop:2,fontStyle:"italic"}}>"{tip}"</p>;
                })()}
              </div>

              {/* Weekly insight card with sparkline */}
              <div className="card" style={{ flex:2, padding:"14px 14px", ...CS }}>
                <div style={{ display:"flex", alignItems:"center", gap:6, marginBottom:6 }}>
                  <div style={{ width:26, height:26, borderRadius:8, background:`${themeAccent}22`, display:"flex", alignItems:"center", justifyContent:"center" }}>
                    <Zap size={13} color={themeAccent} strokeWidth={2.5}/>
                  </div>
                  <p style={{ fontSize:11, fontWeight:800, color:T.textSub, letterSpacing:0.3 }}>{lang==="en"?"THIS WEEK":"MINGGU INI"}</p>
                </div>
                {weeklyInsight.thisTotal === 0 ? (
                  <p style={{ fontSize:12, color:T.textSub }}>{lang==="en"?"No spending this week yet.":"Belum ada transaksi minggu ini."}</p>
                ) : (
                  <>
                    <p style={{ fontSize:18, fontWeight:900, color:T.text, lineHeight:1, marginBottom:3 }}><AnimatedNumber value={weeklyInsight.thisTotal} format={formatRp}/></p>
                    {weeklyInsight.hasBoth && weeklyInsight.diff !== 0 && (
                      <p style={{ fontSize:11, color: weeklyInsight.diff > 0 ? "#f87171" : "#4ade80", fontWeight:700, marginBottom:3 }}>
                        {weeklyInsight.diff > 0 ? "▲" : "▼"} {formatRp(Math.abs(weeklyInsight.diff))} {lang==="en"?"vs last week":"vs minggu lalu"}
                      </p>
                    )}
                    {weeklyInsight.topCat && (
                      <p style={{ fontSize:11, color:T.textSub, marginBottom:6 }}>
                        {lang==="en"?"Most: ":"Terbanyak: "}<span style={{ color:weeklyInsight.topCat.color, fontWeight:700 }}>{getCatLabel(weeklyInsight.topCat, lang)}</span>
                      </p>
                    )}
                    {/* Sparkline 7 hari */}
                    {(() => {
                      const maxVal = Math.max(...sparkline7.map(d => d.total), 1);
                      const H = 28, W = 100;
                      const pts = sparkline7.map((d, i) => {
                        const x = (i / 6) * W;
                        const y = H - (d.total / maxVal) * H;
                        return `${x},${y}`;
                      }).join(" ");
                      const todayDs = today();
                      return (
                        <div style={{ marginTop:4 }}>
                          <svg viewBox={`0 0 ${W} ${H+2}`} width="100%" height={H+2} style={{ display:"block", overflow:"visible" }}>
                            <polyline points={pts} fill="none" stroke={themeAccent} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" opacity="0.7"/>
                            {sparkline7.map((d, i) => {
                              const x = (i / 6) * W;
                              const y = H - (d.total / maxVal) * H;
                              const isToday = d.ds === todayDs;
                              return d.total > 0 ? (
                                <circle key={i} cx={x} cy={y} r={isToday ? 3 : 2} fill={isToday ? themeAccent : T.card} stroke={themeAccent} strokeWidth="1.5"/>
                              ) : null;
                            })}
                          </svg>
                          <div style={{ display:"flex", justifyContent:"space-between", marginTop:2 }}>
                            {sparkline7.map((d,i) => (
                              <p key={i} style={{ fontSize:8, color: d.ds===today()?themeAccent:T.textSub, fontWeight: d.ds===today()?800:600, opacity: d.ds===today()?1:0.6 }}>{d.dayLabel.slice(0,2)}</p>
                            ))}
                          </div>
                        </div>
                      );
                    })()}
                  </>
                )}
              </div>
            </div>

            {/* End-of-month prediction card */}
            {monthPrediction && income > 0 && (
              <div className="card" style={{ padding:"14px 16px", marginBottom:14, ...CS, display:"flex", alignItems:"center", gap:12 }}>
                <div style={{ width:36, height:36, borderRadius:12, background: monthPrediction.predicted > income ? "#f87171" + "22" : themeAccent+"22", display:"flex", alignItems:"center", justifyContent:"center", flexShrink:0 }}>
                  <TrendingUp size={16} color={monthPrediction.predicted > income ? "#f87171" : themeAccent} strokeWidth={2.2}/>
                </div>
                <div style={{ flex:1, minWidth:0 }}>
                  <p style={{ fontSize:11, fontWeight:800, color:T.textSub, letterSpacing:0.3, marginBottom:2 }}>{lang==="en"?"MONTH PREDICTION":"PREDIKSI AKHIR BULAN"}</p>
                  <p style={{ fontSize:13, fontWeight:700, color:T.text, lineHeight:1.4 }}>
                    {lang==="en"?"Est. spending: ":"Est. pengeluaran: "}
                    <span style={{ color: monthPrediction.predicted > income ? "#f87171" : themeAccent, fontWeight:900 }}><AnimatedNumber value={monthPrediction.predicted} format={formatRp}/></span>
                  </p>
                  {monthPrediction.predicted > income ? (
                    <p style={{ fontSize:10, color:"#f87171", fontWeight:600, display:"flex", alignItems:"center", gap:4 }}><AlertTriangle size={11} strokeWidth={2.5}/>{lang==="en"?"Over budget this month":"Kemungkinan over budget bulan ini"}</p>
                  ) : (
                    <p style={{ fontSize:10, color:themeAccent, fontWeight:600, display:"flex", alignItems:"center", gap:4 }}><CheckCircle size={11} strokeWidth={2.5}/>{lang==="en"?"On track · est. saving "+formatRp(income - monthPrediction.predicted):"Aman · estimasi sisa "+formatRp(income - monthPrediction.predicted)}</p>
                  )}
                </div>
              </div>
            )}

            {/* Budget per Kategori — prominent dashboard card */}
            {(() => {
              const budgetEntries = Object.entries(budgets).filter(([,v]) => v > 0);
              const allCatKeys = Object.keys(categories);
              // Empty state CTA
              if (budgetEntries.length === 0 && !overallBudget) return (
                <div className="card" style={{ padding:"16px 18px", marginBottom:14, ...CS }}>
                  <div style={{ display:"flex", alignItems:"center", gap:12 }}>
                    <div style={{ width:44, height:44, borderRadius:14, background:`${TP}18`, display:"flex", alignItems:"center", justifyContent:"center", flexShrink:0 }}>
                      <Wallet size={20} color={TP} strokeWidth={2}/>
                    </div>
                    <div style={{ flex:1 }}>
                      <p style={{ fontSize:13, fontWeight:800, color:T.text, marginBottom:2 }}>{L.monthlyBudget}</p>
                      <p style={{ fontSize:11, color:T.textSub }}>{lang==="en"?"No limits set. Set one to stay on track.":"Belum ada limit. Set biar lebih terkontrol."}</p>
                    </div>
                    <button onClick={() => { haptic(); setTempOverallBudget(overallBudget || 0); setTempOverallBudgetDisplay(overallBudget ? Number(overallBudget).toLocaleString("id-ID") : ""); setShowOverallBudgetModal(true); }} style={{ background:`${TP}18`, border:`1px solid ${TP}33`, borderRadius:10, padding:"7px 12px", color: TP, fontSize:11, fontWeight:800, cursor:"pointer", whiteSpace:"nowrap" }}>
                      {lang==="en"?"Set Budget":"Set Budget"}
                    </button>
                  </div>
                </div>
              );
              return (
                <div className="card" style={{ padding:"16px 18px", marginBottom:14, ...CS }}>
                  <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center", marginBottom:14 }}>
                    <div style={{ display:"flex", alignItems:"center", gap:7 }}>
                      <div style={{ width:28, height:28, borderRadius:9, background:`${TP}18`, display:"flex", alignItems:"center", justifyContent:"center" }}>
                        <Wallet size={13} color={TP} strokeWidth={2.5}/>
                      </div>
                      <p style={{ fontSize:14, fontWeight:800, color:T.text }}>{L.monthlyBudget}</p>
                    </div>
                    <div style={{ display:"flex", alignItems:"center", gap:8 }}>
                      <button onClick={() => { haptic(); setTempOverallBudget(overallBudget || 0); setTempOverallBudgetDisplay(overallBudget ? Number(overallBudget).toLocaleString("id-ID") : ""); setShowOverallBudgetModal(true); }} style={{ ...IBN, padding:4, display:"flex", alignItems:"center", justifyContent:"center" }}>
                        <Pencil size={13} strokeWidth={2} color={T.textSub}/>
                      </button>

                    </div>
                  </div>
                  <div style={{ display:"flex", flexDirection:"column", gap:10 }}>
                    {overallBudget > 0 && (() => {
                      const spent = transactions.filter(t => getMonth(t.date) === currentMonth).reduce((a,t) => a+t.amount, 0);
                      const pct = Math.min(100, Math.round((spent/overallBudget)*100));
                      const over = pct >= 100; const warn = pct >= 80;
                      const barColor2 = over ? "#ef4444" : warn ? "#f59e0b" : themeAccent;
                      return (
                        <div>
                          <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center", marginBottom:5 }}>
                            <span style={{ fontSize:12, fontWeight:700, color:T.text }}>{lang==="en"?"Total Monthly":"Total Bulanan"}</span>
                            <span style={{ fontSize:12, fontWeight:800, color: over?"#ef4444":warn?"#f59e0b":T.accentText }}>
                              {pct}% {over && <AlertCircle size={11} color="#ef4444" strokeWidth={2.5} style={{ display:"inline-block", verticalAlign:"middle" }}/>}
                            </span>
                          </div>
                          <div style={{ background: dark?"rgba(255,255,255,0.06)":"rgba(0,0,0,0.06)", borderRadius:99, height:6, overflow:"hidden" }}>
                            <div className="budget-bar" style={{ height:"100%", "--bw": pct+"%", borderRadius:99,
                              background: over ? "linear-gradient(90deg,#ef4444,#fca5a5)" : warn ? "linear-gradient(90deg,#f59e0b,#fcd34d)" : `linear-gradient(90deg,${themePrimary},${themeAccent})`,
                              position:"relative", overflow:"hidden" }}>
                              
                            </div>
                          </div>
                          <p style={{ fontSize:10, color:T.textSub, marginTop:3 }}>{formatRp(spent)} / {formatRp(overallBudget)}</p>
                        </div>
                      );
                    })()}
                    {budgetEntries.slice(0, 4).map(([key, bgt]) => {
                      const spent = transactions.filter(t => t.category === key && getMonth(t.date) === currentMonth).reduce((a,t) => a+t.amount, 0);
                      const pct = Math.min(100, Math.round((spent / bgt) * 100));
                      const over = pct >= 100; const warn = pct >= 80;
                      const cat = getCategory(key);
                      const barColor2 = over ? "#ef4444" : warn ? "#f59e0b" : themeAccent;
                      return (
                        <div key={key}>
                          <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center", marginBottom:5 }}>
                            <span style={{ fontSize:12, fontWeight:700, color:T.text, display:"flex", alignItems:"center", gap:5 }}>
                              <CatIcon iconKey={cat.icon} size={13} color={cat.color}/> {getCatLabel(cat, lang)}
                            </span>
                            <button onClick={() => { setBudgets(prev => { const next={...prev}; next[key]=0; return next; }); setBudgetsDisplay(prev => { const next={...prev}; next[key]=""; return next; }); }} style={{ ...IBN, fontSize:11, color:T.textSub, padding:"0 4px", opacity:0.6 }} title={lang==="en"?"Reset":"Hapus"}>✕</button>
                            <button onClick={() => { setBudgets(prev => { const next={...prev}; const cur=next[key]||0; const step=50000; next[key]=cur+step; return next; }); }} style={{ ...IBN, fontSize:12, fontWeight:800, color: over ? "#ef4444" : warn ? "#f59e0b" : T.textSub, padding:"0 4px" }}>
                              {pct}% {over && <AlertCircle size={11} color="#ef4444" strokeWidth={2.5} style={{ display:"inline-block", verticalAlign:"middle" }}/>}
                            </button>
                          </div>
                          <div style={{ background: dark?"rgba(255,255,255,0.06)":"rgba(0,0,0,0.06)", borderRadius:99, height:6, overflow:"hidden" }}>
                            <div className="budget-bar" style={{ height:"100%", "--bw": pct+"%", borderRadius:99,
                              background: over ? "linear-gradient(90deg,#ef4444,#fca5a5)" : warn ? "linear-gradient(90deg,#f59e0b,#fcd34d)" : `linear-gradient(90deg,${themePrimary},${themeAccent})`,
                              position:"relative", overflow:"hidden" }}>
                              
                            </div>
                          </div>
                          <p style={{ fontSize:10, color:T.textSub, marginTop:3 }}>{formatRp(spent)} / {formatRp(bgt)}</p>
                        </div>
                      );
                    })}
                  </div>
                </div>
              );
            })()}

            {/* Savings Goals Card */}
            <div className="card" style={{ padding:"16px 18px", marginBottom:14, ...CS }}>
              <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center", marginBottom:14 }}>
                <div style={{ display:"flex", alignItems:"center", gap:7 }}>
                  <div style={{ width:28, height:28, borderRadius:9, background:`${TP}18`, display:"flex", alignItems:"center", justifyContent:"center" }}>
                    <PiggyBank size={13} color={TP} strokeWidth={2.5}/>
                  </div>
                  <p style={{ fontSize:14, fontWeight:800, color:T.text }}>{L.savingsGoal}</p>
                </div>
                {savingsGoals.length > 0 && (
                  <button onClick={() => { setEditingGoal("new"); setGoalForm({ label:"", target:"", targetDisplay:"", saved:"", savedDisplay:"", color:"#60a5fa", icon:"piggy" }); }}
                    style={{ background:"none", border:"none", fontSize:12, color:TP, fontWeight:700, cursor:"pointer", display:"flex", alignItems:"center", gap:3 }}>
                    <Plus size={13} strokeWidth={2.5}/> {lang==="en"?"Add":"+ Tambah"}
                  </button>
                )}
              </div>

              {savingsGoals.length === 0 ? (
                <div style={{ textAlign:"center", padding:"24px 0 8px" }}>
                  <div style={{ display:"flex", justifyContent:"center", marginBottom:10 }}>
                    <div style={{ width:72, height:72, borderRadius:"50%", background:`linear-gradient(135deg,${themeAccent}22,${themePrimary}18)`, border:`1.5px solid ${themeAccent}30`, display:"flex", alignItems:"center", justifyContent:"center" }}>
                      <PiggyBank size={36} color={T.accentText} strokeWidth={1.5}/>
                    </div>
                  </div>
                  <p style={{ fontSize:14, fontWeight:700, color:T.text, marginBottom:4 }}>{L.noGoal}</p>
                  <p style={{ fontSize:12, color:T.textSub, marginBottom:14 }}>Yuk, buat target pertamamu!</p>
                  <button className="btn-p" style={{ display:"inline-flex", alignItems:"center", gap:6, padding:"10px 20px", fontSize:13, borderRadius:14 }}
                    onClick={() => { haptic(); setEditingGoal("new"); setGoalForm({ label:"", target:"", targetDisplay:"", saved:"", savedDisplay:"", color:"#4ade80", icon:"piggy", deadline:"" }); }}>
                    <Plus size={14} strokeWidth={2.5}/> {L.addGoal||L.add}
                  </button>
                </div>
              ) : (
                <div style={{ display:"flex", flexDirection:"column", gap:14 }}>
                  {savingsGoals.map(goal => {
                    const pct = goal.target > 0 ? Math.min(100, Math.round((goal.saved / goal.target) * 100)) : 0;
                    const remaining = Math.max(0, goal.target - goal.saved);
                    const isAchieved = pct >= 100;
                    const confettiColors = [goal.color, "#fbbf24", "#34d399", "#f87171", "#c084fc"];
                    return (
                      <div key={goal.id}>
                        <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center", marginBottom:6 }}>
                          <div style={{ display:"flex", alignItems:"center", gap:7 }}>
                            <div style={{ width:28, height:28, borderRadius:9, background:goal.color+"22", display:"flex", alignItems:"center", justifyContent:"center", flexShrink:0 }}>
                              {(() => { const gi = GOAL_ICONS[goal.icon||"piggy"]; return gi ? <gi.Icon size={13} color={goal.color} strokeWidth={2}/> : <PiggyBank size={13} color={goal.color} strokeWidth={2}/>; })()}
                            </div>
                            <div>
                              <p style={{ fontSize:13, fontWeight:700, color:T.text, lineHeight:1.2 }}>{goal.label}</p>
                              <p key={goal.saved} style={{ fontSize:10, color:T.textSub, fontWeight:600, animation:"count-up 0.3s cubic-bezier(0.25,0.46,0.45,0.94) both" }}>
                                <AnimatedNumber value={goal.saved} format={formatRp}/> / {formatRp(goal.target)}
                              </p>
                            </div>
                          </div>
                          <div style={{ display:"flex", alignItems:"center", gap:6 }}>
                            <span style={{ fontSize:13, fontWeight:900, color: pct >= 100 ? "#4ade80" : goal.color }}>{pct}%</span>
                            <button
                              onClick={() => { setEditingGoal(goal.id); setGoalForm({ label: goal.label, target: goal.target, targetDisplay: goal.target ? Number(goal.target).toLocaleString("id-ID") : "", saved: goal.saved, savedDisplay: goal.saved ? Number(goal.saved).toLocaleString("id-ID") : "", color: goal.color, icon: goal.icon || "piggy", deadline: goal.deadline || "" }); }}
                              style={{ ...IBN, padding:2, display:"flex", alignItems:"center" }}>
                              <Pencil size={12} strokeWidth={2} color={T.textSub}/>
                            </button>
                            <button
                              onClick={() => setSavingsGoals(prev => prev.filter(g => g.id !== goal.id))}
                              style={{ ...IBN, padding:2, display:"flex", alignItems:"center" }}>
                              <X size={12} strokeWidth={2} color={T.textSub}/>
                            </button>
                          </div>
                        </div>
                        {isAchieved && (
                          <div style={{ position:"relative", height:20, marginBottom:2, overflow:"visible" }}>
                            {confettiColors.map((col,ci) => (
                              <div key={ci} className="confetti-piece" style={{ background:col, left:`${8+ci*18}%`, top:0, animationDelay:`${ci*0.12}s`, animationDuration:`${0.8+ci*0.1}s`, animationIterationCount:"infinite" }}/>
                            ))}
                          </div>
                        )}
                        <div style={{ background: dark?"rgba(255,255,255,0.06)":"rgba(0,0,0,0.06)", borderRadius:99, height:6, overflow:"hidden", marginBottom:4 }}>
                          <div style={{ height:"100%", width:pct+"%", background: pct >= 100 ? "#4ade80" : goal.color, borderRadius:8, transition:"width 0.6s cubic-bezier(0.34,1.2,0.64,1)", position:"relative", overflow:"hidden" }}>
                              
                            </div>
                        </div>
                        {remaining > 0 && (
                          <p style={{ fontSize:10, color:T.textSub, fontWeight:600 }}>{L.goalRemaining} {formatRp(remaining)} {L.goalRemainingMore}{goal.deadline ? (() => {
                            const dl = new Date(goal.deadline); const now2 = new Date(); const diff = Math.ceil((dl-now2)/(1000*60*60*24));
                            if (diff < 0) return <span style={{color:"#f87171"}}> · {L.goalOverdue}</span>;
                            if (diff <= 7) return <span style={{color:"#f59e0b"}}> · {diff} {L.goalDaysLeft}</span>;
                            return <span> · {dl.toLocaleDateString(lang==="en"?"en-GB":"id-ID",{day:"numeric",month:"short",year:"numeric"})}</span>;
                          })() : ""}</p>
                        )}
                        {pct >= 100 && (
                          <p style={{ fontSize:10, color:themeAccent, fontWeight:700, display:"flex", alignItems:"center", gap:3 }}><CheckCircle size={10} color={themeAccent} strokeWidth={2.5}/> {L.goalReached}</p>
                        )}
                        {/* Estimasi waktu tercapai */}
                        {pct < 100 && remaining > 0 && avgMonthlySaved > 0 && (
                          <p style={{ fontSize:10, color:T.textSub, fontWeight:600, marginTop:2 }}>
                            {lang==="en"?"Est. ":"Est. "}
                            {(() => {
                              const months = Math.ceil(remaining / avgMonthlySaved);
                              if (months <= 1) return lang==="en"?"< 1 month away":"< 1 bulan lagi";
                              if (months < 12) return lang==="en"?`${months} months away`:`${months} bulan lagi`;
                              const y = Math.floor(months/12); const m = months%12;
                              return lang==="en"?`${y}y${m>0?" "+m+"m":""} away`:`${y}th${m>0?" "+m+"bl":""} lagi`;
                            })()}
                          </p>
                        )}
                        {/* Quick add tabungan */}
                        {pct < 100 && (
                          <div style={{ marginTop:8 }}>
                            {quickAddGoalId === goal.id ? (
                              <div style={{ display:"flex", gap:6, alignItems:"center" }}>
                                <input className="inp" type="text" inputMode="numeric" placeholder="Nominal tabungan" autoFocus
                                  value={quickAddAmtDisplay}
                                  onChange={e => { const {display,raw}=parseRpInput(e.target.value); setQuickAddAmtDisplay(display); setQuickAddAmt(raw); }}
                                  style={{ background:T.inp, border:`1.5px solid ${goal.color}44`, color:T.text, flex:1, marginBottom:0, padding:"8px 12px", fontSize:13, borderRadius:10 }}/>
                                <button onClick={() => {
                                  if (!quickAddAmt) { setQuickAddGoalId(null); return; }
                                  haptic("success");
                                  setSavingsGoals(prev => prev.map(g => g.id===goal.id ? {...g, saved: g.saved + Number(quickAddAmt)} : g));
                                  setQuickAddGoalId(null); setQuickAddAmt(""); setQuickAddAmtDisplay("");
                                }} style={{ padding:"8px 14px", borderRadius:10, border:"none", background:goal.color, color:"white", fontSize:12, fontWeight:800, cursor:"pointer", fontFamily:"inherit", flexShrink:0 }}>
                                  {lang==="en"?"Save":"Simpan"}
                                </button>
                                <button onClick={() => { setQuickAddGoalId(null); setQuickAddAmt(""); setQuickAddAmtDisplay(""); }}
                                  style={{ padding:"8px", borderRadius:10, border:`1px solid ${T.cardBorder}`, background:T.inp, cursor:"pointer", display:"flex", alignItems:"center" }}>
                                  <X size={12} color={T.textSub} strokeWidth={2}/>
                                </button>
                              </div>
                            ) : (
                              <button onClick={() => { haptic(); setQuickAddGoalId(goal.id); setQuickAddAmt(""); setQuickAddAmtDisplay(""); }}
                                style={{ display:"inline-flex", alignItems:"center", gap:4, padding:"5px 10px", borderRadius:8, border:`1px solid ${goal.color}44`, background:goal.color+"15", color:goal.color, fontSize:11, fontWeight:700, cursor:"pointer", fontFamily:"inherit" }}>
                                <Plus size={11} strokeWidth={2.5}/> {lang==="en"?"Add savings":"Tambah tabungan"}
                              </button>
                            )}
                          </div>
                        )}
                      </div>
                    );
                  })}
                </div>
              )}
            </div>


            {/* Recent transactions */}
            <div className="card" style={{ padding:16, marginBottom:14, ...CS }}>
              <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center", marginBottom:14 }}>
                <div style={{ display:"flex", alignItems:"center", gap:7 }}>
                  <div style={{ width:28, height:28, borderRadius:9, background:`${TP}18`, display:"flex", alignItems:"center", justifyContent:"center" }}>
                    <Wallet size={13} color={TP} strokeWidth={2.5}/>
                  </div>
                  <p style={{ fontSize:14, fontWeight:800, color:T.text }}>{L.recentTx}</p>
                </div>
                <button onClick={() => changeTab("transactions")} style={{ background:"none", border:"none", fontSize:12, color:T.accentText, fontWeight:700, cursor:"pointer", display:"flex", alignItems:"center", gap:3 }}>
                  {L.seeAll} <ArrowRight size={13} strokeWidth={2.5}/>
                </button>
              </div>
              {recentTxns.length === 0 ? (
                <div style={{ textAlign:"center", padding:"28px 16px" }}>
                  <div style={{ marginBottom:14, display:"flex", justifyContent:"center" }}>
                    <div style={{ width:72, height:72, borderRadius:"50%", background:`linear-gradient(135deg,${themeAccent}22,${themePrimary}18)`, border:`1.5px solid ${themeAccent}30`, display:"flex", alignItems:"center", justifyContent:"center" }}>
                      <Wallet size={32} color={T.accentText} strokeWidth={1.5}/>
                    </div>
                  </div>
                  <p style={{ fontSize:15, fontWeight:900, color:T.text, marginBottom:6 }}>{L.noTx}</p>
                  <p style={{ fontSize:12, color:T.textSub, marginBottom:18, lineHeight:1.6 }}>{L.noTxDescEmpty}</p>
                  <button className="btn-p" style={{ display:"inline-flex", alignItems:"center", gap:6, padding:"11px 22px", fontSize:13, borderRadius:16 }}
                    onClick={() => { haptic(); setShowForm(true); setEditItem(null); setForm({ date:today(), amount:"", category:Object.keys(categories)[0]||"food", description:"", location:"", note:"" }); }}>
                    <Plus size={14} strokeWidth={2.5}/> {lang==="en"?"Record Now":"Catat Sekarang"}
                  </button>
                </div>
              ) : (
                <div style={{ display:"flex", flexDirection:"column", gap:10 }}>
                  {recentTxns.map((t, idx) => {
                    const cat = getCategory(t.category);
                    return (
                      <div key={t.id} style={{ display:"flex", alignItems:"center", gap:12 }}>
                        <div style={{ width:40, height:40, borderRadius:12, background:cat.color+"18", border:`1px solid ${cat.color}25`, display:"flex", alignItems:"center", justifyContent:"center", flexShrink:0 }}><CatIcon iconKey={cat.icon} size={21} color={cat.color}/></div>
                        <div style={{ flex:1, minWidth:0 }}>
                          <p style={{ fontSize:13, fontWeight:700, color:T.text, whiteSpace:"nowrap", overflow:"hidden", textOverflow:"ellipsis" }}>{t.description}</p>
                          <p style={{ fontSize:11, color:T.textSub, marginTop:1 }}>{getCatLabel(cat, lang)} · {dateLabel(t.date, lang)}</p>
                        </div>
                        <p style={{ fontSize:13, fontWeight:900, color:"#f87171", flexShrink:0 }}>-{formatRp(t.amount)}</p>
                      </div>
                    );
                  })}
                </div>
              )}
              {transactions.length > recentCount && (
                <button className="btn-g" style={{ width:"100%", marginTop:12, background:T.btnG, color:T.btnGText, border:`1.5px solid ${T.btnGBorder}` }} onClick={() => setRecentCount(c => c + 5)}>{L.showMore||"More"}</button>
              )}
            </div>

            {/* Donut Chart */}
            <div className="card" style={{ padding:16, marginBottom:14, ...CS }}>
              <div style={{ display:"flex", alignItems:"center", gap:7, marginBottom:4 }}><div style={{ width:28, height:28, borderRadius:9, background:`${TP}18`, display:"flex", alignItems:"center", justifyContent:"center" }}><BarChart2 size={13} strokeWidth={2} color={TP}/></div><p style={{ fontSize:14, fontWeight:800, color:T.text }}>{L.breakdownCat}</p></div>
              {catBreakdown.length === 0 ? (
                <div style={{ textAlign:"center", padding:"40px 20px" }}>
                <div style={{ display:"flex", justifyContent:"center", marginBottom:14 }}>
                  <div style={{ width:72, height:72, borderRadius:"50%", background:`linear-gradient(135deg,${themeAccent}22,${themePrimary}18)`, border:`1.5px solid ${themeAccent}30`, display:"flex", alignItems:"center", justifyContent:"center" }}>
                    <BarChart2 size={32} color={T.accentText} strokeWidth={1.5}/>
                  </div>
                </div>
                <p style={{ fontSize:16, fontWeight:800, color:T.text, marginBottom:8 }}>{L.noData}</p>
                <p style={{ fontSize:13, color:T.textSub, lineHeight:1.6 }}>{L.startDesc}</p>
              </div>
              ) : (
                <DonutChart data={donutData} total={totalExpense} T={T} lang={lang} />
              )}
            </div>
          </div>
        </>
  );
}
