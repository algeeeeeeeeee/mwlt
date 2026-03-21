function hexToRgb(hex) {
  return {
    r: parseInt(hex.slice(1, 3), 16),
    g: parseInt(hex.slice(3, 5), 16),
    b: parseInt(hex.slice(5, 7), 16),
  };
}

function toHex(r, g, b) {
  return "#" + [r, g, b].map(x => x.toString(16).padStart(2, "0")).join("");
}

export function darken(hex, ratio) {
  const { r, g, b } = hexToRgb(hex);
  return toHex(
    Math.round(r * (1 - ratio)),
    Math.round(g * (1 - ratio)),
    Math.round(b * (1 - ratio))
  );
}

export function lighten(hex, ratio) {
  const { r, g, b } = hexToRgb(hex);
  return toHex(
    Math.min(255, Math.round(r + (255 - r) * ratio)),
    Math.min(255, Math.round(g + (255 - g) * ratio)),
    Math.min(255, Math.round(b + (255 - b) * ratio))
  );
}

export function getLuminance(hex) {
  const { r, g, b } = hexToRgb(hex);
  return (0.299 * r + 0.587 * g + 0.114 * b) / 255;
}

export function getContrastText(hex) {
  return getLuminance(hex) > 0.45 ? "#000000" : "#ffffff";
}

function ensureReadable(hex, minLum = 0.55) {
  if (getLuminance(hex) >= minLum) return hex;
  let ratio = 0.1, result = hex;
  while (getLuminance(result) < minLum && ratio <= 1) { result = lighten(hex, ratio); ratio += 0.1; }
  return result;
}

function ensureReadableOnLight(hex, maxLum = 0.5) {
  if (getLuminance(hex) <= maxLum) return hex;
  let ratio = 0.1, result = hex;
  while (getLuminance(result) > maxLum && ratio <= 1) { result = darken(hex, ratio); ratio += 0.1; }
  return result;
}

export function buildTheme(primary, accent, dark) {
  const readableAccent = ensureReadable(accent, 0.55);
  const readableAccentOnLight = ensureReadableOnLight(accent, 0.5);
  const readablePrimaryOnLight = ensureReadableOnLight(primary, 0.5);
  if (dark) {
    const bg = "#0a0a0a", card = "#141414", card2 = "#1c1c1c", border = "#272727";
    return {
      bg, card, card2, cardBorder: border, cardShadow: "rgba(0,0,0,0.5)",
      text: "#ffffff", textSub: "#9ca3af", textMuted: "#6b7280",
      inp: "#1a1a1a", inpBorder: "#303030", inpFocus: readableAccent,
      btnG: card2, btnGText: "#e5e7eb", btnGBorder: border, btnGHover: "#242424",
      btnD: "#1f0a0a", btnDText: "#f87171", btnDBorder: "#3d1414",
      btnSm: card2, btnSmText: "#e5e7eb", btnSmBdr: border,
      navBg: "#0a0a0a", navBorder: border,
      navActBg: readableAccent, navActTxt: getContrastText(readableAccent), navTxt: "#555555",
      iconBtn: card2, catBg: card2, catBorder: border, catItem: card, catItemBdr: border,
      modalBg: "#111111", hdrBg: "#0a0a0a",
      accentText: readableAccent, primaryText: readableAccent,
    };
  } else {
    const bg = "#f4f4f4", card = "#ffffff", border = "#e8e8e8";
    return {
      bg, card, card2: "#f9f9f9", cardBorder: border, cardShadow: "rgba(0,0,0,0.06)",
      text: "#111111", textSub: "#6b7280", textMuted: "#9ca3af",
      inp: "#f4f4f4", inpBorder: "#e0e0e0", inpFocus: readableAccentOnLight,
      btnG: "#f4f4f4", btnGText: "#374151", btnGBorder: "#e0e0e0", btnGHover: "#eeeeee",
      btnD: "#fff1f2", btnDText: "#e11d48", btnDBorder: "#fecdd3",
      btnSm: "#f4f4f4", btnSmText: "#374151", btnSmBdr: "#e0e0e0",
      navBg: "#ffffff", navBorder: "#e5e5e5",
      navActBg: primary, navActTxt: getContrastText(primary), navTxt: "#aaaaaa",
      iconBtn: "#f4f4f4", catBg: "#f4f4f4", catBorder: "#e8e8e8",
      catItem: "#f9f9f9", catItemBdr: "#eeeeee",
      accentText: readableAccentOnLight, primaryText: readablePrimaryOnLight,
      modalBg: card, hdrBg: primary,
    };
  }
}
