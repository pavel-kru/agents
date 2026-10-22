// PreToolUse hook: stops Claude from hand-editing generated files and says how
// to regenerate them instead. Exit code 2 blocks the call; stderr goes to Claude.
// Paths match by suffix, so relative, absolute and Windows paths all work.
import { readFileSync } from 'node:fs';

const GENERATED = [
  {
    suffix: '/src/shared/api/schema.d.ts',
    message:
      'src/shared/api/schema.d.ts is generated — never edit it by hand. Run `npm run api:generate`; a wrong shape is a back-end fix.',
  },
];

const input = JSON.parse(readFileSync(0, 'utf8'));
const filePath = String(
  input.tool_input?.file_path ?? input.tool_input?.notebook_path ?? '',
).replaceAll('\\', '/');
const match = GENERATED.find(({ suffix }) => `/${filePath}`.endsWith(suffix));

if (match) {
  process.stderr.write(match.message);
  process.exit(2);
}
