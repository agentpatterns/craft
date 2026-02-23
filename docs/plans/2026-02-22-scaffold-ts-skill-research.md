# scaffold-ts Skill Creation - Research

**Date:** 2026-02-22
**Status:** Research Complete
**Depth:** Quick

## Summary

Creating a `scaffold-ts` skill under the `scaffolder` plugin requires following the established scaffolder frontmatter convention (name, description, license, compatibility, metadata with triggers, allowed-tools) and keeping SKILL.md under 300 lines. The skill definition provided by the user is well-structured but at ~280 lines will need careful editing to fit the limit. The fitness test section uses the `archunit` npm package (ArchUnitTS) which supports dependency direction, naming conventions, complexity metrics (LCOM96b), coupling metrics, and `allowEmptyTests`. The primary remaining concern is managing the 300-line SKILL.md limit.

## Relevant Files

### Plugin Registry
- `.claude-plugin/marketplace.json` — Plugin registry; `scaffolder` plugin declared at `./plugins/scaffolder`, version 1.0.0

### Scaffolder Plugin Skills (Existing)
- `plugins/scaffolder/skills/hexagonal-architecture/SKILL.md` — Closest existing skill (architecture patterns, DDD-adjacent); 99 lines, uses full scaffolder frontmatter
- `plugins/scaffolder/skills/adr/SKILL.md` — ADR skill with references/ (template, philosophy, comparison)
- `plugins/scaffolder/skills/data-flow/SKILL.md` — DFD skill with references/ (notation, examples)
- `plugins/scaffolder/skills/likec4-c4/SKILL.md` — C4 diagram skill with references/ (DSL syntax, style guide, examples)
- `plugins/scaffolder/skills/README.md` — Plugin readme

### Crafter Skills (Reference Patterns)
- `plugins/crafter/skills/tdd/SKILL.md` — TDD skill; relevant since scaffold-ts includes TDD workflow section
- `plugins/crafter/skills/research/SKILL.md` — Example of skill with subagent dispatch patterns

## Existing Patterns

### Pattern 1: Scaffolder Frontmatter Convention
**Used in:** All scaffolder skills (hexagonal-architecture, adr, data-flow, likec4-c4, likec4-dynamic)
**How it works:** Full YAML frontmatter with `name`, `description`, `license: MIT`, `compatibility: Claude Code plugin`, `metadata:` block (author, version, workflow, triggers), and `allowed-tools`
**Applicable to new feature:** Yes — must follow this exact format

### Pattern 2: References Subdirectory for Overflow
**Used in:** adr (template, philosophy, comparison), data-flow (notation, examples), likec4-c4 (DSL syntax, style guide, examples)
**How it works:** Content exceeding the 300-line SKILL.md cap goes to `references/*.md`, linked inline from SKILL.md
**Applicable to new feature:** Yes — the user's definition is ~280 lines raw; with frontmatter it will exceed 300 lines. Fitness test templates, code examples, and the naming conventions table should move to `references/`

### Pattern 3: Allowed Tools
**Used in:** All scaffolder skills use `Read Glob Write`
**How it works:** Space-separated tool list in frontmatter
**Applicable to new feature:** Yes — scaffold-ts needs `Read Glob Write Bash` (Bash for running `bunx vitest`, `bunx tsc`, `bunx @biomejs/biome`)

## Web & Pattern Research

### Finding 1: ArchUnitTS (npm: `archunit`)
**Sources:** User clarification
**Confidence:** High
**Summary:** The `archunit` npm package provides ArchUnit-style architectural fitness testing for TypeScript. It supports dependency direction checks, naming convention enforcement, complexity metrics (LCOM96b), coupling metrics (coupling factor, distance from main sequence), and the `allowEmptyTests` option. This is the correct package for all four fitness test files in the skill definition.
**Implication for this feature:** The fitness test section of the skill definition can be used as-is. Install via `bun add -D archunit`.

## Constraints & Considerations

- SKILL.md must be under 300 lines *(codebase convention)*
- User's raw definition is ~280 lines before frontmatter — will need to split content into `references/` *(codebase convention)*
- Must use scaffolder frontmatter format with `metadata.triggers` *(codebase pattern)*
- The `skill-creator` skill referenced in CLAUDE.md does not actually exist in the repo *(codebase gap)*
- Fitness tests use `archunit` npm package (ArchUnitTS) — supports all referenced features *(user clarification)*
- The skill uses Bun as runtime (`bunx vitest`, `bun add zod`) — this is a design choice from the user, not a constraint *(user definition)*

## Open Questions

1. **SKILL.md length management:** The definition is ~280 lines before adding frontmatter. To stay under 300 lines, content needs to move to `references/`. Candidates for extraction:
   - Fitness test generation section (~40 lines) → `references/fitness-tests.md`
   - Code examples (shared kernel, domain events, Zod) → `references/code-templates.md`
   - Naming conventions table → `references/naming-conventions.md`
   - TDD workflow section → could be omitted (overlaps with crafter's `/tdd` skill)

2. **Overlap with existing skills:** The hexagonal-architecture skill covers similar ground (domain/infrastructure separation, naming conventions, anti-patterns). Should scaffold-ts reference it or be standalone?

## Next Steps

Hand off to `/draft` with this research artifact.
