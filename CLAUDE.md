# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Project Is

Craft is a Claude Code plugin marketplace that delivers skills (structured markdown workflow documents) for software development best practices. There is no application code, build system, or test suite — the project is entirely markdown content and plugin configuration.

## Project Structure

- `.claude-plugin/marketplace.json` — Plugin registry declaring one plugin: `crafter` (v2.0.0)
- `plugins/crafter/skills/` — Skills for the crafter plugin (research, draft, craft, tdd, refactor, reflect, tidy, pair, diagram, scaffold, hexagonal-architecture, adr)

Each skill is a directory containing `SKILL.md` (with YAML frontmatter for name, description, triggers, allowed-tools) and an optional `references/` subdirectory with supplementary markdown.

## Installation Commands

```
# From GitHub
/plugin marketplace add agentpatterns/craft
/plugin install crafter

# From local directory
/plugin marketplace add /path/to/craft
/plugin install crafter@craft

# Update
/plugin marketplace update craft
```

## Key Concepts

### RPI Methodology (Research → Draft → Craft)

The core workflow across the crafter skills:

1. **Research** (`/research`) — Spawns parallel subagents to explore a codebase, outputs a ~200-line research artifact to `docs/plans/YYYY-MM-DD-{topic}-research.md`
2. **Draft** (`/draft`) — Consumes the research artifact, produces a compact implementation plan to `docs/plans/YYYY-MM-DD-{topic}-plan.md`
3. **Craft** (`/craft`) — Executes the plan phase-by-phase with strict RED → GREEN → REFACTOR discipline

After any substantive session, **Reflect** (`/reflect`) closes the learning loop — mining git history and artifacts to produce improvement proposals for skills, CLAUDE.md, hooks, and templates.

### L3/L4 Boundary Testing Philosophy

Enforced across TDD, craft, and draft skills:
- **L3 core tests**: Property-based testing with `fast-check` against domain logic
- **L3 feature tests**: Behavioral assertions against real databases via `Testcontainers`
- **L4 HTTP tests**: HTTP contract verification (status codes, response shapes) via `Supertest`
- Internal mocks are forbidden — test at architectural boundaries only
- ZOMBIES heuristic (Zero, One, Many, Boundary, Interface, Exception, Simple) guides test planning

### Hexagonal Architecture

The crafter plugin enforces ports-and-adapters architecture:
- Domain → Application → Adapters (dependencies flow inward only)
- Naming: `*View`/`*Response` for display, `*Request` for input, `*Dbo` for database entities

## Creating New Skills

When asked to create a new skill, use the `/skill-creator` skill. It provides a guided workflow for authoring well-structured skills. Invoke it before doing anything else.

## Skill Authoring Guidelines

- A skill's `SKILL.md` MUST be under 300 lines of markdown. Keep the main file focused on the core workflow and decision logic.
- Supporting content (examples, reference tables, deep-dive explanations, templates) SHOULD go in the skill's `references/` subdirectory as separate markdown files, linked from the main `SKILL.md`.
- Preserve the YAML frontmatter structure (name, description, triggers, allowed-tools metadata) when editing or creating skills.
- Each skill is a directory containing `SKILL.md` and an optional `references/` subdirectory.
