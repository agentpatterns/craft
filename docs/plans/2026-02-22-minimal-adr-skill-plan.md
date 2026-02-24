# Minimal ADR Skill — Implementation Plan

**Date:** 2026-02-22
**Status:** Plan - Ready for Review
**Beads Epic:** N/A (beads not initialized — using inline task graph)

## Goal

Create an `adr` skill for the scaffolder plugin that guides users through writing minimal markdown Architecture Decision Records, blending MADR's structured minimalism with Harmel-Law's advice-process awareness.

## Acceptance Criteria

- [ ] Skill directory exists at `plugins/scaffolder/skills/adr/`
- [ ] `SKILL.md` has valid YAML frontmatter (name, description, allowed-tools, triggers)
- [ ] `SKILL.md` is under 300 lines
- [ ] Workflow covers: decision filter → create file → fill template → seek advice → finalize
- [ ] Template uses 3 statuses (Proposed, Accepted, Superseded)
- [ ] ADR directory convention is `docs/decisions/`
- [ ] Advice section is recommended (not mandatory)
- [ ] Y-statement included as a warm-up/forcing function
- [ ] Anti-patterns section present
- [ ] `references/` subdirectory has supporting content (full template, philosophy summary, comparison table)
- [ ] `plugins/scaffolder/skills/README.md` updated with new skill entry
- [ ] Skill follows patterns from `hexagonal-architecture` skill (concise, directive, bullet-based)

## Files to Create

- `plugins/scaffolder/skills/adr/SKILL.md` — Main skill file (~120-150 lines)
- `plugins/scaffolder/skills/adr/references/template.md` — Full copy-pasteable ADR template with field guidance
- `plugins/scaffolder/skills/adr/references/philosophy.md` — Harmel-Law advice process summary and Y-statement examples
- `plugins/scaffolder/skills/adr/references/comparison.md` — Nygard vs MADR vs Harmel-Law comparison table

## Files to Modify

- `plugins/scaffolder/skills/README.md` — Add `adr` skill row to the table

## Implementation Phases

### Phase 1: Create SKILL.md

**Goal:** Write the main skill file with YAML frontmatter and core workflow.

**Content spec:**
- YAML frontmatter: name `adr`, description targeting ADR/architecture decision triggers, allowed-tools `Read Glob Write`, triggers list
- Decision filter: when to write an ADR (checklist from Harmel-Law signals)
- Workflow steps: (1) decide if needed, (2) create file with naming convention `NNNN-kebab-case-title.md` in `docs/decisions/`, (3) fill template section-by-section with Y-statement warm-up, (4) seek advice from stakeholders, (5) finalize status and commit
- Abbreviated template inline (context, decision, options, consequences, advice)
- Anti-patterns: retroactive ADRs, bikeshedding status, skipping options, no advice attribution
- When NOT to use: trivial decisions, decisions already made and shipped long ago

**Verification:**
- [ ] Under 300 lines
- [ ] All workflow steps present
- [ ] Follows hexagonal-architecture skill patterns (concise, directive, bullet-based)

#### Agent Context
- **Files to create:** `plugins/scaffolder/skills/adr/SKILL.md`
- **Files to read (patterns):** `plugins/scaffolder/skills/hexagonal-architecture/SKILL.md`
- **Acceptance gate:** File exists, valid YAML frontmatter, under 300 lines, all workflow sections present

---

### Phase 2: Create Reference Files

**Goal:** Write supporting content in `references/` subdirectory.

**Content spec:**

**template.md:**
- Full ADR template with field-by-field guidance comments
- Uses: ADR-NNNN numbering, Proposed/Accepted/Superseded statuses, `docs/decisions/` directory
- Advice section marked as "Recommended when multiple stakeholders affected"

**philosophy.md:**
- Harmel-Law's core thesis: architecture as distributed practice
- Advice process mechanics (seek advice, record with attribution, decide)
- Y-statement format and 2-3 examples
- Architecture Advisory Forum concept (brief)

**comparison.md:**
- Table comparing Nygard Original, MADR, and Harmel-Law across: sections, status values, decision authority, advice tracking, purpose

**Verification:**
- [ ] Template is copy-pasteable (no meta-commentary in the template itself)
- [ ] Philosophy summary is concise (under 80 lines)
- [ ] Comparison table is scannable

#### Agent Context
- **Files to create:** `plugins/scaffolder/skills/adr/references/template.md`, `plugins/scaffolder/skills/adr/references/philosophy.md`, `plugins/scaffolder/skills/adr/references/comparison.md`
- **Files to read (research):** `docs/plans/2026-02-22-minimal-adr-skill-research.md` (sections 2-4 contain source material)
- **Acceptance gate:** All three files exist, template is valid markdown, philosophy under 80 lines

---

### Phase 3: Update README and Verify

