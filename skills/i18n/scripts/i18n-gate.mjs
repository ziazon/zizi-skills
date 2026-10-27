#!/usr/bin/env node
/**
 * Language-neutral JSON translation completeness gate. Node 22+, built-ins only.
 * Usage: node i18n-gate.mjs --registry registry.json --packs 'locales/{locale}.json'
 *   [--required-keys file] [--dnt file] [--meta file] [--production]
 *   node i18n-gate.mjs --self-test
 * Registry schema:
 * {"source":"en","locales":[{"code":"en","scripts":["Latin"],
 *   "status":"live|beta|hidden|pseudo","reviewedBy":"Reviewer",
 *   "reviewedAt":"YYYY-MM-DD","allowIdentical":["Menu","Hotel"]}]}
 * The source must be registered; scripts are Unicode Script property names (ASCII letters and underscores only).
 * Packs may be flat dotted keys or nested namespaces, independently per file.
 * Objects containing only CLDR categories and an `other` are plural messages:
 * parity compares message keys, not locale-specific plural category keys.
 * Each plural branch compares tokens to the same source branch, or source `other`.
 * Required keys and DNT terms are one per line; # starts a comment.
 * Metadata is {"dotted.key":{"maxLength":40}} (length uses Unicode code points).
 * Token extraction is deliberately heuristic; full per-syntax parsing (including
 * nested ICU expressions and template grammar validation) is out of scope.
 * Unsupported Intl locales warn once; their plural categories are not guessed.
 */
import { readFileSync, readdirSync, statSync, writeFileSync, mkdtempSync, rmSync, mkdirSync, cpSync } from 'node:fs';
import { dirname, basename, join } from 'node:path';
import { tmpdir } from 'node:os';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';
import assert from 'node:assert/strict';

