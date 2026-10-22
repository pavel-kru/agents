---
sources:
  - https://code.claude.com/docs/en/memory.md
  - https://code.claude.com/docs/en/best-practices.md
verified: 2026-10-21
claude_code: 2.1.303
---

# When instructions disagree

## What the harness does

Nothing. Instruction files are concatenated, and if two of them contradict each
other the model may pick either one. **(docs)** Claude Code defines no ranking
between CLAUDE.md files, rules and skills, and none between those files and a
user's chat message. **(docs; the chat-message part is not stated anywhere)**

## What to do, in order

1. **Remove the conflict.** Give each rule one canonical home and let everything
   else link to it. Every copy drifts eventually: one real case had a rule
   restated in eight places, and two of the copies already contradicted each
   other. **(opinion, from that case)**
2. **Move invariants into mechanics:** hooks, linters, tests, generated contracts.
   When docs disagree with a mechanism, the mechanism decides. **(opinion)**
3. **Write a short tie-break into CLAUDE.md** for whatever is left. It is advisory
   like every other line in the file, but it turns an arbitrary pick into a
   predictable one. **(opinion)**

## Tie-break template

```markdown
## When sources disagree

- A direct instruction from the human in the session wins over these files.
- Facts (what the code does, API shapes, where files are) come from the source:
  the code, generated artifacts, tests, the filesystem. A doc that disagrees is
  stale.
- Rules for new work come from the hard rules above (and the decision record).
  Topic docs only add detail. Existing code that breaks a rule is not a pattern
  to copy.
- If you can't settle it, don't pick silently. Fix the stale doc on your branch,
  or raise the conflict in the PR or ticket.
```

The key move is to **separate facts from norms**. For a fact, the code beats the
doc. For a norm, the doc beats the existing code.

## Detecting conflicts

- Grep for the same rule restated in several places.
- Have a reviewer read the docs like a hostile reader whose job is to find gaps.
- Tests that prove a document against reality turn prose into evidence.
