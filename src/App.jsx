import React, { useState, useMemo, useRef, useEffect, useCallback, lazy, Suspense } from "react";

// Lazy-loaded tab components for code-splitting
const TabDashboard    = lazy(() => import("./components/TabDashboard.jsx"));
const TabTransactions = lazy(() => import("./components/TabTransactions.jsx"));
const TabReport       = lazy(() => import("./components/TabReport.jsx"));
const TabDate         = lazy(() => import("./components/TabDate.jsx"));
const TabSettings     = lazy(() => import("./components/TabSettings.jsx"));
import {
  Home, House, List, LayoutList, BarChart2, Heart, ArrowDown, RefreshCw, Coins,
  Utensils, Car, ShoppingBag, Gamepad2, Pill, FileText, Package,
  Coffee, Pizza, Plane, Book, Music, Monitor, Gift, Dumbbell,
  PawPrint, Leaf, DollarSign, Palette, Droplets, Shirt, Wrench,
  Film, Beer, Umbrella, Flower2,
  Pencil, Trash2, Plus,
  Calendar, PiggyBank, TrendingUp, Clock, Wallet,
  BadgeDollarSign, User, ChartPie,
  Sun, Moon, SlidersHorizontal,
  CircleDollarSign, AlertTriangle, CheckCircle, Search, Inbox,
  ArrowRight, Banknote, Download, Bell, BellOff, X, Camera, Settings,
  WifiOff, Repeat, AlertCircle, Sparkles, Flame, Wind, Zap, Smartphone, Laptop, ChevronDown, ChevronRight, Target, Save, Upload, Share2, Calculator2,
  CreditCard, ImagePlus, Image, ZoomIn, AlarmClock, BellRing, CheckCheck, Tag, Tags,
  Users, UserPlus, Equal, Receipt,
  HeartPulse, Rocket, Flag, Ban, DiamondPlus, SunMoon, Globe, PaintRoller, Grape, BadgeInfo, Cat, HandCoins,
  Waves, Citrus, PaintbrushVertical, MessageCircle, CirclePlus, Smile, Star
} from "./icons.jsx";
import { formatRp, today, getWeek, getMonth, fmtDate, groupByDate, dateLabel, getCatLabel, haptic, parseRpInput, rpInputProps } from "./utils/helpers.js";
import { darken, lighten, getLuminance, getContrastText, buildTheme } from "./utils/theme.js";
import { exportCSV, exportPDFReport } from "./utils/export.js";
import { requestNotificationPermission, sendLocalNotification, scheduleSmartReminder } from "./utils/notifications.js";
import { DEFAULT_CATEGORIES, THEME_PRESETS, GOAL_ICONS, ICON_OPTIONS, COLOR_OPTIONS, PRESET_ICONS } from "./constants/index.js";
import { LANG } from "./constants/lang.js";
import AnimatedNumber from "./components/AnimatedNumber.jsx";
import DonutChart from "./components/DonutChart.jsx";

// IndexedDB helpers for transaction persistence
const IDB_NAME = "meowlett_db", IDB_STORE = "transactions", IDB_VER = 1;
const openIDB = () => new Promise((res,rej) => {
  const req = indexedDB.open(IDB_NAME, IDB_VER);
  req.onupgradeneeded = e => e.target.result.createObjectStore(IDB_STORE, { keyPath:"id" });
  req.onsuccess = e => res(e.target.result);
  req.onerror = () => rej();
});
const saveToIDB = async (txns) => {
  try {
    const db = await openIDB();
    const tx = db.transaction(IDB_STORE, "readwrite");
    const store = tx.objectStore(IDB_STORE);
    store.clear();
    txns.forEach(t => store.put(t));
  } catch {}
};
const loadFromIDB = async () => {
  try {
    const db = await openIDB();
    return new Promise((res) => {
      const tx = db.transaction(IDB_STORE, "readonly");
      const req = tx.objectStore(IDB_STORE).getAll();
      req.onsuccess = () => res(req.result || []);
      req.onerror = () => res([]);
    });
  } catch { return []; }
};

function Ic({ icon, size = 18, color, style = {} }) {
  const Icon = icon;
  return <Icon size={size} color={color} strokeWidth={2} style={{ flexShrink: 0, ...style }} />;
}

const LUCIDE_MAP = {
  // Makanan & Minuman
  utensils: Utensils, coffee: Coffee, pizza: Pizza, beer: Beer,
  // Transportasi & Perjalanan
  car: Car, plane: Plane,
  // Belanja & Gaya Hidup
  shoppingbag: ShoppingBag, shirt: Shirt, palette: Palette, gift: Gift,
  // Kesehatan & Olahraga
  heart: Heart, pill: Pill, dumbbell: Dumbbell,
  // Keuangan
  dollar: CircleDollarSign, banknote: Banknote, wallet: Wallet, piggybank: PiggyBank, trendingup: TrendingUp, coins: Coins,
  // Rumah & Utilitas
  home: Home, droplets: Droplets, zap: Zap, wrench: Wrench, flame: Flame, wind: Wind,
  // Teknologi & Hiburan
  monitor: Monitor, smartphone: Smartphone, laptop: Laptop, gamepad: Gamepad2, music: Music, film: Film, book: Book,
  // Alam & Hewan
  leaf: Leaf, pawprint: PawPrint, flower: Flower2, umbrella: Umbrella,
  // Lain-lain
  package: Package, filetext: FileText, sparkles: Sparkles, target: Target, repeat: Repeat,
  inbox: Inbox, users: Users, clock: Clock, calendar: Calendar, search: Search,
  alarmclock: AlarmClock, bell: Bell, star: Sparkles, tag: Tag, receipt: Receipt,
};
const CatIcon = ({ iconKey, size = 18, color }) => {
  const Icon = LUCIDE_MAP[iconKey] || Package;
  return <Icon size={size} color={color} strokeWidth={2} style={{ flexShrink: 0 }} />;
};

function PresetIcon({ name, size=14, color, strokeWidth=2 }) {
  const Icon = PRESET_ICONS[name] || Palette;
  return <Icon size={size} color={color} strokeWidth={strokeWidth}/>;
}

function SwipeRow({ children, onDelete, style = {} }) {
  return (
    <div style={{ position: "relative", ...style }}>
      {children}
    </div>
  );
}

const STYLES = `
  @import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800;900&display=swap');
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { font-family: 'Plus Jakarta Sans', 'Nunito', -apple-system, BlinkMacSystemFont, 'Helvetica Neue', sans-serif; -webkit-text-size-adjust: 100%; -webkit-font-smoothing: antialiased; -moz-osx-font-smoothing: grayscale; }
  * { -webkit-tap-highlight-color: transparent; -webkit-touch-callout: none; }
  input, textarea, select, [contenteditable] { -webkit-touch-callout: default; user-select: text; -webkit-user-select: text; }
  .scroll-area { -webkit-overflow-scrolling: touch; overscroll-behavior: none; }
  input, select, textarea { font-size: 16px !important; border-radius: 0; -webkit-appearance: none; }
  input[type=number]::-webkit-inner-spin-button, input[type=number]::-webkit-outer-spin-button { -webkit-appearance: none; margin: 0; }
  input[type=number] { -moz-appearance: textfield; }
  input[type=date]::-webkit-calendar-picker-indicator { opacity:0; width:100%; height:100%; position:absolute; top:0; left:0; cursor:pointer; }
  button { touch-action: manipulation; -webkit-appearance: none; }
  a { touch-action: manipulation; }
  .fi { display:flex; flex-direction:column; width: 100%; }
  .card { border-radius:18px; transition: background-color 0.35s ease, box-shadow 0.35s ease, border-color 0.35s ease; }
  .inp { width:100%; padding:13px 16px; border-radius:14px; font-size:16px; font-family:inherit; outline:none; display:block; transition: background-color 0.3s, border-color 0.3s; }
  .btn-p { background:var(--accent); color:white; border:none; border-radius:14px; padding:14px 20px; font-size:14px; font-weight:800; cursor:pointer; font-family:inherit; letter-spacing:0.3px; transition: opacity 0.15s, transform 0.15s; min-height:44px; }
  .btn-p:active { opacity:0.82; transform:scale(0.97); }
  .btn-g { border-radius:14px; padding:13px 18px; font-size:14px; font-weight:700; cursor:pointer; font-family:inherit; transition: opacity 0.15s, transform 0.15s; }
  .btn-g:active { opacity:0.75; transform:scale(0.97); }
  .btn-d { border-radius:12px; padding:7px 11px; font-size:13px; font-weight:700; cursor:pointer; font-family:inherit; transition: opacity 0.15s, transform 0.15s; }
  .btn-d:active { opacity:0.75; transform:scale(0.96); }
  .btn-sm { border-radius:12px; padding:7px 11px; font-size:13px; font-weight:700; cursor:pointer; font-family:inherit; }
  .nav-i { display:flex; flex-direction:column; align-items:center; gap:2px; font-size:10px; font-weight:700; background:none; border:none; cursor:pointer; padding:6px 10px; border-radius:14px; font-family:inherit; min-width:52px; min-height:44px; justify-content:center; }
  .icon-btn { font-size:20px; border:2px solid transparent; border-radius:12px; padding:6px; cursor:pointer; display:flex; align-items:center; justify-content:center; transition: transform 0.18s cubic-bezier(0.34,1.56,0.64,1), border-color 0.2s; }
  .icon-btn:active { transform: scale(0.88); }
  .icon-btn.sel { border-color:var(--accent); }
  .cdot { width:28px; height:28px; border-radius:50%; cursor:pointer; border:3px solid transparent; transition: transform 0.18s cubic-bezier(0.34,1.56,0.64,1), border-color 0.2s; }
  .cdot:active { transform: scale(0.85); }
  .cdot.sel { border-color:var(--primary); transform: scale(1.12); }
  select.inp { appearance:none; }
  select { color-scheme: light dark; }
  svg text { -webkit-user-select:none; user-select:none; pointer-events:none; }

  /* Theme transition - semua elemen smooth saat ganti warna/dark */
  .theme-flash, .theme-flash * {
    transition: background-color 0.35s ease, color 0.35s ease, border-color 0.35s ease !important;
  }

  /* Tab content slide + fade */
  @keyframes tab-enter { 0%{opacity:0; transform:translateY(10px) scale(0.99)} 100%{opacity:1; transform:translateY(0) scale(1)} }
  .tab-enter { animation: tab-enter 0.22s cubic-bezier(0.34,1.1,0.64,1) forwards; }

  /* Card pop-in */
  @keyframes card-pop { 0%{opacity:0; transform:translateY(6px)} 100%{opacity:1; transform:translateY(0)} }
  .card-pop { animation: card-pop 0.18s ease-out forwards; }

  /* Modal slide up */
  @keyframes modal-up { 0%{transform:translateY(100%); opacity:0.6} 100%{transform:translateY(0); opacity:1} }
  .modal-up { animation: modal-up 0.32s cubic-bezier(0.25,0.46,0.45,0.94) forwards; }

  /* Modal float center */
  @keyframes modal-float { 0%{transform:scale(0.88) translateY(16px); opacity:0} 100%{transform:scale(1) translateY(0); opacity:1} }
  .modal-float { animation: modal-float 0.28s cubic-bezier(0.34,1.2,0.64,1) forwards; }

  /* Nav icon active pop */
  @keyframes nav-icon-in { 0%{transform:scale(0.8); opacity:0.4} 60%{transform:scale(1.15)} 100%{transform:scale(1); opacity:1} }
  @keyframes nav-label-in { 0%{opacity:1; -webkit-clip-path:inset(0 100% 0 0); clip-path:inset(0 100% 0 0)} 100%{opacity:1; -webkit-clip-path:inset(0 0% 0 0); clip-path:inset(0 0% 0 0)} }
  .nav-icon-pop { animation: nav-icon-pop 0.28s cubic-bezier(0.34,1.56,0.64,1) forwards; }

  /* Skeleton */
  @keyframes skeleton-pulse { 0%,100%{opacity:0.4} 50%{opacity:0.75} }
  .skeleton { animation: skeleton-pulse 1.4s ease-in-out infinite; }

  /* Toast */
  @keyframes toast-in { 0%{transform:translateX(-50%) translateY(100px);opacity:0} 20%{transform:translateX(-50%) translateY(0);opacity:1} 80%{transform:translateX(-50%) translateY(0);opacity:1} 100%{transform:translateX(-50%) translateY(100px);opacity:0} }
  @keyframes toast-slide-up { from{opacity:0;transform:translateX(-50%) translateY(16px)} to{opacity:1;transform:translateX(-50%) translateY(0)} }
  @keyframes swipe-hint { 0%{transform:translateX(0)} 30%{transform:translateX(-55px)} 60%{transform:translateX(-10px)} 80%{transform:translateX(-20px)} 100%{transform:translateX(0)} }
  .swipe-hint-anim { animation: swipe-hint 0.9s cubic-bezier(0.25,0.46,0.45,0.94) forwards; }
  .toast { animation: toast-in 3s ease forwards; }

  /* Dark mode ripple */
  @keyframes dark-ripple-expand { 0%{transform:scale(0);opacity:0.9} 100%{transform:scale(1);opacity:0} }
  @keyframes spin { to { transform: rotate(360deg); } }
  @keyframes nav-pop { 0%{transform:translateY(-50%) scale(0.7)} 60%{transform:translateY(-50%) scale(1.1)} 100%{transform:translateY(-50%) scale(1)} }
  .ge-indicator-active { animation: nav-pop 0.35s cubic-bezier(0.34,1.56,0.64,1) both; }
  @keyframes count-up { 0%{opacity:0;transform:translateY(6px)} 100%{opacity:1;transform:translateY(0)} }
  @keyframes shimmer { 0%{background-position:-200% 0} 100%{background-position:200% 0} }
  .shimmer-bar { background: linear-gradient(90deg, transparent 25%, rgba(255,255,255,0.4) 50%, transparent 75%); background-size: 200% 100%; animation: shimmer 2s infinite linear; }
  @keyframes confetti-fall { 0%{transform:translateY(-10px) rotate(0deg);opacity:1} 100%{transform:translateY(60px) rotate(720deg);opacity:0} }
  .confetti-piece { position:absolute; width:6px; height:6px; border-radius:1px; animation:confetti-fall 0.8s ease-out forwards; pointer-events:none; }
  @keyframes theme-flash { 0%{filter:brightness(1)} 30%{filter:brightness(1.08)} 100%{filter:brightness(1)} }
  .theme-flash { animation: theme-flash 0.45s ease forwards; }

  /* FAB pulse ring */
  @keyframes fab-ring { 0%{box-shadow:0 0 0 0 rgba(var(--fab-color),0.5)} 70%{box-shadow:0 0 0 10px rgba(var(--fab-color),0)} 100%{box-shadow:0 0 0 0 rgba(var(--fab-color),0)} }

  /* Number count-up flicker */
  @keyframes num-pop { 0%{transform:scale(1)} 40%{transform:scale(1.06)} 100%{transform:scale(1)} }
  .num-pop { animation: num-pop 0.25s ease forwards; }

  /* Slide in from right (form) */
  @keyframes slide-in-r { 0%{opacity:0; transform:translateX(18px)} 100%{opacity:1; transform:translateX(0)} }
  .slide-in { animation: slide-in-r 0.22s cubic-bezier(0.25,0.46,0.45,0.94) forwards; }

  /* Bounce in (savings goal bar) */
  @keyframes bar-fill { 0%{width:0%} 100%{width:var(--bar-w)} }

  /* FAB tap bounce */
  .fab-btn { transition: transform 0.18s cubic-bezier(0.34,1.56,0.64,1), box-shadow 0.18s; }
  .fab-btn:active { transform: scale(0.88) !important; }

  /* Swipe row */
  .swipe-row { transition: transform 0.3s cubic-bezier(0.25,0.46,0.45,0.94); touch-action: pan-y; }
  .swipe-row.dragging { transition: none; }
  @keyframes row-delete { 0%{opacity:1;max-height:80px;margin-bottom:8px} 100%{opacity:0;max-height:0;margin-bottom:0} }
  .row-deleting { animation: row-delete 0.3s ease forwards; overflow:hidden; }

  /* Budget bar animated */
  @keyframes budget-fill { 0%{width:0%} 100%{width:var(--bw)} }
  .budget-bar { animation: budget-fill 0.9s cubic-bezier(0.25,0.46,0.45,0.94) forwards; }

  /* Empty state pulse */
  @keyframes fab-item-in { from{opacity:0;transform:translateY(12px) scale(0.9)} to{opacity:1;transform:translateY(0) scale(1)} }

  /* Share copy flash */
  @keyframes copy-flash { 0%{transform:scale(1)} 40%{transform:scale(0.95)} 100%{transform:scale(1)} }
  .copy-flash { animation: copy-flash 0.2s ease; }
`;

const THEME_LABELS = { green:"themeGreen", blue:"themeBlue", purple:"themePurple", rose:"themeRose", orange:"themeOrange", teal:"themeTeal" };

