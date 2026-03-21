import { useState, useRef, useEffect } from "react";

export default function AnimatedNumber({ value, format, style = {}, className = "" }) {
  const [display, setDisplay] = useState(0);
  const prev = useRef(null);
  const raf = useRef(null);

  useEffect(() => {
    const from = prev.current === null ? 0 : prev.current;
    const to = value;
    prev.current = to;
    if (from === to && from !== 0) return;

    const duration = from === 0 ? 900 : 500;
    const start = performance.now();
    // Ease out expo — fast start, slow finish (like money counter)
    const ease = t => t === 1 ? 1 : 1 - Math.pow(2, -10 * t);

    cancelAnimationFrame(raf.current);
    raf.current = requestAnimationFrame(function tick(now) {
      const t = Math.min((now - start) / duration, 1);
      setDisplay(Math.round(from + (to - from) * ease(t)));
      if (t < 1) raf.current = requestAnimationFrame(tick);
      else setDisplay(to);
    });
    return () => cancelAnimationFrame(raf.current);
  }, [value]);

  return <span className={className} style={style}>{format ? format(display) : display}</span>;
}
