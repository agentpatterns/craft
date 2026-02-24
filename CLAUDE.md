# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

See `AGENTS.md` for contributor instructions, skill authoring guidelines, and issue tracking workflows.

See `docs/architecture.md` for project structure, key concepts, and installation commands.

## Skill Authoring Guidelines

- A skill's `SKILL.md` MUST be under 300 lines of markdown. Keep the main file focused on the core workflow and decision logic.
- Supporting content (examples, reference tables, deep-dive explanations, templates) SHOULD go in the skill's `references/` subdirectory as separate markdown files, linked from the main `SKILL.md`.
- Each skill is a directory containing `SKILL.md` and an optional `references/` subdirectory.

### Frontmatter Format

Every `SKILL.md` MUST begin with YAML frontmatter in this format:

```yaml
---
name: skill-name
description: One-sentence description of what the skill does and when to use it.
triggers:
  - "specific trigger phrase"
  - "another trigger phrase"
allowed-tools: Read Glob Write
---
```

- `name` — Kebab-case identifier matching the skill directory name.
- `description` — Concise summary shown in plugin listings.
- `triggers` — List of phrases that activate the skill. Use specific multi-word phrases; avoid bare single-word triggers that risk false activation.
- `allowed-tools` — Space-separated list of Claude Code tools the skill may use.
