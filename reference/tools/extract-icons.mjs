#!/usr/bin/env node
import { mkdir, readFile, stat, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const referenceRoot = path.resolve(scriptDir, '..');
const pwaRoot = path.join(referenceRoot, 'pwa');
const appPath = path.join(pwaRoot, 'src', 'App.jsx');
const shimPath = path.join(pwaRoot, 'src', 'icons.jsx');
const constantsPath = path.join(pwaRoot, 'src', 'constants', 'index.js');
const packagePath = path.join(pwaRoot, 'node_modules', 'lucide-react', 'package.json');
const iconsDir = path.join(pwaRoot, 'node_modules', 'lucide-react', 'dist', 'esm', 'icons');
const outputPath = path.join(referenceRoot, 'out', 'icons.json');

const required = [
  { key: 'wallet', name: 'Wallet' },
  { key: 'rocket', name: 'Rocket' },
  { key: 'hand.coins', name: 'HandCoins' },
  { key: 'coins', name: 'Coins' },
  { key: 'flower', name: 'Flower2' },
];

function namedImport(source, specifier) {
  const escaped = specifier.replaceAll('.', '\\.');
  const match = source.match(new RegExp(
    'import\\s*\\{([\\s\\S]*?)\\}\\s*from\\s*["\\x27]' + escaped + '["\\x27]'
  ));
  return match ? { block: match[1], full: match[0] } : null;
}

function specifiers(block) {
  return block.replace(/\/\/[^\n]*/g, '').split(',').map((part) => part.trim()).filter(Boolean).map((part) => {
    const split = part.split(/\s+as\s+/);
    return { imported: split[0].trim(), local: (split[1] || split[0]).trim() };
  });
}

function blockAfter(source, declaration, open, close) {
  const declarationAt = source.indexOf(declaration);
  if (declarationAt < 0) return null;
  const openAt = source.indexOf(open, declarationAt + declaration.length);
  if (openAt < 0) return null;
  let depth = 0;
  let quote = null;
  for (let i = openAt; i < source.length; i += 1) {
    const ch = source[i];
    const next = source[i + 1];
    if (quote) {
      if (ch === '\\') i += 1;
      else if (ch === quote) quote = null;
      continue;
    }
    if (ch === '"' || ch === "'") { quote = ch; continue; }
    if (ch === '/' && next === '/') { const end = source.indexOf('\n', i + 2); i = end < 0 ? source.length : end; continue; }
    if (ch === '/' && next === '*') { const end = source.indexOf('*/', i + 2); i = end < 0 ? source.length : end + 1; continue; }
    if (ch === open) depth += 1;
    if (ch === close && --depth === 0) return source.slice(openAt + 1, i);
  }
  return null;
}

function pairs(source, pattern) {
  return source ? [...source.matchAll(pattern)].map((m) => ({ key: m[1], component: m[2] })) : [];
}

function iconFile(name) {
  const slug = name.replace(/([A-Z]+)([A-Z][a-z])/g, '$1-$2')
    .replace(/([a-z0-9])([A-Z])/g, '$1-$2')
    .replace(/([A-Za-z])([0-9])/g, '$1-$2').toLowerCase();
  return slug + '.js';
}

const [app, shim, constants, packageText] = await Promise.all([
  readFile(appPath, 'utf8'), readFile(shimPath, 'utf8'), readFile(constantsPath, 'utf8'), readFile(packagePath, 'utf8'),
]);
const pkg = JSON.parse(packageText);
const appIconsImport = namedImport(app, './icons.jsx');
const lucideImport = namedImport(shim, 'lucide-react');
if (!appIconsImport || !lucideImport) throw new Error('Required named icon imports were not found.');

const appNames = specifiers(appIconsImport.block).map((item) => item.local);
const moduleNames = specifiers(lucideImport.block);
const localToLucide = new Map(moduleNames.map((item) => [item.local, item.imported]));
const customNames = new Set([...shim.matchAll(/export\s+const\s+([\w$]+)\s*=\s*\(/g)].map((m) => m[1]));
const aliases = new Map([...shim.matchAll(/export\s+const\s+([\w$]+)\s*=\s*([\w$]+)\s*;/g)].map((m) => [m[1], m[2]]));
const fallbacks = new Map([...shim.matchAll(/const\s+([\w$]+)\s*=\s*_[\w$]+\s*\|\|\s*([\w$]+)\s*;/g)].map((m) => [m[1], [m[1], m[2]]]));

const lucideMap = pairs(blockAfter(app, 'const LUCIDE_MAP', '{', '}'), /([\w$]+)\s*:\s*([\w$]+)/g);
const goalIcons = pairs(blockAfter(constants, 'export const GOAL_ICONS', '{', '}'), /([\w$]+)\s*:\s*\{\s*Icon\s*:\s*([\w$]+)/g);
const presetBlock = blockAfter(constants, 'export const PRESET_ICONS', '{', '}') || '';
const presetIcons = [...presetBlock.matchAll(/([A-Za-z_$][\w$]*)/g)].map((m) => m[1]);
const optionBlock = blockAfter(constants, 'export const ICON_OPTIONS', '[', ']') || '';
const iconOptions = [...optionBlock.matchAll(/['"]([^'"]+)['"]/g)].map((m) => m[1]);

const uses = new Map();
function addUse(name, source) {
  if (!uses.has(name)) uses.set(name, new Set());
  uses.get(name).add(source);
}
const appBody = app.replace(appIconsImport.full, '');
for (const name of appNames) if (new RegExp('\\b' + name + '\\b').test(appBody)) addUse(name, 'App.jsx direct reference');
for (const entry of lucideMap) addUse(entry.component, 'LUCIDE_MAP.' + entry.key);
for (const entry of goalIcons) addUse(entry.component, 'GOAL_ICONS.' + entry.key);
for (const name of new Set(presetIcons)) addUse(name, 'PRESET_ICONS.' + name);
for (const key of iconOptions) addUse((lucideMap.find((entry) => entry.key === key) || {}).component || 'Package', 'ICON_OPTIONS.' + key);
for (const entry of required) addUse(entry.name, 'required alias ' + entry.key);

function resolve(name, seen = new Set()) {
  if (seen.has(name)) return { kind: 'unresolved', names: [], reason: 'alias cycle' };
  seen.add(name);
  if (customNames.has(name)) return { kind: 'custom-svg', names: [] };
  if (fallbacks.has(name)) return { kind: 'fallback', names: fallbacks.get(name) };
  if (aliases.has(name)) {
    const target = aliases.get(name);
    return { ...resolve(target, seen), aliasOf: target };
  }
  if (localToLucide.has(name)) return { kind: 'lucide', names: [localToLucide.get(name)] };
  return { kind: 'unresolved', names: [], reason: 'not mapped by icons.jsx' };
}

const iconUses = new Map();
const customSvg = [];
const unresolved = [];
const aliasReport = [];
for (const [local, sourceSet] of uses) {
  const resolution = resolve(local);
  const sources = [...sourceSet].sort();
  if (resolution.kind === 'custom-svg') { customSvg.push({ name: local, sources }); continue; }
  if (resolution.kind === 'unresolved') { unresolved.push({ name: local, sources, reason: resolution.reason }); continue; }
  for (const actualName of resolution.names) {
    if (!iconUses.has(actualName)) iconUses.set(actualName, new Set());
    iconUses.get(actualName).add(sources.join('; ') + ' (' + local + ')');
    if (resolution.aliasOf || resolution.names.length > 1) aliasReport.push({ localName: local, sources, resolvesTo: actualName, via: resolution.aliasOf || 'compatibility fallback candidates' });
  }
}

const iconData = [];
const missing = [];
for (const name of [...iconUses.keys()].sort()) {
  const file = iconFile(name);
  const fullPath = path.join(iconsDir, file);
  try {
    await stat(fullPath);
    const mod = await import(pathToFileURL(fullPath).href);
    if (!Array.isArray(mod.__iconNode)) throw new Error('module has no __iconNode array export');
    iconData.push({ name, file: 'node_modules/lucide-react/dist/esm/icons/' + file, found: true, node: mod.__iconNode, usedAs: [...iconUses.get(name)].sort() });
  } catch (error) {
    const item = { name, file: 'node_modules/lucide-react/dist/esm/icons/' + file, found: false, reason: error.message || String(error), usedAs: [...iconUses.get(name)].sort() };
    missing.push(item);
    iconData.push(item);
  }
}

const requiredReport = required.map(({ key, name }) => {
  const found = iconData.find((item) => item.name === name && item.found);
  return { key, requestedName: name, status: found ? 'found' : 'not-found', file: found ? found.file : null };
});
const report = {
  schemaVersion: 1,
  generatedAt: new Date().toISOString(),
  sourceFiles: ['reference/pwa/src/App.jsx', 'reference/pwa/src/icons.jsx', 'reference/pwa/src/constants/index.js'],
  package: { name: pkg.name, version: pkg.version, packageJson: 'reference/pwa/node_modules/lucide-react/package.json', iconDirectory: 'reference/pwa/node_modules/lucide-react/dist/esm/icons/' },
  inventories: {
    appDirectImports: [...uses.keys()].filter((name) => appNames.includes(name)).sort(),
    lucideMap: lucideMap.map(({ key, component }) => ({ key, component })),
    goalIcons: goalIcons.map(({ key, component }) => ({ key, component })),
    presetIcons: [...new Set(presetIcons)].sort(),
    iconOptions: iconOptions.map((key) => ({ key, component: (lucideMap.find((entry) => entry.key === key) || {}).component || 'Package' })),
  },
  aliases: aliasReport,
  requiredIcons: requiredReport,
  icons: iconData,
  customSvgIcons: customSvg,
  unresolvedNames: unresolved,
  missingNames: missing.map(({ name, file, reason }) => ({ name, file, reason })),
  summary: {
    found: iconData.filter((item) => item.found).length,
    missing: missing.length,
    customSvg: customSvg.length,
    unresolved: unresolved.length,
    requiredFound: requiredReport.filter((item) => item.status === 'found').length,
    requiredTotal: requiredReport.length,
  },
};

await mkdir(path.dirname(outputPath), { recursive: true });
await writeFile(outputPath, JSON.stringify(report, null, 2) + '\n', 'utf8');
console.log('lucide-react installed version: ' + pkg.version);
console.log('Lucide icons found: ' + report.summary.found + '; missing: ' + report.summary.missing);
console.log('Custom SVG icons: ' + report.summary.customSvg + '; unresolved names: ' + report.summary.unresolved);
console.log('Required icons found: ' + report.summary.requiredFound + '/' + report.summary.requiredTotal);
for (const item of requiredReport) console.log('Required ' + item.key + ' (' + item.requestedName + '): ' + item.status);
if (missing.length || unresolved.length) {
  console.log('Missing/unresolved names (also recorded in reference/out/icons.json):');
  for (const item of missing) console.log('- ' + item.name + ' | ' + item.file + ' | ' + item.reason);
  for (const item of unresolved) console.log('- ' + item.name + ' | unresolved | ' + item.reason);
}
console.log('Wrote ' + outputPath);
