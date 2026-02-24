# Plan: Enrich AGENTS.md with Anthropic Best Practices

**Date:** 2026-02-23
**Research:** `docs/plans/2026-02-23-enrich-agents-md-research.md`

## Goal

Enrich the project's AGENTS.md (contributor instructions) with high-value tips from Anthropic's official skill authoring and testing documentation, keeping the file concise and scannable.

## Acceptance Criteria

- [ ] AGENTS.md covers: description writing, extended frontmatter, body principles, skill patterns, testing methodology, pre-ship checklist
- [ ] No contradictions between AGENTS.md, CLAUDE.md, and docs/architecture.md
- [ ] AGENTS.md stays under 250 lines
- [ ] All new guidance is actionable (not theoretical)

## Implementation Phases

### Phase 1: Validate Enriched AGENTS.md [no-test]

The enriched file was written during research. Validate:

1. **Cross-reference with CLAUDE.md** — no contradictions on line limits, frontmatter format, or naming conventions
2. **Cross-reference with docs/architecture.md** — skill structure, RPI methodology references are consistent
3. **Verify all existing skills conform** — spot-check 2-3 skills against the new checklist guidance
4. **Check for redundancy** — if AGENTS.md duplicates CLAUDE.md content, link instead of repeating

#### Agent Context
- **Files to read:** `AGENTS.md`, `CLAUDE.md`, `docs/architecture.md`, 2-3 skill `SKILL.md` files
- **Gate:** No contradictions found, or contradictions resolved via edits
- **Constraints:** Do not modify CLAUDE.md or architecture.md — adjust AGENTS.md if conflicts exist

### Phase 2: Commit and Push [no-test]

Stage and commit:
- `AGENTS.md` (enriched)
- `docs/plans/2026-02-23-enrich-agents-md-research.md`
- `docs/plans/2026-02-23-enrich-agents-md-plan.md`

## Constraints

- This is a content-only project — no application code, no test suite
- AGENTS.md should complement (not duplicate) CLAUDE.md and architecture.md
- Keep the file scannable with tables and short sections

## Out of Scope

- Modifying existing skills to conform to new guidance
- Creating evaluation scenarios or test harnesses for skills
- Modifying CLAUDE.md or architecture.md

## Next Steps

Run `/craft` to execute, or since this is a 2-phase content task, proceed directly with validation and commit.
