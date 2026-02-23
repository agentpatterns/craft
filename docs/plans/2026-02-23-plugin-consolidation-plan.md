# Plugin Consolidation — Implementation Plan

**Date:** 2026-02-23
**Status:** Plan - Ready for Review
**Beads Epic:** Plugin Consolidation

## Goal

Consolidate the two-plugin marketplace (`crafter` + `scaffolder`) into a single `crafter` plugin by merging diagram skills (3 → 1 with subtype dispatch), scaffold skills (1 → 1 with language subtypes), and migrating standalone skills (`adr`, `hexagonal-architecture`). This simplifies installation, eliminates cross-plugin references, and establishes a subtype dispatch pattern for future skill families.

## Acceptance Criteria

- [ ] `marketplace.json` declares only `crafter` plugin at version 2.0.0
- [ ] `diagram` skill exists with dispatch table routing to 3 subtypes (`likec4-c4`, `likec4-dynamic`, `data-flow`)
- [ ] `scaffold` skill exists with dispatch table routing to `typescript` subtype
- [ ] `hexagonal-architecture` and `adr` skills exist under `plugins/crafter/skills/` with normalized frontmatter
- [ ] `plugins/scaffolder/` directory is deleted
- [ ] `CLAUDE.md` reflects the consolidated structure
- [ ] All skills have consistent crafter-style frontmatter (no `license`, `compatibility`, `metadata.author/version/workflow` nesting)
- [ ] Marketplace version is 2.0.0; plugin version is 2.0.0

## Files to Create

- `plugins/crafter/skills/diagram/SKILL.md` — unified diagram skill with dispatch table and shared workflow
- `plugins/crafter/skills/diagram/references/likec4-c4/dsl-syntax.md` — copied from scaffolder
- `plugins/crafter/skills/diagram/references/likec4-c4/view-examples.md` — copied
- `plugins/crafter/skills/diagram/references/likec4-c4/style-guide.md` — copied
- `plugins/crafter/skills/diagram/references/likec4-dynamic/dsl-syntax.md` — copied
- `plugins/crafter/skills/diagram/references/likec4-dynamic/flow-examples.md` — copied
- `plugins/crafter/skills/diagram/references/data-flow/dfd-notation.md` — copied
- `plugins/crafter/skills/diagram/references/data-flow/dfd-examples.md` — copied
- `plugins/crafter/skills/scaffold/SKILL.md` — unified scaffold skill with language dispatch
- `plugins/crafter/skills/scaffold/references/typescript/code-templates.md` — copied
- `plugins/crafter/skills/scaffold/references/typescript/fitness-tests.md` — copied

## Files to Modify

- `.claude-plugin/marketplace.json` — remove scaffolder entry, bump versions to 2.0.0
- `CLAUDE.md` — update project structure section to reflect consolidation

## Files to Move (copy then delete source)

- `plugins/scaffolder/skills/hexagonal-architecture/` → `plugins/crafter/skills/hexagonal-architecture/`
- `plugins/scaffolder/skills/adr/` → `plugins/crafter/skills/adr/`

## Files to Delete

- `plugins/scaffolder/` — entire directory after all content migrated

## Implementation Phases

### Phase 1: Create Diagram Skill [no-test]
**Goal:** Author the unified `diagram` SKILL.md with subtype dispatch table and shared workflow, copying reference files into subtype directories.

**Tasks:**
1. Create directory structure `plugins/crafter/skills/diagram/references/{likec4-c4,likec4-dynamic,data-flow}/`
2. Copy all reference files from the three scaffolder diagram skills into the corresponding subtype directories
3. Author `diagram/SKILL.md` with: normalized crafter-style frontmatter, union of all diagram triggers, view type decision tree, subtype dispatch table, shared 6-step workflow, explicit "read ALL files from `references/{subtype}/`" instruction
4. Keep SKILL.md under 300 lines

**Verification:**
- [ ] `diagram/SKILL.md` exists with correct frontmatter
- [ ] All 8 reference files present in subtype directories
- [ ] SKILL.md under 300 lines

#### Agent Context
- **Files to create:** `plugins/crafter/skills/diagram/SKILL.md`, 8 reference files in subtype dirs
- **Files to read:** `plugins/scaffolder/skills/likec4-c4/SKILL.md`, `plugins/scaffolder/skills/likec4-dynamic/SKILL.md`, `plugins/scaffolder/skills/data-flow/SKILL.md`, all their reference files
- **Acceptance gate:** SKILL.md has frontmatter with `name: diagram`, dispatch table with 3 subtypes, shared workflow; all reference files copied; line count ≤ 300

---

### Phase 2: Create Scaffold Skill [no-test]
**Goal:** Author the unified `scaffold` SKILL.md with language dispatch table, copying TypeScript reference files.

**Tasks:**
1. Create directory structure `plugins/crafter/skills/scaffold/references/typescript/`
2. Copy reference files from `scaffold-ts`
3. Author `scaffold/SKILL.md` with: normalized frontmatter, expanded triggers, language dispatch table, shared workflow abstracted from TypeScript-specific details, explicit subtype loading instruction
4. Keep SKILL.md under 300 lines

**Verification:**
- [ ] `scaffold/SKILL.md` exists with correct frontmatter
- [ ] 2 reference files present in `typescript/` directory
- [ ] SKILL.md under 300 lines

#### Agent Context
- **Files to create:** `plugins/crafter/skills/scaffold/SKILL.md`, 2 reference files
- **Files to read:** `plugins/scaffolder/skills/scaffold-ts/SKILL.md`, its reference files
- **Acceptance gate:** SKILL.md has frontmatter with `name: scaffold`, dispatch table with typescript subtype, shared workflow; reference files copied; line count ≤ 300

