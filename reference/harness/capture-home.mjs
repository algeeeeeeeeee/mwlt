import { chromium } from "playwright";
import { readFile, mkdir, writeFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const repositoryRoot = path.resolve(scriptDir, "../..");
const fixturePath = path.join(repositoryRoot, "reference/fixtures/meowlett-demo.json");
const outputDir = process.env.REF_OUTPUT_DIR || path.join(repositoryRoot, "ref");
const baseURL = process.env.REF_BASE_URL || "http://127.0.0.1:4173";
const fixedTime = "2026-11-15T12:00:00+07:00";

const fixture = JSON.parse(await readFile(fixturePath, "utf8"));
if (!Array.isArray(fixture.transactions) || fixture.transactions.length < 10) {
  throw new Error("The R1a fixture must include at least 10 transactions.");
}
if (fixture.income !== 5000000) throw new Error("R1a fixture income must be 5,000,000.");
if (!Array.isArray(fixture.savingsGoals) || fixture.savingsGoals.length !== 1) {
  throw new Error("R1a fixture must include exactly one savings goal.");
}
if (fixture.streak?.count !== 5 || fixture.streak?.lastDate !== "2026-11-15") {
  throw new Error("R1a streak fixture is not the requested five-day snapshot.");
}

const baseStorage = {
  gm_transactions_clean: fixture.transactions,
  gm_income: String(fixture.income),
  gm_savings_goals: fixture.savingsGoals,
  gm_streak: fixture.streak,
  gm_username: fixture.username || "Meowlett Demo",
  gm_lang: "id",
  gm_theme_preset: "rose",
  gm_follow_system: "0",
  gm_onboarded: "1"
};

await mkdir(outputDir, { recursive: true });
const browser = await chromium.launch({ headless: true });
const diagnosticsRuns = [];

try {
  for (const mode of ["light", "dark"]) {
    const context = await browser.newContext({
      viewport: { width: 390, height: 844 },
      deviceScaleFactor: 3,
      isMobile: true,
      hasTouch: true,
      timezoneId: "Asia/Pontianak",
      colorScheme: mode,
      serviceWorkers: "block"
    });

    const page = await context.newPage();
    const pageErrors = [];
    const fontHTTPResponses = [];
    const fontProbePromises = [];
    const probedGstaticURLs = new Set();
    page.on("pageerror", error => pageErrors.push(error.message));
    page.on("response", response => {
      const url = response.url();
      if (/^https:\/\/fonts\.(?:googleapis|gstatic)\.com\//i.test(url)) {
        fontHTTPResponses.push({
          url,
          status: response.status(),
          source: "page-response"
        });
      }
    });

    // Preserve the screenshot's local-font behavior: abort external page font requests,
    // then probe those exact URLs separately and record their HTTP response status.
    await page.route(/^https:\/\/fonts\.(?:googleapis|gstatic)\.com\//i, async route => {
      const requestedURL = route.request().url();
      await route.abort();

      const probe = (async () => {
        try {
          const response = await context.request.get(requestedURL, { timeout: 15000 });
          const statusRecord = {
            url: response.url(),
            requestedURL,
            status: response.status(),
            source: "diagnostic-probe"
          };
          fontHTTPResponses.push(statusRecord);

          if (/^https:\/\/fonts\.googleapis\.com\//i.test(requestedURL) && response.ok()) {
            const css = await response.text();
            const gstaticURLs = new Set(
              [...css.matchAll(/url\((?:["']?)(https:\/\/fonts\.gstatic\.com\/[^)"']+)(?:["']?)\)/gi)]
                .map(match => match[1])
            );
            await Promise.all([...gstaticURLs].map(async fontURL => {
              if (probedGstaticURLs.has(fontURL)) return;
              probedGstaticURLs.add(fontURL);
              try {
                const fontResponse = await context.request.get(fontURL, { timeout: 15000 });
                fontHTTPResponses.push({
                  url: fontResponse.url(),
                  requestedURL: fontURL,
                  status: fontResponse.status(),
                  source: "diagnostic-probe-from-google-css"
                });
                await fontResponse.dispose();
              } catch (error) {
                fontHTTPResponses.push({
                  url: fontURL,
                  requestedURL: fontURL,
                  status: null,
                  source: "diagnostic-probe-from-google-css",
                  error: String(error)
                });
              }
            }));
          }
          await response.dispose();
        } catch (error) {
          fontHTTPResponses.push({
            url: requestedURL,
            requestedURL,
            status: null,
            source: "diagnostic-probe",
            error: String(error)
          });
        }
      })();
      fontProbePromises.push(probe);
    });

    // setFixedTime freezes Date only; application timeout/animation timers keep running.
    await page.clock.setFixedTime(fixedTime);

    const storage = {
      ...baseStorage,
      gm_dark_override: mode === "dark" ? "true" : "false"
    };
    await page.addInitScript(({ storageValues }) => {
      for (const [key, value] of Object.entries(storageValues)) {
        const serialized = typeof value === "string" ? value : JSON.stringify(value);
        window.localStorage.setItem(key, serialized);
      }
    }, { storageValues: storage });

    // Local @font-face is provided by the patched build; block external Google Fonts.
    await page.route(/^https:\/\/fonts\.(?:googleapis|gstatic)\.com\//, route => route.abort());

    const response = await page.goto(baseURL, { waitUntil: "domcontentloaded", timeout: 30000 });
    if (!response?.ok()) throw new Error(`Vite preview returned ${response?.status() ?? "no response"} for ${mode}.`);

    // App.jsx hides its splash after 3s. Wait at least 4s; do not pause the timer queue.
    await page.waitForTimeout(4100);

    const fontState = await page.evaluate(async () => {
      await document.fonts.load('400 16px "Plus Jakarta Sans"');
      await document.fonts.ready;

      const fontFaces = Array.from(document.fonts).map(face => ({
        family: face.family,
        weight: face.weight,
        status: face.status
      }));
      const paragraphs = Array.from(document.querySelectorAll("p"));
      const greetingTexts = new Set([
        "Selamat pagi", "Selamat siang", "Selamat sore", "Selamat malam"
      ]);
      const greeting = paragraphs.find(element => greetingTexts.has(element.textContent.trim()));
      const expenseLabel = paragraphs.find(element =>
        element.textContent.trim() === "Pengeluaran bulan ini"
      );
      const expenseAmount = expenseLabel?.nextElementSibling ?? null;

      const computedTypography = element => {
        if (!element) return { found: false };
        const style = getComputedStyle(element);
        return {
          found: true,
          text: element.textContent.trim(),
          tagName: element.tagName.toLowerCase(),
          fontFamily: style.fontFamily,
          fontWeight: style.fontWeight
        };
      };
      const bodyStyle = getComputedStyle(document.body);

      return {
        ready: document.fonts.check('400 16px "Plus Jakarta Sans"'),
        fontFaces,
        body: {
          fontFamily: bodyStyle.fontFamily,
          fontWeight: bodyStyle.fontWeight
        },
        greeting: computedTypography(greeting),
        expenseAmount: computedTypography(expenseAmount)
      };
    });
    if (!fontState.ready || !fontState.fontFaces.some(face =>
      face.family.replaceAll('"', "") === "Plus Jakarta Sans" && face.status === "loaded"
    )) {
      throw new Error(`Local Plus Jakarta Sans did not load for ${mode}: ${JSON.stringify(fontState)}`);
    }

    await page.getByText("Beranda", { exact: true }).first().waitFor({
      state: "visible",
      timeout: 15000
    });

    const outputPath = path.join(outputDir, `beranda-${mode}.png`);
    await page.screenshot({ path: outputPath, fullPage: true });
    if (pageErrors.length) {
      throw new Error(`Page errors in ${mode}: ${pageErrors.join(" | ")}`);
    }

    // Probe remote font URLs only after the screenshot has been captured so the
    // diagnostics do not change font selection, layout, animation, or screenshot timing.
    await Promise.all(fontProbePromises);
    const modeDiagnostics = {
      mode,
      fontHTTPResponses,
      documentFonts: fontState.fontFaces,
      computedStyles: {
        body: fontState.body,
        greeting: fontState.greeting,
        expenseAmount: fontState.expenseAmount
      }
    };
    diagnosticsRuns.push(modeDiagnostics);
    console.log(`Font diagnostics ${mode}: ${JSON.stringify(modeDiagnostics)}`);
    console.log(`Captured ${outputPath}`);
    await context.close();
  }

  const diagnosticsPath = path.join(outputDir, "font-diagnostics.json");
  await writeFile(diagnosticsPath, JSON.stringify({
    capturedAt: new Date().toISOString(),
    note: "Google Fonts page requests are aborted to preserve local-font screenshots; HTTP statuses are collected using separate diagnostic probes after each screenshot.",
    runs: diagnosticsRuns
  }, null, 2) + "\\n");
  console.log(`Wrote font diagnostics: ${diagnosticsPath}`);
} finally {
  await browser.close();
}
