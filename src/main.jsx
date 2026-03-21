import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App.jsx'

class ErrorBoundary extends React.Component {
  constructor(props) {
    super(props);
    this.state = { error: null, showDetail: false };
  }
  static getDerivedStateFromError(e) { return { error: e }; }

  render() {
    if (this.state.error) {
      const isDark = window.matchMedia?.('(prefers-color-scheme: dark)').matches;
      const bg     = isDark ? '#0a0a0a' : '#f5f5f5';
      const card   = isDark ? '#1c1c1c' : '#ffffff';
      const text   = isDark ? '#ffffff' : '#111111';
      const sub    = isDark ? 'rgba(255,255,255,0.45)' : 'rgba(0,0,0,0.45)';
      const border = isDark ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.08)';

      return (
        <div style={{ minHeight:'100dvh', background:bg, display:'flex', flexDirection:'column', alignItems:'center', justifyContent:'center', padding:'24px', fontFamily:'-apple-system, BlinkMacSystemFont, sans-serif', boxSizing:'border-box' }}>
          <div style={{ width:'100%', maxWidth:360, background:card, borderRadius:24, padding:'28px 24px', border:`1px solid ${border}`, boxShadow:`0 4px 24px rgba(0,0,0,${isDark?'0.4':'0.08'})` }}>
            {/* Icon */}
            <div style={{ width:56, height:56, borderRadius:18, background:'rgba(239,68,68,0.12)', border:'1.5px solid rgba(239,68,68,0.3)', display:'flex', alignItems:'center', justifyContent:'center', marginBottom:20 }}>
              <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="#ef4444" strokeWidth="2.2" strokeLinecap="round">
                <circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/>
              </svg>
            </div>

            <p style={{ fontSize:20, fontWeight:900, color:text, margin:'0 0 6px' }}>Ups, ada yang error</p>
            <p style={{ fontSize:13, color:sub, margin:'0 0 24px', lineHeight:1.6 }}>
              Sesuatu berjalan tidak semestinya. Coba reload dulu — data kamu aman tersimpan di perangkat.
            </p>

            {/* Primary action */}
            <button onClick={() => window.location.reload()}
              style={{ width:'100%', padding:'13px 0', borderRadius:14, border:'none', background:'linear-gradient(135deg,#ef4444,#dc2626)', color:'white', fontSize:14, fontWeight:800, cursor:'pointer', fontFamily:'inherit', marginBottom:10 }}>
              Reload App
            </button>

            {/* Secondary — clear cache */}
            <button onClick={() => { localStorage.clear(); window.location.reload(); }}
              style={{ width:'100%', padding:'11px 0', borderRadius:12, border:`1.5px solid ${border}`, background:'none', color:sub, fontSize:13, fontWeight:700, cursor:'pointer', fontFamily:'inherit', marginBottom:16 }}>
              Reset & Reload (hapus cache)
            </button>

            {/* Error detail toggle */}
            <button onClick={() => this.setState(s => ({ showDetail: !s.showDetail }))}
              style={{ background:'none', border:'none', color:sub, fontSize:12, cursor:'pointer', padding:0, fontFamily:'inherit' }}>
              {this.state.showDetail ? '▲ Sembunyikan detail' : '▼ Lihat detail error'}
            </button>

            {this.state.showDetail && (
              <pre style={{ marginTop:10, fontSize:10, color:sub, background:isDark?'rgba(255,255,255,0.04)':'rgba(0,0,0,0.04)', borderRadius:10, padding:'10px 12px', overflowX:'auto', lineHeight:1.5, whiteSpace:'pre-wrap', wordBreak:'break-all' }}>
                {this.state.error?.message}
                {'\n\n'}
                {this.state.error?.stack}
              </pre>
            )}
          </div>

          <p style={{ fontSize:11, color:sub, marginTop:20, textAlign:'center' }}>Meowlett — Purr-fect finances</p>
        </div>
      );
    }
    return this.props.children;
  }
}

ReactDOM.createRoot(document.getElementById('root')).render(
  <ErrorBoundary>
    <App />
  </ErrorBoundary>
)
