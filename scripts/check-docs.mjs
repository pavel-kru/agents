#!/usr/bin/env node
// Session-start check: have the Claude Code docs the patterns cite changed since
// they were verified, or is Claude Code newer than the version they were checked
// on? Prints a report only when there is something to do, so it costs no context
// otherwise.
//
//   node scripts/check-docs.mjs                check (at most once a day)
//   node scripts/check-docs.mjs --force        check now
//   node scripts/check-docs.mjs --update-lock  record the current docs as verified
import { execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { existsSync, mkdirSync, readdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, join, relative } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const lockPath = join(root, 'docs.lock.json');
const cachePath = join(root, '.cache', 'docs-check.json');
const args = new Set(process.argv.slice(2));
const DAY_MS = 24 * 60 * 60 * 1000;

const readJson = (path, fallback) =>
  existsSync(path) ? JSON.parse(readFileSync(path, 'utf8')) : fallback;

const lock = readJson(lockPath, { pages: {} });
const cache = readJson(cachePath, {});

if (
  !args.has('--force') &&
  !args.has('--update-lock') &&
  cache.checkedAt &&
  Date.now() - Date.parse(cache.checkedAt) < DAY_MS
) {
  process.exit(0);
}

// Patterns are the .md files with front-matter; templates are skipped.
const patterns = [];
const walk = dir => {
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    if (['.git', '.cache', 'node_modules', 'templates'].includes(entry.name)) continue;
    const path = join(dir, entry.name);
    if (entry.isDirectory()) walk(path);
    else if (entry.name.endsWith('.md')) {
      const header = readFileSync(path, 'utf8').match(/^---\n([\s\S]*?)\n---/);
      if (!header) continue;
      const sources = [...header[1].matchAll(/^\s+-\s+(https?:\/\/\S+)/gm)].map(m => m[1]);
      const claudeCode = header[1].match(/^claude_code:\s*([\d.]+)/m)?.[1];
      patterns.push({ file: relative(root, path), sources, claudeCode });
    }
  }
};
walk(root);

const urls = [...new Set(patterns.flatMap(p => p.sources))];
const fetched = await Promise.all(
  urls.map(async url => {
    try {
      const response = await fetch(url, { signal: AbortSignal.timeout(5000) });
      if (!response.ok) return { url, error: `HTTP ${response.status}` };
      const sha256 = createHash('sha256').update(await response.text()).digest('hex');
      return { url, sha256 };
    } catch (error) {
      return { url, error: error.name };
    }
  }),
);
const reached = fetched.filter(page => page.sha256);

if (args.has('--update-lock')) {
  const pages = Object.fromEntries(reached.map(({ url, sha256 }) => [url, { sha256 }]));
  writeFileSync(lockPath, `${JSON.stringify({ pages }, null, 2)}\n`);
  console.log(`docs.lock.json: ${reached.length} of ${urls.length} pages recorded.`);
  for (const { url, error } of fetched.filter(page => page.error)) console.log(`  not reached: ${url} (${error})`);
  process.exit(0);
}

if (!reached.length && urls.length) {
  console.log(
    'Docs check skipped: could not reach the Claude Code docs. Treat the patterns in this repo as unverified this session.',
  );
  process.exit(0);
}

mkdirSync(dirname(cachePath), { recursive: true });
writeFileSync(cachePath, `${JSON.stringify({ checkedAt: new Date().toISOString() })}\n`);

const citedBy = url => patterns.filter(p => p.sources.includes(url)).map(p => p.file).join(', ');
const changed = reached.filter(({ url, sha256 }) => lock.pages[url] && lock.pages[url].sha256 !== sha256);
const unrecorded = reached.filter(({ url }) => !lock.pages[url]);
const unreachable = fetched.filter(page => page.error);

const toParts = version => version.split('.').map(Number);
const newer = (a, b) => {
  const [x, y] = [toParts(a), toParts(b)];
  for (let i = 0; i < Math.max(x.length, y.length); i++) {
    if ((x[i] ?? 0) !== (y[i] ?? 0)) return (x[i] ?? 0) > (y[i] ?? 0);
  }
  return false;
};
const recorded = patterns.map(p => p.claudeCode).filter(Boolean).sort((a, b) => (newer(a, b) ? -1 : 1))[0];
let installed;
try {
  installed = execFileSync('claude', ['--version'], { timeout: 3000, encoding: 'utf8' }).match(/\d+\.\d+\.\d+/)?.[0];
} catch {
  installed = undefined;
}

const lines = [];
if (changed.length) {
  lines.push('Claude Code docs changed since the patterns citing them were verified:');
  for (const { url } of changed) lines.push(`- ${url} (cited by ${citedBy(url)})`);
}
if (unrecorded.length) {
  lines.push('Cited docs never recorded as verified:');
  for (const { url } of unrecorded) lines.push(`- ${url} (cited by ${citedBy(url)})`);
}
if (installed && recorded && newer(installed, recorded)) {
  lines.push(`Claude Code is ${installed}; the patterns were last verified on ${recorded}.`);
}
if (lines.length) {
  if (unreachable.length) lines.push(`Not reached this time: ${unreachable.map(p => p.url).join(', ')}`);
  lines.push('Follow "Keeping the patterns current" in CLAUDE.md before relying on the affected patterns.');
  console.log(lines.join('\n'));
}