const categories = new Set(['zero', 'one', 'two', 'few', 'many', 'other']);
const object = value => value !== null && typeof value === 'object' && !Array.isArray(value);
const compare = (a, b) => a < b ? -1 : a > b ? 1 : 0;
// Literal escapes are consumed before brace placeholders and are not tokens.
const tokenPattern = /\{'[^']*'\}|\{\{[^{}]*\}\}|%\{[^{}]*\}|\{[^{}]*\}|%%|%(?:\[\d+\]|\d+\$)?[-+#0 ']*(?:\d+|\*)?(?:\.(?:\d+|\*))?[a-zA-Z]|<\/?(?:[A-Za-z][\w:.-]*|\d+)\b[^<>]*>/g;
const isToken = value => !value.startsWith("{'") && value !== '%%';
const tokens = value => (value.match(tokenPattern) || []).filter(isToken).sort(compare);
const stripTokens = value => value.replace(tokenPattern, part => isToken(part) ? '' : part);
function read(file, json = false) {
  try {
    const text = readFileSync(file, 'utf8');
    return json ? JSON.parse(text) : text;
  } catch (error) { throw new Error(`${file}: ${error.message}`); }
}
function lines(file) {
  return file ? read(file).split(/\r?\n/).map(line => line.replace(/#.*/, '').trim()).filter(Boolean) : [];
}
function flatten(pack, file) {
  const messages = new Map();
  function visit(value, key) {
    const plural = key && object(value) && Object.hasOwn(value, 'other') && Object.keys(value).every(k => categories.has(k));
    if (typeof value === 'string' || plural) {
      if (plural && Object.values(value).some(v => typeof v !== 'string')) throw new Error(`${file}: non-string plural at ${key}`);
      if (messages.has(key)) throw new Error(`${file}: duplicate flattened key ${key}`);
      messages.set(key, value);
    } else if (object(value)) {
      for (const [child, entry] of Object.entries(value)) visit(entry, key ? `${key}.${child}` : child);
    } else throw new Error(`${file}: expected string or namespace at ${key || '-'}`);
  }
  if (!object(pack)) throw new Error(`${file}: expected JSON object`);
  visit(pack, '');
  return messages;
}
function options(argv) {
  const usage = 'Usage: i18n-gate.mjs --registry <file> --packs <path with {locale}> [--required-keys <file>] [--dnt <file>] [--meta <file>] [--production]; or --self-test';
  if (argv.length === 1 && argv[0] === '--self-test') return { selfTest: true };
  const result = {};
  for (let i = 0; i < argv.length; i++) {
    const flag = argv[i];
    if (flag === '--production' && !result.production) { result.production = true; continue; }
    if (!['--registry', '--packs', '--required-keys', '--dnt', '--meta'].includes(flag) || result[flag.slice(2)] || !argv[i + 1] || argv[i + 1].startsWith('--')) throw new Error(usage);
    result[flag.slice(2)] = argv[++i];
  }
  if (!result.registry || !result.packs || result.packs.split('{locale}').length !== 2) throw new Error(usage);
  return result;
}
function gate(opts) {
  const registry = read(opts.registry, true);
  const invalid = reason => { throw new Error(`${opts.registry}: ${reason}`); };
  if (!object(registry) || !Array.isArray(registry.locales) || typeof registry.source !== 'string') invalid('expected source and locales array');
  const codes = new Set();
  for (const locale of registry.locales) {
    if (!object(locale) || typeof locale.code !== 'string' || !/^[A-Za-z0-9]+(?:-[A-Za-z0-9]+)*$/.test(locale.code) || codes.has(locale.code)) invalid('invalid or duplicate locale code');
    codes.add(locale.code);
    if (!['live', 'beta', 'hidden', 'pseudo'].includes(locale.status)) invalid(`invalid status for ${locale.code}`);
    if (locale.scripts !== undefined && (!Array.isArray(locale.scripts) || locale.scripts.some(s => typeof s !== 'string'))) invalid(`invalid scripts for ${locale.code}`);
    if (locale.allowIdentical !== undefined && (!Array.isArray(locale.allowIdentical) || locale.allowIdentical.some(s => typeof s !== 'string'))) invalid(`invalid allowIdentical for ${locale.code}`);
    if ((locale.scripts || []).some(s => !/^[A-Za-z_]+$/.test(s))) invalid(`invalid Unicode script for ${locale.code}`);
    try { locale.scriptPatterns = (locale.scripts || []).map(s => new RegExp(`^\\p{Script=${s}}$`, 'u')); }
    catch { invalid(`invalid Unicode script for ${locale.code}`); }
  }
  if (codes.size && !codes.has(registry.source)) invalid('source locale must be in locales');
  const required = lines(opts['required-keys']);
  const dnt = lines(opts.dnt).sort((a, b) => b.length - a.length || compare(a, b));
  const stripDnt = value => dnt.reduce((text, term) => text.split(term).join(''), value);
  const meta = opts.meta ? read(opts.meta, true) : {};
  if (!object(meta)) throw new Error(`${opts.meta}: expected metadata object`);
  const failures = [], warnings = [], packs = new Map();
  const fail = (check, locale, key, reason) => failures.push({ check, locale, key, reason });
  if (!codes.size) fail(8, '-', '-', 'empty locales registry');
  const [prefix, suffix] = opts.packs.split('{locale}');
  // A marker can be in the filename or in a directory component. Expand only
  // that component, then retain regular files matching the entire template.
  const templateDir = dirname(prefix || '.');
  const partial = basename(prefix);
  const endsInSeparator = prefix.endsWith('/');
  const scanDir = endsInSeparator ? prefix : templateDir;
  const namePrefix = endsInSeparator ? '' : partial;
  let entries;
  try { entries = readdirSync(scanDir || '.'); }
  catch (error) {
    if (error.code !== 'ENOENT') throw new Error(`${opts.packs}: ${error.message}`);
    entries = [];
  }
  const suffixPart = suffix.split('/')[0];
  for (const name of entries.sort(compare)) {
    if (!name.startsWith(namePrefix) || !name.endsWith(suffixPart)) continue;
    const code = name.slice(namePrefix.length, suffixPart ? -suffixPart.length : undefined);
    const file = opts.packs.replace('{locale}', code);
    let isFile;
    try { isFile = statSync(file).isFile(); } catch (error) {
      if (error.code === 'ENOENT' || error.code === 'ENOTDIR') continue;
      throw new Error(`${file}: ${error.message}`);
    }
    if (isFile && !codes.has(code)) fail(8, code || '-', '-', 'pack has no registry entry');
  }
  for (const locale of [...registry.locales].sort((a, b) => compare(a.code, b.code))) {
    const { code } = locale, file = opts.packs.replace('{locale}', code);
    try { statSync(file); }
    catch (error) {
      if (error.code !== 'ENOENT') throw new Error(`${file}: ${error.message}`);
      fail(8, code, '-', 'missing pack file');
      continue;
    }
    packs.set(code, flatten(read(file, true), file));
  }
  const source = packs.get(registry.source) || new Map();
  for (const locale of registry.locales) {
    const { code } = locale, pack = packs.get(code);
    if (opts.production && locale.status === 'pseudo') fail(8, code, '-', 'pseudo locale in production');
    if (locale.status === 'live' && (!locale.reviewedBy?.trim() || !locale.reviewedAt?.trim())) fail(11, code, '-', 'live locale lacks reviewedBy or reviewedAt');
    let pluralCategories = [];
    try {
      if (Intl.PluralRules.supportedLocalesOf([code]).length) pluralCategories = new Intl.PluralRules(code).resolvedOptions().pluralCategories;
      else warnings.push(`WARN ${code}: Intl.PluralRules locale unsupported; plural category check skipped`);
    } catch { warnings.push(`WARN ${code}: Intl.PluralRules locale unsupported; plural category check skipped`); }
    if (!pack) continue;
    if (code !== registry.source && packs.has(registry.source)) {
      for (const key of source.keys()) if (!pack.has(key)) fail(1, code, key, 'missing key');
      for (const key of pack.keys()) if (!source.has(key)) fail(1, code, key, 'extra key');
    }
    for (const key of new Set(required)) if (!pack.has(key)) fail(9, code, key, 'missing required key');
    for (const [key, message] of pack) {
      if (object(message)) for (const category of new Set([...pluralCategories, 'other'])) {
        if (!Object.hasOwn(message, category)) fail(4, code, key, `missing plural category ${category}`);
      }
      const branches = typeof message === 'string' ? [['', message]] : Object.entries(message);
      for (const [category, value] of branches) {
        const label = category ? `${key}.${category}` : key;
        const original = source.get(key);
        const sourceValue = typeof original === 'string' ? original : original?.[category] ?? original?.other;
        if (!value.trim()) fail(2, code, label, 'empty value');
        if (code !== registry.source && sourceValue !== undefined && JSON.stringify(tokens(value)) !== JSON.stringify(tokens(sourceValue))) fail(3, code, label, 'placeholder/tag multiset differs');
        if (code !== registry.source && (value.startsWith('⟦TODO⟧') || (value === sourceValue && /\p{L}/u.test(stripDnt(stripTokens(value))) && !(locale.allowIdentical || []).includes(value)))) fail(5, code, label, 'untranslated value');
        const letters = stripDnt(stripTokens(value)).match(/\p{L}/gu) || [];
        if (locale.scriptPatterns.length && letters.length >= 3 && letters.filter(letter => locale.scriptPatterns.some(pattern => pattern.test(letter))).length / letters.length < 0.5) fail(6, code, label, 'fewer than 50% of letters match expected scripts');
        if (typeof meta[key]?.maxLength === 'number' && [...value].length > meta[key].maxLength) fail(7, code, label, `length ${[...value].length} exceeds maxLength ${meta[key].maxLength}`);
      }
    }
  }
  warnings.sort(compare).forEach(line => console.log(line));
  failures.sort((a, b) => compare(a.locale, b.locale) || compare(a.key, b.key) || a.check - b.check || compare(a.reason, b.reason));
  for (const { check, locale, key, reason } of failures) console.log(`FAIL ${check} ${locale} ${key}: ${reason}`);
  console.log(failures.length ? `i18n-gate: ${failures.length} failures in ${codes.size} locales, ${source.size} source keys` : `i18n-gate: OK — ${codes.size} locales, ${source.size} source keys`);
  return failures.length ? 1 : 0;
}
function selfTest() {
  const root = mkdtempSync(join(tmpdir(), 'i18n-gate-self-'));
  let dir = join(root, 'passing');
  const write = (name, value) => writeFileSync(join(dir, name), JSON.stringify(value));
  const edit = (name, change) => {
    const value = read(join(dir, name), true);
    change(value);
    write(name, value);
  };
  const registry = { source: 'en', locales: ['en', 'ru', 'ja', 'es'].map(code => ({ code, status: 'beta', scripts: code === 'ru' ? ['Cyrillic'] : code === 'ja' ? ['Han', 'Hiragana', 'Katakana'] : ['Latin'] })) };
  const packs = {
    en: { plain: 'Save', title: 'Save {name}', count: { one: '{n} item', other: '{n} items' } },
    ru: { plain: 'Сохранить', title: 'Сохранить {name}', count: { one: '{n} предмет', few: '{n} предмета', many: '{n} предметов', other: '{n} предмета' } },
    ja: { plain: '保存する', title: '保存する {name}', count: { other: '{n} 個' } },
    es: { plain: 'Guardar', title: 'Guardar {name}', count: { one: '{n} elemento', many: '{n} elementos', other: '{n} elementos' } },
  };
  const run = extra => {
    const result = spawnSync(process.execPath, [fileURLToPath(import.meta.url), '--registry', join(dir, 'registry.json'), '--packs', join(dir, '{locale}.pack.json'), ...extra], { encoding: 'utf8', timeout: 10000 });
    assert.ifError(result.error);
    return result;
  };
  try {
    mkdirSync(dir);
    write('registry.json', registry);
    for (const [code, pack] of Object.entries(packs)) write(`${code}.pack.json`, pack);
    const passingDir = dir, passing = run([]);
    assert.equal(passing.status, 0, passing.stdout + passing.stderr);
    const cases = [
      [1, () => edit('es.pack.json', p => { delete p.title; })],
      [1, () => edit('es.pack.json', p => { p.extra = 'Nuevo'; })],
      [2, () => edit('en.pack.json', p => { p.plain = ' '; })],
      [3, () => edit('es.pack.json', p => { p.title = 'Guardar'; })],
      [4, () => edit('ru.pack.json', p => { delete p.count.few; })],
      [5, () => edit('es.pack.json', p => { p.title = packs.en.title; })],
      [6, () => edit('ru.pack.json', p => { p.title = 'Sohranit {name}'; })],
      [7, () => { edit('es.pack.json', p => { p.title = 'Guardar todos los cambios {name}'; }); write('meta.json', { title: { maxLength: 20 } }); return ['--meta', join(dir, 'meta.json')]; }],
      [8, () => rmSync(join(dir, 'ja.pack.json'))],
      [8, () => write('xx.pack.json', {})],
      [8, () => { edit('registry.json', r => { r.locales[2].status = 'pseudo'; }); return ['--production']; }],
      [11, () => edit('registry.json', r => { Object.assign(r.locales[0], { status: 'live', reviewedBy: 'Reviewer' }); })],
      [8, () => {
        edit('registry.json', r => { r.locales = []; });
        for (const code of Object.keys(packs)) rmSync(join(dir, `${code}.pack.json`));
      }],
      [9, () => { writeFileSync(join(dir, 'required.txt'), 'missing\n'); return ['--required-keys', join(dir, 'required.txt')]; }],
    ];
    for (const [index, [check, plant]] of cases.entries()) {
      dir = join(root, `defect-${index}`);
      cpSync(passingDir, dir, { recursive: true });
      const result = run(plant() || []);
      assert.equal(result.status, 1, result.stdout + result.stderr);
      const failures = result.stdout.split('\n').filter(line => line.startsWith('FAIL '));
      assert.ok(failures.length && failures.every(line => line.startsWith(`FAIL ${check} `)), result.stdout);
      if (!read(join(dir, 'registry.json'), true).locales.length) assert.equal(result.stdout, 'FAIL 8 - -: empty locales registry\ni18n-gate: 1 failures in 0 locales, 0 source keys\n');
      console.log(`self-test: check ${check} goes red ✓`);
    }
    return 0;
  } finally { rmSync(root, { recursive: true, force: true }); }
}

try {
  const opts = options(process.argv.slice(2));
  process.exitCode = opts.selfTest ? selfTest() : gate(opts);
} catch (error) {
  console.error(`i18n-gate: ${error.message}`);
  process.exitCode = 2;
}
