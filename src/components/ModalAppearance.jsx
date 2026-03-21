import { CheckCircle, Monitor, Moon, Palette, Sun, X } from "../icons.jsx";
import { haptic } from "../utils/helpers.js";
import { THEME_PRESETS } from "../constants/index.js";
import { PresetIcon } from "./ui.jsx";

export default function ModalAppearance({ ctx }) {
  const {
    T, dark, lang, L,
    themeAccent, themePrimary, themePresetId,
    setThemePresetId, customPrimary, setCustomPrimary,
    customAccent, setCustomAccent,
    followSystem, setFollowSystem,
    setDarkOverride,
    setShowAppearanceModal,
    triggerThemeChange,
  } = ctx;

  return (
          <div style={{ position:"fixed", inset:0, background:"rgba(0,0,0,0.55)", backdropFilter:"blur(4px)", WebkitBackdropFilter:"blur(4px)", zIndex:300, display:"flex", flexDirection:"column", justifyContent:"flex-end" }}
            onClick={e => { if(e.target===e.currentTarget) setShowAppearanceModal(false); }}>
            <div className="modal-up" style={{ background:T.card, borderRadius:"28px 28px 0 0", paddingBottom:"0px", maxHeight:"90vh", overflowY:"auto" }}>
              {/* Handle */}
              <div style={{ width:36, height:4, background:T.cardBorder, borderRadius:99, margin:"12px auto 0" }}/>
              {/* Header */}
              <div style={{ display:"flex", alignItems:"center", justifyContent:"space-between", padding:"16px 20px 12px" }}>
                <div style={{ display:"flex", alignItems:"center", gap:10 }}>
                  <div style={{ width:36, height:36, borderRadius:12, background:T.catBg, display:"flex", alignItems:"center", justifyContent:"center" }}>
                    {dark ? <Moon size={18} color={themeAccent} strokeWidth={2}/> : <Sun size={18} color={themeAccent} strokeWidth={2}/>}
                  </div>
                  <p style={{ fontSize:17, fontWeight:900, color:T.text }}>{L.appearance}</p>
                </div>
                <button onClick={() => setShowAppearanceModal(false)} style={{ background:T.catBg, border:"none", borderRadius:50, width:32, height:32, cursor:"pointer", display:"flex", alignItems:"center", justifyContent:"center" }}>
                  <X size={16} color={T.textSub} strokeWidth={2.5}/>
                </button>
              </div>
              <div style={{ padding:"0 20px 24px", display:"flex", flexDirection:"column", gap:0 }}>

                {/* Dark mode toggle */}
                <div style={{ display:"flex", alignItems:"center", justifyContent:"space-between", padding:"14px 0", borderBottom:`1px solid ${T.cardBorder}` }}>
                  <div style={{ display:"flex", alignItems:"center", gap:12 }}>
                    <div style={{ width:36, height:36, borderRadius:12, background:T.catBg, display:"flex", alignItems:"center", justifyContent:"center" }}>
                      {dark ? <Moon size={18} color={themeAccent} strokeWidth={2}/> : <Sun size={18} color={themeAccent} strokeWidth={2}/>}
                    </div>
                    <div>
                      <p style={{ fontSize:14, fontWeight:700, color:T.text }}>{L.displayMode}</p>
                      <p style={{ fontSize:11, color:T.textSub }}>{dark ? L.darkActive : L.lightActive}</p>
                    </div>
                  </div>
                  <div ref={settingsToggleRef} onClick={() => { if (!followSystem) toggleDark(settingsToggleRef); }}
                    style={{ width:48, height:28, borderRadius:50, background: dark ? themePrimary : T.catBorder, cursor: followSystem ? "not-allowed" : "pointer", position:"relative", flexShrink:0, opacity: followSystem ? 0.4 : 1, transition:"opacity 0.2s" }}>
                    <div style={{ position:"absolute", top:4, left: dark ? 24 : 4, width:20, height:20, borderRadius:50, background:"white", boxShadow:"0 2px 6px rgba(0,0,0,0.2)", transition:"left 0.2s" }}/>
                  </div>
                </div>

                {/* Ikuti sistem */}
                <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center", padding:"14px 0", borderBottom:`1px solid ${T.cardBorder}` }}>
                  <div style={{ display:"flex", alignItems:"center", gap:12 }}>
                    <div style={{ width:36, height:36, borderRadius:12, background:T.catBg, display:"flex", alignItems:"center", justifyContent:"center" }}>
                      <Monitor size={18} color={T.primaryText} strokeWidth={2}/>
                    </div>
                    <div>
                      <p style={{ fontSize:14, fontWeight:700, color:T.text }}>{L.followSystem}</p>
                      <p style={{ fontSize:11, color:T.textSub }}>{followSystem ? L.followSystemDesc : L.manualMode}</p>
                    </div>
                  </div>
                  <div onClick={() => {
                    haptic();
                    const next = !followSystem;
                    setFollowSystem(next);
                    try { localStorage.setItem("gm_follow_system", next ? "1" : "0"); } catch {}
                    if (!next) { setDarkOverride(dark); try { localStorage.setItem("gm_dark_override", String(dark)); } catch {} }
                    else { setDarkOverride(null); try { localStorage.removeItem("gm_dark_override"); } catch {} }
                  }} style={{ width:48, height:28, borderRadius:50, background: followSystem ? themePrimary : T.catBorder, cursor:"pointer", position:"relative", flexShrink:0, transition:"background 0.2s" }}>
                    <div style={{ position:"absolute", top:4, left: followSystem ? 24 : 4, width:20, height:20, borderRadius:50, background:"white", boxShadow:"0 2px 6px rgba(0,0,0,0.2)", transition:"left 0.2s" }}/>
                  </div>
                </div>

                {/* Bahasa */}
                <div style={{ display:"flex", alignItems:"center", justifyContent:"space-between", padding:"14px 0", borderBottom:`1px solid ${T.cardBorder}` }}>
                  <div style={{ display:"flex", alignItems:"center", gap:12 }}>
                    <div style={{ width:36, height:36, borderRadius:12, background:T.catBg, display:"flex", alignItems:"center", justifyContent:"center" }}>
                      <Monitor size={18} color={T.primaryText} strokeWidth={2}/>
                    </div>
                    <div>
                      <p style={{ fontSize:14, fontWeight:700, color:T.text }}>{L.language}</p>
                      <p style={{ fontSize:11, color:T.textSub }}>{L.languageDesc}</p>
                    </div>
                  </div>
                  <div style={{ display:"flex", gap:6 }}>
                    {[{code:"id", label:"ID"}, {code:"en", label:"EN"}].map(({code, label}) => (
                      <button key={code} onClick={() => { haptic(); setLang(code); }}
                        style={{ padding:"6px 12px", borderRadius:10, border:`1.5px solid ${lang===code ? (TP) : T.cardBorder}`, background: lang===code ? (TP)+"22" : T.catBg, color: lang===code ? (dark ? lighten(themePrimary,0.45) : T.primaryText) : T.textSub, fontSize:12, fontWeight:700, cursor:"pointer", fontFamily:"inherit" }}>
                        {label}
                      </button>
                    ))}
                  </div>
                </div>

                {/* Tema Warna */}
                <div style={{ padding:"14px 0" }}>
                  <div style={{ display:"flex", alignItems:"center", gap:12, marginBottom:14 }}>
                    <div style={{ width:36, height:36, borderRadius:12, background:T.catBg, display:"flex", alignItems:"center", justifyContent:"center" }}>
                      <Palette size={18} color={T.primaryText} strokeWidth={2}/>
                    </div>
                    <p style={{ fontSize:14, fontWeight:700, color:T.text }}>{L.colorTheme}</p>
                  </div>
                  <div style={{ display:"grid", gridTemplateColumns:"repeat(3,1fr)", gap:8, marginBottom:14 }}>
                    {THEME_PRESETS.filter(p => p.id !== "custom").map(preset => {
                      const isSelected = themePresetId === preset.id;
                      return (
                        <button key={preset.id} onClick={() => { haptic(); triggerThemeChange(() => setThemePresetId(preset.id)); }}
                          style={{ border: isSelected ? `2.5px solid ${preset.accent}` : `1.5px solid ${T.cardBorder}`, borderRadius:14, padding:"10px 6px", cursor:"pointer", background: isSelected ? `${preset.primary}22` : T.catBg, display:"flex", flexDirection:"column", alignItems:"center", gap:5 }}>
                          <div style={{ display:"flex", gap:3 }}>
                            <div style={{ width:14, height:14, borderRadius:4, background:preset.primary }}/>
                            <div style={{ width:14, height:14, borderRadius:4, background:preset.accent }}/>
                          </div>
                          <div style={{ display:"flex", alignItems:"center", gap:4 }}>
                            <PresetIcon name={preset.icon} size={11} color={isSelected ? preset.accent : T.textSub} strokeWidth={2.5}/>
                            <span style={{ fontSize:11, fontWeight:700, color: isSelected ? preset.accent : T.textSub }}>{lang === 'id' ? preset.labelId : preset.label}</span>
                          </div>
                        </button>
                      );
                    })}
                  </div>
                  {/* Custom */}
                  <div style={{ background:T.catBg, borderRadius:14, padding:12, border:`1.5px solid ${T.catBorder}` }}>
                    <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center", marginBottom:10 }}>
                      <div style={{ display:"flex", alignItems:"center", gap:5 }}>
                        <Palette size={12} color={T.primaryText} strokeWidth={2}/>
                        <p style={{ fontSize:12, fontWeight:800, color:T.text }}>Custom</p>
                      </div>
                      <button onClick={() => { haptic(); triggerThemeChange(() => setThemePresetId("custom")); }}
                        style={{ background: themePresetId==="custom" ? themePrimary : T.btnG, color: themePresetId==="custom" ? "white" : T.btnGText, border:"none", borderRadius:8, padding:"5px 10px", cursor:"pointer", fontSize:11, fontWeight:700 }}>
                        {themePresetId==="custom" ? <span style={{ display:"flex", alignItems:"center", gap:4 }}><CheckCircle size={12} strokeWidth={2.5}/> {L.active}</span> : L.use}
                      </button>
                    </div>
                    <div style={{ display:"grid", gridTemplateColumns:"1fr 1fr", gap:10 }}>
                      <div>
                        <p style={{ fontSize:10, fontWeight:700, color:T.textSub, marginBottom:5 }}>{L.primaryLabel}</p>
                        <div style={{ display:"flex", alignItems:"center", gap:6 }}>
                          <div style={{ width:28, height:28, borderRadius:8, background:customPrimary, border:`1.5px solid ${T.cardBorder}`, flexShrink:0 }}/>
                          <input type="color" value={customPrimary} onChange={e => { triggerThemeChange(() => { setCustomPrimary(e.target.value); setThemePresetId("custom"); }); }} style={{ width:"100%", height:28, borderRadius:8, border:`1px solid ${T.inpBorder}`, cursor:"pointer", background:"transparent", padding:2 }}/>
                        </div>
                      </div>
                      <div>
                        <p style={{ fontSize:10, fontWeight:700, color:T.textSub, marginBottom:5 }}>{L.accentLabel}</p>
                        <div style={{ display:"flex", alignItems:"center", gap:6 }}>
                          <div style={{ width:28, height:28, borderRadius:8, background:customAccent, border:`1.5px solid ${T.cardBorder}`, flexShrink:0 }}/>
                          <input type="color" value={customAccent} onChange={e => { triggerThemeChange(() => { setCustomAccent(e.target.value); setThemePresetId("custom"); }); }} style={{ width:"100%", height:28, borderRadius:8, border:`1px solid ${T.inpBorder}`, cursor:"pointer", background:"transparent", padding:2 }}/>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>

              </div>
            </div>
          </div>
  );
}
