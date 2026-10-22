---
name: patterns-frontend
description: The user's front-end patterns, in ~/patterns/frontend/ - architecture rules enforced by tooling, such as Feature-Sliced Design layer and public-API rules as eslint-plugin-boundaries errors, with a canary test for silent failures. Use when setting up or reviewing FSD, import boundaries or ESLint architecture rules in a front-end repo.
---

# Front-end patterns (~/patterns/frontend)

1. Read the "Front end" section of `~/patterns/README.md`, then only the files the
   task needs.
2. Run `node ~/patterns/scripts/check-docs.mjs --force`. No output means the cited
   docs are unchanged. Otherwise tell the user which patterns may be stale.
3. Weigh each pattern by its `status` (`proven` or `candidate`) and each claim by
   its label: **(verified)**, **(docs)**, **(opinion)**.

To add or change a pattern, follow the `patterns` skill
(`~/patterns/skills/patterns/SKILL.md`, or `/patterns add`).
