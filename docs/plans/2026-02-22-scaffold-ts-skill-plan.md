# scaffold-ts Skill Creation - Implementation Plan

**Date:** 2026-02-22
**Status:** Plan - Ready for Review
**Beads Epic:** scaffold-ts-skill

## Goal

Create a `scaffold-ts` skill under the `scaffolder` plugin that scaffolds DDD TypeScript projects from Gherkin feature files, including hexagonal architecture, fitness tests (ArchUnitTS), Zod validation, and TDD workflow guidance.

## Acceptance Criteria

- [ ] `plugins/scaffolder/skills/scaffold-ts/SKILL.md` exists with correct scaffolder frontmatter
- [ ] SKILL.md is under 300 lines
- [ ] References files exist for fitness test templates and code templates
- [ ] Frontmatter follows scaffolder convention (name, description, license, compatibility, metadata, allowed-tools)
- [ ] `allowed-tools` includes `Read Glob Write Bash` (Bash needed for vitest, tsc, biome)
- [ ] All code examples use TypeScript with strict mode conventions
- [ ] Skill content accurately represents the user's definition

## Files to Create

- `plugins/scaffolder/skills/scaffold-ts/SKILL.md` — Main skill (core workflow, derivation guide, architecture rules, naming, verification)
- `plugins/scaffolder/skills/scaffold-ts/references/fitness-tests.md` — ArchUnitTS fitness test templates (architecture, naming, complexity, coupling)
- `plugins/scaffolder/skills/scaffold-ts/references/code-templates.md` — Shared kernel contracts, domain event patterns, Zod validation patterns

## Files to Modify

None — all new files.

## Content Split Strategy

The user's definition is ~165 lines. With frontmatter, it fits under 300 lines. However, extracting template-heavy sections to `references/` follows the established scaffolder pattern (adr, data-flow, likec4-c4) and improves maintainability.

**Keep in SKILL.md (~150 lines with frontmatter):**
- Derivation guide (core workflow — must be immediately visible)
- Project structure diagram
- Architectural rules
- TDD workflow
- Naming conventions table
- TypeScript compiler constraints
- Verification steps
- Links to references

**Extract to `references/fitness-tests.md` (~50 lines):**
- All four fitness test file specifications (architecture, naming, complexity, coupling)
- ArchUnitTS-specific details (allowEmptyTests, LCOM96b, coupling factor)

**Extract to `references/code-templates.md` (~40 lines):**
- Shared kernel EventBus/DomainEvent type definitions
- Domain event union pattern
- Zod input validation pattern with error mapping

## Implementation Phases

### Phase 1: Create SKILL.md

**Goal:** Create the main skill file with scaffolder frontmatter and core content.

**Tasks:**
1. Create directory `plugins/scaffolder/skills/scaffold-ts/`
2. Write SKILL.md with scaffolder frontmatter (name, description, license, compatibility, metadata with triggers, allowed-tools)
3. Include: derivation guide, project structure, architectural rules, TDD workflow, naming conventions, TS compiler constraints, verification
4. Add reference links to fitness-tests.md and code-templates.md
5. Verify under 300 lines

#### Agent Context
- **Files to create:** `plugins/scaffolder/skills/scaffold-ts/SKILL.md`
- **Reference files to read:** `plugins/scaffolder/skills/adr/SKILL.md` (frontmatter pattern), `plugins/scaffolder/skills/hexagonal-architecture/SKILL.md` (architecture skill pattern)
- **Acceptance gate:** File exists, has correct frontmatter, is under 300 lines, contains all core sections
- **Architectural constraints:** Must follow scaffolder frontmatter convention exactly; triggers should cover "scaffold typescript", "scaffold ts", "DDD typescript", "scaffold project"

---

### Phase 2: Create References

**Goal:** Create reference files for fitness test templates and code templates.

**Tasks:**
1. Create `references/fitness-tests.md` with all four fitness test specifications
2. Create `references/code-templates.md` with shared kernel, domain events, and Zod patterns

#### Agent Context
- **Files to create:** `plugins/scaffolder/skills/scaffold-ts/references/fitness-tests.md`, `plugins/scaffolder/skills/scaffold-ts/references/code-templates.md`
- **Files to read:** SKILL.md (for consistency), user's original definition (for fitness test and code template content)
- **Acceptance gate:** Both files exist; fitness-tests.md covers all 4 test files (architecture, naming, complexity, coupling); code-templates.md covers shared kernel, domain events, and Zod patterns
- **Architectural constraints:** Content must match user's original definition; no invented behavior

---

### Phase 3: Verification

**Goal:** Verify the complete skill structure is correct.

**Tasks:**
1. Verify SKILL.md is under 300 lines
2. Verify frontmatter matches scaffolder convention
3. Verify all reference links resolve
4. Verify no content was lost from user's original definition

#### Agent Context
- **Files to read:** All files in `plugins/scaffolder/skills/scaffold-ts/`
- **Acceptance gate:** Line count < 300; frontmatter valid; all links resolve; all user-defined content present across SKILL.md + references

## Constraints & Considerations

### Architectural
- Must follow scaffolder plugin conventions (frontmatter format, allowed-tools, references/ pattern)
- `allowed-tools: Read Glob Write Bash` — Bash is needed for vitest, tsc, biome commands unlike other scaffolder skills that use only `Read Glob Write`

### Content
- User's definition is the source of truth — no invented behavior or rules
- Fitness tests use `archunit` npm package (ArchUnitTS) with `allowEmptyTests: true`
- Bun is the runtime (bunx vitest, bun add zod)
- Overlap with hexagonal-architecture skill is acceptable — scaffold-ts is more opinionated and TypeScript-specific

## Out of Scope

- HTTP/API layer scaffolding (skill focuses on domain + application layers)
- Database adapter scaffolding (only in-memory adapters)
- CI/CD configuration
- Package.json / tsconfig.json generation (assumed to exist)

## Approval Checklist

- [x] All files to create listed
- [x] Implementation phases have clear boundaries
- [x] Each phase has an Agent Context block
- [x] Acceptance criteria are testable
- [x] Constraints documented
- [x] Out of scope items noted

## Next Steps

After review and approval:
1. Run `/craft` to execute — dispatches agents from beads issues
2. Each phase creates markdown content (no TDD — this is content, not code)
3. If interrupted, `/craft` picks up where it left off via `beads:ready`
