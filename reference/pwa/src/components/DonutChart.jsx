import { formatRp } from "../utils/helpers.js";

export default function DonutChart({ data, total, T, lang }) {
  if (!data || data.length === 0) return null;
  const size = 200, cx = 100, cy = 100, outer = 90, inner = 58;
  const TWO_PI = 2 * Math.PI;
  let startAngle = -Math.PI / 2;

  const slices = data.map(d => {
    const pct = total > 0 ? d.value / total : 0;
    const angle = pct * TWO_PI;
    const s = { ...d, startAngle, endAngle: startAngle + angle, pct };
    startAngle += angle + 0.02;
    return s;
  });

  const fullCirclePath = (cx, cy, outer, inner) => {
    const ox1 = cx, oy1 = cy - outer, ox2 = cx, oy2 = cy + outer;
    const ix1 = cx, iy1 = cy + inner, ix2 = cx, iy2 = cy - inner;
    return `M${ox1},${oy1} A${outer},${outer} 0 1,1 ${ox2},${oy2} A${outer},${outer} 0 1,1 ${ox1},${oy1} Z M${ix2},${iy2} A${inner},${inner} 0 1,0 ${ix1},${iy1} A${inner},${inner} 0 1,0 ${ix2},${iy2} Z`;
  };

  const donutPath = (cx, cy, outer, inner, start, end) => {
    if (Math.abs(end - start) >= TWO_PI * 0.999) return fullCirclePath(cx, cy, outer, inner);
    const ox1 = cx + outer * Math.cos(start), oy1 = cy + outer * Math.sin(start);
    const ox2 = cx + outer * Math.cos(end),   oy2 = cy + outer * Math.sin(end);
    const ix1 = cx + inner * Math.cos(end),   iy1 = cy + inner * Math.sin(end);
    const ix2 = cx + inner * Math.cos(start), iy2 = cy + inner * Math.sin(start);
    const large = end - start > Math.PI ? 1 : 0;
    return `M${ox1},${oy1} A${outer},${outer} 0 ${large},1 ${ox2},${oy2} L${ix1},${iy1} A${inner},${inner} 0 ${large},0 ${ix2},${iy2} Z`;
  };

  return (
    <div style={{ display: "flex", alignItems: "center", gap: 16, flexWrap: "wrap", justifyContent: "center" }}>
      <svg width="clamp(130px, 36vw, 170px)" height="clamp(130px, 36vw, 170px)" viewBox={`0 0 ${size} ${size}`} style={{ display: "block", flexShrink: 0 }}>
        {slices.map((s, i) => (
          <path key={i} d={donutPath(cx, cy, outer, inner, s.startAngle, s.endAngle)} fill={s.color} opacity={0.92} />
        ))}
        <text x={cx} y={cy - 10} textAnchor="middle" fontSize={13} fill={T.textSub} fontWeight={600}>{lang === "en" ? "Total" : "Total"}</text>
        <text x={cx} y={cy + 12} textAnchor="middle" fontSize={15} fill={T.text} fontWeight={800}>{formatRp(total)}</text>
      </svg>
      <div style={{ display: "flex", flexDirection: "column", gap: 8, flex: 1, minWidth: 120 }}>
        {slices.map((s, i) => (
          <div key={i} style={{ display: "flex", alignItems: "center", gap: 6 }}>
            <div style={{ width: 9, height: 9, borderRadius: "50%", background: s.color, flexShrink: 0 }} />
            <span style={{ fontSize: 13, color: T.textSub, fontWeight: 600, flex: 1 }}>{s.name}</span>
            <span style={{ fontSize: 13, color: T.text, fontWeight: 800 }}>{(s.pct * 100).toFixed(0)}%</span>
          </div>
        ))}
      </div>
    </div>
  );
}
