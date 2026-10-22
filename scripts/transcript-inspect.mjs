#!/usr/bin/env node
// What did a Claude Code session actually load and do? Reads the session
// transcript instead of asking the model (see claude-code/verification.md).
//
//   node scripts/transcript-inspect.mjs                 latest session started in the current directory
//   node scripts/transcript-inspect.mjs <dir>           latest session started in <dir>
//   node scripts/transcript-inspect.mjs <file.jsonl>    that session
//   … --grep "TEXT"                                     which injected attachments contain TEXT
import { existsSync, readdirSync, readFileSync, statSync } from 'node:fs';
import { homedir } from 'node:os';
import { join, resolve } from 'node:path';

const argv = process.argv.slice(2);
const grepAt = argv.indexOf('--grep');
const grep = grepAt >= 0 ? argv.splice(grepAt, 2)[1] : undefined;
const target = resolve(argv[0] ?? process.cwd());

let file = target;
if (!target.endsWith('.jsonl')) {
  const projectDir = join(homedir(), '.claude', 'projects', target.replace(/[^a-zA-Z0-9]/g, '-'));
  if (!existsSync(projectDir)) {
    console.error(`No transcripts for ${target} (looked in ${projectDir}).`);
    process.exit(1);
  }
  const latest = readdirSync(projectDir)
    .filter(name => name.endsWith('.jsonl'))
    .map(name => join(projectDir, name))
    .sort((a, b) => statSync(b).mtimeMs - statSync(a).mtimeMs)[0];
  if (!latest) {
    console.error(`No sessions in ${projectDir}.`);
    process.exit(1);
  }
  file = latest;
}

const entries = readFileSync(file, 'utf8')
  .trim()
  .split('\n')
  .map(line => {
    try {
      return JSON.parse(line);
    } catch {
      return undefined;
    }
  })
  .filter(Boolean);

const prompt = entries.find(e => e.type === 'user' && typeof e.message?.content === 'string')?.message.content;
console.log(`session: ${file}`);
console.log(`prompt:  ${JSON.stringify((prompt ?? '').slice(0, 120))}`);

console.log('\ntool calls:');
for (const call of entries.flatMap(e => (Array.isArray(e.message?.content) ? e.message.content : []))) {
  if (call?.type !== 'tool_use') continue;
  const input = call.input ?? {};
  console.log(`  ${call.name}: ${input.file_path ?? input.command ?? input.pattern ?? JSON.stringify(input).slice(0, 80)}`);
}

console.log('\ninjected attachments (in order):');
for (const entry of entries.filter(e => e.type === 'attachment')) {
  const kind = entry.attachment?.type;
  if (kind === 'prompt_snapshot') continue;
  const text = JSON.stringify(entry.attachment);
  // Local absolute paths only: skips URL tails and bare names quoted in the text.
  const files = [...new Set([...text.matchAll(/(?<![\w:/.])\/[\w.-]+\/[^"\s\\]+?\.md\b/g)].map(m => m[0]))];
  const hit = grep && text.includes(grep) ? `  <-- contains ${JSON.stringify(grep)}` : '';
  if (files.length || hit || ['nested_memory', 'instructions', 'skill_listing'].includes(kind)) {
    console.log(`  ${kind}${files.length ? `: ${files.join(', ')}` : ''}${hit}`);
  }
}