// ── Split Bills Modal ─────────────────────────────────────────────────────────
function SplitBillsModal({ show, onClose, splitBills, setSplitBills, T, themeAccent, themePrimary, dark, lang, formatRp, parseRpInput, haptic, showToast }) {
  const L = LANG[lang] || LANG.id;
  const [view, setView] = React.useState("list"); // list | form | detail
  const [editId, setEditId] = React.useState(null);
  const [detail, setDetail] = React.useState(null);
  const [form, setForm] = React.useState({ title:"", totalDisplay:"", total:"", members:"", paidBy:"" });

  if (!show) return null;

  const resetForm = () => setForm({ title:"", totalDisplay:"", total:"", members:"", paidBy:"" });

  const save = () => {
    if (!form.title || !form.total) return;
    const names = form.members.split(",").map(s=>s.trim()).filter(Boolean);
    if (names.length < 2) { showToast("err:"+(L.splitMinMembers)); return; }
    const perPerson = Math.round(Number(form.total) / names.length);
    const item = {
      id: editId || Date.now(),
      title: form.title,
      total: Number(form.total),
      members: names.map(name => ({
        name,
        share: perPerson,
        paid: editId ? (splitBills.find(x=>x.id===editId)?.members.find(m=>m.name===name)?.paid || false) : false
      })),
      paidBy: form.paidBy || names[0],
      date: new Date().toISOString().split("T")[0],
      settled: false,
    };
    if (editId) {
      setSplitBills(p => p.map(x => x.id===editId ? {...item, settled: x.settled} : x));
    } else {
      setSplitBills(p => [...p, item]);
    }
    showToast("ok:"+L.splitSaved.replace("ok:",""));
    haptic("success");
    resetForm(); setEditId(null); setView("list");
  };

  const del = (id) => {
    setSplitBills(p => p.filter(x => x.id !== id));
    showToast("ok:"+L.splitDeleted.replace("ok:",""));
    setView("list"); setDetail(null); haptic();
  };

  const togglePaid = (billId, memberName) => {
    setSplitBills(p => p.map(bill => {
      if (bill.id !== billId) return bill;
      const updated = bill.members.map(m => m.name===memberName ? {...m, paid:!m.paid} : m);
      const settled = updated.every(m => m.name===bill.paidBy || m.paid);
      return {...bill, members:updated, settled};
    }));
    setDetail(prev => {
      if (!prev || prev.id !== billId) return prev;
      const updated = prev.members.map(m => m.name===memberName ? {...m, paid:!m.paid} : m);
      const settled = updated.every(m => m.name===prev.paidBy || m.paid);
      return {...prev, members:updated, settled};
    });
    haptic();
  };

  const openEdit = (bill) => {
    setEditId(bill.id);
    setForm({
      title: bill.title,
      total: String(bill.total),
      totalDisplay: Number(bill.total).toLocaleString("id-ID"),
      members: bill.members.map(m=>m.name).join(", "),
      paidBy: bill.paidBy,
    });
    setView("form");
  };

  const active = splitBills.filter(b => !b.settled);
  const done   = splitBills.filter(b => b.settled);

  return (
    <div style={{ position:"fixed", inset:0, background:"rgba(0,0,0,0.55)", backdropFilter:"blur(6px)", WebkitBackdropFilter:"blur(6px)", zIndex:300, display:"flex", alignItems:"flex-end", justifyContent:"center" }}
      onClick={e => { if(e.target===e.currentTarget) onClose(); }}>
      <div style={{ background:T.modalBg||T.card, borderRadius:"28px 28px 0 0", width:"100%", maxWidth:420, maxHeight:"90dvh", display:"flex", flexDirection:"column", overflow:"hidden" }}>
        {/* Handle */}
        <div style={{ width:36, height:4, background:T.cardBorder, borderRadius:99, margin:"12px auto 0", flexShrink:0 }}/>

        {/* Header */}
        <div style={{ display:"flex", alignItems:"center", justifyContent:"space-between", padding:"12px 20px 14px", borderBottom:`1px solid ${T.cardBorder}`, flexShrink:0 }}>
          <div style={{ display:"flex", alignItems:"center", gap:9 }}>
            <Users size={18} color={themeAccent} strokeWidth={2}/>
            <p style={{ fontSize:16, fontWeight:900, color:T.text }}>{L.splitBills}</p>
          </div>
          <div style={{ display:"flex", gap:8, alignItems:"center" }}>
            {view==="list" && (
              <button onClick={() => { resetForm(); setEditId(null); setView("form"); }}
                style={{ background:`linear-gradient(135deg,${themeAccent},${themePrimary})`, border:"none", borderRadius:10, padding:"6px 12px", color:"white", fontSize:12, fontWeight:800, cursor:"pointer", display:"flex", alignItems:"center", gap:5, fontFamily:"inherit" }}>
                <Plus size={13} strokeWidth={2.5}/> {lang==="en"?"New":"Baru"}
              </button>
            )}
            <button onClick={onClose} style={{ width:30, height:30, borderRadius:"50%", background:T.card2, border:"none", cursor:"pointer", display:"flex", alignItems:"center", justifyContent:"center" }}>
              <X size={14} color={T.textSub} strokeWidth={2}/>
            </button>
          </div>
        </div>

        {/* Body */}
        <div style={{ overflowY:"auto", flex:1, padding:16 }}>

          {/* ── FORM ── */}
          {view==="form" && (
            <div style={{ display:"flex", flexDirection:"column", gap:10 }}>
              <p style={{ fontSize:13, fontWeight:800, color:T.text, marginBottom:4 }}>
                {editId ? (L.splitEdit) : (L.splitNew)}
              </p>
              <input className="inp" placeholder={lang==="en"?L.splitTitle:"Judul (mis. Makan di X)"}
                value={form.title} onChange={e=>setForm(f=>({...f,title:e.target.value}))}
                style={{ background:T.inp, border:`1.5px solid ${T.inpBorder}`, color:T.text }}/>
              <input className="inp" type="text" inputMode="numeric" placeholder={lang==="en"?L.splitTotal:"Total tagihan (mis. 300.000)"}
                value={form.totalDisplay||""}
                onFocus={e=>e.target.select()}
                onChange={e=>{ const {display,raw}=parseRpInput(e.target.value); setForm(f=>({...f,total:raw,totalDisplay:display})); }}
                style={{ background:T.inp, border:`1.5px solid ${T.inpBorder}`, color:T.text }}/>
              <div>
                <p style={{ fontSize:10, fontWeight:700, color:T.textSub, marginBottom:4 }}>
                  {L.splitMembers}
                </p>
                <input className="inp" placeholder={lang==="en"?"e.g. Alice, Bob, Charlie":"mis. Andi, Budi, Cici"}
                  value={form.members} onChange={e=>setForm(f=>({...f,members:e.target.value}))}
                  style={{ background:T.inp, border:`1.5px solid ${T.inpBorder}`, color:T.text }}/>
              </div>
              <div>
                <p style={{ fontSize:10, fontWeight:700, color:T.textSub, marginBottom:4 }}>
                  {L.splitPayer}
                </p>
                <input className="inp" placeholder={L.splitPayerPlaceholder}
                  value={form.paidBy} onChange={e=>setForm(f=>({...f,paidBy:e.target.value}))}
                  style={{ background:T.inp, border:`1.5px solid ${T.inpBorder}`, color:T.text }}/>
              </div>
              {form.total && form.members && form.members.split(",").filter(s=>s.trim()).length >= 2 && (
                <div style={{ background:`${themeAccent}12`, border:`1px solid ${themeAccent}30`, borderRadius:12, padding:"10px 14px", display:"flex", alignItems:"center", gap:10 }}>
                  <Equal size={14} color={themeAccent} strokeWidth={2.5}/>
                  <p style={{ fontSize:13, fontWeight:800, color:T.text }}>
                    {formatRp(Math.round(Number(form.total) / form.members.split(",").filter(s=>s.trim()).length))}
                    <span style={{ fontSize:11, fontWeight:600, color:T.textSub }}> / {L.splitPerson}</span>
                  </p>
                </div>
              )}
              <div style={{ display:"flex", gap:8, marginTop:4 }}>
                <button onClick={() => { haptic("success"); save(); }} style={{ flex:1, padding:"12px 0", borderRadius:14, background:`linear-gradient(135deg,${themeAccent},${themePrimary})`, border:"none", color:"white", fontSize:13, fontWeight:800, cursor:"pointer", fontFamily:"inherit" }}>
                {lang==="en"?"Save":"Simpan"}
                </button>
                <button onClick={() => { setView("list"); setEditId(null); resetForm(); }}
                  style={{ flex:.5, padding:"12px 0", borderRadius:14, background:T.btnG||T.card2, border:`1.5px solid ${T.btnGBorder||T.cardBorder}`, color:T.btnGText||T.textSub, fontSize:13, fontWeight:700, cursor:"pointer", fontFamily:"inherit" }}>
                  {lang==="en"?"Cancel":"Batal"}
                </button>
              </div>
            </div>
          )}

          {/* ── DETAIL ── */}
          {view==="detail" && detail && (() => {
            const bill = splitBills.find(b=>b.id===detail.id) || detail;
            const perPerson = Math.round(bill.total / bill.members.length);
            const paidCount = bill.members.filter(m=>m.paid||m.name===bill.paidBy).length;
            return (
              <div>
                {/* Hero */}
                <div style={{ background:`linear-gradient(135deg,${themePrimary},${themeAccent}88)`, borderRadius:18, padding:"18px 20px 20px", marginBottom:14 }}>
                  <p style={{ fontSize:18, fontWeight:900, color:"white", marginBottom:4 }}>{bill.title}</p>
                  <p style={{ fontSize:13, color:"rgba(255,255,255,0.75)", marginBottom:12 }}>
                    {bill.date} · {bill.members.length} {L.splitPeople}
                  </p>
                  <div style={{ display:"flex", gap:20 }}>
                    <div>
                      <p style={{ fontSize:20, fontWeight:900, color:"white" }}>{formatRp(bill.total)}</p>
                      <p style={{ fontSize:10, color:"rgba(255,255,255,0.6)", fontWeight:600 }}>{lang==="en"?"TOTAL":"TOTAL"}</p>
                    </div>
                    <div>
                      <p style={{ fontSize:20, fontWeight:900, color:"white" }}>{formatRp(perPerson)}</p>
                      <p style={{ fontSize:10, color:"rgba(255,255,255,0.6)", fontWeight:600 }}>{lang==="en"?"PER PERSON":"PER ORANG"}</p>
                    </div>
                    <div>
                      <p style={{ fontSize:20, fontWeight:900, color:"white" }}>{paidCount}/{bill.members.length}</p>
                      <p style={{ fontSize:10, color:"rgba(255,255,255,0.6)", fontWeight:600 }}>{lang==="en"?"PAID":"LUNAS"}</p>
                    </div>
                  </div>
                </div>

                {/* Progress bar */}
                <div style={{ height:6, borderRadius:99, background:T.card2, overflow:"hidden", marginBottom:14 }}>
                  <div style={{ height:"100%", width:`${(paidCount/bill.members.length)*100}%`, background:`linear-gradient(90deg,${themeAccent},${themePrimary})`, borderRadius:99, transition:"width 0.4s ease" }}/>
                </div>

                {/* Paid by info */}
                <p style={{ fontSize:11, fontWeight:700, color:T.textSub, marginBottom:10 }}>
                  {L.splitPaidBy}: <span style={{ color:themeAccent }}>{bill.paidBy}</span>
                  {" — "}{L.splitTapMark}
                </p>

                {/* Members list */}
                <div style={{ display:"flex", flexDirection:"column", gap:8, marginBottom:16 }}>
                  {bill.members.map(m => {
                    const isPayer = m.name === bill.paidBy;
                    const isDone  = m.paid || isPayer;
                    return (
                      <div key={m.name}
                        onClick={() => !isPayer && togglePaid(bill.id, m.name)}
                        style={{ display:"flex", alignItems:"center", gap:12, padding:"12px 14px", borderRadius:14, background: isDone ? `${themeAccent}15` : T.card2, border:`1.5px solid ${isDone ? themeAccent+"40" : T.cardBorder}`, cursor: isPayer ? "default" : "pointer", transition:"all 0.15s" }}>
                        <div style={{ width:36, height:36, borderRadius:"50%", background: isDone ? `linear-gradient(135deg,${themeAccent},${themePrimary})` : T.catBg, display:"flex", alignItems:"center", justifyContent:"center", flexShrink:0 }}>
                          {isDone
                            ? <CheckCheck size={16} color="white" strokeWidth={2.5}/>
                            : <User size={16} color={T.textSub} strokeWidth={2}/>
                          }
                        </div>
                        <div style={{ flex:1 }}>
                          <p style={{ fontSize:14, fontWeight:700, color:T.text }}>{m.name}</p>
                          <p style={{ fontSize:11, color:T.textSub, marginTop:1 }}>
                            {isPayer
                              ? (L.splitPaidBill)
                              : isDone
                                ? (L.splitHasPaid)
                                : (L.splitNotPaid)
                            }
                          </p>
                        </div>
                        <p style={{ fontSize:14, fontWeight:800, color: isDone ? themeAccent : T.text }}>
                          {isPayer ? `+${formatRp(bill.total - perPerson)}` : `-${formatRp(perPerson)}`}
                        </p>
                      </div>
                    );
                  })}
                </div>

                {/* Actions */}
                <div style={{ display:"flex", gap:8 }}>
                  <button onClick={() => openEdit(bill)}
                    style={{ width:44, height:44, borderRadius:12, background:T.catBg, border:`1.5px solid ${T.cardBorder}`, cursor:"pointer", display:"flex", alignItems:"center", justifyContent:"center" }}>
                    <Pencil size={15} color={T.text} strokeWidth={2}/>
                  </button>
                  <button onClick={() => del(bill.id)}
                    style={{ width:44, height:44, borderRadius:12, background:"#ef444418", border:"1.5px solid #ef444435", cursor:"pointer", display:"flex", alignItems:"center", justifyContent:"center" }}>
                    <Trash2 size={15} color="#f87171" strokeWidth={2}/>
                  </button>
                  <button onClick={() => { setView("list"); setDetail(null); }}
                    style={{ flex:1, padding:"12px 0", borderRadius:12, background:T.card2, border:`1.5px solid ${T.cardBorder}`, color:T.textSub, fontSize:13, fontWeight:700, cursor:"pointer", fontFamily:"inherit" }}>
                    ← {lang==="en"?"Back":"Kembali"}
                  </button>
                </div>
              </div>
            );
          })()}

          {/* ── LIST ── */}
          {view==="list" && (
            <div>
              {splitBills.length === 0 ? (
                <div style={{ padding:"48px 20px", textAlign:"center" }}>
                  <div style={{ width:72, height:72, borderRadius:22, background:themeAccent+"18", border:`1.5px solid ${themeAccent}30`, display:"flex", alignItems:"center", justifyContent:"center", margin:"0 auto 14px" }}>
                    <Users size={32} color={themeAccent} strokeWidth={1.5}/>
                  </div>
                  <p style={{ fontSize:15, fontWeight:800, color:T.text, marginBottom:6 }}>
                    {L.splitEmpty}
                  </p>
                  <p style={{ fontSize:12, color:T.textSub }}>
                    {L.splitBillsDesc}
                  </p>
                </div>
              ) : (
                <div>
                  {active.length > 0 && (
                    <>
                      <p style={{ fontSize:11, fontWeight:800, color:T.textSub, letterSpacing:1, marginBottom:8 }}>
                        {L.splitActive}
                      </p>
                      <div style={{ display:"flex", flexDirection:"column", gap:8, marginBottom:16 }}>
                        {active.map(bill => {
                          const paidCount = bill.members.filter(m=>m.paid||m.name===bill.paidBy).length;
                          const pct = Math.round((paidCount/bill.members.length)*100);
                          return (
                            <div key={bill.id} onClick={() => { setDetail(bill); setView("detail"); }}
                              style={{ padding:"14px 16px", borderRadius:16, background:T.card2, border:`1.5px solid ${T.cardBorder}`, cursor:"pointer" }}>
                              <div style={{ display:"flex", justifyContent:"space-between", alignItems:"flex-start", marginBottom:8 }}>
                                <div>
                                  <p style={{ fontSize:14, fontWeight:800, color:T.text, marginBottom:2 }}>{bill.title}</p>
                                  <p style={{ fontSize:11, color:T.textSub }}>
                                    {bill.members.length} {L.splitPeople} · {formatRp(Math.round(bill.total/bill.members.length))}/{L.splitOrg}
                                  </p>
                                </div>
                                <p style={{ fontSize:15, fontWeight:900, color:T.text }}>{formatRp(bill.total)}</p>
                              </div>
                              <div style={{ height:4, borderRadius:99, background:T.catBg, overflow:"hidden" }}>
                                <div style={{ height:"100%", width:`${pct}%`, background:`linear-gradient(90deg,${themeAccent},${themePrimary})`, borderRadius:99 }}/>
                              </div>
                              <p style={{ fontSize:10, color:T.textSub, marginTop:4, fontWeight:600 }}>
                                {paidCount}/{bill.members.length} {L.splitPaidBack} ({pct}%)
                              </p>
                            </div>
                          );
                        })}
                      </div>
                    </>
                  )}
                  {done.length > 0 && (
                    <>
                      <p style={{ fontSize:11, fontWeight:800, color:T.textSub, letterSpacing:1, marginBottom:8 }}>
                        {L.splitSettled}
                      </p>
                      <div style={{ display:"flex", flexDirection:"column", gap:8 }}>
                        {done.map(bill => (
                          <div key={bill.id} onClick={() => { setDetail(bill); setView("detail"); }}
                            style={{ padding:"12px 16px", borderRadius:14, background:T.card2, border:`1.5px solid ${T.cardBorder}`, cursor:"pointer", opacity:0.6 }}>
                            <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center" }}>
                              <div>
                                <p style={{ fontSize:13, fontWeight:800, color:T.text }}>{bill.title}</p>
                                <p style={{ fontSize:11, color:T.textSub }}>
                                  ✓ {L.splitAllSettled} · {bill.date}
                                </p>
                              </div>
                              <p style={{ fontSize:14, fontWeight:800, color:themeAccent }}>{formatRp(bill.total)}</p>
                            </div>
                          </div>
                        ))}
                      </div>
                    </>
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

// ── Built-in Calculator ───────────────────────────────────────────────────────
function Calculator({ onUse, onClose, T, themeAccent, themePrimary, dark }) {
  const [display, setDisplay] = useState("0");
  const [prev, setPrev] = useState(null);
  const [op, setOp] = useState(null);
  const [fresh, setFresh] = useState(true);

  const press = (val) => {
    if (val === "C") { setDisplay("0"); setPrev(null); setOp(null); setFresh(true); return; }
    if (val === "⌫") { setDisplay(d => d.length > 1 ? d.slice(0,-1) : "0"); return; }
    if (val === "%") { setDisplay(d => String(parseFloat(d) / 100)); return; }
    if (["+","-","×","÷"].includes(val)) {
      setPrev(parseFloat(display)); setOp(val); setFresh(true); return;
    }
    if (val === "=") {
      if (prev === null || !op) return;
      const a = prev, b = parseFloat(display);
      let res = op==="+" ? a+b : op==="-" ? a-b : op==="×" ? a*b : b!==0 ? a/b : 0;
      // round floating point
      res = Math.round(res * 1e10) / 1e10;
      setDisplay(String(res)); setPrev(null); setOp(null); setFresh(true); return;
    }
    if (val === "." && display.includes(".")) return;
    setDisplay(d => {
      if (fresh || d === "0") { setFresh(false); return val === "." ? "0." : val; }
      return d.length < 12 ? d + val : d;
    });
  };

  const fmt = (s) => {
    const n = parseFloat(s);
    if (isNaN(n)) return s;
    if (s.endsWith(".") || s.endsWith(".0")) return s;
    return n.toLocaleString("id-ID", { maximumFractionDigits: 6 });
  };

  const rows = [
    ["C", "⌫", "%", "÷"],
    ["7", "8", "9", "×"],
    ["4", "5", "6", "-"],
    ["1", "2", "3", "+"],
    ["0", ".", "="],
  ];

  const isOp = v => ["+","-","×","÷"].includes(v);

  return (
    <div style={{ position:"fixed", inset:0, background:"rgba(0,0,0,0.6)", zIndex:9000, display:"flex", alignItems:"flex-end", justifyContent:"center" }} onClick={onClose}>
      <div style={{ background:T.card, borderRadius:"24px 24px 0 0", width:"100%", maxWidth:420, paddingBottom:"0px" }} onClick={e => e.stopPropagation()}>
        {/* Handle */}
        <div style={{ width:36, height:4, background:T.cardBorder, borderRadius:99, margin:"12px auto 0" }}/>
        {/* Header */}
        <div style={{ display:"flex", alignItems:"center", justifyContent:"space-between", padding:"12px 20px 4px" }}>
          <p style={{ fontSize:14, fontWeight:800, color:T.text }}>Kalkulator</p>
          <div style={{ display:"flex", gap:8 }}>
            <button onClick={() => { onUse(parseFloat(display)); onClose(); }}
              style={{ padding:"7px 16px", borderRadius:50, border:"none", cursor:"pointer", background:`linear-gradient(135deg,${themeAccent},${themePrimary})`, color:"white", fontSize:12, fontWeight:800, fontFamily:"inherit" }}>
              Pakai angka ini
            </button>
            <button onClick={onClose} style={{ background:"none", border:"none", cursor:"pointer", padding:4 }}>
              <X size={18} color={T.textSub}/>
            </button>
          </div>
        </div>
        {/* Display */}
        <div style={{ padding:"8px 20px 16px", textAlign:"right" }}>
          {op && prev !== null && <p style={{ fontSize:12, color:T.textSub, marginBottom:2 }}>{prev.toLocaleString("id-ID")} {op}</p>}
          <p style={{ fontSize:42, fontWeight:900, color:T.text, lineHeight:1, letterSpacing:-1, overflow:"hidden", textOverflow:"ellipsis", whiteSpace:"nowrap" }}>{fmt(display)}</p>
        </div>
        {/* Buttons */}
        <div style={{ padding:"0 16px 16px", display:"flex", flexDirection:"column", gap:8 }}>
          {rows.map((row, ri) => (
            <div key={ri} style={{ display:"flex", gap:8 }}>
              {row.map(v => (
                <button key={v} onClick={() => press(v)}
                  style={{ flex: v==="0" ? 2 : 1, padding:"18px 0", borderRadius:16, border:"none", cursor:"pointer", fontFamily:"inherit", fontWeight:800, fontSize:18, transition:"transform 0.1s, background 0.1s",
                    background: v==="=" ? `linear-gradient(135deg,${themeAccent},${themePrimary})` : isOp(v) || v==="%" ? dark?"rgba(255,255,255,0.12)":"rgba(0,0,0,0.08)" : v==="C"||v==="⌫" ? "rgba(248,113,113,0.15)" : T.card2,
                    color: v==="=" ? "white" : isOp(v)||v==="%" ? themeAccent : v==="C"||v==="⌫" ? "#f87171" : T.text,
                  }}
                  onPointerDown={e => e.currentTarget.style.transform="scale(0.92)"}
                  onPointerUp={e => e.currentTarget.style.transform="scale(1)"}
                >
                  {v}
                </button>
              ))}
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

// ── REMINDER MODAL COMPONENT ─────────────────────────────────────────────────
function ReminderModal({ show, onClose, lang, L, T, themeAccent, themePrimary, notifEnabled, handleNotification, reminderHour, setReminderHour, reminderDays, setReminderDays, reminderSmart, setReminderSmart, scheduleSmartReminder, transactions, showToast }) {
  if (!show) return null;
  const padT = h => String(h).padStart(2,"0")+":00";
  const DAY_L = lang==="en"?["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]:["Min","Sen","Sel","Rab","Kam","Jum","Sab"];
  return (
    <div style={{position:"fixed",inset:0,background:"rgba(0,0,0,0.55)",backdropFilter:"blur(6px)",WebkitBackdropFilter:"blur(6px)",zIndex:300,display:"flex",alignItems:"flex-end",justifyContent:"center"}} onClick={e=>{if(e.target===e.currentTarget)onClose();}}>
      <div style={{background:T.modalBg,borderRadius:"24px 24px 0 0",width:"100%",maxWidth:420,maxHeight:"90dvh",display:"flex",flexDirection:"column",overflow:"hidden"}}>
        <div style={{width:36,height:4,background:T.cardBorder,borderRadius:99,margin:"12px auto 0",flexShrink:0}}/>
        <div style={{display:"flex",alignItems:"center",justifyContent:"space-between",padding:"12px 20px 14px",borderBottom:`1px solid ${T.cardBorder}`,flexShrink:0}}>
          <div style={{display:"flex",alignItems:"center",gap:9}}><Bell size={18} color={themeAccent} strokeWidth={2}/><p style={{fontSize:16,fontWeight:900,color:T.text}}>{L.reminderTitle}</p></div>
          <button onClick={onClose} style={{width:30,height:30,borderRadius:"50%",background:T.card2,border:"none",cursor:"pointer",display:"flex",alignItems:"center",justifyContent:"center"}}><X size={14} color={T.textSub} strokeWidth={2}/></button>
        </div>
        <div style={{overflowY:"auto",flex:1}}>
          <div style={{margin:"14px 16px",padding:"16px",background:`linear-gradient(135deg,${themeAccent}18,${themePrimary}28)`,border:`1px solid ${themeAccent}25`,borderRadius:16,display:"flex",alignItems:"center",gap:14}}>
            <div style={{width:50,height:50,borderRadius:16,background:`linear-gradient(135deg,${themeAccent},${themePrimary})`,display:"flex",alignItems:"center",justifyContent:"center",flexShrink:0}}><Bell size={22} color="white" strokeWidth={2}/></div>
            <div><p style={{fontSize:14,fontWeight:800,color:T.text}}>{L.reminderTitle}</p><p style={{fontSize:12,color:T.textSub,marginTop:3,lineHeight:1.5}}>{L.reminderDesc}</p></div>
          </div>
          <div onClick={()=>handleNotification()} style={{display:"flex",alignItems:"center",justifyContent:"space-between",padding:"14px 20px",borderBottom:`1px solid ${T.cardBorder}`,cursor:"pointer"}}>
            <div style={{display:"flex",alignItems:"center",gap:12}}><div style={{width:38,height:38,borderRadius:12,background:T.card2,display:"flex",alignItems:"center",justifyContent:"center"}}><Bell size={18} color={notifEnabled?themeAccent:T.textSub} strokeWidth={2}/></div><div><p style={{fontSize:14,fontWeight:700,color:T.text}}>{L.pushNotifications}</p><p style={{fontSize:11,color:T.textSub,marginTop:1}}>{notifEnabled?L.notifActive:L.notifOff}</p></div></div>
            <div style={{width:46,height:26,borderRadius:99,background:notifEnabled?`linear-gradient(135deg,${themeAccent},${themePrimary})`:T.card2,border:notifEnabled?"none":`1.5px solid ${T.cardBorder}`,position:"relative",flexShrink:0}}><div style={{position:"absolute",width:20,height:20,borderRadius:"50%",background:"white",top:3,left:notifEnabled?"calc(100% - 23px)":3,transition:"left 0.2s cubic-bezier(0.34,1.1,0.64,1)",boxShadow:"0 2px 6px rgba(0,0,0,0.3)"}}/></div>
          </div>
          <div style={{display:"flex",alignItems:"center",justifyContent:"space-between",padding:"14px 20px",borderBottom:`1px solid ${T.cardBorder}`}}>
            <div><p style={{fontSize:14,fontWeight:700,color:T.text}}>{L.reminderTime}</p><p style={{fontSize:11,color:T.textSub,marginTop:1}}>{lang==="en"?"Notification sent at":"Notif dikirim jam"}</p></div>
            <select value={reminderHour} onChange={e=>setReminderHour(Number(e.target.value))} style={{background:T.card2,border:`1.5px solid ${T.cardBorder}`,borderRadius:10,padding:"8px 12px",color:themeAccent,fontSize:16,fontWeight:900,cursor:"pointer",fontFamily:"inherit",outline:"none"}}>
              {[6,7,8,9,10,12,15,18,19,20,21,22].map(h=><option key={h} value={h}>{padT(h)}</option>)}
            </select>
          </div>
          <div style={{padding:"14px 20px",borderBottom:`1px solid ${T.cardBorder}`}}>
            <p style={{fontSize:12,fontWeight:700,color:T.textSub,marginBottom:10}}>{L.reminderDays}</p>
            <div style={{display:"flex",gap:6}}>
              {[0,1,2,3,4,5,6].map(d=>(
                <div key={d} onClick={()=>setReminderDays(p=>p.includes(d)?p.filter(x=>x!==d):[...p,d])} style={{flex:1,height:38,borderRadius:10,display:"flex",alignItems:"center",justifyContent:"center",fontSize:11,fontWeight:800,cursor:"pointer",transition:"all 0.15s",background:reminderDays.includes(d)?themeAccent+"20":T.card2,border:reminderDays.includes(d)?`1.5px solid ${themeAccent}50`:`1.5px solid ${T.cardBorder}`,color:reminderDays.includes(d)?themeAccent:T.textSub}}>{DAY_L[d]}</div>
              ))}
            </div>
          </div>
          <div onClick={()=>setReminderSmart(p=>!p)} style={{display:"flex",alignItems:"center",justifyContent:"space-between",padding:"14px 20px",borderBottom:`1px solid ${T.cardBorder}`,cursor:"pointer"}}>
            <div style={{display:"flex",alignItems:"center",gap:12}}><div style={{width:38,height:38,borderRadius:12,background:T.card2,display:"flex",alignItems:"center",justifyContent:"center"}}><Bell size={18} color={T.textSub} strokeWidth={2}/></div><div><p style={{fontSize:14,fontWeight:700,color:T.text}}>{L.reminderSmart}</p><p style={{fontSize:11,color:T.textSub,marginTop:1}}>{L.reminderSmartDesc}</p></div></div>
            <div style={{width:46,height:26,borderRadius:99,background:reminderSmart?`linear-gradient(135deg,${themeAccent},${themePrimary})`:T.card2,border:reminderSmart?"none":`1.5px solid ${T.cardBorder}`,position:"relative",flexShrink:0}}><div style={{position:"absolute",width:20,height:20,borderRadius:"50%",background:"white",top:3,left:reminderSmart?"calc(100% - 23px)":3,transition:"left 0.2s cubic-bezier(0.34,1.1,0.64,1)",boxShadow:"0 2px 6px rgba(0,0,0,0.3)"}}/></div>
          </div>
          <div style={{margin:"14px 16px 0"}}><p style={{fontSize:11,fontWeight:700,color:T.textSub,marginBottom:8}}>{(L.reminderPreview||"PREVIEW").toUpperCase()}</p><div style={{background:T.card2,border:`1px solid ${T.cardBorder}`,borderRadius:16,padding:14}}><div style={{display:"flex",alignItems:"center",gap:8,marginBottom:8}}><div style={{width:28,height:28,borderRadius:8,background:`linear-gradient(135deg,${themeAccent},${themePrimary})`,display:"flex",alignItems:"center",justifyContent:"center",fontSize:14}}>🐱</div><p style={{fontSize:11,fontWeight:700,color:T.textSub}}>Meowlett</p><p style={{fontSize:11,color:T.textMuted,marginLeft:"auto"}}>{padT(reminderHour)}</p></div><p style={{fontSize:13,fontWeight:800,color:T.text,marginBottom:3}}>{L.reminderNotifTitle}</p><p style={{fontSize:12,color:T.textSub,lineHeight:1.4}}>{L.reminderNotifBody}</p></div></div>
          <button onClick={()=>{haptic("success");if(notifEnabled)scheduleSmartReminder({hour:reminderHour,minute:0,days:reminderDays,smart:reminderSmart,lang,getTransactions:()=>transactions});showToast(L.settingsSaved);onClose();}}
            style={{display:"block",margin:"14px 16px 24px",width:"calc(100% - 32px)",padding:"14px 0",borderRadius:14,background:`linear-gradient(135deg,${themeAccent},${themePrimary})`,border:"none",color:"white",fontSize:14,fontWeight:800,cursor:"pointer",fontFamily:"inherit"}}>{L.saveSettings}</button>
        </div>
      </div>
    </div>
  );
}
// ── CICILAN MODAL COMPONENT ──────────────────────────────────────────────────
function CicilanModal({ show, onClose, cicilan, setCicilan, lang, L, T, themeAccent, themePrimary, formatRp, parseRpInput, haptic, showToast }) {
  const [view, setView] = React.useState("list");
  const [editId, setEditId] = React.useState(null);
  const [detail, setDetail] = React.useState(null);
  const [form, setForm] = React.useState({name:"",monthly:"",monthlyDisplay:"",dueDay:"5",total:"",totalDisplay:"",duration:"12"});
  if(!show) return null;
  const curMonth = new Date().toISOString().slice(0,7);
  const totalMonthly = cicilan.reduce((s,ci)=>s+Number(ci.monthly||0),0);
  const getPaid = ci => (ci.paidMonths||[]).length;
  const isPaidNow = ci => (ci.paidMonths||[]).includes(curMonth);
  const getPct = ci => ci.duration ? Math.round(getPaid(ci)/ci.duration*100) : 0;
  const save = () => {
    if(!form.name||!form.monthly) return;
    const item = {id:editId||Date.now(),name:form.name,total:Number(String(form.total).replace(/\./g,"")),monthly:Number(String(form.monthly).replace(/\./g,"")),dueDay:form.dueDay||"5",duration:Number(form.duration)||12,paidMonths:editId?(cicilan.find(x=>x.id===editId)?.paidMonths||[]):[]};
    if(editId) setCicilan(p=>p.map(x=>x.id===editId?item:x)); else setCicilan(p=>[...p,item]);
    showToast(L.cicilanSaved); setView("list"); setEditId(null); haptic("success");
  };
  const del = id => { setCicilan(p=>p.filter(x=>x.id!==id)); showToast(L.cicilanDeleted); setView("list"); haptic(); };
  const openEdit = ci => { setEditId(ci.id); setForm({name:ci.name,monthly:ci.monthly,monthlyDisplay:Number(ci.monthly).toLocaleString("id-ID"),dueDay:ci.dueDay,total:ci.total||"",totalDisplay:ci.total?Number(ci.total).toLocaleString("id-ID"):"",duration:String(ci.duration)}); setView("form"); };
  const markPaid = ci => {
    if(isPaidNow(ci)){showToast("info:"+L.cicilanAlreadyPaid);return;}
    setCicilan(p=>p.map(x=>x.id===ci.id?{...x,paidMonths:[...(x.paidMonths||[]),curMonth]}:x));
    setDetail(p=>p?{...p,paidMonths:[...(p.paidMonths||[]),curMonth]}:p);
    showToast(L.cicilanPaidToast); haptic("success");
  };
  const IBNs = {background:"none",border:"none",cursor:"pointer"};
  return (
    <div style={{position:"fixed",inset:0,background:"rgba(0,0,0,0.55)",backdropFilter:"blur(6px)",WebkitBackdropFilter:"blur(6px)",zIndex:300,display:"flex",alignItems:"flex-end",justifyContent:"center"}} onClick={e=>{if(e.target===e.currentTarget)onClose();}}>
      <div style={{background:T.modalBg,borderRadius:"24px 24px 0 0",width:"100%",maxWidth:420,maxHeight:"90dvh",display:"flex",flexDirection:"column",overflow:"hidden"}}>
        <div style={{width:36,height:4,background:T.cardBorder,borderRadius:99,margin:"12px auto 0",flexShrink:0}}/>
        <div style={{display:"flex",alignItems:"center",justifyContent:"space-between",padding:"12px 20px 14px",borderBottom:`1px solid ${T.cardBorder}`,flexShrink:0}}>
          <div style={{display:"flex",alignItems:"center",gap:9}}><CreditCard size={18} color={themeAccent} strokeWidth={2}/><p style={{fontSize:16,fontWeight:900,color:T.text}}>{L.cicilan}</p></div>
          <div style={{display:"flex",gap:8,alignItems:"center"}}>
            {view==="list" && <button onClick={()=>{setEditId(null);setForm({name:"",monthly:"",monthlyDisplay:"",dueDay:"5",total:"",totalDisplay:"",duration:"12"});setView("form");}} style={{background:`linear-gradient(135deg,${themeAccent},${themePrimary})`,border:"none",borderRadius:10,padding:"6px 12px",color:"white",fontSize:12,fontWeight:800,cursor:"pointer",display:"flex",alignItems:"center",gap:5,fontFamily:"inherit"}}><Plus size={13} strokeWidth={2.5}/> {L.addCicilan}</button>}
            <button onClick={onClose} style={{width:30,height:30,borderRadius:"50%",background:T.card2,border:"none",cursor:"pointer",display:"flex",alignItems:"center",justifyContent:"center"}}><X size={14} color={T.textSub} strokeWidth={2}/></button>
          </div>
        </div>
        <div style={{overflowY:"auto",flex:1}}>
          {view==="form" && (
            <div style={{padding:16,display:"flex",flexDirection:"column",gap:10}}>
              <p style={{fontSize:13,fontWeight:800,color:T.text}}>{editId?L.editCicilan:L.addCicilan}</p>
              <input className="inp" placeholder={L.cicilanName} value={form.name} onChange={e=>setForm(f=>({...f,name:e.target.value}))} style={{background:T.inp,border:`1.5px solid ${T.inpBorder}`,color:T.text}}/>
              <div style={{display:"flex",gap:8}}>
                <div style={{flex:1}}><p style={{fontSize:10,fontWeight:700,color:T.textSub,marginBottom:4}}>{L.cicilanMonthly}</p><input className="inp" type="text" inputMode="numeric" placeholder="750.000" value={form.monthlyDisplay||""} onFocus={e=>e.target.select()} onChange={e=>{const {display,raw}=parseRpInput(e.target.value);setForm(f=>({...f,monthly:raw,monthlyDisplay:display}));}} style={{background:T.inp,border:`1.5px solid ${T.inpBorder}`,color:T.text}}/></div>
                <div style={{flex:1}}><p style={{fontSize:10,fontWeight:700,color:T.textSub,marginBottom:4}}>{L.cicilanDue}</p><input className="inp" type="number" min="1" max="31" placeholder="5" value={form.dueDay} onChange={e=>setForm(f=>({...f,dueDay:e.target.value}))} style={{background:T.inp,border:`1.5px solid ${T.inpBorder}`,color:T.text}}/></div>
              </div>
              <div style={{display:"flex",gap:8}}>
                <div style={{flex:1}}><p style={{fontSize:10,fontWeight:700,color:T.textSub,marginBottom:4}}>{L.cicilanTotal}</p><input className="inp" type="text" inputMode="numeric" placeholder="18.000.000" value={form.totalDisplay||""} onFocus={e=>e.target.select()} onChange={e=>{const {display,raw}=parseRpInput(e.target.value);setForm(f=>({...f,total:raw,totalDisplay:display}));}} style={{background:T.inp,border:`1.5px solid ${T.inpBorder}`,color:T.text}}/></div>
                <div style={{flex:1}}><p style={{fontSize:10,fontWeight:700,color:T.textSub,marginBottom:4}}>{L.cicilanDuration}</p><input className="inp" type="number" min="1" placeholder="24" value={form.duration} onChange={e=>setForm(f=>({...f,duration:e.target.value}))} style={{background:T.inp,border:`1.5px solid ${T.inpBorder}`,color:T.text}}/></div>
              </div>
              <div style={{display:"flex",gap:8,marginTop:4}}>
                <button onClick={() => { haptic("success"); save(); }} style={{flex:1,padding:"12px 0",borderRadius:14,background:`linear-gradient(135deg,${themeAccent},${themePrimary})`,border:"none",color:"white",fontSize:13,fontWeight:800,cursor:"pointer",fontFamily:"inherit"}}>{L.save}</button>
                <button onClick={()=>{setView("list");setEditId(null);}} style={{flex:0.5,padding:"12px 0",borderRadius:14,background:T.btnG,border:`1.5px solid ${T.btnGBorder}`,color:T.btnGText,fontSize:13,fontWeight:700,cursor:"pointer",fontFamily:"inherit"}}>{L.cancel}</button>
              </div>
            </div>
          )}
          {view==="detail" && detail && (
            <div>
              <div style={{background:`linear-gradient(135deg,${themePrimary},${themeAccent}88)`,padding:"18px 20px 20px"}}>
                <p style={{fontSize:18,fontWeight:900,color:"white"}}>{detail.name}</p>
                <div style={{display:"flex",gap:20,marginTop:12}}>
                  <div><p style={{fontSize:16,fontWeight:900,color:"white"}}>{formatRp(detail.monthly)}</p><p style={{fontSize:10,color:"rgba(255,255,255,0.6)",fontWeight:600}}>{L.perMonthLabel}</p></div>
                  <div><p style={{fontSize:16,fontWeight:900,color:"white"}}>{getPaid(detail)}/{detail.duration}</p><p style={{fontSize:10,color:"rgba(255,255,255,0.6)",fontWeight:600}}>{L.monthsLabel}</p></div>
                  <div><p style={{fontSize:16,fontWeight:900,color:"white"}}>tgl {detail.dueDay}</p><p style={{fontSize:10,color:"rgba(255,255,255,0.6)",fontWeight:600}}>{lang==="en"?"due":"jatuh tempo"}</p></div>
                </div>
              </div>
              <div style={{padding:"14px 20px",borderBottom:`1px solid ${T.cardBorder}`}}>
                <div style={{display:"flex",justifyContent:"space-between",fontSize:12,color:T.textSub,fontWeight:600,marginBottom:8}}><span>{L.progressCicilan}</span><span>{getPct(detail)}%</span></div>
                <div style={{height:8,borderRadius:99,background:T.card2,overflow:"hidden"}}><div style={{height:"100%",width:`${getPct(detail)}%`,background:`linear-gradient(90deg,${themeAccent},${themePrimary})`,borderRadius:99,transition:"width 0.6s ease"}}/></div>
                <div style={{display:"flex",justifyContent:"space-between",marginTop:6,fontSize:11,color:T.textSub}}><span>{lang==="en"?"Paid:":"Sudah:"} {formatRp(getPaid(detail)*detail.monthly)}</span><span>{lang==="en"?"Left:":"Sisa:"} {formatRp((detail.duration-getPaid(detail))*detail.monthly)}</span></div>
              </div>
              <div style={{padding:"14px 20px",display:"flex",gap:8,borderBottom:`1px solid ${T.cardBorder}`}}>
                <button onClick={()=>markPaid(detail)} style={{flex:1,padding:"11px 0",borderRadius:12,background:isPaidNow(detail)?T.card2:`linear-gradient(135deg,${themeAccent},${themePrimary})`,border:isPaidNow(detail)?`1.5px solid ${T.cardBorder}`:"none",color:isPaidNow(detail)?T.textSub:"white",fontSize:12,fontWeight:800,cursor:"pointer",fontFamily:"inherit"}}>{isPaidNow(detail)?"✓ "+L.cicilanAlreadyPaid:L.cicilanMarkPaid}</button>
                <button onClick={()=>openEdit(detail)} style={{width:42,height:42,borderRadius:12,background:T.catBg,border:`1.5px solid ${T.cardBorder}`,cursor:"pointer",display:"flex",alignItems:"center",justifyContent:"center"}}><Pencil size={15} color={T.text} strokeWidth={2}/></button>
                <button onClick={()=>del(detail.id)} style={{width:42,height:42,borderRadius:12,background:"#ef444418",border:"1.5px solid #ef444435",cursor:"pointer",display:"flex",alignItems:"center",justifyContent:"center"}}><Trash2 size={15} color="#f87171" strokeWidth={2}/></button>
              </div>
              <button onClick={()=>setView("list")} style={{display:"block",margin:"12px 20px",width:"calc(100% - 40px)",padding:"10px 0",borderRadius:12,background:T.card2,border:`1.5px solid ${T.cardBorder}`,color:T.textSub,fontSize:13,fontWeight:700,cursor:"pointer",fontFamily:"inherit"}}>← {L.splitBack}</button>
            </div>
          )}
          {view==="list" && (
            <div>
              {cicilan.length===0 ? (
                <div style={{padding:"48px 20px",textAlign:"center"}}><div style={{width:72,height:72,borderRadius:22,background:themeAccent+"18",border:`1.5px solid ${themeAccent}30`,display:"flex",alignItems:"center",justifyContent:"center",margin:"0 auto 14px"}}><CreditCard size={32} color={themeAccent} strokeWidth={1.5}/></div><p style={{fontSize:15,fontWeight:800,color:T.text,marginBottom:6}}>{L.noCicilan}</p><p style={{fontSize:12,color:T.textSub}}>{L.cicilanDesc}</p></div>
              ) : (
                <div>
                  <div style={{margin:"14px 16px 0",padding:"14px 16px",background:T.card2,border:`1px solid ${T.cardBorder}`,borderRadius:16,display:"flex",justifyContent:"space-between",alignItems:"center"}}><div><p style={{fontSize:11,fontWeight:700,color:T.textSub,marginBottom:3}}>{L.cicilanTotal2}</p><p style={{fontSize:20,fontWeight:900,color:"#f87171"}}>-{formatRp(totalMonthly)}</p></div><p style={{fontSize:11,color:T.textSub,maxWidth:120,textAlign:"right"}}>{L.cicilanDesc}</p></div>
                  {cicilan.map((ci,i)=>(
                    <div key={ci.id} onClick={()=>{setDetail(ci);setView("detail");}} style={{display:"flex",alignItems:"center",gap:12,padding:"14px 16px",borderBottom:i<cicilan.length-1?`1px solid ${T.cardBorder}`:"none",cursor:"pointer"}}>
                      <div style={{width:44,height:44,borderRadius:14,background:themeAccent+"18",display:"flex",alignItems:"center",justifyContent:"center",flexShrink:0}}><CreditCard size={20} color={themeAccent} strokeWidth={1.5}/></div>
                      <div style={{flex:1,minWidth:0}}><p style={{fontSize:14,fontWeight:700,color:T.text}}>{ci.name}</p><p style={{fontSize:11,color:T.textSub,marginTop:2}}>{lang==="en"?"Inst.":"Cicilan ke-"} {getPaid(ci)}/{ci.duration} · tgl {ci.dueDay}</p><div style={{height:3,borderRadius:99,background:T.card2,overflow:"hidden",marginTop:5,maxWidth:100}}><div style={{height:"100%",width:`${getPct(ci)}%`,background:`linear-gradient(90deg,${themeAccent},${themePrimary})`,borderRadius:99}}/></div></div>
                      <div style={{textAlign:"right",flexShrink:0}}><p style={{fontSize:14,fontWeight:800,color:"#f87171"}}>-{formatRp(ci.monthly)}</p><p style={{fontSize:10,color:isPaidNow(ci)?"#4ade80":T.textSub,marginTop:2,fontWeight:isPaidNow(ci)?700:500}}>{isPaidNow(ci)?"✓ "+(lang==="en"?"Paid":lang==="en"?"Paid":"Lunas"):(ci.duration-getPaid(ci))+" "+(L.cicilanRemain||"bln lagi")}</p></div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

export default function App() {
  const [tab, setTab] = useState("dashboard");
  const [showFabMenu, setShowFabMenu] = useState(false);
  const fabPressTimer = useRef(null);
  const tabScrollPos = useRef({});
  const [lang, setLang] = useState(() => {
    try { return localStorage.getItem("gm_lang") || "id"; } catch { return "id"; }
  });
  useEffect(() => { try { localStorage.setItem("gm_lang", lang); } catch {} }, [lang]);
  const L = LANG[lang] || LANG.id;
  const [systemDark, setSystemDark] = useState(
    () => window.matchMedia ? window.matchMedia("(prefers-color-scheme: dark)").matches : false
  );
  useEffect(() => {
    const mq = window.matchMedia("(prefers-color-scheme: dark)");
    const handler = e => setSystemDark(e.matches);
    mq.addEventListener("change", handler);
    return () => mq.removeEventListener("change", handler);
  }, []);
  const [darkOverride, setDarkOverride] = useState(() => {
    try {
      const v = localStorage.getItem("gm_dark_override");
      if (v === "true") return true;
      if (v === "false") return false;
      return null; // null = ikut sistem
    } catch { return null; }
  });
  const [followSystem, setFollowSystem] = useState(() => {
    try {
      const saved = localStorage.getItem("gm_follow_system");
      if (saved !== null) return saved === "1";
      return false; // default: manual, tidak ikut sistem
    } catch { return false; }
  });
  const [darkRipple, setDarkRipple] = useState(null); // {x, y, toD ark}
  const [navbarOffset, setNavbarOffset] = useState(() => { try { return parseInt(localStorage.getItem("gm_navbar_offset")||"5"); } catch { return 5; } });
  const darkToggleRef = useRef(null);
  const settingsToggleRef = useRef(null);
  const dark = followSystem ? systemDark : (darkOverride !== null ? darkOverride : systemDark);
  const [themePresetId, setThemePresetId] = useState(() => {
    try { return localStorage.getItem("gm_theme_preset") || "rose"; } catch { return "rose"; }
  });
  const [customPrimary, setCustomPrimary] = useState(() => {
    try { return localStorage.getItem("gm_custom_primary") || "#881337"; } catch { return "#166534"; }
  });
  const [customAccent, setCustomAccent] = useState(() => {
    try { return localStorage.getItem("gm_custom_accent") || "#fb7185"; } catch { return "#4ade80"; }
  });
  const [showThemePicker, setShowThemePicker] = useState(false);
  const [themeChanging, setThemeChanging] = useState(false);
  const triggerThemeChange = (fn) => {
    setThemeChanging(true);
    fn();
    setTimeout(() => setThemeChanging(false), 500);
  };

  const activePreset = THEME_PRESETS.find(p => p.id === themePresetId) || THEME_PRESETS[0];
  const themePrimary = themePresetId === "custom" ? customPrimary : activePreset.primary;
  const themeAccent  = themePresetId === "custom" ? customAccent  : activePreset.accent;
  const T = buildTheme(themePrimary, themeAccent, dark);
  const TP  = dark ? lighten(themePrimary,0.45) : themePrimary;
  const hex2rgb = h => { const r=parseInt(h.slice(1,3),16),g=parseInt(h.slice(3,5),16),b=parseInt(h.slice(5,7),16); return r+","+g+","+b; };
  const headerShadow = (t) => {
    return `0 1px 4px ${T.cardShadow}`;
  };
  const CS  = { background:T.card, border:`1px solid ${T.cardBorder}`, boxShadow:`0 1px 4px ${T.cardShadow}` };
  const CSN = { background:T.card, border:`1px solid ${T.cardBorder}` };
  const IBN = { background:"none", border:"none", cursor:"pointer" };

  // Compute statusbar color per tab
  const statusBarColor = useMemo(() => {
    if (tab === "date") return dark ? "#7f1d3d" : "#9d174d";
    if (tab === "dashboard") return dark ? "rgba(10,10,10,0)" : "rgba(0,0,0,0)"; // transparent for frosted
    return dark ? darken(themePrimary, 0.3) : themePrimary;
  }, [tab, dark, themePrimary]);

  useEffect(() => {
    const metas = [
      { name:"viewport", content:"width=device-width, initial-scale=1, viewport-fit=cover, user-scalable=no" },
      { name:"apple-mobile-web-app-capable", content:"yes" },
      { name:"apple-mobile-web-app-status-bar-style", content: "black-translucent" },
      { name:"apple-mobile-web-app-title", content:"Meowlett" },
      { name:"mobile-web-app-capable", content:"yes" },
      { name:"theme-color", content: tab === "date" ? (dark ? "#7f1d3d" : "#9d174d") : (tab === "dashboard" ? (dark ? "#0a0a0a" : lighten(themePrimary, 0.3)) : (dark ? darken(themePrimary, 0.3) : themePrimary)) },
    ];
    const added = [];
    metas.forEach(({ name, content }) => {
      let el = document.querySelector(`meta[name="${name}"]`);
      if (!el) { el = document.createElement("meta"); el.name = name; document.head.appendChild(el); added.push(el); }
      el.content = content;
    });
    return () => added.forEach(el => el.remove());
  }, [dark, themePrimary, tab]);

  const [categories, setCategories] = useState(() => {
    try {
      const s = localStorage.getItem("gm_categories");
      if (!s) return DEFAULT_CATEGORIES;
      const saved = JSON.parse(s);
      // Merge labelId from DEFAULT_CATEGORIES for built-in cats (fixes stuck-English bug)
      const merged = { ...saved };
      Object.keys(merged).forEach(k => {
        if (DEFAULT_CATEGORIES[k] && !merged[k].labelId) {
          merged[k] = { ...DEFAULT_CATEGORIES[k], ...merged[k], labelId: DEFAULT_CATEGORIES[k].labelId };
        }
      });
      return merged;
    } catch { return DEFAULT_CATEGORIES; }
  });
  const _d = (daysAgo) => { const d = new Date(); d.setDate(d.getDate() - daysAgo); return d.toISOString().split("T")[0]; };
  const DEMO_DATA = [
    { id:"d1",  date:_d(0),  amount:32000,  category:"food",          description:"Sarapan nasi uduk",       location:"", note:"" },
    { id:"d2",  date:_d(0),  amount:15000,  category:"transport",     description:"Ojol ke kantor",          location:"", note:"" },
    { id:"d3",  date:_d(1),  amount:45000,  category:"food",          description:"Makan siang ayam geprek", location:"", note:"" },
    { id:"d4",  date:_d(2),  amount:58000,  category:"food",          description:"Kopi Kenangan + snack",   location:"", note:"" },
    { id:"d5",  date:_d(2),  amount:189000, category:"shopping",      description:"Skincare Wardah",         location:"", note:"" },
    { id:"d6",  date:_d(3),  amount:75000,  category:"entertainment", description:"Nonton Bioskop",          location:"", note:"" },
    { id:"d7",  date:_d(5),  amount:280000, category:"date",          description:"Nonton + makan malam",   location:"", note:"" },
    { id:"d8",  date:_d(8),  amount:1163000,category:"bills",         description:"Angsuran motor",          location:"", note:"" },
    { id:"d9",  date:_d(8),  amount:54990,  category:"entertainment", description:"Spotify Premium",         location:"", note:"" },
    { id:"d10", date:_d(9),  amount:36000,  category:"food",          description:"Mie ayam + es teh",       location:"", note:"" },
    { id:"d11", date:_d(10), amount:145000, category:"health",        description:"Beli vitamin C",          location:"", note:"" },
    { id:"d12", date:_d(12), amount:450000, category:"bills",         description:"Bayar kos bulan ini",     location:"", note:"" },
    { id:"d13", date:_d(13), amount:85000,  category:"food",          description:"Makan malam shabu",       location:"", note:"" },
    { id:"d14", date:_d(14), amount:350000, category:"date",          description:"Anniversary dinner",      location:"", note:"" },
    { id:"d15", date:_d(16), amount:200000, category:"shopping",      description:"Shopee haul bulanan",     location:"", note:"" },
    { id:"d16", date:_d(18), amount:188000, category:"bills",         description:"Token listrik",           location:"", note:"" },
    { id:"d17", date:_d(20), amount:55000,  category:"food",          description:"Lunch set Hokben",        location:"", note:"" },
    { id:"d22", date:_d(22), amount:99000,  category:"entertainment", description:"Netflix 1 bulan",         location:"", note:"" },
    { id:"d23", date:_d(24), amount:220000, category:"shopping",      description:"Sepatu olahraga",         location:"", note:"" },
    { id:"d24", date:_d(32), amount:1163000,category:"bills",         description:"Angsuran motor",          location:"", note:"" },
    { id:"d25", date:_d(33), amount:54990,  category:"entertainment", description:"Spotify Premium",         location:"", note:"" },
    { id:"d26", date:_d(34), amount:450000, category:"bills",         description:"Bayar kos",               location:"", note:"" },
    { id:"d27", date:_d(36), amount:95000,  category:"food",          description:"Makan siang kantor",      location:"", note:"" },
    { id:"d28", date:_d(37), amount:175000, category:"bills",         description:"Tagihan internet",        location:"", note:"" },
    { id:"d29", date:_d(38), amount:260000, category:"shopping",      description:"Baju kondangan",          location:"", note:"" },
    { id:"d30", date:_d(40), amount:65000,  category:"health",        description:"Suplemen multivitamin",   location:"", note:"" },
    { id:"d31", date:_d(41), amount:310000, category:"date",          description:"Makan malam & bioskop",   location:"", note:"" },
    { id:"d32", date:_d(45), amount:185000, category:"bills",         description:"Token listrik",           location:"", note:"" },
    { id:"d33", date:_d(47), amount:340000, category:"shopping",      description:"Kosmetik Sephora",        location:"", note:"" },
    { id:"d34", date:_d(50), amount:75000,  category:"health",        description:"Obat flu & batuk",        location:"", note:"" },
    { id:"d35", date:_d(63), amount:1163000,category:"bills",         description:"Angsuran motor",          location:"", note:"" },
    { id:"d36", date:_d(64), amount:450000, category:"bills",         description:"Bayar kos",               location:"", note:"" },
    { id:"d37", date:_d(66), amount:54990,  category:"entertainment", description:"Spotify Premium",         location:"", note:"" },
    { id:"d38", date:_d(70), amount:195000, category:"shopping",      description:"Shopee haul",             location:"", note:"" },
    { id:"d39", date:_d(72), amount:55000,  category:"health",        description:"Vitamin & suplemen",      location:"", note:"" },
    { id:"d40", date:_d(74), amount:250000, category:"date",          description:"Piknik & makan",          location:"", note:"" },
    { id:"d41", date:_d(76), amount:165000, category:"bills",         description:"Token listrik",           location:"", note:"" },
    { id:"d42", date:_d(80), amount:310000, category:"shopping",      description:"Baju & celana",           location:"", note:"" },
    { id:"d43", date:_d(84), amount:125000, category:"food",          description:"Makan keluarga",          location:"", note:"" },
    { id:"d44", date:_d(93), amount:1163000,category:"bills",         description:"Angsuran motor",          location:"", note:"" },
    { id:"d45", date:_d(94), amount:450000, category:"bills",         description:"Bayar kos",               location:"", note:"" },
    { id:"d46", date:_d(95), amount:175000, category:"bills",         description:"Tagihan internet",        location:"", note:"" },
    { id:"d47", date:_d(97), amount:54990,  category:"entertainment", description:"Spotify Premium",         location:"", note:"" },
    { id:"d48", date:_d(100),amount:145000, category:"bills",         description:"Token listrik",           location:"", note:"" },
    { id:"d49", date:_d(102),amount:280000, category:"shopping",      description:"Belanja bulanan",         location:"", note:"" },
    { id:"d50", date:_d(104),amount:95000,  category:"food",          description:"Makan bareng teman",      location:"", note:"" },
  ];
  const [transactions, setTransactions] = useState(() => {
    try {
      const s = localStorage.getItem("gm_transactions_clean");
      const parsed = s ? JSON.parse(s) : null;
      return (parsed && parsed.length > 0) ? parsed : [];
    } catch { return []; }
  });
  useEffect(() => {
    if (transactions.length === 0) {
      loadFromIDB().then(data => {
        if (data.length > 0) {
          setTransactions(data);
          try { localStorage.setItem("gm_transactions_clean", JSON.stringify(data)); } catch {}
        }
      });
    }
  }, []);
  const [income, setIncome] = useState(() => {
    try {
      const s = localStorage.getItem("gm_income");
      const n = s ? Number(s) : 0;
      return n > 0 ? n : 5000000;
    } catch { return 5000000; }
  });
  const [savingsGoal, setSavingsGoal] = useState(() => {
    try {
      const s = localStorage.getItem("gm_savings");
      return s ? Number(s) : 0;
    } catch { return 0; }
  });
  const [recentCount, setRecentCount] = useState(5);
  const [showForm, setShowForm] = useState(false);

  // Smooth sliding indicator — pure math, no getBoundingClientRect drift
  useEffect(() => {
    const ind = document.getElementById("ge-indicator");
    if (!ind) return;
    const navItems = ["dashboard","transactions","report","date"];
    const btnIdx = navItems.indexOf(tab);
    if (btnIdx === -1 || showForm) { ind.style.opacity = "0"; return; }
    const PAD = 7, BTN = 60, IND_HALF = 23;
    const left = PAD + btnIdx * BTN + (BTN / 2) - IND_HALF;
    const isFirst = !ind.dataset.init;
    if (isFirst) {
      ind.style.transition = "none";
      ind.style.left = left + "px";
      ind.style.opacity = "1";
      ind.dataset.init = "1";
      requestAnimationFrame(() => {
        ind.style.transition = "left 0.4s cubic-bezier(0.34,1.15,0.64,1)";
      });
    } else {
      ind.style.transition = "left 0.4s cubic-bezier(0.34,1.15,0.64,1)";
      ind.style.left = left + "px";
      ind.style.opacity = "1";
      ind.classList.remove("ge-indicator-active");
      void ind.offsetWidth;
      ind.classList.add("ge-indicator-active");
    }
  }, [tab, showForm]);

  const [editItem, setEditItem] = useState(null);
  const [filterPeriod, setFilterPeriod] = useState("monthly");
  const [filterCat, setFilterCat] = useState("all");
  const [sortOrder, setSortOrder] = useState("date-desc"); // new sort state
  const [showCalc, setShowCalc] = useState(false); // calculator modal
  const [form, setForm] = useState({ date: today(), amount: "", category: "food", description: "", location: "", note: "" });
  // Check if form has meaningful user input (for discard confirmation)
  const formIsDirty = () => !editItem && (!!form.amount || !!form.description || !!form.location || !!form.note);
  const closeFormSafe = () => {
    if (formIsDirty()) { setShowDiscardConfirm(true); }
    else { setShowForm(false); setEditItem(null); }
  };
  const [editIncome, setEditIncome] = useState(false);
  const headerRef = useRef(null);
  const sharedHeaderRef = useRef(null);
  const balanceCardRef = useRef(null);
  const [headerHeight, setHeaderHeight] = useState(185);
  useEffect(() => {
    const update = () => {
      if (headerRef.current) setHeaderHeight(headerRef.current.offsetHeight);
      if (sharedHeaderRef.current) setHeaderHeight(sharedHeaderRef.current.offsetHeight);
    };
    update();
    const t1 = setTimeout(update, 100);
    const t2 = setTimeout(update, 500);
    window.addEventListener("resize", update);
    return () => { window.removeEventListener("resize", update); clearTimeout(t1); clearTimeout(t2); };
  }, [tab]);

  // Persist data to localStorage (iOS Safari compatible)
  useEffect(() => {
    try { localStorage.setItem("gm_categories", JSON.stringify(categories)); } catch {}
  }, [categories]);
  useEffect(() => {
    try { localStorage.setItem("gm_transactions_clean", JSON.stringify(transactions)); } catch {}
    saveToIDB(transactions);
  }, [transactions]);
  useEffect(() => {
    try { localStorage.setItem("gm_income", String(income)); } catch {}
  }, [income]);
  useEffect(() => {
    try { localStorage.setItem("gm_savings", String(savingsGoal)); } catch {}
  }, [savingsGoal]);
  useEffect(() => {
    try { localStorage.setItem("gm_theme_preset", themePresetId); } catch {}
  }, [themePresetId]);
  useEffect(() => {
    try { localStorage.setItem("gm_custom_primary", customPrimary); } catch {}
  }, [customPrimary]);
  useEffect(() => {
    try { localStorage.setItem("gm_custom_accent", customAccent); } catch {}
  }, [customAccent]);
  const [userName, setUserName] = useState(() => {
    try { return localStorage.getItem("gm_username") || ""; } catch { return ""; }
  });
  useEffect(() => {
    try { localStorage.setItem("gm_username", userName); } catch {}
  }, [userName]);

  // Onboarding — show once on first launch
  const [showOnboarding, setShowOnboarding] = useState(() => {
    try { if(localStorage.getItem("gm_onboarded")) return false; if(sessionStorage.getItem("gm_onboarded_session")) return false; return true; } catch { return false; }
  });
  const [onboardStep, setOnboardStep] = useState(0);
  const [onboardVisible, setOnboardVisible] = useState(true);
  const goToStep = (step) => {
    setOnboardVisible(false);
    setTimeout(() => { setOnboardStep(step); setOnboardVisible(true); }, 180);
  };
  const [onboardName, setOnboardName] = useState("");
  const [onboardIncome, setOnboardIncome] = useState("");
  const [onboardIncomeDisplay, setOnboardIncomeDisplay] = useState("");
  const finishOnboarding = () => {
    if (onboardName.trim()) setUserName(onboardName.trim());
    if (onboardIncome) setIncome(Number(onboardIncome) || 0);
    try { localStorage.setItem("gm_onboarded","1"); sessionStorage.setItem("gm_onboarded_session","1"); } catch {}
    setShowOnboarding(false);
  };

  // Weekly summary notif
  const [weeklyNotif, setWeeklyNotif] = useState(() => {
    try { return JSON.parse(localStorage.getItem("gm_weekly_notif") || "false"); } catch { return false; }
  });
  const [weeklyNotifDay, setWeeklyNotifDay] = useState(() => {
    try { return localStorage.getItem("gm_weekly_notif_day") || "0"; } catch { return "0"; }
  });
  useEffect(() => {
    try { localStorage.setItem("gm_weekly_notif", JSON.stringify(weeklyNotif)); } catch {}
  }, [weeklyNotif]);
  useEffect(() => {
    try { localStorage.setItem("gm_weekly_notif_day", weeklyNotifDay); } catch {}
  }, [weeklyNotifDay]);
  const [editSavings, setEditSavings] = useState(false);
  const [tempIncome, setTempIncome] = useState(income);
  const [tempIncomeDisplay, setTempIncomeDisplay] = useState(income ? income.toLocaleString("id-ID") : "");
  const [incomeAdj, setIncomeAdj] = useState("");
  const [incomeAdjDisplay, setIncomeAdjDisplay] = useState("");
  const [incomeTab, setIncomeTab] = useState("tambah");
  const [tempSavings, setTempSavings] = useState(savingsGoal);
  const [showCatManager, setShowCatManager] = useState(false);
  const [showCategoryMenu, setShowCategoryMenu] = useState(false);
  const [showBudgetLimit, setShowBudgetLimit] = useState(false);
  const [showAppearanceModal, setShowAppearanceModal] = useState(false);
  const [showNotifModal, setShowNotifModal] = useState(false);
  const [catForm, setCatForm] = useState({ label: "", icon: "package", color: "#94a3b8" });
  const [editCatKey, setEditCatKey] = useState(null);
  const [reportDate, setReportDate] = useState(today());
  const [showDataModal, setShowDataModal] = useState(false);
  const [tabScrolled, setTabScrolled] = useState(false);

  const [notifEnabled, setNotifEnabled] = useState(() => {
    try { return localStorage.getItem("gm_notif") === "1"; } catch { return false; }
  });
  // Cicilan
  const [cicilan, setCicilan] = useState(() => {
    try { return JSON.parse(localStorage.getItem("gm_cicilan") || "[]"); } catch { return []; }
  });
  useEffect(() => { try { localStorage.setItem("gm_cicilan", JSON.stringify(cicilan)); } catch {} }, [cicilan]);
  const [showCicilanModal, setShowCicilanModal] = useState(false);
  const [showSplitBills, setShowSplitBills] = useState(false);
  const [splitBills, setSplitBills] = useState(() => {
    try { return JSON.parse(localStorage.getItem("gm_splitbills") || "[]"); } catch { return []; }
  });
  useEffect(() => { try { localStorage.setItem("gm_splitbills", JSON.stringify(splitBills)); } catch {} }, [splitBills]);

  // Reminder settings
  const [reminderHour, setReminderHour] = useState(() => {
    try { return Number(localStorage.getItem("gm_reminder_hour") || "21"); } catch { return 21; }
  });
  const [reminderDays, setReminderDays] = useState(() => {
    try { return JSON.parse(localStorage.getItem("gm_reminder_days") || "[1,2,3,4,5]"); } catch { return [1,2,3,4,5]; }
  });
  const [reminderSmart, setReminderSmart] = useState(() => {
    try { return localStorage.getItem("gm_reminder_smart") !== "0"; } catch { return true; }
  });
  const [showReminderModal, setShowReminderModal] = useState(false);
  useEffect(() => { try { localStorage.setItem("gm_reminder_hour", reminderHour); } catch {} }, [reminderHour]);
  useEffect(() => { try { localStorage.setItem("gm_reminder_days", JSON.stringify(reminderDays)); } catch {} }, [reminderDays]);
  useEffect(() => { try { localStorage.setItem("gm_reminder_smart", reminderSmart ? "1" : "0"); } catch {} }, [reminderSmart]);

  // Tags
  const [userTags, setUserTags] = useState(() => {
    try { return JSON.parse(localStorage.getItem("gm_user_tags") || "[]"); } catch { return []; }
  });
  useEffect(() => { try { localStorage.setItem("gm_user_tags", JSON.stringify(userTags)); } catch {} }, [userTags]);
  const [txTags, setTxTags] = useState(() => {
    try { return JSON.parse(localStorage.getItem("gm_tx_tags") || "{}"); } catch { return {}; }
  });
  useEffect(() => { try { localStorage.setItem("gm_tx_tags", JSON.stringify(txTags)); } catch {} }, [txTags]);
  const [showTagModal, setShowTagModal] = useState(false);

  // Receipts (base64 stored per tx id)
  const [txReceipts, setTxReceipts] = useState(() => {
    try { return JSON.parse(localStorage.getItem("gm_tx_receipts") || "{}"); } catch { return {}; }
  });
  useEffect(() => { try { localStorage.setItem("gm_tx_receipts", JSON.stringify(txReceipts)); } catch {} }, [txReceipts]);
  const [showNameEdit, setShowNameEdit] = useState(false);
  const [tempName, setTempName] = useState("");
  const [toast, setToast] = useState(null);
  const [showExportMenu, setShowExportMenu] = useState(false);
  const [showStoryCard, setShowStoryCard] = useState(false);
  // Skeleton
  const [loaded, setLoaded] = useState(true);

  // Global keyboard tracking — reliable for iOS PWA
  const [kbHeight, setKbHeight] = useState(0);

  // Hide splash screen after 3s
  useEffect(() => {
    const t = setTimeout(() => {
      if (window.__hideSplash) window.__hideSplash();
    }, 3000);
    return () => clearTimeout(t);
  }, []);

  const [vpOffsetTop, setVpOffsetTop] = useState(0);
  useEffect(() => {
    if (!window.visualViewport) return;
    const measure = () => {
      const vv = window.visualViewport;
      const kb = window.innerHeight - vv.height - vv.offsetTop;
      const kbVal = kb > 50 ? Math.round(kb) : 0;
      setKbHeight(kbVal);
      setVpOffsetTop(vv.offsetTop);
      const sheet = document.getElementById("form-sheet");
      if (sheet) sheet.style.paddingBottom = kbVal > 0 ? `${kbVal}px` : "0px";
      // also directly update onboarding container if visible
      const ob = document.getElementById("onboarding-container");
      if (ob) {
        ob.style.justifyContent = kbVal > 0 ? "flex-end" : "center";
        ob.style.paddingBottom = kbVal > 0 ? `${kbVal}px` : "40px";
      }
    };
    const onResize = () => {
      measure();
      setTimeout(measure, 100);
      setTimeout(measure, 300);
    };
    window.visualViewport.addEventListener("resize", onResize);
    window.visualViewport.addEventListener("scroll", onResize);
    return () => {
      window.visualViewport.removeEventListener("resize", onResize);
      window.visualViewport.removeEventListener("scroll", onResize);
    };
  }, []);
  useEffect(() => {
    document.body.style.background = T.bg;
    document.body.style.backgroundColor = T.bg;
    const root = document.getElementById("root");
    if (root) { root.style.background = T.bg; root.style.backgroundColor = T.bg; }
    const meta = document.querySelector("meta[name='theme-color']");
    if (meta) meta.setAttribute("content", T.bg);
  }, [T.bg]);

  // Offline
  const [isOnline, setIsOnline] = useState(navigator.onLine);
  useEffect(() => {
    const on = () => setIsOnline(true), off = () => setIsOnline(false);
    window.addEventListener("online", on); window.addEventListener("offline", off);
    return () => { window.removeEventListener("online",on); window.removeEventListener("offline",off); };
  }, []);

  // Install prompt
  const [installPrompt, setInstallPrompt] = useState(null);
  const [showInstallBanner, setShowInstallBanner] = useState(false);
  useEffect(() => {
    const h = (e) => { e.preventDefault(); setInstallPrompt(e); setShowInstallBanner(true); };
    window.addEventListener("beforeinstallprompt", h);
    return () => window.removeEventListener("beforeinstallprompt", h);
  }, []);

  // Delete with undo
  const [confirmDelete, setConfirmDelete] = useState(null); // kept for compatibility
  const [customConfirm, setCustomConfirm] = useState(null); // {msg, onOk}
  const [showDiscardConfirm, setShowDiscardConfirm] = useState(false);
  const showConfirm = (msg, onOk) => setCustomConfirm({ msg, onOk });
  const deletedItemRef = useRef(null);
  const isRestoringRef = useRef(false);
  const undoTimerRef = useRef(null);
  const [undoToast, setUndoToast] = useState(null); // { id, label }

  // Swipe hint — show once
  const [swipeHintShown, setSwipeHintShown] = useState(false);
  const [swipeHintAnim, setSwipeHintAnim] = useState(false);

  // Search
  const [searchQuery, setSearchQuery] = useState("");

  // Recurring
  const [recurring, setRecurring] = useState(() => {
    try { const v = localStorage.getItem("gm_recurring"); return v ? JSON.parse(v) : []; } catch { return []; }
  });
  useEffect(() => { try { localStorage.setItem("gm_recurring", JSON.stringify(recurring)); } catch {} }, [recurring]);
  const [recurForm, setRecurForm] = useState({ description:"", amount:"", amountDisplay:"", category:"food", day:1, autoApply:true });
  const [editRecurId, setEditRecurId] = useState(null);
  const [showRecurPanel, setShowRecurPanel] = useState(false);

  // ── Recurring Income ──────────────────────────────────────────────────────
  const [recurringIncome, setRecurringIncome] = useState(() => {
    try { const v = localStorage.getItem("gm_recurring_income"); return v ? JSON.parse(v) : []; } catch { return []; }
  });
  useEffect(() => { try { localStorage.setItem("gm_recurring_income", JSON.stringify(recurringIncome)); } catch {} }, [recurringIncome]);
  const [recurIncomeForm, setRecurIncomeForm] = useState({ description:"", amount:"", amountDisplay:"", day:1, autoApply:true });
  const [editRecurIncomeId, setEditRecurIncomeId] = useState(null);
  const [showRecurIncomePanel, setShowRecurIncomePanel] = useState(false);

  // Budgets
  const [budgets, setBudgets] = useState(() => {
    try { const v = localStorage.getItem("gm_budgets"); return v ? JSON.parse(v) : {}; } catch { return {}; }
  });
  const [budgetsDisplay, setBudgetsDisplay] = useState(() => {
    try { const v = localStorage.getItem("gm_budgets"); const b = v ? JSON.parse(v) : {}; return Object.fromEntries(Object.entries(b).map(([k,val]) => [k, val ? Number(val).toLocaleString("id-ID") : ""])); } catch { return {}; }
  });
  useEffect(() => { try { localStorage.setItem("gm_budgets", JSON.stringify(budgets)); } catch {} }, [budgets]);

  // Overall monthly budget limit
  const [overallBudget, setOverallBudget] = useState(() => {
    try { const v = localStorage.getItem("gm_overall_budget"); return v ? Number(v) : 0; } catch { return 0; }
  });
  useEffect(() => { try { localStorage.setItem("gm_overall_budget", String(overallBudget)); } catch {} }, [overallBudget]);
  const [showOverallBudgetEdit, setShowOverallBudgetEdit] = useState(false);
  const [tempOverallBudget, setTempOverallBudget] = useState(0);
  const [tempOverallBudgetDisplay, setTempOverallBudgetDisplay] = useState("");
  const [showOverallBudgetModal, setShowOverallBudgetModal] = useState(false);

  // Savings Goals (custom progress targets)
  const [savingsGoals, setSavingsGoals] = useState(() => {
    try {
      const v = localStorage.getItem("gm_savings_goals");
      return v ? JSON.parse(v) : [];
    } catch { return []; }
  });
  useEffect(() => { try { localStorage.setItem("gm_savings_goals", JSON.stringify(savingsGoals)); } catch {} }, [savingsGoals]);
  // ── Daily Notes ─────────────────────────────────────────────────────────────
  const [dailyNotes, setDailyNotes] = useState(() => {
    try { return JSON.parse(localStorage.getItem("gm_daily_notes") || "{}"); } catch { return {}; }
  });
  useEffect(() => { try { localStorage.setItem("gm_daily_notes", JSON.stringify(dailyNotes)); } catch {} }, [dailyNotes]);
  const [showDailyNote, setShowDailyNote] = useState(false);
  const [dailyNoteInput, setDailyNoteInput] = useState("");

  const [editingGoal, setEditingGoal] = useState(null); // null or goal id
  const modalScrollY = useRef(0);
  const anyModal = showForm || editIncome || editingGoal !== null;
  useEffect(() => {
    if (anyModal) {
      modalScrollY.current = window.scrollY;
    } else {
      window.scrollTo(0, modalScrollY.current);
    }
  }, [anyModal]);

  const [quickAddGoalId, setQuickAddGoalId] = useState(null);
  const [quickAddAmt, setQuickAddAmt] = useState("");
  const [quickAddAmtDisplay, setQuickAddAmtDisplay] = useState("");
  const [activeCardId, setActiveCardId] = useState(null);
  const [activeDateId, setActiveDateId] = useState(null);
  const [goalForm, setGoalForm] = useState({ label:"", target:"", targetDisplay:"", saved:"", savedDisplay:"", color:"#60a5fa", icon:"piggy", deadline:"" });

  // Date wishlist
  const [dateWishlist, setDateWishlist] = useState(() => {
    try { const v = localStorage.getItem("gm_date_wishlist"); return v ? JSON.parse(v) : []; } catch { return []; }
  });
  useEffect(() => { try { localStorage.setItem("gm_date_wishlist", JSON.stringify(dateWishlist)); } catch {} }, [dateWishlist]);
  const [showWishlistForm, setShowWishlistForm] = useState(false);
  const [wishlistInput, setWishlistInput] = useState("");

  // Count-up balance
  const [displayBalance, setDisplayBalance] = useState(0);
  const [profilePhoto, setProfilePhoto] = useState(() => {
    try { return localStorage.getItem("gm_profile_photo") || null; } catch { return null; }
  });
  const profileInputRef = useRef(null);
  useEffect(() => {
    try {
      if (profilePhoto) localStorage.setItem("gm_profile_photo", profilePhoto);
      else localStorage.removeItem("gm_profile_photo");
    } catch {}
  }, [profilePhoto]);
  const handleProfilePhotoChange = (e) => {
    const file = e.target.files[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = (ev) => {
      setProfilePhoto(ev.target.result);
      showToast("ok:Foto profil diperbarui");
    };
    reader.readAsDataURL(file);
  };

  const [scrolled, setScrolled] = useState(false);
  const [pullY, setPullY] = useState(0);
  const [refreshing, setRefreshing] = useState(false);
  const pullStartY = useRef(null);
  const swipeStartX = useRef(null);
  const swipeStartY = useRef(null);
  const swipeBlocked = useRef(false); // true saat card sedang diswipe
  const lastScrollTop = useRef(0);
  const PULL_THRESHOLD = 120;

  // Freeze header as soon as balance card is touched by header (IntersectionObserver)
  useEffect(() => {
    if (!balanceCardRef.current) return;
    const observer = new IntersectionObserver(
      ([entry]) => { setScrolled(!entry.isIntersecting); },
      { threshold: 0, rootMargin: `-${headerHeight || 60}px 0px 0px 0px` }
    );
    observer.observe(balanceCardRef.current);
    return () => observer.disconnect();
  }, [headerHeight]);

  useEffect(() => {
    if (tab === "dashboard") return;
    const onScroll = () => setTabScrolled(window.scrollY > 10);
    window.addEventListener("scroll", onScroll, { passive:true });
    return () => window.removeEventListener("scroll", onScroll);
  }, [tab]);

  const handlePullStart = (e) => {
    if (tab !== "dashboard") return;
    const scrollY = window.scrollY || document.documentElement.scrollTop;
    if (scrollY === 0) {
      pullStartY.current = e.touches[0].clientY;
    }
  };
  const handlePullMove = (e) => {
    if (pullStartY.current === null || refreshing) return;
    const dy = e.touches[0].clientY - pullStartY.current;
    if (dy > 0) setPullY(Math.min(dy * 0.25, PULL_THRESHOLD + 10));
  };
  const handlePullEnd = () => {
    if (pullY >= PULL_THRESHOLD && !refreshing) {
      haptic();
      setRefreshing(true);
      setPullY(PULL_THRESHOLD * 0.6);
      setTimeout(() => {
        setRefreshing(false);
        setPullY(0);
        showToast("ok:Data diperbarui");
      }, 1200);
    } else {
      setPullY(0);
    }
    pullStartY.current = null;
  };
  const TAB_ORDER = ["dashboard", "transactions", "report", "date", "settings"];

  const toggleDark = useCallback((btnRef) => {
    const btn = btnRef?.current;
    const rect = btn ? btn.getBoundingClientRect() : null;
    const x = rect ? rect.left + rect.width / 2 : window.innerWidth / 2;
    const y = rect ? rect.top + rect.height / 2 : window.innerHeight / 2;
    const nextDark = darkOverride === null ? !systemDark : darkOverride === systemDark ? !darkOverride : !darkOverride;
    setDarkRipple({ x, y, toDark: nextDark });
    setTimeout(() => {
      setDarkOverride(d => {
        const next = d === null ? !systemDark : !d;
        try { localStorage.setItem("gm_dark_override", String(next)); } catch {}
        return next;
      });
      setTimeout(() => setDarkRipple(null), 400);
    }, 30);
  }, [darkOverride, systemDark]);

  const [tabAnim, setTabAnim] = useState(true);
  const changeTab = useCallback((newTab) => {
    setTabScrolled(false);
    haptic();
    const el = document.getElementById("root") || document.documentElement;
    // Save current scroll position
    tabScrollPos.current[tab] = el.scrollTop;
    // Restore scroll position for new tab
    const savedPos = tabScrollPos.current[newTab] || 0;
    el.scrollTo({ top: savedPos, behavior: "instant" });
    setActiveCardId(null);
    setTabAnim(false);
    requestAnimationFrame(() => {
      setTab(newTab);
      requestAnimationFrame(() => {
        setTabAnim(true);
        // Show swipe hint once when opening transactions tab
        if (newTab === "transactions" && !swipeHintShown) {
          setSwipeHintShown(true);
          setTimeout(() => setSwipeHintAnim(true), 600);
          setTimeout(() => setSwipeHintAnim(false), 2000);
        }
      });
    });
  }, [swipeHintShown]);

  // ── Kalkulasi derivatif (harus di atas useEffect yang memakainya) ──
  const now = today();
  const currentWeek = getWeek(now);
  const currentMonth = getMonth(now);
  const getCategory = (key) => {
    const cat = categories[key];
    if (!cat) return { label: key, icon: "package", color: "#94a3b8" };
    // Merge labelId from DEFAULT_CATEGORIES if missing (fixes English stuck bug)
    if (!cat.labelId && DEFAULT_CATEGORIES[key]?.labelId) {
      return { ...cat, labelId: DEFAULT_CATEGORIES[key].labelId };
    }
    return cat;
  };

  const weekExpense = useMemo(() => {
    const d = new Date(); const startOfWeek = new Date(d); startOfWeek.setDate(d.getDate() - d.getDay() + 1);
    return transactions.filter(t => { const td = new Date(t.date); return td >= startOfWeek && td <= d; }).reduce((s,t) => s+t.amount, 0);
  }, [transactions]);

    const totalExpense = useMemo(() =>
    transactions.filter(t => getMonth(t.date) === currentMonth).reduce((s, t) => s + t.amount, 0),
    [transactions, currentMonth]);

  const totalCicilanMonthly = cicilan.reduce((s, ci) => s + Number(ci.monthly || 0), 0);
  const balance = income - totalExpense - totalCicilanMonthly;
  const monthlySave = Math.max(0, Math.min(balance, savingsGoal));
  const savePct = income > 0 ? Math.min(100, Math.round((monthlySave / income) * 100)) : 0;

  // Set balance directly - no animation (removed: was causing lag with 50fps interval)
  useEffect(() => {
    if (!loaded) return;
    setDisplayBalance(balance);
  }, [balance, loaded]);

  // Swipe tab gesture
  const handleSwipeStart = useCallback((e) => {
    swipeStartX.current = e.touches[0].clientX;
    swipeStartY.current = e.touches[0].clientY;
  }, []);

  const handleSwipeEnd = useCallback((e) => {
    if (swipeStartX.current === null) return;
    const dx = e.changedTouches[0].clientX - swipeStartX.current;
    const dy = Math.abs(e.changedTouches[0].clientY - swipeStartY.current);
    swipeStartX.current = null;
    if (swipeBlocked.current) { swipeBlocked.current = false; return; }
    // Disable swipe when any modal/popup is open
    const anyModalOpen = showForm || showCalc || editIncome || showCatManager || showDailyNote ||
      showBudgetLimit || showAppearanceModal || showNotifModal || showDataModal ||
      showOverallBudgetModal || showCicilanModal || showReminderModal || showSplitBills ||
      editingGoal !== null;
    if (anyModalOpen) return;
    // Higher threshold (120px) + stricter vertical check (50px max)
    if (Math.abs(dx) < 120 || dy > 50) return;
    const TABS = ["dashboard","transactions","report","date","settings"];
    const cur = TABS.indexOf(tab);
    if (dx < 0 && cur < TABS.length-1) changeTab(TABS[cur+1]);
    else if (dx > 0 && cur > 0) changeTab(TABS[cur-1]);
  }, [tab, changeTab, showForm, showCalc, editIncome, showCatManager,
    showBudgetLimit, showAppearanceModal, showNotifModal, showDataModal,
    showOverallBudgetModal, showCicilanModal, showReminderModal, editingGoal]);

  // Apply recurring transactions
  useEffect(() => {
    if (!loaded) return;
    const todayDate = today();
    const todayDay = new Date().getDate();
    recurring.forEach(r => {
      const shouldApply = r.autoApply !== false;
      if (!shouldApply) {
        // Send reminder notif for manual recurring items due today
        if (Number(r.day) === todayDay && notifEnabled) {
          sendLocalNotification(
            lang === "en" ? "Payment Reminder" : "Pengingat Tagihan",
            lang === "en" ? `Time to record: ${r.description} — ${formatRp(Number(r.amount))}` : `Waktunya catat: ${r.description} — ${formatRp(Number(r.amount))}`
          );
        }
        return;
      }
      const exists = transactions.some(t => t.description===r.description && t.date===todayDate && t.amount===Number(r.amount));
      if (Number(r.day)===todayDay && !exists) {
        setTransactions(prev => [...prev, { description:r.description, amount:Number(r.amount), category:r.category, date:todayDate, location:"Rutin", note:"Otomatis", id:Date.now()+Math.random() }]);
        // Notif for auto-applied
        if (notifEnabled) {
          sendLocalNotification(
            lang === "en" ? "Auto-recorded" : "Tercatat Otomatis",
            lang === "en" ? `${r.description} — ${formatRp(Number(r.amount))} recorded` : `${r.description} — ${formatRp(Number(r.amount))} dicatat`
          );
        }
      }
    });
  }, [loaded]);

  // Delete with undo
  const deleteTransaction = (id) => {
    haptic("warning");
    const item = transactions.find(t => t.id === id);
    if (!item) return;
    deletedItemRef.current = item;
    setTransactions(prev => prev.filter(t => t.id !== id));
    if (undoTimerRef.current) clearTimeout(undoTimerRef.current);
    setUndoToast({ id, label: item.description || item.category });
    undoTimerRef.current = setTimeout(() => {
      setUndoToast(null);
      deletedItemRef.current = null;
    }, 4000);
  };

  const undoDelete = () => {
    const item = deletedItemRef.current;
    if (!item) return;
    clearTimeout(undoTimerRef.current);
    deletedItemRef.current = null;
    setTransactions(prev => [...prev, item].sort((a,b) => new Date(b.date)-new Date(a.date)));
    setUndoToast(null);
    haptic("light");
  };

  // Delete confirm (legacy — unused now)
  const confirmDeleteFn = () => {
    haptic("error");
    setTransactions(prev => prev.filter(t => t.id !== confirmDelete));
    setConfirmDelete(null);
    showToast("del:"+L.txDeleted);
  };

  const showToast = (msg) => {
    setToast(msg);
    setTimeout(() => setToast(null), 3000);
  };

  const filtered = useMemo(() => {
    let list = transactions;
    if (filterCat !== "all") list = list.filter(t => t.category === filterCat);
    if (filterPeriod === "daily") list = list.filter(t => t.date === now);
    else if (filterPeriod === "weekly") list = list.filter(t => getWeek(t.date) === currentWeek);
    else list = list.filter(t => getMonth(t.date) === currentMonth);
    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase();
      list = list.filter(t => t.description.toLowerCase().includes(q) || (t.location||"").toLowerCase().includes(q) || (t.note||"").toLowerCase().includes(q));
    }
    return list.sort((a, b) => {
      if (sortOrder === "date-asc")  return a.date.localeCompare(b.date);
      if (sortOrder === "amt-desc")  return b.amount - a.amount;
      if (sortOrder === "amt-asc")   return a.amount - b.amount;
      return b.date.localeCompare(a.date); // date-desc default
    });
  }, [transactions, filterPeriod, filterCat, now, currentWeek, currentMonth, searchQuery, sortOrder]);

  const dateExpense = useMemo(() =>
    transactions.filter(t => t.category === "date" && getMonth(t.date) === currentMonth).reduce((s, t) => s + t.amount, 0),
    [transactions, currentMonth]);

  const filteredTotal = filtered.reduce((s, t) => s + t.amount, 0);

  const catBreakdown = useMemo(() => {
    const m = transactions.filter(t => getMonth(t.date) === currentMonth);
    const map = {};
    m.forEach(t => { map[t.category] = (map[t.category] || 0) + t.amount; });
    return Object.entries(map).sort((a, b) => b[1] - a[1]);
  }, [transactions, currentMonth]);

  // Donut chart data
  const donutData = useMemo(() =>
    catBreakdown.map(([key, value]) => ({
      name: getCatLabel(getCategory(key), lang),
      value,
      color: getCategory(key).color
    })),
    [catBreakdown, categories]);

  const reportTxns = useMemo(() =>
    transactions.filter(t => t.date === reportDate).sort((a, b) => b.id - a.id),
    [transactions, reportDate]);

  const reportTotal = reportTxns.reduce((s, t) => s + t.amount, 0);
  const prevMonth = useMemo(() => {
    const d = new Date(currentMonth + "-01");
    d.setMonth(d.getMonth() - 1);
    return d.toISOString().slice(0, 7);
  }, [currentMonth]);

  const monthCompareData = useMemo(() => {
    const cats = [...new Set(transactions.map(t => t.category))];
    return cats.map(key => {
      const cat = getCategory(key);
      const curr = transactions.filter(t => t.category === key && getMonth(t.date) === currentMonth).reduce((s, t) => s + t.amount, 0);
      const prev = transactions.filter(t => t.category === key && getMonth(t.date) === prevMonth).reduce((s, t) => s + t.amount, 0);
      if (curr === 0 && prev === 0) return null;
      return { name: getCatLabel(cat, lang), curr, prev, color: cat.color };
    }).filter(Boolean).sort((a,b) => b.curr - a.curr).slice(0, 6);
  }, [transactions, currentMonth, prevMonth, categories]);

  const monthInsights = useMemo(() => {
    const insights = [];
    const currTotal = transactions.filter(t => getMonth(t.date) === currentMonth).reduce((s,t) => s+t.amount, 0);
    const prevTotal = transactions.filter(t => getMonth(t.date) === prevMonth).reduce((s,t) => s+t.amount, 0);
    if (prevTotal > 0) {
      const pct = Math.round(((currTotal - prevTotal) / prevTotal) * 100);
      insights.push({ type: pct > 0 ? "up" : "down", text: `${pct > 0 ? L.insightMore : L.insightLess} ${Math.abs(pct)}% ${L.insightFrom}` });
    }
    // Gunakan nama lengkap dari categories, bukan nama terpotong dari chart
    const cats = [...new Set(transactions.map(t => t.category))];
    cats.forEach(key => {
      const cat = getCategory(key);
      const curr = transactions.filter(t => t.category === key && getMonth(t.date) === currentMonth).reduce((s,t) => s+t.amount, 0);
      const prev = transactions.filter(t => t.category === key && getMonth(t.date) === prevMonth).reduce((s,t) => s+t.amount, 0);
      if (prev > 0 && curr > 0) {
        const pct = Math.round(((curr - prev) / prev) * 100);
        if (Math.abs(pct) >= 20) insights.push({ type: pct > 0 ? "up" : "down", text: `${getCatLabel(cat, lang)} ${pct > 0 ? L.insightUp : L.insightDown} ${Math.abs(pct)}% ${L.insightFrom}` });
      }
    });
    return insights.slice(0, 4);
  }, [transactions, currentMonth, prevMonth, categories]);

  // ── Streak: track daily app opens ──────────────────────────────
  const [streak, setStreak] = useState(() => {
    try { return JSON.parse(localStorage.getItem("gm_streak") || '{"count":0,"lastDate":""}'); }
    catch { return { count: 0, lastDate: "" }; }
  });
  useEffect(() => {
    const todayStr = today();
    if (streak.lastDate === todayStr) return;
    const yesterday = new Date(Date.now() - 86400000).toISOString().split("T")[0];
    const newCount = streak.lastDate === yesterday ? streak.count + 1 : 1;
    const newStreak = { count: newCount, lastDate: todayStr };
    setStreak(newStreak);
    try { localStorage.setItem("gm_streak", JSON.stringify(newStreak)); } catch {}
  }, []);

  // ── Financial Health Score ───────────────────────────────────────────────────
  const healthScore = useMemo(() => {
    let score = 0;
    const scores = {};

    // 1. Rasio pengeluaran vs pemasukan (max 30 poin)
    if (income > 0) {
      const ratio = totalExpense / income;
      if (ratio <= 0.5) scores.ratio = 30;
      else if (ratio <= 0.7) scores.ratio = 20;
      else if (ratio <= 0.9) scores.ratio = 10;
      else scores.ratio = 0;
    } else scores.ratio = 0;

    // 2. Konsistensi mencatat (max 25 poin) — berapa hari bulan ini ada transaksi
    const daysInMonth = new Date(new Date().getFullYear(), new Date().getMonth()+1, 0).getDate();
    const daysPassed = new Date().getDate();
    const activeDays = new Set(transactions.filter(t => getMonth(t.date) === currentMonth).map(t => t.date)).size;
    const consistency = activeDays / Math.min(daysPassed, daysInMonth);
    scores.consistency = Math.round(consistency * 25);

    // 3. Streak (max 15 poin)
    scores.streak = Math.min(15, Math.round(streak.count / 7 * 15));

    // 4. Ada savings goal (max 15 poin)
    scores.goals = savingsGoals.length > 0 ? (savingsGoals.some(g => g.saved > 0) ? 15 : 8) : 0;

    // 5. Budget tidak terlampaui (max 15 poin)
    const overBudget = Object.entries(budgets).filter(([k,v]) => {
      const spent = transactions.filter(t => t.category===k && getMonth(t.date)===currentMonth).reduce((s,t)=>s+t.amount,0);
      return spent > v;
    }).length;
    scores.budget = overBudget === 0 ? 15 : overBudget === 1 ? 8 : 0;

    score = Object.values(scores).reduce((s,v) => s+v, 0);
    const label = score >= 80 ? (L.healthExcellent) :
                  score >= 60 ? (L.healthGood) :
                  score >= 40 ? (L.healthFair) :
                  (L.healthNeedAttention);
    const color = score >= 80 ? "#4ade80" : score >= 60 ? themeAccent : score >= 40 ? "#fbbf24" : "#f87171";
    return { score, label, color, scores };
  }, [transactions, income, totalExpense, currentMonth, streak, savingsGoals, budgets, lang]);

  const weeklyTrend = useMemo(() => {
    const weeks = [];
    for (let i = 7; i >= 0; i--) {
      const d = new Date(); d.setDate(d.getDate() - i*7);
      const wk = getWeek(d.toISOString().split("T")[0]);
      const total = transactions.filter(t => getWeek(t.date)===wk).reduce((s,t) => s+t.amount, 0);
      weeks.push({ label:`W${8-i}`, total });
    }
    return weeks;
  }, [transactions]);

  // Sparkline: last 7 days spending per day
  const sparkline7 = useMemo(() => {
    const days = [];
    for (let i = 6; i >= 0; i--) {
      const d = new Date(); d.setDate(d.getDate() - i);
      const ds = d.toISOString().split("T")[0];
      const total = transactions.filter(t => t.date === ds).reduce((s,t) => s+t.amount, 0);
      const dayLabel = d.toLocaleDateString("id-ID", { weekday:"short" });
      days.push({ ds, total, dayLabel });
    }
    return days;
  }, [transactions]);

  // End-of-month prediction based on daily average so far
  const monthPrediction = useMemo(() => {
    const d = new Date();
    const dayOfMonth = d.getDate();
    const daysInMonth = new Date(d.getFullYear(), d.getMonth()+1, 0).getDate();
    if (dayOfMonth < 3 || totalExpense === 0) return null;
    const dailyAvg = totalExpense / dayOfMonth;
    const predicted = Math.round(dailyAvg * daysInMonth);
    return { predicted, dailyAvg, daysLeft: daysInMonth - dayOfMonth, daysInMonth };
  }, [totalExpense]);

  // Average monthly savings across last 3 months
  const avgMonthlySaved = useMemo(() => {
    const results = [];
    for (let i = 1; i <= 3; i++) {
      const d = new Date(); d.setDate(1); d.setMonth(d.getMonth() - i);
      const m = d.toISOString().slice(0,7);
      const exp = transactions.filter(t => getMonth(t.date)===m).reduce((s,t)=>s+t.amount,0);
      results.push(exp);
    }
    const nonZero = results.filter(v => v > 0);
    if (nonZero.length === 0) return 0;
    // Use income if available; savings = income - expense
    const avgExp = nonZero.reduce((a,b)=>a+b,0)/nonZero.length;
    return Math.max(0, income - avgExp);
  }, [transactions, income]);

  // ── Weekly insight ──────────────────────────────────────────────
  const weeklyInsight = useMemo(() => {
    const todayStr = today();
    const d = new Date(todayStr);
    const dayOfWeek = d.getDay(); // 0=Sun
    const startThisWeek = new Date(d); startThisWeek.setDate(d.getDate() - (dayOfWeek === 0 ? 6 : dayOfWeek - 1));
    const startLastWeek = new Date(startThisWeek); startLastWeek.setDate(startThisWeek.getDate() - 7);
    const endLastWeek = new Date(startThisWeek); endLastWeek.setDate(startThisWeek.getDate() - 1);
    const thisWeekStr = startThisWeek.toISOString().split("T")[0];
    const lastWeekStart = startLastWeek.toISOString().split("T")[0];
    const lastWeekEnd = endLastWeek.toISOString().split("T")[0];

    const thisWeekTxns = transactions.filter(t => t.date >= thisWeekStr && t.date <= todayStr);
    const lastWeekTxns = transactions.filter(t => t.date >= lastWeekStart && t.date <= lastWeekEnd);

    const thisTotal = thisWeekTxns.reduce((s,t) => s+t.amount, 0);
    const lastTotal = lastWeekTxns.reduce((s,t) => s+t.amount, 0);

    // Top category this week
    const catMap = {};
    thisWeekTxns.forEach(t => { catMap[t.category] = (catMap[t.category]||0) + t.amount; });
    const topCatEntry = Object.entries(catMap).sort((a,b)=>b[1]-a[1])[0];
    const topCat = topCatEntry ? categories[topCatEntry[0]] : null;

    return { thisTotal, lastTotal, diff: thisTotal - lastTotal, topCat, topCatAmt: topCatEntry?.[1] || 0, hasBoth: lastTotal > 0 };
  }, [transactions, categories]);

  // ── Category trend (multi-month line data) ──────────────────────
  const [catTrendView, setCatTrendView] = useState("bar"); // "bar" | "line"
  const catTrendData = useMemo(() => {
    // Last 4 months
    const months = [];
    for (let i = 3; i >= 0; i--) {
      const d = new Date(); d.setDate(1); d.setMonth(d.getMonth() - i);
      months.push(d.toISOString().slice(0,7));
    }
    const catKeys = Object.keys(categories);
    // Line data: per category, one point per month
    const lineData = catKeys.map(key => {
      const cat = categories[key];
      return {
        key, label: getCatLabel(cat, lang), color: cat.color,
        data: months.map(m => ({
          month: new Date(m+"-01").toLocaleDateString(lang==="en"?"en-GB":"id-ID",{month:"short"}),
          value: transactions.filter(t => t.category===key && getMonth(t.date)===m).reduce((s,t)=>s+t.amount,0)
        }))
      };
    }).filter(d => d.data.some(p => p.value > 0));

    // Bar data: per month, each category as a group
    const barData = months.map(m => {
      const obj = { month: new Date(m+"-01").toLocaleDateString(lang==="en"?"en-GB":"id-ID",{month:"short"}) };
      catKeys.forEach(key => { obj[key] = transactions.filter(t => t.category===key && getMonth(t.date)===m).reduce((s,t)=>s+t.amount,0); });
      return obj;
    });

    return { lineData, barData, months, catKeys };
  }, [transactions, categories, lang]);

  const reportByCat = useMemo(() => {
    const map = {};
    reportTxns.forEach(t => { map[t.category] = (map[t.category] || 0) + t.amount; });
    return Object.entries(map).sort((a, b) => b[1] - a[1]);
  }, [reportTxns]);

  const recentTxns = useMemo(() =>
    [...transactions].sort((a, b) => b.id - a.id).slice(0, recentCount),
    [transactions, recentCount]);

  const startEdit = (t) => {
    const amtDisplay = t.amount ? Number(t.amount).toLocaleString("id-ID") : "";
    setForm({ date: t.date, amount: t.amount, amountDisplay: amtDisplay, category: t.category, description: t.description, location: t.location, note: t.note||"" });
    setEditItem(t.id);
    setShowForm(true);
  };

  // ctx object passed to all lazy-loaded tab components
  const ctx = useMemo(() => ({
    T, dark, lang, L, setLang,
    tabAnim, loaded, headerHeight,
    themeAccent, themePrimary, themePresetId, setThemePresetId,
    customPrimary, setCustomPrimary, customAccent, setCustomAccent,
    showThemePicker, setShowThemePicker,
    THEME_PRESETS,
    income, totalExpense, balance, savePct, monthlySave,
    transactions, categories, setCategories,
    savingsGoals, setSavingsGoals,
    overallBudget, setOverallBudget,
    budgets, setBudgets,
    recurring, setRecurring,
    recurringIncome, setRecurringIncome,
    filtered, filteredTotal,
    filterPeriod, setFilterPeriod,
    filterCat, setFilterCat,
    sortOrder, setSortOrder,
    editItem, setEditItem,
    form, setForm,
    setShowForm,
    startEdit,
    recurForm, setRecurForm,
    showRecurPanel, setShowRecurPanel,
    editRecurId, setEditRecurId,
    recurIncomeForm, setRecurIncomeForm,
    showRecurIncomePanel, setShowRecurIncomePanel,
    editRecurIncomeId, setEditRecurIncomeId,
    recentTxns, recentCount, setRecentCount,
    donutData, catBreakdown, sparkline7, monthPrediction, avgMonthlySaved,
    streak, weeklyInsight, weeklyTrend,
    monthCompareData, monthInsights, catTrendData,
    prevMonth,
    reportTxns, reportTotal, reportByCat,
    reportDate, setReportDate,
    quickAddGoalId, setQuickAddGoalId,
    quickAddAmtDisplay, setQuickAddAmtDisplay, setQuickAddAmt,
    balanceCardRef,
    showExportMenu, setShowExportMenu,
    userName, setUserName,
    showNameEdit, setShowNameEdit,
    tempName, setTempName,
    profilePhoto, profileInputRef, handleProfilePhotoChange,
    catForm, setCatForm,
    editCatKey, setEditCatKey,
    showCatManager, setShowCatManager,
    showBudgetLimit, setShowBudgetLimit,
    showAppearanceModal, setShowAppearanceModal,
    showDataModal, setShowDataModal,
    followSystem, setFollowSystem,
    darkOverride, setDarkOverride,
    navbarOffset, setNavbarOffset,
    exportCSV, exportPDFReport,
    ICON_OPTIONS, COLOR_OPTIONS,
    userTags, setUserTags, txTags, setTxTags, txReceipts,
    showTagModal, setShowTagModal,
    setShowOverallBudgetModal,
    setEditingGoal, setGoalForm,
    setTempIncome, setTempIncomeDisplay,
    setIncomeAdj, setIncomeAdjDisplay, setEditIncome,
    setTempOverallBudget, setTempOverallBudgetDisplay,
    budgetsDisplay, setBudgetsDisplay,
    showToast, haptic,
    dateExpense,
    triggerThemeChange,
    changeTab,
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }), [tab, transactions, categories, savingsGoals, income, recurring, recurringIncome,
    dark, lang, themePresetId, customPrimary, customAccent, loaded, tabAnim,
    filtered, filterPeriod, filterCat, sortOrder, editItem, form, recurForm,
    showRecurPanel, editRecurId, recurIncomeForm, showRecurIncomePanel, editRecurIncomeId,
    recentTxns, recentCount, overallBudget, budgets, reportDate, showExportMenu,
    userName, showNameEdit, tempName, profilePhoto, catForm, editCatKey,
    showCatManager, showBudgetLimit, showAppearanceModal, showDataModal,
    followSystem, darkOverride, userTags, txTags, txReceipts, showTagModal,
    quickAddGoalId, quickAddAmtDisplay, T, L, themeAccent, themePrimary,
  ]);

  const submitForm = () => {
    if (!form.amount || !form.description) return;
    haptic("success");
    if (editItem) {
      setTransactions(prev => prev.map(t => t.id === editItem ? { ...form, id: editItem, amount: Number(form.amount) } : t));
      setEditItem(null);
      showToast("ok:"+L.txUpdated);
    } else {
      const newAmount = Number(form.amount);
      setTransactions(prev => {
        const updated = [...prev, { ...form, id: Date.now(), amount: newAmount }];
        // Cek budget warning setelah tambah
        const catKey = form.category;
        const limit = budgets[catKey] || 0;
        if (limit > 0 && !isRestoringRef.current) {
          const spent = updated.filter(t => t.category === catKey && t.date.startsWith(getMonth(form.date))).reduce((s,t) => s+t.amount, 0);
          const catName = getCatLabel(categories[catKey], lang) || catKey;
          const pct = Math.round(spent / limit * 100);
          if (spent >= limit) {
            setTimeout(() => {
              showToast(lang === "en"
                ? `warn:${catName} budget exceeded! (${pct}% used)`
                : `warn:Budget ${catName} terlampaui! (${pct}% terpakai)`);
              if (notifEnabled) sendLocalNotification(
                lang === "en" ? "Budget Alert" : "Peringatan Budget",
                lang === "en" ? `${catName} budget is over the limit (${pct}%)` : `Budget ${catName} sudah melebihi batas (${pct}%)`
              );
            }, 400);
          } else if (spent >= limit * 0.8) {
            setTimeout(() => {
              showToast(lang === "en"
                ? `warn:${catName} budget at ${pct}% — almost full!`
                : `warn:Budget ${catName} sudah ${pct}% — hampir habis!`);
              if (notifEnabled && pct >= 90) sendLocalNotification(
                lang === "en" ? "Budget Warning" : "Peringatan Budget",
                lang === "en" ? `${catName} budget is at ${pct}%` : `Budget ${catName} sudah ${pct}%`
              );
            }, 400);
          }
        }
        return updated;
      });
      showToast("ok:"+L.txAdded);
    }
    setForm({ date: today(), amount: "", category: Object.keys(categories)[0] || "other", description: "", location: "", note: "" });
    setShowForm(false);
  };

  const saveCat = () => {
    if (!catForm.label.trim()) return;
    if (editCatKey) {
      // Preserve labelId if editing a default category (prevent English stuck bug)
      const existing = categories[editCatKey] || {};
      const defaults = DEFAULT_CATEGORIES[editCatKey];
      const labelId = existing.labelId || defaults?.labelId || catForm.label;
      setCategories(prev => ({ ...prev, [editCatKey]: { label: catForm.label, labelId, icon: catForm.icon, color: catForm.color } }));
      setEditCatKey(null);
    } else {
      const key = catForm.label.toLowerCase().replace(/\s+/g, "_") + "_" + Date.now();
      setCategories(prev => ({ ...prev, [key]: { label: catForm.label, icon: catForm.icon, color: catForm.color } }));
    }
    setCatForm({ label: "", icon: "package", color: "#94a3b8" });
  };

  const startEditCat = (key) => {
    setEditCatKey(key);
    setCatForm({ label: categories[key].label, icon: categories[key].icon, color: categories[key].color });
  };

  const deleteCat = (key) => {
    if (Object.keys(categories).length <= 1) return;
    setCategories(prev => { const c = { ...prev }; delete c[key]; return c; });
  };

  const expensePct = income > 0 ? Math.min(100, Math.round((totalExpense / income) * 100)) : 0;

  const handleNotification = async () => {
    if (notifEnabled) {
      setNotifEnabled(false);
      try { localStorage.setItem("gm_notif", "0"); } catch {}
      showToast(L.toastReminderOff);
      return;
    }

    // Check if running as installed PWA on iOS
    const isStandalone = window.navigator.standalone === true ||
      window.matchMedia("(display-mode: standalone)").matches;

    if (!isStandalone && /iPhone|iPad|iPod/.test(navigator.userAgent)) {
      showToast(L.toastAddHome);
      return;
    }

    if (!("Notification" in window)) {
      showToast("err:Browser tidak support notifikasi");
      return;
    }

    const perm = await requestNotificationPermission();
    if (perm === "granted") {
      setNotifEnabled(true);
      try { localStorage.setItem("gm_notif", "1"); } catch {}
      scheduleSmartReminder({ hour: reminderHour, minute: 0, days: reminderDays, smart: reminderSmart, lang, getTransactions: () => transactions });
      await sendLocalNotification("Meowlett", lang === "en" ? "Reminder on! You'll be notified every day at 9 PM." : "Pengingat aktif! Kamu akan diingatkan setiap hari jam 9 malam.");
      showToast(L.toastReminderOn);
    } else if (perm === "denied") {
      showToast("err:Izin notifikasi ditolak");
    } else {
      showToast("err:Notifikasi tidak didukung");
    }
  };

  const todayStr = today();

  return (
    <div className={`theme-transition${themeChanging ? " theme-flash" : ""}`} style={{ minHeight:"100dvh", background:T.bg, "--primary":themePrimary, "--accent":themeAccent }}>

      {/* Statusbar handled by shared fixed header */}

      <style>{STYLES}</style>

      {/* ── ONBOARDING ── */}
      {showOnboarding && (
        <div style={{ position:"fixed", inset:0, background:T.bg, zIndex:10000, display:"flex", flexDirection:"column", boxSizing:"border-box" }}>

          {/* Top area — kosong, tap bisa dismiss keyboard */}
          <div style={{ flex:1, minHeight:0 }} onClick={() => { if(document.activeElement) document.activeElement.blur(); }}/>

          {/* Bottom sheet content */}
          <div style={{ paddingLeft:24, paddingRight:24, paddingTop:28, paddingBottom: kbHeight > 0 ? kbHeight : 32, boxSizing:"border-box", transition:"padding-bottom 0.2s ease" }}>

            {/* Step dots */}
            <div style={{ display:"flex", gap:5, marginBottom:20 }}>
              {[0,1,2,3].map(i => (
                <div key={i} style={{ height:3, borderRadius:99, transition:"all 0.3s", width:i===onboardStep?24:6, background:i<=onboardStep?themeAccent:dark?"rgba(255,255,255,0.12)":"rgba(0,0,0,0.12)" }}/>
              ))}
            </div>

            {/* Step content with fade animation */}
            <div style={{ opacity: onboardVisible ? 1 : 0, transform: onboardVisible ? "translateY(0)" : "translateY(10px)", transition: "opacity 0.18s ease, transform 0.18s ease" }}>
            {/* Step 0 — Welcome */}
            {onboardStep === 0 && (
              <div style={{ width:"100%", maxWidth:400 }}>
                <p style={{ fontSize:11, fontWeight:800, color:themeAccent, letterSpacing:1, margin:"0 0 6px" }}>{lang==="en" ? "STEP 1 / 4" : "LANGKAH 1 / 4"}</p>
                <p style={{ fontSize:28, fontWeight:900, color:T.text, margin:"0 0 4px", lineHeight:1.15 }}>{lang==="en" ? "Welcome to\nMeowlett" : "Selamat datang\ndi Meowlett"}</p>
                <p style={{ fontSize:13, color:T.textSub, margin:"0 0 20px", lineHeight:1.6 }}>{lang==="en"?"Track expenses, monitor your budget, and reach your financial goals.":"Catat pengeluaran, pantau budget,\ndan capai tujuan finansialmu."}</p>
                {/* Language picker */}
                <div style={{ display:"flex", gap:8, marginBottom:20 }}>
                  {[{code:"id", label:"ID  Indonesia"}, {code:"en", label:"EN  English"}].map(opt => {
                    const isActive = lang === opt.code;
                    return (
                      <button key={opt.code} onClick={() => { setLang(opt.code); try { localStorage.setItem("gm_lang", opt.code); } catch {} }}
                        style={{ flex:1, padding:"10px 0", borderRadius:12, border: isActive ? `2px solid ${themeAccent}` : `2px solid ${T.cardBorder}`, background: isActive ? themeAccent+"18" : T.card, cursor:"pointer", fontFamily:"inherit", fontSize:13, fontWeight:700, color: isActive ? themeAccent : T.textSub, transition:"all 0.18s", display:"flex", alignItems:"center", justifyContent:"center", gap:6 }}>
                        {opt.label}
                        {isActive && <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke={themeAccent} strokeWidth="3" strokeLinecap="round"><polyline points="20 6 9 17 4 12"/></svg>}
                      </button>
                    );
                  })}
                </div>
                <button onClick={() => { haptic(); goToStep(1); }} style={{ width:"100%", padding:16, borderRadius:16, border:"none", cursor:"pointer", fontFamily:"inherit", fontSize:15, fontWeight:800, background:`linear-gradient(135deg,${themeAccent},${themePrimary})`, color:"white" }}>
                  {lang==="en" ? "Start Setup →" : "Mulai Setup →"}
                </button>
              </div>
            )}

            {/* Step 1 — Nama */}
            {onboardStep === 1 && (
              <div style={{ width:"100%", maxWidth:400 }}>
                <p style={{ fontSize:11, fontWeight:800, color:themeAccent, letterSpacing:1, margin:"0 0 6px" }}>{lang==="en" ? "STEP 2 / 4" : "LANGKAH 2 / 4"}</p>
                <p style={{ fontSize:26, fontWeight:900, color:T.text, margin:"0 0 4px", lineHeight:1.15 }}>{lang==="en" ? "What's your\nname?" : "Siapa\nnamamu?"}</p>
                <p style={{ fontSize:13, color:T.textSub, margin:"0 0 16px" }}>{lang==="en" ? "So greetings feel more personal." : "Biar sapaan lebih personal."}</p>
                <input value={onboardName} onChange={e => setOnboardName(e.target.value)}
                  placeholder={lang==="en" ? "e.g. Virgie..." : "Contoh: Virgie..."} autoFocus
                  onFocus={() => { setTimeout(() => { if(window.visualViewport){ const kb=window.innerHeight-window.visualViewport.height-window.visualViewport.offsetTop; setKbHeight(kb>50?Math.round(kb):0); }},150); }}
                  style={{ width:"100%", background:T.card, border:`2px solid ${onboardName?themeAccent:T.cardBorder}`, borderRadius:14, padding:"14px 18px", color:T.text, fontSize:16, fontFamily:"inherit", outline:"none", marginBottom:12, transition:"border 0.2s", boxSizing:"border-box" }}/>
                <button onClick={() => { haptic(); goToStep(2); }} style={{ width:"100%", padding:15, borderRadius:14, border:"none", cursor:"pointer", fontFamily:"inherit", fontSize:14, fontWeight:800, background:`linear-gradient(135deg,${themeAccent},${themePrimary})`, color:"white", marginBottom:8 }}>
                  {lang==="en" ? "Next →" : "Lanjut →"}
                </button>
                <button onClick={() => { haptic("light"); goToStep(2); }} style={{ width:"100%", padding:10, borderRadius:12, border:"none", cursor:"pointer", fontFamily:"inherit", fontSize:13, background:"none", color:T.textSub }}>
                  {lang==="en" ? "Skip" : "Lewati"}
                </button>
              </div>
            )}

            {/* Step 2 — Pemasukan */}
            {onboardStep === 2 && (
              <div style={{ width:"100%", maxWidth:400 }}>
                <p style={{ fontSize:11, fontWeight:800, color:themeAccent, letterSpacing:1, margin:"0 0 6px" }}>{lang==="en" ? "STEP 3 / 4" : "LANGKAH 3 / 4"}</p>
                <p style={{ fontSize:26, fontWeight:900, color:T.text, margin:"0 0 4px", lineHeight:1.15 }}>{lang==="en" ? "Monthly\nincome?" : "Pemasukan\nbulan ini?"}</p>
                <p style={{ fontSize:13, color:T.textSub, margin:"0 0 16px" }}>{L.changeAnytime}</p>
                <div style={{ position:"relative", marginBottom:8 }}>
                  <span style={{ position:"absolute", left:16, top:"50%", transform:"translateY(-50%)", fontSize:13, color:T.textSub, fontWeight:700, pointerEvents:"none" }}>Rp</span>
                  <input type="text" inputMode="numeric" value={onboardIncomeDisplay}
                    onChange={e => { const {display,raw}=parseRpInput(e.target.value); setOnboardIncomeDisplay(display); setOnboardIncome(raw||""); }}
                    placeholder="5.000.000" autoFocus
                    onFocus={() => { setTimeout(() => { if(window.visualViewport){ const kb=window.innerHeight-window.visualViewport.height-window.visualViewport.offsetTop; setKbHeight(kb>50?Math.round(kb):0); }},150); }}
                    style={{ width:"100%", background:T.card, border:`2px solid ${onboardIncome?themeAccent:T.cardBorder}`, borderRadius:14, padding:"14px 18px 14px 46px", color:T.text, fontSize:16, fontFamily:"inherit", outline:"none", transition:"border 0.2s", boxSizing:"border-box" }}/>
                </div>
                {onboardIncome && <p style={{ fontSize:12, color:themeAccent, fontWeight:700, marginBottom:8, paddingLeft:2 }}>= {formatRp(Number(onboardIncome))}</p>}
                {!onboardIncome && <div style={{ height:8 }}/>}
                <button onClick={() => { haptic(); goToStep(3); }} style={{ width:"100%", padding:15, borderRadius:14, border:"none", cursor:"pointer", fontFamily:"inherit", fontSize:14, fontWeight:800, background:`linear-gradient(135deg,${themeAccent},${themePrimary})`, color:"white", marginBottom:8 }}>
                  {lang==="en" ? "Next →" : "Lanjut →"}
                </button>
                <button onClick={() => { haptic("light"); goToStep(1); }} style={{ width:"100%", padding:10, borderRadius:12, border:"none", cursor:"pointer", fontFamily:"inherit", fontSize:13, background:"none", color:T.textSub }}>
                  {lang==="en" ? "← Back" : "← Kembali"}
                </button>
              </div>
            )}

            {/* Step 3 — Tema */}
            {onboardStep === 3 && (
              <div style={{ width:"100%", maxWidth:400 }}>
                <p style={{ fontSize:11, fontWeight:800, color:themeAccent, letterSpacing:1, margin:"0 0 6px" }}>{lang==="en" ? "STEP 4 / 4" : "LANGKAH 4 / 4"}</p>
                <p style={{ fontSize:26, fontWeight:900, color:T.text, margin:"0 0 4px", lineHeight:1.15 }}>{lang==="en" ? "Choose your\nlook" : "Pilih\ntampilan"}</p>
                <p style={{ fontSize:13, color:T.textSub, margin:"0 0 14px" }}>{lang==="en" ? "You can change this anytime in Settings." : "Bisa diganti kapan saja di Pengaturan."}</p>

                {/* Dark / Light mode toggle */}
                <p style={{ fontSize:10, fontWeight:800, color:T.textMuted, letterSpacing:1, marginBottom:8 }}>{lang==="en" ? "DISPLAY MODE" : "MODE TAMPILAN"}</p>
                <div style={{ display:"flex", gap:8, marginBottom:18 }}>
                  {[
                    { labelId:"Terang", labelEn:"Light", icon: <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round"><circle cx="12" cy="12" r="4"/><line x1="12" y1="2" x2="12" y2="4"/><line x1="12" y1="20" x2="12" y2="22"/><line x1="4.22" y1="4.22" x2="5.64" y2="5.64"/><line x1="18.36" y1="18.36" x2="19.78" y2="19.78"/><line x1="2" y1="12" x2="4" y2="12"/><line x1="20" y1="12" x2="22" y2="12"/><line x1="4.22" y1="19.78" x2="5.64" y2="18.36"/><line x1="18.36" y1="5.64" x2="19.78" y2="4.22"/></svg>, value: false },
                    { labelId:"Gelap", labelEn:"Dark", icon: <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round"><path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/></svg>, value: true },
                  ].map(opt => {
                    const isActive = dark === opt.value;
                    return (
                      <button key={String(opt.value)} onClick={() => {
                        setDarkOverride(opt.value);
                        setFollowSystem(false);
                        try { localStorage.setItem("gm_dark_override", String(opt.value)); localStorage.setItem("gm_follow_system", "0"); } catch {}
                      }} style={{ flex:1, display:"flex", alignItems:"center", justifyContent:"center", gap:7, padding:"11px 0", borderRadius:12, border: isActive ? `2px solid ${themeAccent}` : `2px solid ${T.cardBorder}`, background: isActive ? themeAccent+"18" : T.card, cursor:"pointer", fontFamily:"inherit", fontSize:13, fontWeight:700, color: isActive ? themeAccent : T.textSub, transition:"all 0.18s" }}>
                        <span style={{ color: isActive ? themeAccent : T.textSub }}>{opt.icon}</span>
                        {lang==="en" ? opt.labelEn : opt.labelId}
                        {isActive && <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke={themeAccent} strokeWidth="3" strokeLinecap="round"><polyline points="20 6 9 17 4 12"/></svg>}
                      </button>
                    );
                  })}
                </div>

                {/* Color presets */}
                <p style={{ fontSize:10, fontWeight:800, color:T.textMuted, letterSpacing:1, marginBottom:8 }}>{lang==="en" ? "COLOR THEME" : "TEMA WARNA"}</p>
                <div style={{ display:"flex", gap:12, marginBottom:12, flexWrap:"wrap" }}>
                  {THEME_PRESETS.filter(p => p.id !== "custom").map(preset => (
                    <button key={preset.id} onClick={() => { setThemePresetId(preset.id); try { localStorage.setItem("gm_theme_preset", preset.id); } catch {} }}
                      style={{ width:44, height:44, borderRadius:"50%", border: themePresetId===preset.id ? `3px solid ${preset.accent}` : "3px solid transparent", background:preset.primary, cursor:"pointer", padding:0, boxShadow: themePresetId===preset.id ? `0 0 0 2px ${preset.accent}55` : "none", transition:"all 0.2s", outline:"none" }}>
                      {themePresetId===preset.id && <div style={{ width:"100%", height:"100%", borderRadius:"50%", display:"flex", alignItems:"center", justifyContent:"center" }}>
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke={preset.accent} strokeWidth="3" strokeLinecap="round"><polyline points="20 6 9 17 4 12"/></svg>
                      </div>}
                    </button>
                  ))}
                  {/* Custom color dot */}
                  <label style={{ position:"relative", width:44, height:44, cursor:"pointer" }}>
                    <div style={{ width:44, height:44, borderRadius:"50%", border: themePresetId==="custom" ? `3px solid ${customAccent}` : `3px solid transparent`, background: themePresetId==="custom" ? customPrimary : "#888", display:"flex", alignItems:"center", justifyContent:"center", boxShadow: themePresetId==="custom" ? `0 0 0 2px ${customAccent}55` : "none", transition:"all 0.2s" }}>
                      {themePresetId==="custom"
                        ? <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke={customAccent} strokeWidth="3" strokeLinecap="round"><polyline points="20 6 9 17 4 12"/></svg>
                        : <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><circle cx="13.5" cy="6.5" r=".5" fill="white"/><circle cx="17.5" cy="10.5" r=".5" fill="white"/><circle cx="8.5" cy="7.5" r=".5" fill="white"/><circle cx="6.5" cy="12.5" r=".5" fill="white"/><path d="M12 2C6.5 2 2 6.5 2 12s4.5 10 10 10c.926 0 1.648-.746 1.648-1.688 0-.437-.18-.835-.437-1.125-.29-.289-.438-.652-.438-1.125a1.64 1.64 0 0 1 1.668-1.668h1.996c3.051 0 5.555-2.503 5.555-5.554C21.965 6.012 17.461 2 12 2z"/></svg>
                      }
                    </div>
                    <input type="color" value={customPrimary} onChange={e => { setCustomPrimary(e.target.value); setThemePresetId("custom"); try { localStorage.setItem("gm_custom_primary", e.target.value); localStorage.setItem("gm_theme_preset", "custom"); } catch {} }} style={{ position:"absolute", inset:0, width:"100%", height:"100%", opacity:0, cursor:"pointer" }}/>
                  </label>
                </div>

                {/* Custom color pickers — only show when custom selected */}
                {themePresetId === "custom" && (
                  <div style={{ display:"flex", gap:8, marginBottom:14, padding:"12px 14px", borderRadius:14, background:T.card, border:`1.5px solid ${T.cardBorder}` }}>
                    <div style={{ flex:1 }}>
                      <p style={{ fontSize:10, fontWeight:800, color:T.textMuted, letterSpacing:1, marginBottom:6 }}>{lang==="en" ? "PRIMARY" : "WARNA UTAMA"}</p>
                      <label style={{ display:"flex", alignItems:"center", gap:8, cursor:"pointer" }}>
                        <div style={{ width:32, height:32, borderRadius:8, background:customPrimary, border:`2px solid ${T.cardBorder}`, flexShrink:0, overflow:"hidden", position:"relative" }}>
                          <input type="color" value={customPrimary} onChange={e => { setCustomPrimary(e.target.value); try { localStorage.setItem("gm_custom_primary", e.target.value); } catch {} }} style={{ position:"absolute", inset:0, width:"100%", height:"100%", opacity:0, cursor:"pointer", border:"none", padding:0 }}/>
                        </div>
                        <span style={{ fontSize:12, color:T.textSub, fontWeight:600 }}>{customPrimary}</span>
                      </label>
                    </div>
                    <div style={{ flex:1 }}>
                      <p style={{ fontSize:10, fontWeight:800, color:T.textMuted, letterSpacing:1, marginBottom:6 }}>{lang==="en" ? "ACCENT" : "WARNA AKSEN"}</p>
                      <label style={{ display:"flex", alignItems:"center", gap:8, cursor:"pointer" }}>
                        <div style={{ width:32, height:32, borderRadius:8, background:customAccent, border:`2px solid ${T.cardBorder}`, flexShrink:0, overflow:"hidden", position:"relative" }}>
                          <input type="color" value={customAccent} onChange={e => { setCustomAccent(e.target.value); try { localStorage.setItem("gm_custom_accent", e.target.value); } catch {} }} style={{ position:"absolute", inset:0, width:"100%", height:"100%", opacity:0, cursor:"pointer", border:"none", padding:0 }}/>
                        </div>
                        <span style={{ fontSize:12, color:T.textSub, fontWeight:600 }}>{customAccent}</span>
                      </label>
                    </div>
                  </div>
                )}

                <button onClick={() => { haptic("success"); finishOnboarding(); }} style={{ width:"100%", padding:15, borderRadius:14, border:"none", cursor:"pointer", fontFamily:"inherit", fontSize:14, fontWeight:800, background:`linear-gradient(135deg,${themeAccent},${themePrimary})`, color:"white", marginBottom:8, display:"flex", alignItems:"center", justifyContent:"center", gap:8 }}>
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.5" strokeLinecap="round"><polyline points="20 6 9 17 4 12"/></svg>
                  {lang==="en" ? "Done, Let's Go!" : "Selesai, Mulai!"}
                </button>
                <button onClick={() => { haptic("light"); goToStep(2); }} style={{ width:"100%", padding:10, borderRadius:12, border:"none", cursor:"pointer", fontFamily:"inherit", fontSize:13, background:"none", color:T.textSub }}>
                  {lang==="en" ? "← Back" : "← Kembali"}
                </button>
              </div>
            )}

            </div>{/* end step fade wrapper */}
          </div>
        </div>
      )}

      {/* Dark mode ripple overlay */}
      {darkRipple && (
        <div style={{
          position:"fixed", zIndex:9998, pointerEvents:"none",
          background: darkRipple.toDark ? "#0a0a0a" : lighten(themeAccent, 0.85),
          borderRadius:"50%",
          width: Math.hypot(window.innerWidth, window.innerHeight) * 2.2,
          height: Math.hypot(window.innerWidth, window.innerHeight) * 2.2,
          left: darkRipple.x - Math.hypot(window.innerWidth, window.innerHeight) * 1.1,
          top:  darkRipple.y - Math.hypot(window.innerWidth, window.innerHeight) * 1.1,
          transform:"scale(0)",
          animation:"dark-ripple-expand 0.55s cubic-bezier(0.4,0,0.2,1) forwards",
        }}/>
      )}
      <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800;900&display=swap" rel="stylesheet" />

      {/* Offline bar */}
      {!isOnline && (
        <div style={{ position:"fixed",top:0,left:0,right:0,zIndex:9999,background:"#ef4444",color:"white",padding:"8px 16px",display:"flex",alignItems:"center",justifyContent:"center",gap:8,fontSize:13,fontWeight:700 }}>
          <WifiOff size={14} color="white" strokeWidth={2.5}/> Tidak ada koneksi internet
        </div>
      )}

      {/* Install banner */}
      {showInstallBanner && (
        <div style={{ position:"fixed",bottom:"72px",left:14,right:14,zIndex:500,background:themePrimary,borderRadius:20,padding:"14px 16px",display:"flex",alignItems:"center",gap:12,boxShadow:`0 8px 32px ${themePrimary}88` }}>
          <Download size={28} color={T.primaryText} strokeWidth={1.5}/>
          <div style={{ flex:1 }}>
            <p style={{ fontSize:13,fontWeight:800,color:"white" }}>Pasang ke Home Screen</p>
            <p style={{ fontSize:11,color:"rgba(255,255,255,0.7)" }}>Akses lebih cepat, bisa offline!</p>
          </div>
          <button onClick={() => { haptic(); installPrompt && installPrompt.prompt(); setShowInstallBanner(false); }} style={{ background:"white",color:themePrimary,border:"none",borderRadius:12,padding:"8px 14px",fontSize:12,fontWeight:800,cursor:"pointer" }}>Pasang</button>
          <button onClick={() => setShowInstallBanner(false)} style={{ background:"rgba(255,255,255,0.2)",border:"none",borderRadius:10,padding:8,cursor:"pointer",display:"flex" }}><X size={14} color="white"/></button>
        </div>
      )}

      {/* Offline indicator */}
      {!isOnline && (
        <div style={{ position:"fixed", top:0, left:0, right:0, zIndex:600, background:"#1c1917", padding:"10px 16px", display:"flex", alignItems:"center", gap:10, boxShadow:"0 2px 12px rgba(0,0,0,0.4)" }}>
          <WifiOff size={16} color="#fbbf24" strokeWidth={2}/>
          <div style={{ flex:1 }}>
            <p style={{ fontSize:13, fontWeight:800, color:"#fbbf24", margin:0 }}>{L.offlineTitle}</p>
            <p style={{ fontSize:11, color:"rgba(255,255,255,0.55)", margin:0 }}>{L.offlineDesc}</p>
          </div>
        </div>
      )}

      {/* Calculator modal */}
      {showCalc && (
        <Calculator
          onUse={(val) => { const n = Math.round(val); setForm(f => ({ ...f, amount: n, amountDisplay: n ? Number(n).toLocaleString("id-ID") : "" })); }}
          onClose={() => setShowCalc(false)}
          T={T} themeAccent={themeAccent} themePrimary={themePrimary} dark={dark}
        />
      )}

      {/* Undo delete toast */}
      {/* Custom Confirm Modal */}
      {customConfirm && (
        <div style={{ position:"fixed", inset:0, background:"rgba(0,0,0,0.6)", zIndex:99999, display:"flex", alignItems:"center", justifyContent:"center", padding:"0 32px" }}
          onClick={() => setCustomConfirm(null)}>
          <div style={{ background:T.card, borderRadius:20, padding:"24px 20px", width:"100%", maxWidth:320, boxShadow:"0 16px 48px rgba(0,0,0,0.4)" }}
            onClick={e => e.stopPropagation()}>
            <p style={{ fontSize:15, fontWeight:700, color:T.text, marginBottom:20, lineHeight:1.5 }}>{customConfirm.msg}</p>
            <div style={{ display:"flex", gap:10 }}>
              <button onClick={() => setCustomConfirm(null)}
                style={{ flex:1, padding:"12px", borderRadius:12, border:`1px solid ${T.cardBorder}`, background:T.inp, color:T.textSub, fontSize:14, fontWeight:700, cursor:"pointer", fontFamily:"inherit" }}>
                {L.cancel}
              </button>
              <button onClick={() => { customConfirm.onOk(); setCustomConfirm(null); }}
                style={{ flex:1, padding:"12px", borderRadius:12, border:"none", background:"#ef4444", color:"white", fontSize:14, fontWeight:800, cursor:"pointer", fontFamily:"inherit" }}>
                {L.done||"OK"}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Discard Confirmation Modal */}
      {showDiscardConfirm && (
        <div style={{ position:"fixed", inset:0, background:"rgba(0,0,0,0.65)", zIndex:99999, display:"flex", alignItems:"center", justifyContent:"center", padding:"0 32px" }}
          onClick={() => setShowDiscardConfirm(false)}>
          <div style={{ background:T.card, borderRadius:22, padding:"24px 20px", width:"100%", maxWidth:320, boxShadow:"0 16px 48px rgba(0,0,0,0.4)" }}
            onClick={e => e.stopPropagation()}>
            <div style={{ width:44, height:44, borderRadius:14, background:"rgba(239,68,68,0.12)", border:"1.5px solid rgba(239,68,68,0.25)", display:"flex", alignItems:"center", justifyContent:"center", marginBottom:14 }}>
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#ef4444" strokeWidth="2.2" strokeLinecap="round"><path d="M3 6h18"/><path d="M8 6V4h8v2"/><path d="M19 6l-1 14H6L5 6"/></svg>
            </div>
            <p style={{ fontSize:16, fontWeight:900, color:T.text, marginBottom:6 }}>{L.discardTitle}</p>
            <p style={{ fontSize:13, color:T.textSub, marginBottom:20, lineHeight:1.5 }}>{L.discardDesc}</p>
            <div style={{ display:"flex", gap:10 }}>
              <button onClick={() => setShowDiscardConfirm(false)}
                style={{ flex:1, padding:"12px", borderRadius:12, border:`1.5px solid ${T.cardBorder}`, background:T.inp, color:T.text, fontSize:13, fontWeight:700, cursor:"pointer", fontFamily:"inherit" }}>
                {L.discardCancel}
              </button>
              <button onClick={() => { setShowDiscardConfirm(false); setShowForm(false); setEditItem(null); haptic(); }}
                style={{ flex:1, padding:"12px", borderRadius:12, border:"none", background:"#ef4444", color:"white", fontSize:13, fontWeight:800, cursor:"pointer", fontFamily:"inherit" }}>
                {L.discardConfirm}
              </button>
            </div>
          </div>
        </div>
      )}

      {undoToast && (
        <div style={{ position:"fixed", bottom:"72px", left:"50%", transform:"translateX(-50%)", zIndex:9998, display:"flex", alignItems:"center", gap:10, background: dark ? "#1a0d0d" : "#fff5f5", border:"1px solid rgba(239,68,68,0.35)", borderRadius:20, padding:"10px 12px 10px 16px", boxShadow:"0 8px 32px rgba(0,0,0,0.25)", animation:"toast-slide-up 0.3s cubic-bezier(0.34,1.5,0.64,1) both", maxWidth:320, width:"calc(100vw - 32px)" }}>
          <Trash2 size={15} color="#ef4444" strokeWidth={2.5}/>
          <p style={{ fontSize:13, fontWeight:600, color: dark ? "#fca5a5" : "#b91c1c", flex:1 }}>{L.txDeleted}</p>
          <button onClick={undoDelete} style={{ background:"rgba(239,68,68,0.15)", border:"1px solid rgba(239,68,68,0.4)", borderRadius:12, padding:"6px 14px", color:"#ef4444", fontSize:12, fontWeight:800, cursor:"pointer", fontFamily:"inherit", flexShrink:0 }}>
            {L.txUndo}
          </button>
        </div>
      )}

      {/* Toast */}
      {toast && (() => {
        const [prefix, ...rest] = toast.split(":");
        const msg = rest.join(":");
        const isOk   = prefix === "ok";
        const isDel  = prefix === "del";
        const isErr  = prefix === "err";
        const isInfo = prefix === "info";
        const isWarn = prefix === "warn";
        const isHome = isInfo && (msg.toLowerCase().includes("home screen") || msg.toLowerCase().includes("home screen"));
        const bgColor = isErr ? "#ef4444" : isWarn ? "#f59e0b" : isInfo ? (dark ? darken(themePrimary,0.5) : darken(themePrimary,0.1)) : dark ? darken(themePrimary,0.3) : themePrimary;
        return (
          <div className="toast" style={{ position:"fixed", bottom:"90px", left:"50%", transform:"translateX(-50%)", background:bgColor, color:"white", padding:"10px 18px", borderRadius:40, fontSize:13, fontWeight:700, zIndex:9999, whiteSpace:"nowrap", boxShadow:"0 8px 32px rgba(0,0,0,0.3)", display:"flex", alignItems:"center", gap:7 }}>
            {isOk   && <CheckCircle size={15} color="white" strokeWidth={2.5}/>}
            {isDel  && <Trash2 size={15} color="white" strokeWidth={2.5}/>}
            {isErr  && <AlertCircle size={15} color="white" strokeWidth={2.5}/>}
            {isInfo && !isHome && <AlertTriangle size={15} color="white" strokeWidth={2.5}/>}
            {isHome && <Star size={15} color="white" strokeWidth={2.5}/>}
            {msg || toast}
          </div>
        );
      })()}

      {/* Long Press Context Menu */}

      {/* Income Edit Modal */}
      {editIncome && (
        <div style={{ position:"fixed", inset:0, background:"rgba(0,0,0,0.55)", backdropFilter:"blur(6px)", WebkitBackdropFilter:"blur(6px)", zIndex:900, display:"flex", alignItems:"flex-end", justifyContent:"center", paddingBottom: kbHeight > 0 ? kbHeight : 0, boxSizing:"border-box", transition:"padding-bottom 0.25s ease" }} onClick={() => setEditIncome(false)}>
          <div className="modal-float" style={{ background:T.card, borderRadius:"28px 28px 0 0", width:"100%", boxShadow: dark?"0 24px 80px rgba(0,0,0,0.8)":"0 24px 80px rgba(0,0,0,0.25)", overflowY:"auto", maxHeight:`calc(100svh - env(safe-area-inset-top) - 20px - ${kbHeight}px)`, padding:"24px 20px 28px" }} onClick={e => e.stopPropagation()}>
            <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center", marginBottom:20 }}>
              <div style={{ display:"flex", alignItems:"center", gap:10 }}>
                <div style={{ width:36, height:36, borderRadius:12, background:`${TP}18`, display:"flex", alignItems:"center", justifyContent:"center" }}>
                  <Smile size={17} color={TP} strokeWidth={2.2}/>
                </div>
                <p style={{ fontSize:17, fontWeight:900, color:T.text }}>{L.editIncome}</p>
              </div>
              <button onClick={() => setEditIncome(false)} style={{ ...IBN, padding:4 }}><X size={20} color={T.textSub}/></button>
            </div>
            {/* Tab Tambah / Kurangi */}
            {(() => {
              const isAdd = incomeTab === "tambah";
              return (<>
                <div style={{ display:"flex", background:T.inp, borderRadius:14, padding:4, marginBottom:16 }}>
                  {["tambah","kurangi"].map(tab => (
                    <button key={tab} onMouseDown={e=>e.preventDefault()} onClick={() => setIncomeTab(tab)}
                      style={{ flex:1, padding:"9px 0", borderRadius:11, border:"none", fontFamily:"inherit", fontSize:13, fontWeight:700, cursor:"pointer",
                        background: incomeTab===tab ? (tab==="tambah" ? T.accentText : "#f87171") : "transparent",
                        color: incomeTab===tab ? "white" : T.textSub, transition:"all 0.2s" }}>
                      {tab==="tambah" ? (lang==="en"?"+ Add":"+ Tambah") : (lang==="en"?"− Subtract":"− Kurangi")}
                    </button>
                  ))}
                </div>
                <p style={{ fontSize:11, fontWeight:700, color:T.textSub, marginBottom:6 }}>
                  {isAdd ? (L.currentIncome) : (L.currentIncome)}
                </p>
                <input className="inp" type="text" inputMode="numeric" placeholder="5.000.000" value={tempIncomeDisplay} autoFocus
                  onChange={e => { const {display,raw}=parseRpInput(e.target.value); setTempIncomeDisplay(display); setTempIncome(raw); }}
                  style={{ background:T.inp, border:`1.5px solid ${T.inpBorder}`, color:T.text, marginBottom:10 }}/>
                <p style={{ fontSize:11, fontWeight:700, color:T.textSub, marginBottom:6 }}>
                  {isAdd ? (L.amountAdd) : (L.amountSubtract)}
                </p>
                <input className="inp" type="text" inputMode="numeric" placeholder="0" value={incomeAdjDisplay||""}
                  onChange={e => { const {display,raw}=parseRpInput(e.target.value); setIncomeAdjDisplay(display); setIncomeAdj(raw); }}
                  style={{ background:T.inp, border:`1.5px solid ${T.inpBorder}`, color:T.text, marginBottom:16 }}/>
                <button className="btn-p" style={{ width:"100%", fontFamily:"inherit",
                  background: isAdd ? T.accentText : "#f87171" }}
                  onClick={() => {
                    if (!incomeAdj) { setIncome(Number(tempIncome)||0); setEditIncome(false); showToast("ok:"+L.incomeSaved); return; }
                    const cur = Number(tempIncome)||0;
                    const adj = Number(incomeAdj);
                    const nv = isAdd ? cur+adj : Math.max(0, cur-adj);
                    setIncome(nv); setEditIncome(false);
                    showToast("ok:"+L.incomeSaved);
                  }}>
                  {isAdd ? (L.saveAndAdd) : (L.saveAndSubtract)}
                </button>
              </>);
            })()}
          </div>
        </div>
      )}

      {/* Pull to refresh indicator */}
      {pullY > 0 && (
        <div style={{
          position:"fixed", top:0, left:0, right:0, zIndex:200,
          display:"flex", alignItems:"center", justifyContent:"center",
          paddingTop:`calc(env(safe-area-inset-top) + ${pullY * 0.5}px)`,
          pointerEvents:"none",
        }}>
          <div style={{
            width:36, height:36, borderRadius:50,
            background: dark ? "rgba(30,30,35,0.95)" : "rgba(255,255,255,0.95)",
            backdropFilter:"blur(12px)",
            display:"flex", alignItems:"center", justifyContent:"center",
            boxShadow:"0 4px 20px rgba(0,0,0,0.15)",
          }}>
            {refreshing
              ? <RefreshCw size={16} color={themeAccent} strokeWidth={2.5} style={{ animation:"spin 0.7s linear infinite" }}/>
              : <ArrowDown size={16} color={pullY >= PULL_THRESHOLD ? themeAccent : T.textSub} strokeWidth={2.5} style={{ transform:`rotate(${(pullY/PULL_THRESHOLD)*180}deg)`, transition:"transform 0.1s" }}/>
            }
          </div>
        </div>
      )}
      <div className="fi"
        onTouchStart={(e) => { handleSwipeStart(e); handlePullStart(e); }}
        onTouchMove={handlePullMove}
        onTouchEnd={(e) => { handleSwipeEnd(e); handlePullEnd(); }}
        style={{ width:"100%", minHeight:"100dvh", background:T.bg, position:"relative", paddingBottom:"calc(env(safe-area-inset-bottom) + 90px)",
          transform: pullY > 0 ? `translateY(${Math.min(pullY * 0.25, 18)}px)` : "none",
          transition: pullY === 0 ? "transform 0.3s cubic-bezier(0.25,0.46,0.45,0.94)" : "none",
        }}>

        {/* FIXED HEADER - only on dashboard */}
        {tab === "dashboard" && <div ref={headerRef} style={{
          position:"fixed", top:0, left:0, right:0,
          zIndex:50,
          background: dark ? "rgba(10,10,10,0.65)" : `${T.bg}99`,
          backdropFilter: "blur(20px)", WebkitBackdropFilter: "blur(20px)",
          boxShadow: headerShadow("dashboard"),
          paddingTop:"calc(env(safe-area-inset-top) + 10px)",
          paddingBottom:10, paddingLeft:16, paddingRight:16,
          boxSizing:"border-box",
        }}>
          <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center", width:"100%" }}>
          <div style={{ overflow:"hidden" }}>
            <p style={{
              fontSize:12, fontWeight:600, color:T.textSub, marginBottom:1,
            }}>
              {new Date().getHours() < 12 ? L.morning : new Date().getHours() < 15 ? L.afternoon : new Date().getHours() < 18 ? L.evening : L.night}
            </p>
            <p style={{
              fontWeight:900, color:T.text,
              fontSize: 20,
            }}>{userName || (lang==="en" ? "Set your name" : "Isi namamu")}</p>
          </div>
          <div style={{ display:"flex", alignItems:"center", gap:7 }}>
            <button ref={darkToggleRef} onClick={() => toggleDark(darkToggleRef)}
              style={{ width:34, height:34, borderRadius:50, background:dark?"rgba(255,255,255,0.07)":"rgba(0,0,0,0.05)", border:"none", display:"flex", alignItems:"center", justifyContent:"center", cursor:"pointer" }}>
              {dark ? <Moon size={15} color={themeAccent} strokeWidth={2}/> : <Sun size={15} color={themeAccent} strokeWidth={2}/>}
            </button>
            <button onClick={() => changeTab("settings")}
              style={{ width:34, height:34, borderRadius:50, background:dark?"rgba(255,255,255,0.07)":"rgba(0,0,0,0.05)", border:"none", display:"flex", alignItems:"center", justifyContent:"center", cursor:"pointer", position:"relative" }}>
              <Settings size={15} color={dark ? lighten(themePrimary,0.55) : T.primaryText} strokeWidth={2}/>
              {!notifEnabled && (
                <div style={{ position:"absolute", top:4, right:4, width:7, height:7, borderRadius:"50%", background:"#ef4444", border:`1.5px solid ${T.bg}` }}/>
              )}
            </button>
            <div style={{ position:"relative", flexShrink:0 }}>
              <div style={{ width:38, height:38, borderRadius:50, border:`2.5px solid ${themeAccent}`, display:"flex", alignItems:"center", justifyContent:"center", cursor:"pointer", overflow:"hidden" }}
                onClick={() => profileInputRef.current && profileInputRef.current.click()}>
                <img src={profilePhoto || "/meow.png"} alt="" style={{ width:38, height:38, objectFit:"cover" }}/>
              </div>
              <div style={{ position:"absolute", bottom:-1, right:-1, width:12, height:12, borderRadius:50, background:themeAccent, border:`2px solid ${dark?"#0a0a0a":"#fff"}`, display:"flex", alignItems:"center", justifyContent:"center", pointerEvents:"none" }}>
                <Camera size={5} color="white" strokeWidth={2.5}/>
              </div>
              <input ref={profileInputRef} type="file" accept="image/*" style={{ display:"none" }} onChange={handleProfilePhotoChange}/>
            </div>
          </div>
          </div>
        </div>}

        {tab !== "dashboard" && (
          <div ref={sharedHeaderRef} style={{
            position:"fixed", top:0, left:0, right:0, zIndex:50,
            background: dark ? "rgba(10,10,10,0.65)" : `${T.bg}99`,
            backdropFilter:"blur(20px)", WebkitBackdropFilter:"blur(20px)",
            boxShadow: headerShadow(tab),
            paddingTop:"calc(env(safe-area-inset-top) + 10px)",
            paddingBottom:10, paddingLeft:16, paddingRight:16,
            boxSizing:"border-box",
          }}>
            <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center", width:"100%" }}>
              <div style={{ display:"flex", alignItems:"center", gap:8 }}>
                {tab==="transactions" && <p style={{ fontWeight:900, color:T.text, fontSize:20, margin:0, lineHeight:"1.3" }}>{L.transactions}</p>}
                {tab==="report" && <p style={{ fontWeight:900, color:T.text, fontSize:20, margin:0, lineHeight:"1.3" }}>{L.report}</p>}
                {tab==="date" && <><p style={{ fontWeight:900, color:T.text, fontSize:20, margin:0, lineHeight:"1.3" }}>{L.date}</p><Heart size={18} color="#f9a8d4" strokeWidth={1.5}/></>}
                {tab==="settings" && <p style={{ fontWeight:900, color:T.text, fontSize:20, margin:0 }}>{L.settingsTitle}</p>}
              </div>
              <div style={{ display:"flex", alignItems:"center", gap:7 }}>
                <button ref={darkToggleRef} onClick={() => toggleDark(darkToggleRef)}
                  style={{ width:34, height:34, borderRadius:50, background:dark?"rgba(255,255,255,0.07)":"rgba(0,0,0,0.05)", border:"none", display:"flex", alignItems:"center", justifyContent:"center", cursor:"pointer" }}>
                  {dark ? <Moon size={15} color={themeAccent} strokeWidth={2}/> : <Sun size={15} color={themeAccent} strokeWidth={2}/>}
                </button>
                <button onClick={() => changeTab("settings")}
                  style={{ width:34, height:34, borderRadius:50, background:dark?"rgba(255,255,255,0.07)":"rgba(0,0,0,0.05)", border:"none", display:"flex", alignItems:"center", justifyContent:"center", cursor:"pointer", position:"relative" }}>
                  <Settings size={15} color={dark ? lighten(themePrimary,0.55) : T.primaryText} strokeWidth={2}/>
                  {!notifEnabled && (
                    <div style={{ position:"absolute", top:4, right:4, width:7, height:7, borderRadius:"50%", background:"#ef4444", border:`1.5px solid ${T.bg}`}}/>
                  )}
                </button>
                <div style={{ position:"relative", flexShrink:0 }}>
                  <div style={{ width:38, height:38, borderRadius:50, border:`2.5px solid ${themeAccent}`, display:"flex", alignItems:"center", justifyContent:"center", cursor:"pointer", overflow:"hidden" }}
                    onClick={() => profileInputRef.current && profileInputRef.current.click()}>
                    <img src={profilePhoto || "/meow.png"} alt="" style={{ width:38, height:38, objectFit:"cover" }}/>
                  </div>
                  <div style={{ position:"absolute", bottom:-1, right:-1, width:12, height:12, borderRadius:50, background:themeAccent, border:`2px solid ${dark?"#0a0a0a":"#fff"}`, display:"flex", alignItems:"center", justifyContent:"center", pointerEvents:"none" }}>
                    <Camera size={5} color="white" strokeWidth={2.5}/>
                  </div>
                  <input ref={profileInputRef} type="file" accept="image/*" style={{ display:"none" }} onChange={handleProfilePhotoChange}/>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* ── DASHBOARD ── */}
{/* Edit/Add Goal Modal */}
{editingGoal !== null && (
  <div style={{ position:"fixed", inset:0, background:"rgba(0,0,0,0.55)", backdropFilter:"blur(6px)", WebkitBackdropFilter:"blur(6px)", zIndex:9500, display:"flex", alignItems:"flex-end", justifyContent:"center", paddingBottom: kbHeight > 0 ? kbHeight : 0, boxSizing:"border-box", transition:"padding-bottom 0.25s ease" }} onClick={() => { setEditingGoal(null); }}>
    <div className="modal-float" style={{ background:T.card, borderRadius:"28px 28px 0 0", width:"100%", boxShadow: dark?"0 24px 80px rgba(0,0,0,0.8)":"0 24px 80px rgba(0,0,0,0.25)", overflowY:"auto", maxHeight:`calc(100svh - env(safe-area-inset-top) - 20px - ${kbHeight}px)`, padding:"20px 16px 24px" }} onClick={e => e.stopPropagation()}>
      <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center", marginBottom:12 }}>
        <p style={{ fontSize:15, fontWeight:900, color:T.text }}>{editingGoal === "new" ? L.addTarget : L.editTarget}</p>
        <button onClick={() => { setEditingGoal(null); }} style={{ ...IBN, padding:4 }}><X size={20} color={T.textSub}/></button>
      </div>
      <div style={{ display:"flex", flexDirection:"column", gap:8 }}>
        <div>
          <p style={{ fontSize:10, fontWeight:700, color:T.textSub, marginBottom:3 }}>Nama Target</p>
          <input className="inp" placeholder={L.goalNamePlaceholder} value={goalForm.label} autoFocus
            onChange={e => setGoalForm(f => ({ ...f, label: e.target.value }))}
            style={{ background:T.inp, border:`1.5px solid ${T.inpBorder}`, color:T.text }}/>
        </div>
        <div style={{ display:"flex", gap:8 }}>
          <div style={{ flex:1 }}>
            <p style={{ fontSize:10, fontWeight:700, color:T.textSub, marginBottom:3 }}>Target (Rp)</p>
            <input className="inp" placeholder="5.000.000" type="text" inputMode="numeric" value={goalForm.targetDisplay||""}
              onChange={e => { const {display,raw}=parseRpInput(e.target.value); setGoalForm(f => ({ ...f, target: raw, targetDisplay: display })); }}
              style={{ background:T.inp, border:`1.5px solid ${T.inpBorder}`, color:T.text }}/>
          </div>
          <div style={{ flex:1 }}>
            <p style={{ fontSize:10, fontWeight:700, color:T.textSub, marginBottom:3 }}>Ditabung (Rp)</p>
            <input className="inp" placeholder="0" type="text" inputMode="numeric" value={goalForm.savedDisplay||""}
              onChange={e => { const {display,raw}=parseRpInput(e.target.value); setGoalForm(f => ({ ...f, saved: raw, savedDisplay: display })); }}
              style={{ background:T.inp, border:`1.5px solid ${T.inpBorder}`, color:T.text }}/>
          </div>
        </div>
        <div style={{ display:"flex", gap:8, alignItems:"flex-end" }}>
          <div style={{ flex:1 }}>
            <p style={{ fontSize:10, fontWeight:700, color:T.textSub, marginBottom:3 }}>Icon</p>
            <div style={{ position:"relative" }}>
              <select value={goalForm.icon || "piggy"} onChange={e => setGoalForm(f => ({ ...f, icon: e.target.value }))}
                style={{ width:"100%", padding:"10px 32px 10px 36px", borderRadius:12, border:`1.5px solid ${T.inpBorder}`, background:T.inp, color:T.text, fontSize:13, fontWeight:600, fontFamily:"inherit", appearance:"none", cursor:"pointer" }}>
                {Object.entries(GOAL_ICONS).map(([key, { label }]) => (
                  <option key={key} value={key}>{label}</option>
                ))}
              </select>
              <div style={{ position:"absolute", left:10, top:"50%", transform:"translateY(-50%)", pointerEvents:"none" }}>
                {(() => { const gi = GOAL_ICONS[goalForm.icon||"piggy"]; return gi ? <gi.Icon size={15} color={goalForm.color} strokeWidth={2}/> : null; })()}
              </div>
              <div style={{ position:"absolute", right:10, top:"50%", transform:"translateY(-50%)", pointerEvents:"none" }}>
                <ChevronDown size={14} color={T.textSub}/>
              </div>
            </div>
          </div>
          <div style={{ flex:1 }}>
            <p style={{ fontSize:10, fontWeight:700, color:T.textSub, marginBottom:4 }}>Warna</p>
            <div style={{ display:"flex", gap:6, flexWrap:"wrap" }}>
              {["#60a5fa","#c084fc","#f87171","#4ade80","#fbbf24","#fb923c","#34d399","#e879f9","#38bdf8","#a3e635"].map(c => (
                <div key={c} onClick={() => setGoalForm(f => ({ ...f, color: c }))}
                  style={{ width:20, height:20, borderRadius:"50%", background:c, cursor:"pointer", border: goalForm.color===c ? `3px solid ${T.text}` : "3px solid transparent", boxSizing:"border-box", flexShrink:0 }}/>
              ))}
            </div>
          </div>
        </div>
        <div>
          <p style={{ fontSize:10, fontWeight:700, color:T.textSub, marginBottom:3 }}>Target Tanggal <span style={{ fontWeight:400, fontSize:10 }}>(opsional)</span></p>
          <input className="inp" type="date" value={goalForm.deadline||""}
            onChange={e => setGoalForm(f => ({ ...f, deadline: e.target.value }))}
            style={{ background:T.inp, border:`1.5px solid ${T.inpBorder}`, color:T.text }}/>
        </div>
        <button className="btn-p" style={{ marginTop:4, background: TP, fontFamily:"inherit" }}
          onClick={() => {
            if (!goalForm.label.trim() || !goalForm.target) return;
            if (editingGoal === "new") {
              setSavingsGoals(prev => [...prev, { id: Date.now(), label: goalForm.label, target: Number(goalForm.target), saved: Number(goalForm.saved||0), color: goalForm.color, icon: goalForm.icon, deadline: goalForm.deadline }]);
            } else {
              setSavingsGoals(prev => prev.map(g => g.id === editingGoal ? { ...g, label: goalForm.label, target: Number(goalForm.target), saved: Number(goalForm.saved||0), color: goalForm.color, icon: goalForm.icon, deadline: goalForm.deadline } : g));
            }
            setEditingGoal(null);
            showToast(L.toastGoalSaved);
          }}>
          {L.saveTarget}
        </button>
      </div>
    </div>
  </div>
)}

        {tab === "dashboard" && (
          <Suspense fallback={<div style={{display:"flex",alignItems:"center",justifyContent:"center",height:"60vh"}}><div className="skeleton" style={{width:48,height:48,borderRadius:"50%"}}/></div>}>
            <TabDashboard ctx={ctx}/>
          </Suspense>
        )}

        {/* ── TRANSACTIONS ── */}
        {tab === "transactions" && (
          <Suspense fallback={<div style={{display:"flex",alignItems:"center",justifyContent:"center",height:"60vh"}}><div className="skeleton" style={{width:48,height:48,borderRadius:"50%"}}/></div>}>
            <TabTransactions ctx={ctx}/>
          </Suspense>
        )}

        {/* ── REPORT ── */}
        {tab === "report" && (
          <Suspense fallback={<div style={{display:"flex",alignItems:"center",justifyContent:"center",height:"60vh"}}><div className="skeleton" style={{width:48,height:48,borderRadius:"50%"}}/></div>}>
            <TabReport ctx={ctx}/>
          </Suspense>
        )}

        {/* ── DATE ── */}
        {tab === "date" && (
          <Suspense fallback={<div style={{display:"flex",alignItems:"center",justifyContent:"center",height:"60vh"}}><div className="skeleton" style={{width:48,height:48,borderRadius:"50%"}}/></div>}>
            <TabDate ctx={ctx}/>
          </Suspense>
        )}

        {/* ── SETTINGS TAB ── */}
        {tab === "settings" && (
          <Suspense fallback={<div style={{display:"flex",alignItems:"center",justifyContent:"center",height:"60vh"}}><div className="skeleton" style={{width:48,height:48,borderRadius:"50%"}}/></div>}>
            <TabSettings ctx={ctx}/>
          </Suspense>
        )}

        {/* ── NOTIFICATION MODAL ── */}
        {showNotifModal && (
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
                      {notifEnabled ? <Bell size={18} color={themeAccent} strokeWidth={2}/> : <BellOff size={18} color={T.textSub} strokeWidth={2}/>}
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
                        <BadgeInfo size={18} color={weeklyNotif ? themeAccent : T.textSub} strokeWidth={2}/>
                      </div>
                      <div>
                        <p style={{ fontSize:14, fontWeight:700, color:T.text }}>{L.weekSummary}</p>
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
                {/* Pengingat Transaksi sub-item */}
                <div onClick={() => { setShowNotifModal(false); setTimeout(()=>setShowReminderModal(true), 200); }}
                  style={{ display:"flex", alignItems:"center", justifyContent:"space-between", padding:"14px 0", borderTop:`1px solid ${T.cardBorder}`, cursor:"pointer", marginTop: weeklyNotif ? 0 : 0 }}>
                  <div style={{ display:"flex", alignItems:"center", gap:12 }}>
                    <div style={{ width:36, height:36, borderRadius:12, background:T.catBg, display:"flex", alignItems:"center", justifyContent:"center" }}>
                      <BellRing size={18} color={themeAccent} strokeWidth={2}/>
                    </div>
                    <div>
                      <p style={{ fontSize:14, fontWeight:700, color:T.text }}>{L.reminderTitle}</p>
                      <p style={{ fontSize:11, color:T.textSub }}>{L.reminderDesc}</p>
                    </div>
                  </div>
                  <ChevronRight size={16} color={T.textSub} strokeWidth={2.5}/>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* ── OVERALL BUDGET MODAL ── */}
        {showOverallBudgetModal && (
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
                      <p style={{ fontSize:15, fontWeight:900, color:"white", marginBottom:1 }}>{lang==="en"?"Monthly Budget":"Anggaran Bulanan"}</p>
                      <p style={{ fontSize:11, color:"rgba(255,255,255,0.65)" }}>{L.totalSpendingCap}</p>
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
                            {formatRp(spent)} {L.spentLabel} · {over ? (lang==="en"?"Over budget!":"Melebihi batas!") : (lang==="en"?"remaining":"sisa")+" "+formatRp(overallBudget-spent)}
                          </p>
                        </div>
                      );
                    })()}
                  </div>
                )}
              </div>

              {/* Body */}
              <div style={{ padding:"20px 20px 24px" }}>
                <p style={{ fontSize:12, fontWeight:700, color:T.textSub, marginBottom:8 }}>{lang==="en"?"SET NEW LIMIT (Rp)":"ATUR BATAS BARU (Rp)"}</p>
                <input
                  className="inp"
                  type="text"
                  inputMode="numeric"
                  autoFocus
                  placeholder={lang==="en"?"3.000.000":"3.000.000"}
                  value={tempOverallBudgetDisplay}
                  onChange={e => { const {display,raw}=parseRpInput(e.target.value); setTempOverallBudgetDisplay(display); setTempOverallBudget(raw); }}
                  onKeyDown={e => { if(e.key==="Enter" && tempOverallBudget > 0){ setOverallBudget(tempOverallBudget); setShowOverallBudgetModal(false); showToast(lang==="en"?"Budget saved!":"Anggaran disimpan!"); }}}
                  style={{ background:T.inp, border:"1.5px solid "+(dark?"rgba(255,255,255,0.1)":T.cardBorder), color:T.text, fontSize:18, fontWeight:700, marginBottom:12 }}
                />
                <div style={{ display:"flex", gap:8 }}>
                  {overallBudget > 0 && (
                    <button onClick={() => { setOverallBudget(0); setTempOverallBudget(0); setShowOverallBudgetModal(false); showToast(L.budgetRemoved); }}
                      style={{ flex:1, padding:"13px 0", borderRadius:14, background:dark?"rgba(239,68,68,0.15)":"#fef2f2", border:"1.5px solid "+dark?"rgba(239,68,68,0.3)":"#fecaca", color:"#f87171", fontSize:13, fontWeight:800, cursor:"pointer" }}>
                      {L.removeLabel}
                    </button>
                  )}
                  <button onClick={() => { if(tempOverallBudget > 0){ setOverallBudget(tempOverallBudget); setShowOverallBudgetModal(false); showToast(lang==="en"?"Budget saved!":"Anggaran disimpan!"); haptic(); }}}
                    style={{ flex:2, padding:"13px 0", borderRadius:14, background: tempOverallBudget > 0 ? themePrimary : (dark?"rgba(255,255,255,0.08)":"#f3f4f6"), color: tempOverallBudget > 0 ? "white" : T.textSub, fontSize:13, fontWeight:800, cursor: tempOverallBudget > 0 ? "pointer":"default", border:"none", transition:"all 0.2s" }}>
                    {L.saveLimitBtn}
                  </button>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* ── ADD TRANSACTION MODAL (float center) ── */}
        {showForm && (
          <div style={{ position:"fixed", inset:0, background:"rgba(0,0,0,0.55)", backdropFilter:"blur(6px)", WebkitBackdropFilter:"blur(6px)", zIndex:300, display:"flex", alignItems:"flex-end", justifyContent:"center", boxSizing:"border-box" }}
            onClick={e => { if (e.target===e.currentTarget) { closeFormSafe(); } }}>
            <div className="modal-float" style={{ background:T.modalBg, borderRadius:"24px 24px 0 0", width:"100%", maxWidth:400, boxShadow: dark ? "0 24px 60px rgba(0,0,0,0.8)" : "0 12px 40px rgba(0,0,0,0.2)", overflow:"hidden", maxHeight: kbHeight > 0 ? `calc(100dvh - ${kbHeight}px - env(safe-area-inset-top))` : "88dvh", display:"flex", flexDirection:"column", marginBottom: kbHeight > 0 ? kbHeight : 0, transition:"margin-bottom 0.25s ease, max-height 0.25s ease" }}>

              {/* Header strip */}
              <div style={{ background:`linear-gradient(135deg,${themePrimary},${darken(themePrimary,0.25)})`, padding:"14px 16px 12px", display:"flex", alignItems:"center", justifyContent:"space-between" }}>
                <p style={{ fontSize:14, fontWeight:900, color:"white" }}>{editItem ? L.editTx : L.newTx}</p>
                <button onClick={() => { closeFormSafe(); }}
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

                {/* Foto Struk */}
                {(() => {
                  const rKey = editItem ? String(editItem.id) : "_new";
                  const receipt = txReceipts[rKey];
                  return receipt ? (
                    <div style={{ position:"relative", borderRadius:14, overflow:"hidden" }}>
                      <img src={receipt} alt="struk" style={{ width:"100%", maxHeight:160, objectFit:"cover", borderRadius:14, display:"block" }}/>
                      <div style={{ position:"absolute", top:8, right:8, display:"flex", gap:6 }}>
                        <button onClick={() => setTxReceipts(p=>{const n={...p};delete n[rKey];return n;})}
                          style={{ width:30, height:30, borderRadius:50, background:"rgba(239,68,68,0.8)", border:"none", cursor:"pointer", display:"flex", alignItems:"center", justifyContent:"center" }}>
                          <Trash2 size={13} color="white" strokeWidth={2}/>
                        </button>
                      </div>
                    </div>
                  ) : (
                    <div style={{ display:"flex", gap:8 }}>
                      {/* Foto dari kamera */}
                      <label style={{ flex:1, display:"flex", alignItems:"center", justifyContent:"center", gap:7, padding:"10px 14px", borderRadius:12, border:`1.5px dashed ${T.cardBorder}`, cursor:"pointer", background:T.catBg }}>
                        <Camera size={14} color={T.textSub} strokeWidth={2}/>
                        <span style={{ fontSize:12, color:T.textSub, fontWeight:600 }}>{L.cameraLabel}</span>
                        <input type="file" accept="image/*" capture="environment" style={{ display:"none" }} onChange={e => {
                          const file = e.target.files?.[0]; if (!file) return;
                          const reader = new FileReader();
                          reader.onload = ev => { setTxReceipts(p=>({...p,[rKey]:ev.target.result})); showToast(L.receiptAdded); };
                          reader.readAsDataURL(file);
                        }}/>
                      </label>
                      {/* Upload dari galeri/file */}
                      <label style={{ flex:1, display:"flex", alignItems:"center", justifyContent:"center", gap:7, padding:"10px 14px", borderRadius:12, border:`1.5px dashed ${T.cardBorder}`, cursor:"pointer", background:T.catBg }}>
                        <ImagePlus size={14} color={T.textSub} strokeWidth={2}/>
                        <span style={{ fontSize:12, color:T.textSub, fontWeight:600 }}>{L.uploadLabel}</span>
                        <input type="file" accept="image/*,application/pdf" style={{ display:"none" }} onChange={e => {
                          const file = e.target.files?.[0]; if (!file) return;
                          const reader = new FileReader();
                          reader.onload = ev => { setTxReceipts(p=>({...p,[rKey]:ev.target.result})); showToast(L.receiptAdded); };
                          reader.readAsDataURL(file);
                        }}/>
                      </label>
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
                    onClick={() => { closeFormSafe(); }}>{L.cancel}</button>
                </div>
              </div>
            </div>
          </div>
        )}

                {/* Cicilan Modal */}
        {/* ── STORY CARD MODAL ── */}
        {showStoryCard && (() => {
          const now4 = new Date();
          const bulanStr = now4.toLocaleDateString(lang==="en"?"en-GB":"id-ID", { month:"long", year:"numeric" });
          const sisa = income - totalExpense;
          const pct = income > 0 ? Math.round(totalExpense/income*100) : 0;
          const topCats = Object.entries(
            transactions.filter(t => getMonth(t.date) === currentMonth)
              .reduce((acc, t) => { acc[t.category] = (acc[t.category]||0) + t.amount; return acc; }, {})
          ).sort((a,b) => b[1]-a[1]).slice(0,3);

          const handleDownload = () => {
            const el = document.getElementById("meowlett-story-card");
            if (!el) return;
            // Use html2canvas via CDN if available, else show hint
            if (window.html2canvas) {
              window.html2canvas(el, { scale:3, backgroundColor:null, useCORS:true }).then(canvas => {
                const a = document.createElement("a");
                a.download = `meowlett-${currentMonth}.png`;
                a.href = canvas.toDataURL("image/png");
                a.click();
                showToast(L.imageDownloaded);
              });
            } else {
              // Fallback: load html2canvas then retry
              const s = document.createElement("script");
              s.src = "https://cdnjs.cloudflare.com/ajax/libs/html2canvas/1.4.1/html2canvas.min.js";
              s.onload = () => {
                window.html2canvas(el, { scale:3, backgroundColor:null, useCORS:true }).then(canvas => {
                  const a = document.createElement("a");
                  a.download = `meowlett-${currentMonth}.png`;
                  a.href = canvas.toDataURL("image/png");
                  a.click();
                  showToast(L.imageDownloaded);
                });
              };
              document.head.appendChild(s);
            }
          };

          return (
            <div style={{ position:"fixed", inset:0, background:"rgba(0,0,0,0.75)", backdropFilter:"blur(8px)", zIndex:400, display:"flex", flexDirection:"column", alignItems:"center", justifyContent:"center", padding:20 }}
              onClick={() => setShowStoryCard(false)}>
              <div onClick={e => e.stopPropagation()} style={{ width:"100%", maxWidth:380 }}>
                {/* Card preview */}
                <div id="meowlett-story-card" style={{
                  background:`linear-gradient(135deg, ${themePrimary}, ${themePrimary}cc, #0d0d0d)`,
                  borderRadius:24, padding:32, color:"white", position:"relative", overflow:"hidden"
                }}>
                  {/* Decorative circles */}
                  <div style={{ position:"absolute", top:-40, right:-40, width:160, height:160, borderRadius:"50%", background:"rgba(255,255,255,0.05)" }}/>
                  <div style={{ position:"absolute", bottom:-20, left:-20, width:100, height:100, borderRadius:"50%", background:"rgba(255,255,255,0.04)" }}/>

                  {/* Header */}
                  <div style={{ display:"flex", justifyContent:"space-between", alignItems:"flex-start", marginBottom:24, position:"relative" }}>
                    <div>
                      <p style={{ fontSize:11, color:"rgba(255,255,255,0.5)", fontWeight:600, letterSpacing:1, marginBottom:3 }}>MEOWLETT</p>
                      <p style={{ fontSize:14, fontWeight:800, color:"white" }}>{bulanStr}</p>
                    </div>
                    <div style={{ background:"rgba(255,255,255,0.1)", borderRadius:12, padding:"6px 12px" }}>
                      <p style={{ fontSize:11, fontWeight:700, color:"rgba(255,255,255,0.8)" }}>{pct}% {L.usedLabel}</p>
                    </div>
                  </div>

                  {/* Main number */}
                  <p style={{ fontSize:11, color:"rgba(255,255,255,0.5)", fontWeight:600, letterSpacing:1, marginBottom:4, position:"relative" }}>{lang==="en"?"TOTAL SPENDING":"TOTAL PENGELUARAN"}</p>
                  <p style={{ fontSize:36, fontWeight:900, color:"white", letterSpacing:-1, marginBottom:4, position:"relative" }}>{formatRp(totalExpense)}</p>
                  <p style={{ fontSize:12, color:"rgba(255,255,255,0.45)", marginBottom:24, position:"relative" }}>{lang==="en"?`of ${formatRp(income)} income`:`dari ${formatRp(income)} pemasukan`}</p>

                  {/* Progress bar */}
                  <div style={{ background:"rgba(255,255,255,0.1)", borderRadius:99, height:6, overflow:"hidden", marginBottom:24, position:"relative" }}>
                    <div style={{ height:"100%", width:`${Math.min(pct,100)}%`, background:"rgba(255,255,255,0.7)", borderRadius:99 }}/>
                  </div>

                  {/* Top categories */}
                  {topCats.length > 0 && (
                    <div style={{ position:"relative" }}>
                      <p style={{ fontSize:10, color:"rgba(255,255,255,0.4)", fontWeight:700, letterSpacing:1, marginBottom:10 }}>{L.topCategories}</p>
                      <div style={{ display:"flex", flexDirection:"column", gap:8 }}>
                        {topCats.map(([key, amt]) => {
                          const cat = getCategory(key);
                          return (
                            <div key={key} style={{ display:"flex", justifyContent:"space-between", alignItems:"center" }}>
                              <div style={{ display:"flex", alignItems:"center", gap:8 }}>
                                <div style={{ width:8, height:8, borderRadius:"50%", background:cat.color, flexShrink:0 }}/>
                                <span style={{ fontSize:12, color:"rgba(255,255,255,0.8)", fontWeight:600 }}>{getCatLabel(cat, lang)}</span>
                              </div>
                              <span style={{ fontSize:12, fontWeight:800, color:"white" }}>{formatRp(amt)}</span>
                            </div>
                          );
                        })}
                      </div>
                    </div>
                  )}

                  {/* Sisa */}
                  <div style={{ marginTop:20, paddingTop:16, borderTop:"1px solid rgba(255,255,255,0.1)", display:"flex", justifyContent:"space-between", alignItems:"center", position:"relative" }}>
                    <span style={{ fontSize:12, color:"rgba(255,255,255,0.5)", fontWeight:600 }}>{L.remaining}</span>
                    <span style={{ fontSize:15, fontWeight:900, color: sisa >= 0 ? "rgba(255,255,255,0.9)" : "#f87171" }}>{sisa >= 0 ? formatRp(sisa) : `-${formatRp(Math.abs(sisa))}`}</span>
                  </div>
                </div>

                {/* Buttons */}
                <div style={{ display:"flex", gap:10, marginTop:14 }}>
                  <button onClick={() => setShowStoryCard(false)}
                    style={{ flex:1, padding:"12px", borderRadius:14, border:"1.5px solid rgba(255,255,255,0.2)", background:"transparent", color:"white", fontSize:13, fontWeight:700, cursor:"pointer" }}>
                    {L.cancel}
                  </button>
                  <button onClick={handleDownload}
                    style={{ flex:2, padding:"12px", borderRadius:14, border:"none", background:`linear-gradient(135deg,${themeAccent},${themePrimary})`, color:"white", fontSize:13, fontWeight:800, cursor:"pointer", display:"flex", alignItems:"center", justifyContent:"center", gap:8 }}>
                    <Download size={15} strokeWidth={2}/> {L.downloadImage}
                  </button>
                </div>
                <p style={{ textAlign:"center", fontSize:11, color:"rgba(255,255,255,0.35)", marginTop:10 }}>
                  {L.tapOutsideClose}
                </p>
              </div>
            </div>
          );
        })()}

        {/* ── DAILY NOTE MODAL ── */}
        {showDailyNote && (
          <div style={{ position:"fixed", inset:0, background:"rgba(0,0,0,0.6)", backdropFilter:"blur(6px)", zIndex:300, display:"flex", alignItems:"flex-end", justifyContent:"center" }}
            onClick={e => { if(e.target===e.currentTarget) setShowDailyNote(false); }}>
            <div className="modal-up" style={{ background:T.card, borderRadius:"24px 24px 0 0", width:"100%", maxWidth:480, padding:"20px 20px 32px" }}>
              <div style={{ width:36, height:4, background:T.cardBorder, borderRadius:99, margin:"0 auto 16px" }}/>
              <div style={{ display:"flex", alignItems:"center", gap:10, marginBottom:16 }}>
                <div style={{ width:36, height:36, borderRadius:12, background:`${themeAccent}22`, display:"flex", alignItems:"center", justifyContent:"center" }}>
                  <Book size={18} color={themeAccent} strokeWidth={2}/>
                </div>
                <div>
                  <p style={{ fontSize:16, fontWeight:900, color:T.text }}>{L.dailyNote}</p>
                  <p style={{ fontSize:11, color:T.textSub }}>{new Date().toLocaleDateString(lang==="en"?"en-GB":"id-ID",{weekday:"long",day:"numeric",month:"long"})}</p>
                </div>
              </div>
              <textarea
                autoFocus
                value={dailyNoteInput}
                onChange={e => setDailyNoteInput(e.target.value)}
                placeholder={lang==="en"?"How was your spending today? Any notes about your finances...":"Bagaimana pengeluaranmu hari ini? Catatan tentang keuanganmu..."}
                style={{ width:"100%", minHeight:100, background:T.inp, border:`1.5px solid ${T.inpBorder}`, borderRadius:14, padding:"12px 14px", fontSize:14, color:T.text, outline:"none", fontFamily:"inherit", resize:"none", boxSizing:"border-box", lineHeight:1.6 }}
              />
              <div style={{ display:"flex", gap:10, marginTop:12 }}>
                <button onClick={() => setShowDailyNote(false)}
                  style={{ flex:1, padding:"12px", borderRadius:14, border:`1.5px solid ${T.cardBorder}`, background:T.catBg, color:T.text, fontSize:13, fontWeight:700, cursor:"pointer", fontFamily:"inherit" }}>
                  {L.cancel}
                </button>
                {dailyNotes[todayStr] && (
                  <button onClick={() => { setDailyNotes(p => { const n={...p}; delete n[todayStr]; return n; }); setShowDailyNote(false); haptic(); }}
                    style={{ padding:"12px 16px", borderRadius:14, border:"1.5px solid #ef444435", background:"#ef444412", color:"#f87171", fontSize:13, fontWeight:700, cursor:"pointer", fontFamily:"inherit" }}>
                    {L.delete}
                  </button>
                )}
                <button onClick={() => {
                  if (dailyNoteInput.trim()) {
                    setDailyNotes(p => ({...p, [todayStr]: dailyNoteInput.trim()}));
                    showToast("ok:"+(lang==="en"?"Note saved":"Catatan disimpan"));
                  }
                  setShowDailyNote(false);
                  haptic("success");
                }}
                  style={{ flex:2, padding:"12px", borderRadius:14, border:"none", background:`linear-gradient(135deg,${themeAccent},${themePrimary})`, color:"white", fontSize:13, fontWeight:800, cursor:"pointer", fontFamily:"inherit" }}>
                  {L.save}
                </button>
              </div>
            </div>
          </div>
        )}

        {showCicilanModal && <CicilanModal show={showCicilanModal} onClose={()=>setShowCicilanModal(false)} cicilan={cicilan} setCicilan={setCicilan} lang={lang} L={L} T={T} themeAccent={themeAccent} themePrimary={themePrimary} formatRp={formatRp} parseRpInput={parseRpInput} haptic={haptic} showToast={showToast}/>}
        {showSplitBills && <SplitBillsModal show={showSplitBills} onClose={()=>setShowSplitBills(false)} splitBills={splitBills} setSplitBills={setSplitBills} T={T} themeAccent={themeAccent} themePrimary={themePrimary} dark={dark} lang={lang} formatRp={formatRp} parseRpInput={parseRpInput} haptic={haptic} showToast={showToast}/>}

        {showReminderModal && <ReminderModal
          show={showReminderModal} onClose={()=>setShowReminderModal(false)}
          lang={lang} L={L} T={T} themeAccent={themeAccent} themePrimary={themePrimary}
          notifEnabled={notifEnabled} handleNotification={handleNotification}
          reminderHour={reminderHour} setReminderHour={setReminderHour}
          reminderDays={reminderDays} setReminderDays={setReminderDays}
          reminderSmart={reminderSmart} setReminderSmart={setReminderSmart}
          scheduleSmartReminder={scheduleSmartReminder} transactions={transactions}
          showToast={showToast}
        />}

        {/* Bottom Nav */}
        {(() => {
          const NI = ({ id, size=22, color }) => {
            const s = { fill:"none", stroke:color, strokeWidth:1.5, strokeLinecap:"round", strokeLinejoin:"round" };
            if (id==="dashboard") return <Cat width={size} height={size} color={color} strokeWidth={1.5}/>;
            if (id==="transactions") return <svg width={size} height={size} viewBox="0 0 24 24" {...s}><line x1="3" y1="6" x2="21" y2="6"/><line x1="3" y1="12" x2="17" y2="12"/><line x1="3" y1="18" x2="13" y2="18"/></svg>;
            if (id==="report") return <svg width={size} height={size} viewBox="0 0 24 24" {...s}><line x1="3" y1="6" x2="21" y2="6"/><line x1="3" y1="12" x2="21" y2="12"/><line x1="3" y1="18" x2="21" y2="18"/></svg>;
            if (id==="date") return <svg width={size} height={size} viewBox="0 0 24 24" {...s}><path d="M12 21C12 21 3 15 3 8.5C3 5.46 5.46 3 8.5 3C10.2 3 11.72 3.88 12 5C12.28 3.88 13.8 3 15.5 3C18.54 3 21 5.46 21 8.5C21 15 12 21 12 21Z"/></svg>;
            return null;
          };
          const navItems = [
            { id:"dashboard",    label: L.dashboard },
            { id:"transactions", label: L.transactions },
            { id:"report",       label: L.report },
            { id:"date",         label: L.date },
          ];
          const iconActive  = dark ? lighten(themeAccent, 0.15) : themePrimary;
          const iconInactive = dark ? "rgba(255,255,255,0.28)" : "rgba(0,0,0,0.28)";
          const NAV_BTN = 54;

          return (
            <div style={{ position:"fixed", bottom:0, left:0, right:0, zIndex:100, display:"flex", flexDirection:"column", alignItems:"center", pointerEvents:"none", visibility: (editingGoal !== null || editIncome || quickAddGoalId !== null) ? "hidden" : "visible" }}>
              {/* Pill row */}
              <div style={{ display:"flex", alignItems:"center", justifyContent:"center", gap:10, paddingTop:4, paddingBottom:20, width:"100%" }}>
              {/* FAB "+" */}
              <button
                onClick={() => { haptic(); setShowForm(true); setEditItem(null); setForm({ date: today(), amount:"", category: Object.keys(categories)[0]||"food", description:"", location:"", note:"" }); }}
                style={{ width:NAV_BTN, height:NAV_BTN, borderRadius:"50%", border:"none", cursor:"pointer", display:"flex", alignItems:"center", justifyContent:"center", flexShrink:0, alignSelf:"center", background:`linear-gradient(135deg,${themeAccent},${themePrimary})`, boxShadow:`0 4px 16px ${themeAccent}55`, padding:0, transition:"transform 0.18s cubic-bezier(0.34,1.56,0.64,1)", pointerEvents:"auto" }}
                onTouchStart={e => e.currentTarget.style.transform="scale(0.88)"}
                onTouchEnd={e => e.currentTarget.style.transform="scale(1)"}
              >
                <svg width={22} height={22} viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth={2.5} strokeLinecap="round"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
              </button>

              {/* Pill navbar */}
              <div style={{ background: dark ? "rgba(10,10,10,0.72)" : "rgba(255,255,255,0.72)", backdropFilter:"blur(20px)", WebkitBackdropFilter:"blur(20px)", borderRadius:28, padding:"5px 5px", display:"flex", alignItems:"center", gap:0, border:`1px solid ${dark ? "rgba(255,255,255,0.1)" : "rgba(0,0,0,0.08)"}`, boxShadow: dark ? "0 4px 24px rgba(0,0,0,0.45)" : "0 2px 20px rgba(0,0,0,0.1)", pointerEvents:"auto" }}>
                {navItems.map(({ id, label }) => {
                  const isActive = tab === id && !showForm;
                  const isDate = id === "date";
                  const datePink = "#be185d";
                  const datePinkBg = dark ? "rgba(190,24,93,0.15)" : "rgba(190,24,93,0.08)";
                  const activeColor = isDate ? datePink : iconActive;
                  const activeBg = isDate ? datePinkBg : (dark ? `${themeAccent}1c` : `${themePrimary}10`);
                  return (
                    <button key={id}
                      onClick={() => { haptic(); setShowForm(false); changeTab(id); }}
                      style={{ width: isActive ? "auto" : NAV_BTN, minWidth: NAV_BTN, height:NAV_BTN, borderRadius:20, border:"none",
                        background: isActive ? activeBg : "transparent",
                        cursor:"pointer", display:"flex", alignItems:"center", justifyContent:"center",
                        gap:6, padding: isActive ? "0 14px" : "0",
                        flexShrink:0, transition:"background 0.2s" }}
                    >
                      <NI id={id} size={isActive ? 18 : 22} color={isActive ? activeColor : (isDate ? "#f9a8d4" : iconInactive)}/>
                      {isActive && (
                        <span style={{ fontSize:12, fontWeight:800, color:activeColor, whiteSpace:"nowrap", overflow:"hidden", animation:"nav-label-in 0.55s cubic-bezier(0.4,0,0.2,1) forwards", letterSpacing:0.1 }}>
                          {label}
                        </span>
                      )}
                    </button>
                  );
                })}
              </div>
              </div>

            </div>
          );
        })()}
      </div>
    </div>
  );
}

