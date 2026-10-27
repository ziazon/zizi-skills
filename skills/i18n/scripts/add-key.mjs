#!/usr/bin/env node
/**
 * Propagate one JSON translation key, preserving order. Node 22+, built-ins only.
 * Usage: node add-key.mjs --registry <registry.json> --packs '<path with {locale}>'
 *   --key <dotted.key> --text <source text> [--after <dotted.key> | --first] [--dry-run]
 * Registry: {"source":"en","locales":[{"code":"en","status":"beta"}, ...]}.
 * Flat dotted packs and nested namespaces are detected independently per file.
 * Exit codes: 0 ok; 2 usage/bad registry/unknown --after; 3 key exists or
 * collides; 4 a pack does not round-trip through JSON.stringify.
 * All packs are validated and computed before staging temporary sibling files;
 * each rename is atomic. Multiple renames are not a filesystem transaction.
 */
import { readFileSync, writeFileSync, renameSync, rmSync, mkdtempSync, statSync } from 'node:fs';
import { dirname, join } from 'node:path';

const object = value => value !== null && typeof value === 'object' && !Array.isArray(value);
const categories = new Set(['zero', 'one', 'two', 'few', 'many', 'other']);
function fail(code, message) { throw Object.assign(new Error(message), { exitCode: code }); }
function read(file, json = false) {
  try {
    const text = readFileSync(file, 'utf8');
    return json ? JSON.parse(text) : text;
  } catch (error) { fail(2, `${file}: ${error.message}`); }
}
// Keep the gate's flattened message and plural detection conventions.
function flatten(pack, file) {
  const messages = new Map();
  function visit(value, key) {
    const plural = key && object(value) && Object.hasOwn(value, 'other') && Object.keys(value).every(k => categories.has(k));
    if (typeof value === 'string' || plural) {
      if (plural && Object.values(value).some(v => typeof v !== 'string')) fail(2, `${file}: non-string plural at ${key}`);
      if (messages.has(key)) fail(2, `${file}: duplicate flattened key ${key}`);
      messages.set(key, value);
    } else if (object(value)) {
      for (const [child, entry] of Object.entries(value)) visit(entry, key ? `${key}.${child}` : child);
    } else fail(2, `${file}: expected string or namespace at ${key || '-'}`);
  }
  if (!object(pack)) fail(2, `${file}: expected JSON object`);
  visit(pack, '');
  return messages;
}
function options(argv) {
  const usage = 'Usage: add-key.mjs --registry <file> --packs <path with {locale}> --key <dotted.key> --text <text> [--after <dotted.key> | --first] [--dry-run]';
  const opts = {};
  for (let i = 0; i < argv.length; i++) {
    const flag = argv[i], name = flag.slice(2);
    if (!['--registry', '--packs', '--key', '--text', '--after', '--first', '--dry-run'].includes(flag) || Object.hasOwn(opts, name)) fail(2, usage);
    if (flag === '--first' || flag === '--dry-run') opts[name] = true;
    else {
      if (argv[i + 1] === undefined || argv[i + 1].startsWith('--')) fail(2, usage);
      opts[name] = argv[++i];
    }
  }
  const dotted = key => typeof key === 'string' && key.split('.').every(part => part.length > 0);
  if (!opts.registry || !opts.packs || opts.packs.split('{locale}').length !== 2 || !dotted(opts.key) || !Object.hasOwn(opts, 'text') || (opts.after !== undefined && (!dotted(opts.after) || opts.first))) fail(2, usage);
  return opts;
}
function registry(file) {
  const value = read(file, true), codes = new Set();
  const invalid = () => fail(2, `${file}: invalid locale registry`);
  if (!object(value) || typeof value.source !== 'string' || !Array.isArray(value.locales) || !value.locales.length) invalid();
  for (const locale of value.locales) {
    if (!object(locale) || typeof locale.code !== 'string' || !/^[A-Za-z0-9]+(?:-[A-Za-z0-9]+)*$/.test(locale.code) || codes.has(locale.code) || !['live', 'beta', 'hidden', 'pseudo'].includes(locale.status)) invalid();
    codes.add(locale.code);
    for (const field of ['scripts', 'allowIdentical']) {
      if (locale[field] !== undefined && (!Array.isArray(locale[field]) || locale[field].some(item => typeof item !== 'string'))) invalid();
    }
    try { for (const script of locale.scripts || []) new RegExp(`^\\p{Script=${script}}$`, 'u'); }
    catch { invalid(); }
  }
  if (!codes.has(value.source)) invalid();
  return value;
}
function load(file) {
  const text = read(file);
  let pack;
  try { pack = JSON.parse(text); }
  catch (error) { fail(2, `${file}: ${error.message}`); }
  const indent = text.match(/\n([\t ]+)"/)?.[1] ?? 2;
  const newline = text.endsWith('\n') ? '\n' : '';
  const stringify = value => JSON.stringify(value, null, indent) + newline;
  if (stringify(pack) !== text) fail(4, `${file} does not round-trip through JSON.stringify; edit it by hand`);
  const messages = flatten(pack, file);
  const flat = Object.keys(pack).some(key => key.includes('.')) && Object.keys(pack).every(key => messages.has(key));
  return { file, pack, messages, flat, stringify };
}
function insert(loaded, opts, text) {
  const { file, pack, messages, flat } = loaded;
  const parts = opts.key.split('.');
  const collision = () => fail(3, `${file}: key ${opts.key} already exists or collides`);
  if (messages.has(opts.key) || [...messages.keys()].some(key => key.startsWith(`${opts.key}.`) || opts.key.startsWith(`${key}.`))) collision();
  let parent = pack;
  if (!flat) {
    for (const part of parts.slice(0, -1)) {
      if (!Object.hasOwn(parent, part)) Object.defineProperty(parent, part, { value: {}, enumerable: true, writable: true, configurable: true });
      if (!object(parent[part])) collision();
      parent = parent[part];
    }
  }
  const key = flat ? opts.key : parts.at(-1);
  if (Object.hasOwn(parent, key)) collision();
  if (opts.after && !flat && opts.after.split('.').slice(0, -1).join('.') !== parts.slice(0, -1).join('.')) fail(2, `${file}: --after must name a key in the same parent as ${opts.key}`);
  const anchor = flat ? opts.after : opts.after?.split('.').at(-1);
  const entries = Object.entries(parent);
  let index = opts.first ? 0 : entries.length;
  if (opts.after) {
    const found = entries.findIndex(([name]) => name === anchor);
    if (found === -1) console.warn(`WARN ${file}: --after ${opts.after} missing; appending to parent`);
    else index = found + 1;
  }
  entries.splice(index, 0, [key, text]);
  // Define own properties so keys such as __proto__ remain ordinary JSON data.
  for (const name of Object.keys(parent)) delete parent[name];
  Object.defineProperties(parent, Object.fromEntries(entries.map(([name, value]) => [name, { value, enumerable: true, writable: true, configurable: true }])));
  if (Object.keys(parent).join('\0') !== entries.map(([name]) => name).join('\0')) fail(2, `${file}: integer-like keys cannot preserve requested insertion order`);
  return loaded.stringify(pack);
}
function main(opts) {
  const locales = registry(opts.registry);
  const packs = locales.locales.map(({ code }) => ({ ...load(opts.packs.replace('{locale}', code)), code }));
  if (opts.after && !packs.find(pack => pack.code === locales.source).messages.has(opts.after)) fail(2, `--after ${opts.after} is absent from the source pack`);
  const computed = packs.map(pack => ({ ...pack, text: insert(pack, opts, `${pack.code === locales.source ? '' : '⟦TODO⟧ '}${opts.text}`) }));
  if (opts['dry-run']) {
    for (const { file } of computed) console.log(`${file}: + ${opts.key}`);
    return;
  }
  const staged = [];
  try {
    for (const { file, text } of computed) {
      const dir = mkdtempSync(join(dirname(file), '.add-key-'));
      const temp = join(dir, 'pack.json');
      staged.push({ dir, temp, file });
      writeFileSync(temp, text, { mode: statSync(file).mode & 0o777 });
    }
    for (const { temp, file } of staged) renameSync(temp, file);
  } finally {
    for (const { dir } of staged) rmSync(dir, { recursive: true, force: true });
  }
}
try { main(options(process.argv.slice(2))); }
catch (error) {
  console.error(`add-key: ${error.message}`);
  process.exitCode = error.exitCode || 2;
}
