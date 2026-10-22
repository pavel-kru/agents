---
sources:
  - https://code.claude.com/docs/en/cli-reference.md
  - https://code.claude.com/docs/en/memory.md
verified: 2026-10-21
claude_code: 2.1.303
---

# Proving what an agent loaded or was blocked from

## Don't ask the model

A model's answer to "is X in your context?" is unreliable. **(verified)** In one
check the model said a rule hadn't loaded, and the transcript showed it had.
Treat the model's answer as a hint, never as evidence.

## Do this instead

1. Build the situation in a scratch dir or a worktree. Put **marker strings**
   (`RULE-GAMMA-3`) in the files whose loading you want to test.
2. Run a cheap headless session from the right directory:
   `claude -p "Read src/x/api/a.ts and nothing else, then reply OK." --model haiku --allowedTools Read`
3. Read the **transcript**:
   `~/.claude/projects/<cwd with / turned into ->/<session>.jsonl`.
   `node scripts/transcript-inspect.mjs [<dir> | <file.jsonl>] [--grep TEXT]`
   picks the latest session for the directory and prints the prompt, the tool
   calls, and each injected attachment with the local files it carried. With
   `--grep`, it also marks which attachments contain TEXT.
4. Look only inside the injected attachments:
   - `instructions`: memory files loaded at start, imports included;
   - `nested_memory`: a CLAUDE.md or a rule loaded on file access;
   - `skill_listing`: the skills offered.

   Phrase counts over the whole file are confounded, because your prompt
   contains the phrase too.

## Traps in the method

- `--output-format stream-json` does **not** include injected memory text. A
  "0 hits" there proves nothing. **(verified)**
- Confirm that the session read only the file you meant: list its `tool_use`
  entries. A model can read the rule file itself and fake a positive.
- When testing a hook, also check the file on disk after the run.
- One probe's "success" can be a false positive. A serialised body of 137 bytes
  turned out to be the string `"[object File]"`. Check the content, not only the
  size.