**Goal:** Register the new skill in the scaffolder README and verify the full skill is well-formed.

**Tasks:**
1. Add `adr` row to `plugins/scaffolder/skills/README.md` table
2. Verify all files exist and cross-references resolve

**Verification:**
- [ ] README table has adr entry with correct command and description
- [ ] All `references/` links from SKILL.md point to existing files
- [ ] All acceptance criteria from top of plan met

#### Agent Context
- **Files to modify:** `plugins/scaffolder/skills/README.md`
- **Files to read (verify):** `plugins/scaffolder/skills/adr/SKILL.md`, all `references/` files
- **Acceptance gate:** README updated, all cross-references valid, acceptance criteria checklist passes

## Constraints & Considerations

### Architectural
- Skill must fit within existing scaffolder plugin — no marketplace.json changes needed
- Follow SKILL.md conventions from CLAUDE.md (frontmatter structure, 300-line limit, references/ for supporting content)
- Match the style of hexagonal-architecture skill: concise, directive, bullet-based, minimal prose

### Content
- Template blends MADR structure with Harmel-Law's advice section
- Status vocabulary: Proposed, Accepted, Superseded (3 values only)
- Directory convention: `docs/decisions/`
- Advice section: recommended, not mandatory
- Tool-agnostic — describe the markdown format, don't prescribe adr-tools or log4brains

## Out of Scope

- CLI tooling integration (adr-tools, log4brains)
- ADR linting or validation automation
- Status lifecycle state machine enforcement
- ADR index/table of contents generation
- Integration with crafter plugin workflows

## Approval Checklist

Before implementing, verify:
- [ ] All files to create/modify listed
- [ ] Implementation phases have clear boundaries
- [ ] Each phase has an Agent Context block
- [ ] Content specs are behavioral descriptions (what to write, not verbatim content)
- [ ] Acceptance criteria are testable
- [ ] Constraints documented
- [ ] Out of scope items noted

## Inline Task Graph (beads unavailable)

### P1: Create SKILL.md [no-test] [no blockers]
- **Agent Context:**
  - **Files to create:** `plugins/scaffolder/skills/adr/SKILL.md`
  - **Files to read (patterns):** `plugins/scaffolder/skills/hexagonal-architecture/SKILL.md`
  - **Content spec:** Write the main skill file with YAML frontmatter (name: `adr`, description targeting ADR/architecture decision triggers, allowed-tools: `Read Glob Write`, triggers list). Include: decision filter checklist (Harmel-Law signals), 5-step workflow (decide → create → fill → advise → finalize), abbreviated template inline, naming convention (`NNNN-kebab-case-title.md` in `docs/decisions/`), Y-statement warm-up, anti-patterns, when NOT to use. Style: concise, directive, bullet-based per hexagonal-architecture skill.
  - **Acceptance gate:** File exists, valid YAML frontmatter, under 300 lines, all workflow sections present

### P2: Create Reference Files [no-test] [blocked-by: P1]
- **Agent Context:**
  - **Files to create:** `plugins/scaffolder/skills/adr/references/template.md`, `plugins/scaffolder/skills/adr/references/philosophy.md`, `plugins/scaffolder/skills/adr/references/comparison.md`
  - **Files to read (research):** `docs/plans/2026-02-22-minimal-adr-skill-research.md` (sections 2-4)
  - **Content spec:**
    - **template.md:** Full copy-pasteable ADR template with field-by-field guidance. ADR-NNNN numbering, Proposed/Accepted/Superseded statuses, `docs/decisions/` directory. Advice section marked "Recommended when multiple stakeholders affected."
    - **philosophy.md:** Harmel-Law's core thesis (architecture as distributed practice), advice process mechanics, Y-statement format with 2-3 examples, Architecture Advisory Forum concept. Under 80 lines.
    - **comparison.md:** Table comparing Nygard Original, MADR, and Harmel-Law across: sections, status values, decision authority, advice tracking, purpose.
  - **Acceptance gate:** All three files exist, template is valid copy-pasteable markdown, philosophy under 80 lines, comparison table is scannable

### P3: Update README and Verify [no-test] [blocked-by: P2]
- **Agent Context:**
  - **Files to modify:** `plugins/scaffolder/skills/README.md`
  - **Files to read (verify):** `plugins/scaffolder/skills/adr/SKILL.md`, all `references/` files
  - **Content spec:** Add `adr` row to README table matching existing format: `| [adr](adr/) | /adr | Guides writing minimal Architecture Decision Records with advice-process awareness |`
  - **Acceptance gate:** README updated, all cross-references from SKILL.md to references/ resolve, all acceptance criteria from plan met

## Next Steps

After human review and approval:
1. Run `/craft` to execute — dispatches agents from inline task graph
2. Each phase creates markdown files per the content specs
3. Phase order: P1 (SKILL.md) → P2 (references/) → P3 (README + verify)
