import { AlertCircle, AlertTriangle, Ban, BarChart2, Calculator2, Calendar, CheckCircle, DiamondPlus, Download, Flag, Globe, HandCoins, HeartPulse, Inbox, MessageCircle, PaintRoller, Rocket, Share2, TrendingUp, X, Zap } from "../icons.jsx";
import { formatRp, fmtDate, getCatLabel, getMonth, haptic } from "../utils/helpers.js";
import { darken, lighten } from "../utils/theme.js";
import { CatIcon } from "./ui.jsx";

export default function TabReport({ ctx }) {
  const {
    T, dark, lang, L,
    tabAnim, loaded, headerHeight,
    transactions, categories,
    reportTxns, reportTotal, reportByCat,
    reportDate, setReportDate,
    themeAccent, themePrimary,
    income, totalExpense,
    weeklyInsight, weeklyTrend,
    monthCompareData, monthInsights,
    catTrendData, catBreakdown,
    prevMonth, avgMonthlySaved,
    budgets,
    overallBudget,
    showExportMenu, setShowExportMenu,
    exportCSV, exportPDFReport,
  } = ctx;

  return (
        <>
          <div key="report" className={`fi${tabAnim ? " tab-enter" : ""}`} style={{ padding:"0" }}>
            <div style={{ padding:"14px 16px 0", paddingTop:`${headerHeight + 8}px`, overflowX:"hidden", width:"100%", boxSizing:"border-box", paddingBottom:"16px" }}>

            {/* Budget warnings */}
            {Object.entries(budgets).filter(([k,v]) => {
              const spent = transactions.filter(t => t.category===k && getMonth(t.date)===currentMonth).reduce((a,t)=>a+t.amount,0);
              return v>0 && spent>=v*0.8;
            }).map(([k,v]) => {
              const spent = transactions.filter(t => t.category===k && getMonth(t.date)===currentMonth).reduce((a,t)=>a+t.amount,0);
              const over = spent>=v; const cat = getCategory(k);
              return (
                <div key={k} style={{ display:"flex",alignItems:"center",gap:10,padding:"11px 14px",borderRadius:14,background:over?"#fef2f2":"#fffbeb",border:`1.5px solid ${over?"#fca5a5":"#fde68a"}`,marginBottom:8 }}>
                  <AlertCircle size={18} color={over?"#ef4444":"#f59e0b"} strokeWidth={2}/>
                  <div style={{ flex:1 }}>
                    <p style={{ fontSize:13,fontWeight:700,color:over?"#b91c1c":"#92400e" }}>{over?(lang==="en"?"Exceeded":"Terlampaui"):(lang==="en"?"Near limit":"Mendekati limit")}: {getCatLabel(cat, lang)}</p>
                    <p style={{ fontSize:11,color:over?"#ef4444":"#f59e0b" }}>{formatRp(spent)} / {formatRp(v)}</p>
                  </div>
                </div>
              );
            })}

            {/* Per-category month comparison table */}
            {(() => {
              const entries = Object.entries(categories).map(([key]) => {
                const cur = transactions.filter(t => t.category===key && getMonth(t.date)===currentMonth).reduce((s,t)=>s+t.amount,0);
                const prev = transactions.filter(t => t.category===key && getMonth(t.date)===prevMonth).reduce((s,t)=>s+t.amount,0);
                return { key, cur, prev };
              }).filter(d => d.cur > 0 || d.prev > 0).sort((a,b) => b.cur - a.cur);
              if (entries.length === 0) return null;
              const maxAmt = Math.max(...entries.map(d => Math.max(d.cur, d.prev)), 1);
              return (
                <div className="card" style={{ padding:16, marginBottom:12, ...CS }}>
                  <div style={{ display:"flex", alignItems:"center", gap:7, marginBottom:4 }}>
                    <div style={{ width:28, height:28, borderRadius:9, background:`${TP}18`, display:"flex", alignItems:"center", justifyContent:"center" }}>
                      <BarChart2 size={13} strokeWidth={2} color={TP}/>
                    </div>
                    <p style={{ fontSize:13, fontWeight:800, color:T.text }}>{lang==="en"?"Per Category — This vs Last Month":"Per Kategori — Bulan Ini vs Lalu"}</p>
                  </div>
                  <div style={{ display:"flex", gap:12, marginBottom:12, marginTop:4 }}>
                    <div style={{ display:"flex", alignItems:"center", gap:5 }}><div style={{ width:10, height:10, borderRadius:3, background:themePrimary }}/><span style={{ fontSize:10, color:T.textSub }}>{lang==="en"?"This month":"Bulan ini"}</span></div>
                    <div style={{ display:"flex", alignItems:"center", gap:5 }}><div style={{ width:10, height:10, borderRadius:3, background:dark?"rgba(255,255,255,0.15)":"rgba(0,0,0,0.1)" }}/><span style={{ fontSize:10, color:T.textSub }}>{lang==="en"?"Last month":"Bulan lalu"}</span></div>
                  </div>
                  <div style={{ display:"flex", flexDirection:"column", gap:12 }}>
                    {entries.map(({ key, cur, prev }) => {
                      const cat = getCategory(key);
                      const diff = cur - prev;
                      const pctDiff = prev > 0 ? Math.round(diff * 100 / prev) : null;
                      const up = diff > 0;
                      return (
                        <div key={key}>
                          <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center", marginBottom:4 }}>
                            <span style={{ fontSize:12, fontWeight:700, color:T.text, display:"flex", alignItems:"center", gap:6 }}>
                              <span style={{ width:20, height:20, borderRadius:6, background:cat.color+"22", display:"flex", alignItems:"center", justifyContent:"center", flexShrink:0 }}><CatIcon iconKey={cat.icon} size={11} color={cat.color}/></span> {getCatLabel(cat, lang)}
                            </span>
                            {pctDiff !== null && <span style={{ fontSize:11, fontWeight:700, color: up ? "#f87171" : "#4ade80" }}>{up?"▲":"▼"} {Math.abs(pctDiff)}%</span>}
                          </div>
                          <div style={{ background:dark?"rgba(255,255,255,0.07)":"rgba(0,0,0,0.07)", borderRadius:99, height:7, overflow:"hidden", marginBottom:3 }}>
                            <div style={{ height:"100%", width:`${Math.round(cur*100/maxAmt)}%`, background:`linear-gradient(90deg,${themePrimary},${themeAccent})`, borderRadius:99, transition:"width 0.4s ease" }}/>
                          </div>
                          <div style={{ background:dark?"rgba(255,255,255,0.04)":"rgba(0,0,0,0.04)", borderRadius:99, height:4, overflow:"hidden" }}>
                            <div style={{ height:"100%", width:`${Math.round(prev*100/maxAmt)}%`, background:dark?"rgba(255,255,255,0.2)":"rgba(0,0,0,0.12)", borderRadius:99 }}/>
                          </div>
                          <div style={{ display:"flex", justifyContent:"space-between", marginTop:3 }}>
                            <p style={{ fontSize:10, color:T.textSub }}>{formatRp(cur)}</p>
                            <p style={{ fontSize:10, color:T.textSub, opacity:0.5 }}>{formatRp(prev)}</p>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                </div>
              );
            })()}

            {/* AI Insights */}
            {monthInsights.length > 0 && (
              <div className="card" style={{ padding:16, marginBottom:12, background: dark?"#0d1a0d":"#f0fdf4", border:`1px solid ${dark?"#1a3a1a":"#bbf7d0"}` }}>
                <div style={{ display:"flex", alignItems:"center", gap:7, marginBottom:10 }}><div style={{ width:28, height:28, borderRadius:9, background:dark?"#1a3a1a":"#bbf7d022", display:"flex", alignItems:"center", justifyContent:"center" }}><Zap size={13} strokeWidth={2} color={dark?"#4ade80":"#166534"}/></div><p style={{ fontSize:13, fontWeight:800, color: dark?"#4ade80":"#166534" }}>{L.repInsightMonthly}</p></div>
                <div style={{ display:"flex", flexDirection:"column", gap:7 }}>
                  {monthInsights.map((ins, i) => (
                    <div key={i} style={{ display:"flex", alignItems:"center", gap:8 }}>
                      <div style={{ width:22, height:22, borderRadius:50, background: ins.type==="up"?"rgba(239,68,68,0.15)":"rgba(22,163,74,0.15)", display:"flex", alignItems:"center", justifyContent:"center", flexShrink:0 }}>
                        <TrendingUp size={11} strokeWidth={2.5} color={ins.type==="up"?"#ef4444":"#16a34a"} style={{ transform: ins.type==="down"?"rotate(180deg)":"none" }}/>
                      </div>
                      <p style={{ fontSize:12, color: dark?"#d1fae5":"#166534" }}>{ins.text}</p>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* ── Category Trend Chart (4 months, toggleable) ── */}
            {catTrendData.lineData.length > 0 && (
              <div className="card" style={{ padding:16, marginBottom:12, ...CS, overflow:"hidden" }}>
                <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center", marginBottom:4 }}>
                  <div style={{ display:"flex", alignItems:"center", gap:7 }}>
                    <div style={{ width:28, height:28, borderRadius:9, background:`${TP}18`, display:"flex", alignItems:"center", justifyContent:"center" }}>
                      <TrendingUp size={13} strokeWidth={2} color={TP}/>
                    </div>
                    <p style={{ fontSize:13, fontWeight:800, color:T.text }}>{lang==="en"?"Category Trend (4 months)":"Tren Kategori (4 bulan)"}</p>
                  </div>
                  {/* Toggle */}
                  <div style={{ display:"flex", gap:4 }}>
                    {[["bar", lang==="en"?"Bar":"Bar"], ["line", lang==="en"?"Line":"Line"]].map(([v, label]) => (
                      <button key={v} onClick={() => setCatTrendView(v)}
                        style={{ padding:"4px 10px", borderRadius:20, border:`1.5px solid ${catTrendView===v ? themeAccent : T.cardBorder}`, background: catTrendView===v ? themeAccent+"22" : "transparent", color: catTrendView===v ? T.accentText : T.textSub, fontSize:11, fontWeight:700, cursor:"pointer" }}>
                        {label}
                      </button>
                    ))}
                  </div>
                </div>
                <p style={{ fontSize:11, color:T.textSub, marginBottom:12 }}>
                  {catTrendData.months.map(m => new Date(m+"-01").toLocaleDateString(lang==="en"?"en-GB":"id-ID",{month:"short"})).join(" · ")}
                </p>

                {catTrendView === "bar" ? (() => {
                  // Grouped bar chart per month, each category a bar
                  const H = 150, pad = 8;
                  const activeCats = catTrendData.catKeys.filter(k => catTrendData.barData.some(d => d[k] > 0));
                  const maxVal = Math.max(...catTrendData.barData.flatMap(d => activeCats.map(k => d[k]||0)), 1);
                  const numMonths = catTrendData.months.length;
                  const barW = Math.max(4, Math.min(12, Math.floor(48 / Math.max(activeCats.length, 1))));
                  const groupW = activeCats.length * (barW + 1) + 12;
                  const totalW = numMonths * groupW + pad*2;
                  return (
                    <svg width="100%" viewBox={`0 0 ${totalW} ${H+28}`} style={{ display:"block", overflow:"visible" }}>
                      {catTrendData.barData.map((d, mi) => {
                        const gx = pad + mi * groupW;
                        return (
                          <g key={mi}>
                            {activeCats.map((k, ci) => {
                              const cat = categories[k];
                              const h = Math.max(2, (d[k]||0)/maxVal*(H-pad));
                              return <rect key={k} x={gx + ci*(barW+1)} y={H-h} width={barW} height={h} fill={cat?.color||"#888"} rx={2} opacity={0.88}/>;
                            })}
                            <text x={gx + (activeCats.length*(barW+1))/2} y={H+16} textAnchor="middle" fontSize={10} fill={T.textSub} fontWeight={600}>{d.month}</text>
                          </g>
                        );
                      })}
                      <line x1={pad} y1={H} x2={totalW-pad} y2={H} stroke={T.cardBorder} strokeWidth={1}/>
                    </svg>
                  );
                })() : (() => {
                  // Line chart per category
                  const H = 150, pad = 12;
                  const W2 = 300;
                  const numMonths = catTrendData.months.length;
                  const allVals = catTrendData.lineData.flatMap(d => d.data.map(p => p.value));
                  const maxVal = Math.max(...allVals, 1);
                  return (
                    <svg width="100%" viewBox={`0 0 ${W2} ${H+28}`} style={{ display:"block", overflow:"visible" }}>
                      {catTrendData.lineData.map(cat => {
                        const pts = cat.data.map((p, i) => [
                          pad + i/(numMonths-1||1)*(W2-pad*2),
                          H - pad - (p.value/maxVal)*(H-pad*2)
                        ]);
                        const pathD = pts.map((p,i)=>`${i===0?"M":"L"}${p[0].toFixed(1)},${p[1].toFixed(1)}`).join(" ");
                        return (
                          <g key={cat.key}>
                            <path d={pathD} fill="none" stroke={cat.color} strokeWidth={2} strokeLinecap="round" strokeLinejoin="round" opacity={0.9}/>
                            {pts.map(([x,y],i) => cat.data[i].value > 0 ? <circle key={i} cx={x} cy={y} r={3} fill={cat.color} stroke={T.card} strokeWidth={1.5}/> : null)}
                          </g>
                        );
                      })}
                      {catTrendData.lineData[0]?.data.map((p, i) => {
                        const x = pad + i/(numMonths-1||1)*(W2-pad*2);
                        return <text key={i} x={x} y={H+16} textAnchor="middle" fontSize={10} fill={T.textSub} fontWeight={600}>{p.month}</text>;
                      })}
                      <line x1={pad} y1={H} x2={W2-pad} y2={H} stroke={T.cardBorder} strokeWidth={1}/>
                    </svg>
                  );
                })()}

                {/* Legend */}
                <div style={{ display:"flex", flexWrap:"wrap", gap:"6px 12px", marginTop:10 }}>
                  {catTrendData.lineData.map(cat => (
                    <div key={cat.key} style={{ display:"flex", alignItems:"center", gap:5 }}>
                      <div style={{ width:8, height:8, borderRadius:"50%", background:cat.color, flexShrink:0 }}/>
                      <span style={{ fontSize:10, color:T.textSub, fontWeight:600 }}>{getCatLabel(cat, lang)}</span>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Weekly trend line chart */}
            <div className="card" style={{ padding:16,marginBottom:12,background:T.card,border:`1px solid ${T.cardBorder}`,boxShadow:`0 1px 4px ${T.cardShadow}`, overflow:"hidden" }}>
              <div style={{ display:"flex", alignItems:"center", gap:7, marginBottom:12 }}><div style={{ width:28, height:28, borderRadius:9, background:`${TP}18`, display:"flex", alignItems:"center", justifyContent:"center" }}><TrendingUp size={13} strokeWidth={2} color={TP}/></div><p style={{ fontSize:13,fontWeight:800,color:T.text }}>{L.trend8w}</p></div>
              <div style={{ width:"100%", overflow:"hidden" }}>
              {(() => {
                if (!weeklyTrend || weeklyTrend.length === 0) return <p style={{ color:T.textSub, fontSize:12, textAlign:"center", padding:"20px 0" }}>{L.noData||"No data"}</p>;
                const H = 110, W = 320, pad = 12;
                const vals = weeklyTrend.map(d => d.total || 0);
                const maxV = Math.max(...vals, 1);
                const pts = vals.map((v, i) => {
                  const x = pad + (i / (vals.length - 1 || 1)) * (W - pad*2);
                  const y = H - pad - (v / maxV) * (H - pad*2);
                  return [x, y];
                });
                const pathD = pts.map((p, i) => `${i===0?"M":"L"}${p[0].toFixed(1)},${p[1].toFixed(1)}`).join(" ");
                const fillD = pathD + ` L${pts[pts.length-1][0]},${H-pad} L${pts[0][0]},${H-pad} Z`;
                return (
                  <svg width="100%" height="140" viewBox={`0 0 ${W} ${H+20}`} style={{ display:"block" }}>
                    <defs>
                      <linearGradient id="lg" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="0%" stopColor={themeAccent} stopOpacity={0.3}/>
                        <stop offset="100%" stopColor={themeAccent} stopOpacity={0}/>
                      </linearGradient>
                    </defs>
                    <path d={fillD} fill="url(#lg)"/>
                    <path d={pathD} fill="none" stroke={themeAccent} strokeWidth={2.5} strokeLinecap="round" strokeLinejoin="round"/>
                    {pts.map(([x,y], i) => <circle key={i} cx={x} cy={y} r={4.5} fill={themePrimary} stroke={themeAccent} strokeWidth={2}/>)}
                    {weeklyTrend.map((d, i) => (
                      <text key={i} x={pts[i][0]} y={H+16} textAnchor="middle" fontSize={10} fill={T.textSub} fontWeight={600}>{d.label}</text>
                    ))}
                    <line x1={pad} y1={H-pad} x2={W-pad} y2={H-pad} stroke={T.cardBorder} strokeWidth={1}/>
                  </svg>
                );
              })()}
              </div>
            </div>
            {/* Insight Mingguan */}
            {weeklyInsight.thisTotal > 0 && (
              <div className="card" style={{ padding:16, marginBottom:12, background: dark?darken(themePrimary,0.55)+"cc":themePrimary+"12", border:`1px solid ${dark?themePrimary+"44":themePrimary+"33"}` }}>
                <div style={{ display:"flex", alignItems:"center", gap:7, marginBottom:10 }}>
                  <div style={{ width:28, height:28, borderRadius:9, background:dark?themePrimary+"25":themePrimary+"18", display:"flex", alignItems:"center", justifyContent:"center" }}>
                    <Zap size={13} strokeWidth={2} color={dark?lighten(themeAccent,0.3):themePrimary}/>
                  </div>
                  <p style={{ fontSize:13, fontWeight:800, color: dark?lighten(themeAccent,0.3):themePrimary }}>{L.repInsightWeekly}</p>
                </div>
                <div style={{ display:"flex", flexDirection:"column", gap:7 }}>
                  <div style={{ display:"flex", alignItems:"center", gap:8 }}>
                    <div style={{ width:22, height:22, borderRadius:50, background:dark?"rgba(255,255,255,0.07)":themePrimary+"18", display:"flex", alignItems:"center", justifyContent:"center", flexShrink:0 }}>
                      <TrendingUp size={11} strokeWidth={2.5} color={dark?lighten(themeAccent,0.3):themePrimary}/>
                    </div>
                    <p style={{ fontSize:12, color: dark?lighten(themeAccent,0.2):themePrimary }}>{L.repWeekTotal} <b>{formatRp(weeklyInsight.thisTotal)}</b></p>
                  </div>
                  {weeklyInsight.hasBoth && weeklyInsight.diff !== 0 && (
                    <div style={{ display:"flex", alignItems:"center", gap:8 }}>
                      <div style={{ width:22, height:22, borderRadius:50, background: weeklyInsight.diff>0?"rgba(239,68,68,0.15)":"rgba(22,163,74,0.15)", display:"flex", alignItems:"center", justifyContent:"center", flexShrink:0 }}>
                        <TrendingUp size={11} strokeWidth={2.5} color={weeklyInsight.diff>0?"#ef4444":"#16a34a"} style={{ transform: weeklyInsight.diff<0?"rotate(180deg)":"none" }}/>
                      </div>
                      <p style={{ fontSize:12, color: dark?lighten(themeAccent,0.2):themePrimary }}>{weeklyInsight.diff>0?L.repMoreSpend:L.repLessSpend} {formatRp(Math.abs(weeklyInsight.diff))} {L.repVsLastWeek}</p>
                    </div>
                  )}
                  {weeklyInsight.topCat && (
                    <div style={{ display:"flex", alignItems:"center", gap:8 }}>
                      <div style={{ width:22, height:22, borderRadius:50, background:dark?"rgba(255,255,255,0.07)":themePrimary+"18", display:"flex", alignItems:"center", justifyContent:"center", flexShrink:0 }}>
                        <CatIcon iconKey={weeklyInsight.topCat.icon} size={11} color={dark?lighten(themeAccent,0.3):themePrimary}/>
                      </div>
                      <p style={{ fontSize:12, color: dark?lighten(themeAccent,0.2):themePrimary }}>{L.repTopCat} <b style={{ color:weeklyInsight.topCat.color }}>{getCatLabel(weeklyInsight.topCat, lang)}</b></p>
                    </div>
                  )}
                </div>
              </div>
            )}

            {/* Export + Share buttons */}
            <div style={{ display:"flex", gap:8, marginBottom:12 }}>
              <button className="btn-g" style={{ flex:1, background:T.card, color:T.text, border:`1.5px solid ${T.cardBorder}`, display:"flex", alignItems:"center", justifyContent:"center", gap:6, padding:"10px 12px", fontSize:13 }}
                onClick={() => { exportCSV(transactions, categories, lang); showToast(lang==="en"?"ok:CSV downloaded successfully":"ok:CSV berhasil didownload"); }}>
                <Download size={14} strokeWidth={2}/> {L.exportCSV}
              </button>
              <button className="btn-g" style={{ flex:1, background:T.card, color:T.text, border:`1.5px solid ${T.cardBorder}`, display:"flex", alignItems:"center", justifyContent:"center", gap:6, padding:"10px 12px", fontSize:13 }}
                onClick={() => { exportPDFReport(transactions, categories, currentMonth, income, lang); showToast(L.toastReportOk); }}>
                <Download size={14} strokeWidth={2}/> {L.exportReport}
              </button>
            </div>
            {/* Share Summary button */}
            {(() => {
              const topCat = Object.entries(
                transactions.filter(t => getMonth(t.date) === currentMonth)
                  .reduce((acc, t) => { acc[t.category] = (acc[t.category]||0) + t.amount; return acc; }, {})
              ).sort((a,b) => b[1]-a[1])[0];
              const topCatLabel = topCat ? getCatLabel(getCategory(topCat[0]), lang) : "-";
              const sisa = income - totalExpense;
              const now3 = new Date();
              const bulan = now3.toLocaleDateString(lang==="en"?"en-GB":"id-ID", { month:"long", year:"numeric" });
              const shareText = lang === "en"
                ? `*Finance Report — ${bulan}*\n\nExpenses: ${formatRp(totalExpense)}\nIncome: ${formatRp(income)}\nRemaining: ${formatRp(Math.max(0,sisa))}\n\nBiggest: ${topCatLabel}${topCat ? ` (${formatRp(topCat[1])})` : ""}\n\n_Made with Meowlett_`
                : `*Laporan Keuangan — ${bulan}*\n\nPengeluaran: ${formatRp(totalExpense)}\nPemasukan: ${formatRp(income)}\nSisa: ${formatRp(Math.max(0,sisa))}\n\nTerbesar: ${topCatLabel}${topCat ? ` (${formatRp(topCat[1])})` : ""}\n\n_Dibuat dengan Meowlett_`;

              const handleShare = async () => {
                haptic();
                // 1. Native share (mobile)
                if (navigator.share) {
                  try { await navigator.share({ title: L.shareTitle, text: shareText }); return; }
                  catch(e) { if (e.name === "AbortError") return; } // user cancelled
                }
                // 2. Clipboard API
                if (navigator.clipboard?.writeText) {
                  try { await navigator.clipboard.writeText(shareText); showToast(L.shareCopied); return; } catch {}
                }
                // 3. Manual fallback — show textarea to copy
                showToast("info:"+L.shareCopy);
              };
              return (
                <div style={{ marginBottom:12 }}>
                  <button onClick={handleShare}
                    style={{ width:"100%", marginBottom:8, display:"flex", alignItems:"center", justifyContent:"center", gap:8,
                      padding:"12px", borderRadius:14, border:"none", cursor:"pointer",
                      background:`linear-gradient(135deg,${themeAccent},${themePrimary})`, color:"white", fontSize:13, fontWeight:800,
                      boxShadow:`0 4px 16px ${themeAccent}44` }}>
                    <Share2 size={15} strokeWidth={2.5}/> {L.shareSummary}
                  </button>
                  <button onClick={() => { haptic(); const url = `https://wa.me/?text=${encodeURIComponent(shareText)}`; window.open(url, "_blank"); }}
                    style={{ width:"100%", display:"flex", alignItems:"center", justifyContent:"center", gap:8,
                      padding:"12px", borderRadius:14, border:`1.5px solid ${themeAccent}`, cursor:"pointer",
                      background: `${themeAccent}15`, color:T.accentText, fontSize:13, fontWeight:800 }}>
                    <MessageCircle size={16} strokeWidth={2} fill={T.accentText}/>
                    {L.shareWhatsapp}
                  </button>
                </div>
              );
            })()}

            <div className="card" style={{ padding:16, marginBottom:12, ...CS }}>
              <div style={{ display:"flex", alignItems:"center", gap:7, marginBottom:9 }}><div style={{ width:28, height:28, borderRadius:9, background:`${TP}18`, display:"flex", alignItems:"center", justifyContent:"center" }}><Calendar size={13} strokeWidth={2} color={TP}/></div><p style={{ fontSize:13, fontWeight:800, color:T.text }}>{L.pickDate}</p></div>
              <input className="inp" type="date" value={reportDate} onChange={e => setReportDate(e.target.value)} style={{ background:T.inp, border:`1.5px solid ${T.inpBorder}`, color:T.text }} />
            </div>

            <div className="card" style={{ padding:18, marginBottom:12, background:dark?darken(themePrimary,0.55)+"cc":themePrimary+"12", border:`1px solid ${dark?themePrimary+"44":themePrimary+"33"}` }}>
              <p style={{ fontSize:11, fontWeight:700, color:T.textSub, letterSpacing:1 }}>{L.totalExpense}</p>
              <p style={{ fontSize:30, fontWeight:900, color: reportTotal > 0 ? "#f87171" : T.textSub, margin:"4px 0" }}>{reportTotal > 0 ? `-${formatRp(reportTotal)}` : formatRp(0)}</p>
              <p style={{ fontSize:12, color:T.textSub }}>{fmtDate(reportDate, lang)} · {reportTxns.length} {L.transactions_label}</p>
            </div>

            {reportTxns.length === 0 ? (
              <div className="card" style={{ padding:40, textAlign:"center", ...CSN }}>
                <div style={{ display:"flex", justifyContent:"center", marginBottom:10 }}>
                  <div style={{ width:60, height:60, borderRadius:"50%", background:`linear-gradient(135deg,${themeAccent}22,${themePrimary}18)`, border:`1.5px solid ${themeAccent}30`, display:"flex", alignItems:"center", justifyContent:"center" }}>
                    <X size={28} color={T.accentText} strokeWidth={1.5}/>
                  </div>
                </div>
                <p style={{ color:T.textSub, fontSize:14 }}>{L.noTxDate}</p>
              </div>
            ) : (
              <>
                <div className="card" style={{ padding:16, marginBottom:12, ...CS }}>
                  <div style={{ display:"flex", alignItems:"center", gap:7, marginBottom:11 }}>
                    <div style={{ width:24, height:24, borderRadius:7, background:`${TP}18`, display:"flex", alignItems:"center", justifyContent:"center" }}>
                      <BarChart2 size={12} strokeWidth={2} color={TP}/>
                    </div>
                    <p style={{ fontSize:13, fontWeight:800, color:T.text }}>{L.perCategory}</p>
                  </div>
                  <div style={{ display:"flex", flexDirection:"column", gap:8 }}>
                    {reportByCat.map(([key, amt]) => {
                      const cat = getCategory(key);
                      const pct = reportTotal > 0 ? Math.round((amt/reportTotal)*100) : 0;
                      return (
                        <div key={key}>
                          <div style={{ display:"flex", justifyContent:"space-between", marginBottom:4 }}>
                            <span style={{ fontSize:13, fontWeight:700, color:T.text, display:"flex", alignItems:"center", gap:5 }}><CatIcon iconKey={cat.icon} size={14} color={cat.color}/> {getCatLabel(cat, lang)}</span>
                            <span style={{ fontSize:13, fontWeight:700, color:T.textSub }}>{pct}% · {formatRp(amt)}</span>
                          </div>
                          <div style={{ background:T.bg, borderRadius:4, height:6 }}>
                            <div style={{ height:"100%", width:pct+"%", background:cat.color, borderRadius:4 }} />
                          </div>
                        </div>
                      );
                    })}
                  </div>
                </div>

                <div className="card" style={{ padding:16, marginBottom:12, ...CS }}>
                  <p style={{ fontSize:13, fontWeight:800, color:T.text, marginBottom:11 }}>{L.txDetail}</p>
                  <div style={{ display:"flex", flexDirection:"column", gap:8 }}>
                    {reportTxns.map(t => {
                      const cat = getCategory(t.category);
                      return (
                        <div key={t.id} style={{ display:"flex", alignItems:"center", gap:11, padding:"10px 0", borderBottom:`1px solid ${T.cardBorder}` }}>
                          <div style={{ width:36, height:36, borderRadius:11, background:cat.color+"25", display:"flex", alignItems:"center", justifyContent:"center", flexShrink:0 }}><CatIcon iconKey={cat.icon} size={17} color={cat.color}/></div>
                          <div style={{ flex:1, minWidth:0 }}>
                            <p style={{ fontSize:13, fontWeight:700, color:T.text }}>{t.description}</p>
                            {t.location && <p style={{ fontSize:11, color:T.textSub }}>{t.location}</p>}
                          </div>
                          <p style={{ fontSize:13, fontWeight:800, color:"#f87171" }}>-{formatRp(t.amount)}</p>
                        </div>
                      );
                    })}
                  </div>
                  <div style={{ display:"flex", justifyContent:"space-between", paddingTop:11, marginTop:4, borderTop:`2px solid ${T.inpBorder}` }}>
                    <span style={{ fontSize:14, fontWeight:800, color:T.text }}>{L.totalToday}</span>
                    <span style={{ fontSize:15, fontWeight:900, color:"#f87171" }}>-{formatRp(reportTotal)}</span>
                  </div>
                </div>

                {(() => {
                    const topCat = reportByCat[0];
                    const topC = topCat ? getCategory(topCat[0]) : null;
                    const daysInMonth = new Date(new Date(reportDate).getFullYear(), new Date(reportDate).getMonth()+1, 0).getDate();
                    const avgDaily = income > 0 ? Math.round(income / daysInMonth) : 0;
                    const isOver = reportTotal > avgDaily;
                    return (
                      <div className="card" style={{ padding:16, marginBottom:12, background: dark?darken(themePrimary,0.55)+"cc":themePrimary+"12", border:`1px solid ${dark?themePrimary+"44":themePrimary+"33"}` }}>
                        <div style={{ display:"flex", alignItems:"center", gap:7, marginBottom:10 }}>
                          <div style={{ width:28, height:28, borderRadius:9, background:dark?themePrimary+"25":themePrimary+"18", display:"flex", alignItems:"center", justifyContent:"center" }}>
                            <TrendingUp size={13} strokeWidth={2} color={dark?lighten(themeAccent,0.3):themePrimary}/>
                          </div>
                          <p style={{ fontSize:13, fontWeight:800, color: dark?lighten(themeAccent,0.3):themePrimary }}>{L.insightToday}</p>
                        </div>
                        <div style={{ display:"flex", flexDirection:"column", gap:8 }}>
                          {topCat && topC && (
                            <div style={{ display:"flex", alignItems:"center", gap:8 }}>
                              <div style={{ width:22, height:22, borderRadius:50, background:topC.color+"22", display:"flex", alignItems:"center", justifyContent:"center", flexShrink:0 }}>
                                <CatIcon iconKey={topC.icon} size={11} color={topC.color}/>
                              </div>
                              <p style={{ fontSize:12, color: dark?lighten(themeAccent,0.2):themePrimary }}>{L.topSpend} <b style={{ color:topC.color }}>{getCatLabel(topC, lang)}</b> — {formatRp(topCat[1])}</p>
                            </div>
                          )}
                          <div style={{ display:"flex", alignItems:"center", gap:8 }}>
                            <div style={{ width:22, height:22, borderRadius:50, background: isOver?"rgba(239,68,68,0.15)":"rgba(22,163,74,0.15)", display:"flex", alignItems:"center", justifyContent:"center", flexShrink:0 }}>
                              {isOver ? <AlertTriangle size={11} strokeWidth={2.5} color="#ef4444"/> : <CheckCircle size={11} strokeWidth={2.5} color="#16a34a"/>}
                            </div>
                            <p style={{ fontSize:12, color: isOver?"#ef4444": dark?"#86efac":"#16a34a" }}>
                              {isOver ? `${L.aboveAvg} (${formatRp(avgDaily)})` : `${L.belowAvg} (${formatRp(avgDaily)})`}
                            </p>
                          </div>
                          {reportTxns.length > 0 && (
                            <div style={{ display:"flex", alignItems:"center", gap:8 }}>
                              <div style={{ width:22, height:22, borderRadius:50, background:dark?"rgba(255,255,255,0.07)":themePrimary+"18", display:"flex", alignItems:"center", justifyContent:"center", flexShrink:0 }}>
                                <Calculator2 size={11} strokeWidth={2.5} color={dark?lighten(themeAccent,0.3):themePrimary}/>
                              </div>
                              <p style={{ fontSize:12, color: dark?lighten(themeAccent,0.2):themePrimary }}>{L.avgPerTx} <b>{formatRp(Math.round(reportTotal/reportTxns.length))}</b></p>
                            </div>
                          )}
                        </div>
                      </div>
                    );
                  })()}
              </>
            )}

          </div>
            </div>
        </>
  );
}
