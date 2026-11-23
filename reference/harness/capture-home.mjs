import { chromium } from "playwright";
import { PNG } from "pngjs";
import { readFile, mkdir, writeFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");
const fixture = JSON.parse(await readFile(path.join(root, "reference/fixtures/meowlett-demo.json"), "utf8"));
const buildDir = process.env.REF_OUTPUT_DIR || path.join(root, "ref");
const liveDir = process.env.REF_LIVE_OUTPUT_DIR || path.join(root, "ref-live");
const diffDir = process.env.REF_DIFF_OUTPUT_DIR || path.join(root, "ref-diff");
const buildURL = process.env.REF_BASE_URL || "http://127.0.0.1:4173";
const liveURL = "https://mwlt.pages.dev";
const fixedTime = "2026-11-15T12:00:00+07:00";
const fontURL = /^https:\/\/fonts\.(?:googleapis|gstatic)\.com\//i;
if (!Array.isArray(fixture.transactions) || fixture.transactions.length < 10 ||
    fixture.income !== 5000000 || !Array.isArray(fixture.savingsGoals) ||
    fixture.savingsGoals.length !== 1 || fixture.streak?.count !== 5 ||
    fixture.streak?.lastDate !== "2026-11-15") throw new Error("R1a fixture validation failed.");
const storageBase = {
  gm_transactions_clean: fixture.transactions, gm_income: String(fixture.income),
  gm_savings_goals: fixture.savingsGoals, gm_streak: fixture.streak,
  gm_username: fixture.username || "Meowlett Demo", gm_lang: "id",
  gm_theme_preset: "rose", gm_follow_system: "0", gm_onboarded: "1"
};
for (const dir of [buildDir, liveDir, diffDir]) await mkdir(dir, { recursive: true });

async function typography(page, captureDOM = false) {
  return page.evaluate(async (includeDOM) => {
    await document.fonts.ready;
    await new Promise(resolve => setTimeout(resolve, 1500));

    const ps = Array.from(document.querySelectorAll("p"));
    const greetings = new Set(["Selamat pagi", "Selamat siang", "Selamat sore", "Selamat malam"]);
    const greeting = ps.find(el => greetings.has(el.textContent.trim()));
    const label = ps.find(el => el.textContent.trim() === "Pengeluaran bulan ini");
    const amount = label?.nextElementSibling || null;

    // The Beranda header is the fixed top-level ancestor containing the greeting.
    let header = greeting;
    while (header && header !== document.body) {
      const style = getComputedStyle(header);
      if (style.position === "fixed" && style.top === "0px" && style.zIndex === "50") break;
      header = header.parentElement;
    }
    if (header === document.body) header = null;

    const faces = Array.from(document.fonts).map(face => ({
      family: face.family, weight: face.weight, status: face.status
    }));
    const styleOf = el => {
      if (!el) return { found: false };
      const s = getComputedStyle(el);
      return { found: true, text: el.textContent.trim(), tagName: el.tagName.toLowerCase(),
        fontFamily: s.fontFamily, fontWeight: s.fontWeight };
    };
    const body = getComputedStyle(document.body);
    const domSnapshot = includeDOM ? (() => {
      const root = document.querySelector("#root");
      if (!root) throw new Error("DOM snapshot requested but #root was not found.");
      const round = value => Math.round(value * 100) / 100;
      const elements = Array.from(root.querySelectorAll("*")).map((el, index) => {
        const rect = el.getBoundingClientRect();
        return {
          index,
          tag: el.tagName.toLowerCase(),
          text: (el.textContent || "").replace(/\s+/g, " ").trim().slice(0, 20),
          top: round(rect.top),
          left: round(rect.left),
          width: round(rect.width),
          height: round(rect.height)
        };
      });
      return {
        elementCount: elements.length,
        outerHTMLLength: root.outerHTML.length,
        elements
      };
    })() : null;
    return {
      headerOffsetHeight: header ? header.offsetHeight : null,
      documentScrollHeight: document.documentElement.scrollHeight,
      faces,
      body: { fontFamily: body.fontFamily, fontWeight: body.fontWeight },
      greeting: styleOf(greeting), expenseAmount: styleOf(amount),
      check900: document.fonts.check('900 16px "Plus Jakarta Sans"'),
      domSnapshot
    };
  }, captureDOM);
}

async function probeLiveMainBundle(context, page) {
  const terms = ["FINANCIAL HEALTH", "gm_recurring_income", "ge-indicator", "Patungan"];
  let result;
  try {
    const scriptURL = await page.evaluate(() => {
      const scripts = Array.from(document.querySelectorAll("script[src]"));
      const main = scripts.find(script => script.type === "module" && /\.m?js(?:[?#]|$)/i.test(script.src)) ||
        scripts.find(script => /\.m?js(?:[?#]|$)/i.test(script.src));
      return main ? main.src : null;
    });
    if (!scriptURL) throw new Error("Main JavaScript bundle URL was not found in script[src].");
    const response = await context.request.get(scriptURL, { timeout: 30000 });
    const status = response.status();
    if (!response.ok()) {
      await response.dispose();
      throw new Error("Main JavaScript bundle returned HTTP " + status + ".");
    }
    const source = await response.text();
    await response.dispose();
    await writeFile(path.join(liveDir, "live-main-bundle.js"), source, "utf8");
    result = {
      downloaded: true,
      url: scriptURL,
      httpStatus: status,
      bytes: Buffer.byteLength(source, "utf8"),
      strings: Object.fromEntries(terms.map(term => [term, source.includes(term)])),
      savedAs: "ref-live/live-main-bundle.js"
    };
  } catch (error) {
    result = { downloaded: false, error: String(error), strings: null };
  }
  await writeFile(path.join(liveDir, "live-main-bundle-check.json"), JSON.stringify(result, null, 2) + "\n");
  console.log("Live main bundle string check: " + JSON.stringify(result));
  return result;
}

async function probeBuildFonts(context, responses, requested) {
  const cssURLs = [...requested].filter(url => url.startsWith("https://fonts.googleapis.com/"));
  for (const url of cssURLs) {
    try {
      const res = await context.request.get(url, { timeout: 20000 });
      responses.push({ url: res.url(), requestedURL: url, status: res.status(), source: "post-capture-probe" });
      if (res.ok()) {
        const css = await res.text();
        const fonts = new Set([...css.matchAll(/url\((?:["']?)(https:\/\/fonts\.gstatic\.com\/[^)"']+)(?:["']?)\)/gi)].map(m => m[1]));
        for (const font of fonts) {
          if (requested.has(font)) continue;
          requested.add(font);
          try {
            const fr = await context.request.get(font, { timeout: 20000 });
            responses.push({ url: fr.url(), requestedURL: font, status: fr.status(), source: "post-capture-probe-from-google-css" });
            await fr.dispose();
          } catch (e) {
            responses.push({ url: font, requestedURL: font, status: null, source: "post-capture-probe-from-google-css", error: String(e) });
          }
        }
      }
      await res.dispose();
    } catch (e) {
      responses.push({ url, requestedURL: url, status: null, source: "post-capture-probe", error: String(e) });
    }
  }
}

async function capture(browser, target, mode) {
  const live = target === "live";
  const outDir = live ? liveDir : buildDir;
  const context = await browser.newContext({
    viewport: { width: 390, height: 844 }, deviceScaleFactor: 3,
    isMobile: true, hasTouch: true, timezoneId: "Asia/Pontianak",
    colorScheme: mode, serviceWorkers: "block"
  });
  const page = await context.newPage();
  const errors = [], fontResponses = [], requestedFonts = new Set();
  page.on("pageerror", e => errors.push(e.message));
  page.on("request", req => { if (fontURL.test(req.url())) requestedFonts.add(req.url()); });
  page.on("response", res => {
    if (fontURL.test(res.url())) fontResponses.push({
      url: res.url(), status: res.status(),
      source: live ? "actual-live-page-response" : "build-page-response"
    });
  });

  if (live) {
    await page.route("**/*", async route => {
      const req = route.request();
      if (!["script", "stylesheet"].includes(req.resourceType())) return route.continue();
      const res = await route.fetch();
      const type = res.headers()["content-type"] || "";
      if (!/(javascript|ecmascript|text\/css)/i.test(type)) return route.fulfill({ response: res });
      const before = await res.text();
      const after = before
        .replace(/env\(\s*safe-area-inset-top(?:\s*,\s*[^)]*)?\s*\)/g, "47px")
        .replace(/env\(\s*safe-area-inset-bottom(?:\s*,\s*[^)]*)?\s*\)/g, "34px");
      if (after !== before) {
        console.log("[live/" + mode + "] patched safe-area in intercepted response: " + req.url());
        const headers = { ...res.headers() };
        delete headers["content-length"]; delete headers["content-encoding"];
        return route.fulfill({ response: res, body: after, headers });
      }
      return route.fulfill({ response: res });
    });
    console.log("[live/" + mode + "] safe-area rewrite enabled in-memory only (top=47px, bottom=34px); live app unchanged.");
  } else {
    await page.route(fontURL, route => route.abort());
  }

  // Freeze Date only; never call clock.install() or pauseAt().
  await page.clock.setFixedTime(fixedTime);
  const storage = { ...storageBase, gm_dark_override: mode === "dark" ? "true" : "false" };
  await page.addInitScript(({ values }) => {
    for (const [key, value] of Object.entries(values)) {
      localStorage.setItem(key, typeof value === "string" ? value : JSON.stringify(value));
    }
  }, { values: storage });
  const url = live ? liveURL : buildURL;
  const response = await page.goto(url, { waitUntil: "domcontentloaded", timeout: 60000 });
  if (!response?.ok()) throw new Error(target + " returned " + (response?.status() ?? "no response") + " for " + mode);
  await page.waitForTimeout(4100);
  await page.getByText("Beranda", { exact: true }).first().waitFor({ state: "visible", timeout: 20000 });
  const fonts = await typography(page, mode === "light");
  const screenshot = path.join(outDir, "beranda-" + mode + ".png");
  await page.screenshot({ path: screenshot, fullPage: true });
  const domSnapshot = fonts.domSnapshot ? { target, mode, ...fonts.domSnapshot } : null;
  if (domSnapshot) {
    const domPath = path.join(outDir, "beranda-" + mode + "-dom.json");
    await writeFile(domPath, JSON.stringify(domSnapshot, null, 2) + "\n");
    console.log("Saved DOM snapshot " + domPath + " (" + domSnapshot.elementCount + " descendants).");
  }
  const bundleStrings = live && mode === "light" ? await probeLiveMainBundle(context, page) : null;
  if (!live) await probeBuildFonts(context, fontResponses, requestedFonts);
  if (errors.length) throw new Error("Page errors " + target + "/" + mode + ": " + errors.join(" | "));
  const diagnostics = {
    target, mode, pageURL: url, googleFontsHTTPResponses: fontResponses,
    headerOffsetHeight: fonts.headerOffsetHeight,
    documentScrollHeight: fonts.documentScrollHeight,
    documentFonts: fonts.faces,
    computedStyles: { body: fonts.body, greeting: fonts.greeting, expenseAmount: fonts.expenseAmount },
    documentFontsCheck900: fonts.check900
  };
  console.log("Font diagnostics " + target + "/" + mode + ": " + JSON.stringify(diagnostics));
  console.log("Captured " + screenshot);
  await context.close();
  return { screenshot, diagnostics, domSnapshot, bundleStrings };
}

function compareDOM(build, live) {
  if (!build || !live) return { verified: false, reason: "One or both target DOM snapshots are missing." };
  const keyOf = element => element.tag + "\u0000" + element.text;
  const a = build.elements, b = live.elements;
  const cols = b.length + 1;
  const dp = Array.from({ length: a.length + 1 }, () => new Uint32Array(cols));
  for (let i = a.length - 1; i >= 0; i--) {
    for (let j = b.length - 1; j >= 0; j--) {
      dp[i][j] = keyOf(a[i]) === keyOf(b[j])
        ? 1 + dp[i + 1][j + 1]
        : Math.max(dp[i + 1][j], dp[i][j + 1]);
    }
  }
  const matched = [];
  let i = 0, j = 0;
  while (i < a.length && j < b.length) {
    if (keyOf(a[i]) === keyOf(b[j])) {
      matched.push({ build: a[i], live: b[j] });
      i++; j++;
    } else if (dp[i + 1][j] >= dp[i][j + 1]) {
      i++;
    } else {
      j++;
    }
  }
  const counts = elements => {
    const map = new Map();
    for (const element of elements) {
      const key = keyOf(element);
      map.set(key, (map.get(key) || 0) + 1);
    }
    return map;
  };
  const buildCounts = counts(a), liveCounts = counts(b);
  const unmatchedByMultiplicity = (elements, otherCounts) => {
    const seen = new Map(), missing = [];
    for (const element of elements) {
      const key = keyOf(element);
      const occurrence = (seen.get(key) || 0) + 1;
      seen.set(key, occurrence);
      if (occurrence > (otherCounts.get(key) || 0)) {
        missing.push({ index: element.index, tag: element.tag, text: element.text });
      }
    }
    return missing;
  };
  const buildOnly = unmatchedByMultiplicity(a, liveCounts);
  const liveOnly = unmatchedByMultiplicity(b, buildCounts);
  const topDifferences = matched
    .filter(pair => Math.abs(pair.build.top - pair.live.top) > 0.5)
    .slice(0, 10)
    .map(pair => ({
      buildIndex: pair.build.index, liveIndex: pair.live.index,
      tag: pair.build.tag, text: pair.build.text,
      buildTop: pair.build.top, liveTop: pair.live.top,
      differencePx: Number((pair.live.top - pair.build.top).toFixed(2))
    }));
  const firstHeightDifference = matched.find(pair => Math.abs(pair.build.height - pair.live.height) > 0.5);
  return {
    identityRule: "Multiset presence uses tag + first 20 normalized text characters; geometry pairs are aligned in DOM order using longest common subsequence.",
    elementTotals: {
      build: { elementCount: build.elementCount, outerHTMLLength: build.outerHTMLLength },
      live: { elementCount: live.elementCount, outerHTMLLength: live.outerHTMLLength }
    },
    matchedInDOMOrder: matched.length,
    topDifferencesFirst10: topDifferences,
    firstHeightDifference: firstHeightDifference ? {
      buildIndex: firstHeightDifference.build.index,
      liveIndex: firstHeightDifference.live.index,
      tag: firstHeightDifference.build.tag,
      text: firstHeightDifference.build.text,
      buildHeight: firstHeightDifference.build.height,
      liveHeight: firstHeightDifference.live.height,
      differencePx: Number((firstHeightDifference.live.height - firstHeightDifference.build.height).toFixed(2))
    } : null,
    presence: {
      anyElementsUniqueToOneTarget: buildOnly.length > 0 || liveOnly.length > 0,
      buildOnlyCount: buildOnly.length,
      liveOnlyCount: liveOnly.length,
      buildOnlyFirst20: buildOnly.slice(0, 20),
      liveOnlyFirst20: liveOnly.slice(0, 20)
    }
  };
}

async function compare(buildPath, livePath, diffPath) {
  const [a, b] = await Promise.all([readFile(buildPath), readFile(livePath)]);
  const build = PNG.sync.read(a), live = PNG.sync.read(b);
  const width = Math.max(build.width, live.width);
  const height = Math.max(build.height, live.height);
  const diff = new PNG({ width, height });
  const rowChanged = new Array(height).fill(false);
  let changed = 0;
  let total = 0;

  // Compare the complete union of both screenshots. Pixels present in only one
  // image are real differences and remain visible as magenta at the diff edge.
  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      const inBuild = x < build.width && y < build.height;
      const inLive = x < live.width && y < live.height;
      const outIndex = (y * width + x) * 4;
      if (!inBuild && !inLive) {
        diff.data[outIndex] = 24;
        diff.data[outIndex + 1] = 24;
        diff.data[outIndex + 2] = 24;
        diff.data[outIndex + 3] = 255;
        continue;
      }

      total++;
      const buildIndex = inBuild ? (y * build.width + x) * 4 : -1;
      const liveIndex = inLive ? (y * live.width + x) * 4 : -1;
      const different = !inBuild || !inLive ||
        build.data[buildIndex] !== live.data[liveIndex] ||
        build.data[buildIndex + 1] !== live.data[liveIndex + 1] ||
        build.data[buildIndex + 2] !== live.data[liveIndex + 2] ||
        build.data[buildIndex + 3] !== live.data[liveIndex + 3];

      if (different) {
        changed++;
        rowChanged[y] = true;
        diff.data[outIndex] = 255;
        diff.data[outIndex + 1] = 0;
        diff.data[outIndex + 2] = 255;
        diff.data[outIndex + 3] = 255;
      } else {
        const gray = Math.round((build.data[buildIndex] + build.data[buildIndex + 1] +
          build.data[buildIndex + 2]) / 3 * 0.35);
        diff.data[outIndex] = gray;
        diff.data[outIndex + 1] = gray;
        diff.data[outIndex + 2] = gray;
        diff.data[outIndex + 3] = 255;
      }
    }
  }

  const bands = [];
  let start = -1;
  for (let y = 0; y <= rowChanged.length; y++) {
    if (y < rowChanged.length && rowChanged[y] && start < 0) start = y;
    if ((y === rowChanged.length || !rowChanged[y]) && start >= 0) {
      bands.push({ yStart: start, yEnd: y - 1, height: y - start });
      start = -1;
    }
  }
  await writeFile(diffPath, PNG.sync.write(diff));
  const pct = total ? changed / total * 100 : 0;
  return {
    width,
    height,
    buildDimensions: { width: build.width, height: build.height },
    liveDimensions: { width: live.width, height: live.height },
    dimensionsMatch: build.width === live.width && build.height === live.height,
    changedPixels: changed,
    totalPixels: total,
    percentDifferent: Number(pct.toFixed(4)),
    changedRowBands: bands,
    thresholdExceeded: pct > 1
  };
}

const browser = await chromium.launch({ headless: true });
const results = [];
try {
  for (const mode of ["light", "dark"]) {
    const build = await capture(browser, "build", mode);
    const live = await capture(browser, "live", mode);
    const diff = path.join(diffDir, "beranda-" + mode + "-diff.png");
    const comparison = await compare(build.screenshot, live.screenshot, diff);
    const domComparison = mode === "light" ? compareDOM(build.domSnapshot, live.domSnapshot) : null;
    results.push({
      mode, build: build.diagnostics, live: live.diagnostics, comparison, diff,
      ...(domComparison ? { domComparison } : {}),
      ...(live.bundleStrings ? { liveMainBundleStringCheck: live.bundleStrings } : {})
    });
    console.log("Pixel comparison " + mode + ": " + JSON.stringify(comparison));
    if (domComparison) console.log("DOM comparison light: " + JSON.stringify(domComparison));
    if (!comparison.dimensionsMatch) {
      console.log("SCREENSHOT DIMENSIONS DIFFER: build " +
        comparison.buildDimensions.width + "x" + comparison.buildDimensions.height +
        ", live " + comparison.liveDimensions.width + "x" + comparison.liveDimensions.height +
        ". Unmatched edge pixels are included in the diff and percentage; continuing capture.");
      console.log("Dimension-related difference rows (inspect magenta edge in diff): " +
        JSON.stringify(comparison.changedRowBands));
    }
    if (comparison.thresholdExceeded) {
      console.log("SNAPSHOT MUNGKIN TIDAK SAMA DENGAN LIVE");
      console.log("Visible difference regions (pixel-row bands; inspect diff image): " + JSON.stringify(comparison.changedRowBands));
    }
  }
  const capturedAt = new Date().toISOString();
  const report = {
    capturedAt, primaryReference: liveURL, fixture: "reference/fixtures/meowlett-demo.json",
    clock: "page.clock.setFixedTime('2026-11-15T12:00:00+07:00') only; clock.install/pauseAt not used",
    context: { timezoneId: "Asia/Pontianak", viewport: { width: 390, height: 844 },
      deviceScaleFactor: 3, isMobile: true, hasTouch: true, serviceWorkers: "block" },
    liveSafeAreaPatch: "Intercepted JS/CSS responses only; top=47px and bottom=34px; deployed app not modified.",
    domComparison: results.find(item => item.domComparison)?.domComparison || null,
    liveMainBundleStringCheck: results.find(item => item.liveMainBundleStringCheck)?.liveMainBundleStringCheck || null,
    results
  };
  await writeFile(path.join(diffDir, "comparison-report.json"), JSON.stringify(report, null, 2) + "\n");
  await writeFile(path.join(buildDir, "font-diagnostics.json"), JSON.stringify({
    capturedAt, target: "build", runs: results.map(r => r.build)
  }, null, 2) + "\n");
  await writeFile(path.join(liveDir, "font-diagnostics.json"), JSON.stringify({
    capturedAt, target: "live", runs: results.map(r => r.live)
  }, null, 2) + "\n");
  console.log("Wrote build/live font diagnostics and pixel comparison report.");
} finally {
  await browser.close();
}