---

### Phase 3: Migrate Standalone Skills [no-test]
**Goal:** Move `hexagonal-architecture` and `adr` from scaffolder to crafter, normalizing frontmatter to crafter style.

**Tasks:**
1. Copy `plugins/scaffolder/skills/hexagonal-architecture/` → `plugins/crafter/skills/hexagonal-architecture/`
2. Copy `plugins/scaffolder/skills/adr/` → `plugins/crafter/skills/adr/`
3. Normalize frontmatter in both SKILL.md files: remove `license`, `compatibility`, `metadata.author/version/workflow` nesting; use flat crafter-style format (`name`, `description`, `triggers`, `allowed-tools`)
4. Content of SKILL.md body and reference files unchanged

**Verification:**
- [ ] Both skill directories exist under `plugins/crafter/skills/`
- [ ] Frontmatter normalized to crafter style
- [ ] All reference files present

#### Agent Context
- **Files to create:** `plugins/crafter/skills/hexagonal-architecture/SKILL.md` (modified frontmatter), `plugins/crafter/skills/adr/SKILL.md` (modified frontmatter), all reference files
- **Files to read:** source skills from `plugins/scaffolder/skills/`
- **Acceptance gate:** Skills exist under crafter with normalized frontmatter; reference files intact

---

### Phase 4: Update Config and Docs [no-test]
**Goal:** Update marketplace.json and CLAUDE.md to reflect the consolidated single-plugin structure.

**Tasks:**
1. Edit `.claude-plugin/marketplace.json`: remove scaffolder entry, set marketplace version to 2.0.0, set crafter plugin version to 2.0.0
2. Edit `CLAUDE.md`: update project structure section to list all skills under crafter (research, draft, craft, tdd, refactor, reflect, tidy, pair, diagram, scaffold, hexagonal-architecture, adr)

**Verification:**
- [ ] `marketplace.json` has single plugin entry at v2.0.0
- [ ] `CLAUDE.md` lists correct skill inventory

#### Agent Context
- **Files to modify:** `.claude-plugin/marketplace.json`, `CLAUDE.md`
- **Acceptance gate:** Only one plugin in marketplace.json at v2.0.0; CLAUDE.md skill list matches actual directory contents

---

### Phase 5: Delete Scaffolder Plugin [no-test]
**Goal:** Remove the scaffolder plugin directory now that all content has been migrated.

**Tasks:**
1. Verify all content migrated (compare file counts)
2. Delete `plugins/scaffolder/` directory

**Verification:**
- [ ] `plugins/scaffolder/` does not exist
- [ ] `plugins/crafter/skills/` contains all 12 skills

#### Agent Context
- **Commands to run:** `rm -rf plugins/scaffolder/`
- **Pre-check:** Verify `plugins/crafter/skills/` contains: tdd, craft, refactor, reflect, pair, draft, research, tidy, diagram, scaffold, hexagonal-architecture, adr (12 skills)
- **Acceptance gate:** scaffolder directory gone; 12 skill directories present under crafter

---

### Phase 6: Final Verification [no-test]
**Goal:** Verify the complete consolidation — all skills present, structure correct, no orphaned references.

**Tasks:**
1. List all skill directories under `plugins/crafter/skills/`
2. Verify each SKILL.md has valid frontmatter
3. Verify each referenced file exists
4. Confirm `marketplace.json` is valid JSON with correct structure
5. Confirm no `scaffolder` references remain in any file

**Verification:**
- [ ] 12 skills present
- [ ] All SKILL.md files have valid frontmatter
- [ ] All referenced files exist
- [ ] No broken cross-references
- [ ] All acceptance criteria met

#### Agent Context
- **Commands to run:** `ls plugins/crafter/skills/`, grep for orphaned scaffolder references
- **Acceptance gate:** All acceptance criteria from top of plan verified; no scaffolder references remain

## Constraints & Considerations

### Architectural
- SKILL.md must stay under 300 lines per project guideline
- Plugin discovery is filesystem-based: `{source}/skills/{name}/SKILL.md`
- Existing crafter skills (research, draft, craft, etc.) must not be modified
- Reference files are standalone — no back-references to parent SKILL.md

### Breaking Change
- Version 2.0.0 because anyone who installed `scaffolder` separately will need to reinstall via `crafter`
- The `diagram` skill replaces three separate skills — trigger overlap is intentional (union of all)

### Subtype Dispatch Contract
- SKILL.md must include explicit "read ALL files from `references/{subtype}/`" instruction
- Dispatch table in SKILL.md is the only routing mechanism — no metadata or code-based dispatch

## Out of Scope

- Adding new diagram subtypes beyond the existing three
- Adding new scaffold language subtypes beyond TypeScript
- Modifying the content of reference files (only location changes)
- Changing the shared workflow logic within merged skills beyond what's needed for dispatch
- GitHub Action updates for version bumping

## Approval Checklist

- [x] All files to create/modify listed
- [x] Implementation phases have clear boundaries
- [x] Each phase has an Agent Context block
- [x] Verification steps are concrete and observable
- [x] Acceptance criteria are testable
- [x] Constraints documented
- [x] Out of scope items noted

## Next Steps

After review and approval:
1. Run `/craft` to execute — dispatches agents from beads issues
2. Each phase is a no-test issue (content project, no application code)
3. If interrupted, `/craft` picks up where it left off via `beads:ready`
