# Architecture

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

### Subtype Dispatch Pattern

Skills that serve multiple related use cases (e.g., different diagram types, different project scaffolds) use the **subtype dispatch pattern** instead of creating separate skills:

1. **Dispatch table in `SKILL.md`** — A table mapping user intent to a subtype identifier and its reference directory.
2. **Subtype reference directories** — `references/{subtype}/` contains all syntax, examples, and conventions for that subtype.
3. **Explicit load instruction** — The skill MUST instruct the agent to "read ALL files from `references/{subtype}/`" before proceeding.

Skills using this pattern: `diagram` (subtypes: `likec4-c4`, `likec4-dynamic`, `data-flow`) and `scaffold` (subtypes: `typescript`).
