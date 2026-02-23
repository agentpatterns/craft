# LikeC4 Diagram Skills — Implementation Plan

**Date:** 2026-02-22
**Status:** Plan - Ready for Review
**Research:** [2026-02-22-likec4-diagram-skills-research.md](2026-02-22-likec4-diagram-skills-research.md)

## Goal

Create three scaffolder skills for architecture diagramming: `likec4-c4` for structural C4 diagrams (including deployment), `likec4-dynamic` for temporal workload flow diagrams, and `data-flow` for traditional data flow diagrams using Mermaid. These are the first diagram-generation skills in the craft marketplace.

## Acceptance Criteria

- [ ] `likec4-c4` skill exists at `plugins/scaffolder/skills/likec4-c4/` with SKILL.md under 300 lines
- [ ] `likec4-dynamic` skill exists at `plugins/scaffolder/skills/likec4-dynamic/` with SKILL.md under 300 lines
- [ ] `data-flow` skill exists at `plugins/scaffolder/skills/data-flow/` with SKILL.md under 300 lines
- [ ] Each skill has correct YAML frontmatter (name, description, triggers, allowed-tools)
- [ ] LikeC4 DSL syntax examples are in `references/` subdirectories, not in SKILL.md
- [ ] Each skill follows the interactive workflow pattern (gather context → generate → review)
- [ ] Deployment views covered in `likec4-c4` skill
- [ ] Skills follow conventions from existing scaffolder skills (adr, hexagonal-architecture)

## Files to Create

### Skill 1: likec4-c4 (Structural C4 Diagrams)
- `plugins/scaffolder/skills/likec4-c4/SKILL.md` — Main skill: workflow for creating C4 Context, Container, Component, and Deployment views
- `plugins/scaffolder/skills/likec4-c4/references/dsl-syntax.md` — LikeC4 DSL specification block, element kinds, relationships, predicates
- `plugins/scaffolder/skills/likec4-c4/references/view-examples.md` — Example views: context, container, component, deployment
- `plugins/scaffolder/skills/likec4-c4/references/style-guide.md` — Styling predicates, colors, shapes, element customization

### Skill 2: likec4-dynamic (Workload Flow Diagrams)
- `plugins/scaffolder/skills/likec4-dynamic/SKILL.md` — Main skill: workflow for creating dynamic views showing temporal service interactions
- `plugins/scaffolder/skills/likec4-dynamic/references/dsl-syntax.md` — Dynamic view syntax, parallel blocks, sequence variant, navigateTo
- `plugins/scaffolder/skills/likec4-dynamic/references/flow-examples.md` — Example flows: request/response, parallel processing, error paths

### Skill 3: data-flow (Data Flow Diagrams)
- `plugins/scaffolder/skills/data-flow/SKILL.md` — Main skill: workflow for creating traditional DFDs using Mermaid flowchart notation
- `plugins/scaffolder/skills/data-flow/references/dfd-notation.md` — DFD notation guide: processes, data stores, external entities, data flows
- `plugins/scaffolder/skills/data-flow/references/dfd-examples.md` — Example DFDs at context and detailed levels

## Files to Modify

- None. All new files.

## Implementation Phases

### Phase 1: likec4-c4 Skill
**Goal:** Create the structural C4 diagram skill with LikeC4 DSL reference material

**Tasks:**
1. Create `references/dsl-syntax.md` — LikeC4 specification block, model syntax, element kinds, relationship syntax, predicates
2. Create `references/view-examples.md` — Complete examples for context, container, component, and deployment views
3. Create `references/style-guide.md` — Styling predicates, colors, shapes
4. Create `SKILL.md` — Interactive workflow: gather system context → choose view level → generate `.likec4` file → review and refine

**Verification:**
- [ ] SKILL.md under 300 lines
- [ ] Frontmatter matches scaffolder conventions (name, description, triggers, allowed-tools: Read Glob Write)
- [ ] Workflow covers all four view types (context, container, component, deployment)
- [ ] DSL examples are in references/, not SKILL.md
- [ ] All reference files linked from SKILL.md

#### Agent Context
- **Files to create:** `plugins/scaffolder/skills/likec4-c4/SKILL.md`, `plugins/scaffolder/skills/likec4-c4/references/dsl-syntax.md`, `plugins/scaffolder/skills/likec4-c4/references/view-examples.md`, `plugins/scaffolder/skills/likec4-c4/references/style-guide.md`
- **Files to read for conventions:** `plugins/scaffolder/skills/adr/SKILL.md`, `plugins/scaffolder/skills/hexagonal-architecture/SKILL.md`
- **Source material:** `docs/plans/2026-02-22-likec4-diagram-skills-research.md` (Section 2: LikeC4 Tool Overview)
- **Acceptance gate:** SKILL.md exists, is under 300 lines, has correct frontmatter, references all 3 reference files
- **Architectural constraints:** SKILL.md contains workflow and decision logic only; all DSL syntax examples go in references/

---

### Phase 2: likec4-dynamic Skill
**Goal:** Create the workload flow diagram skill using LikeC4 dynamic views

**Tasks:**
1. Create `references/dsl-syntax.md` — Dynamic view syntax, message ordering, parallel blocks, sequence variant, navigateTo
2. Create `references/flow-examples.md` — Example dynamic views for common patterns (request/response, parallel fan-out, error handling)
3. Create `SKILL.md` — Interactive workflow: identify scenario → list participants → map interactions → generate dynamic view → review

**Verification:**
- [ ] SKILL.md under 300 lines
- [ ] Frontmatter matches scaffolder conventions
- [ ] Workflow covers dynamic view features (parallel, sequence, navigateTo)
- [ ] Clear distinction from structural C4 skill documented
- [ ] Reference files linked from SKILL.md

#### Agent Context
- **Files to create:** `plugins/scaffolder/skills/likec4-dynamic/SKILL.md`, `plugins/scaffolder/skills/likec4-dynamic/references/dsl-syntax.md`, `plugins/scaffolder/skills/likec4-dynamic/references/flow-examples.md`
- **Files to read for conventions:** `plugins/scaffolder/skills/adr/SKILL.md`, `plugins/scaffolder/skills/likec4-c4/SKILL.md` (from Phase 1)
- **Source material:** `docs/plans/2026-02-22-likec4-diagram-skills-research.md` (Section 2: Dynamic view syntax)
- **Acceptance gate:** SKILL.md exists, is under 300 lines, has correct frontmatter, references all 2 reference files
- **Architectural constraints:** SKILL.md contains workflow only; DSL syntax in references/. Must not duplicate structural C4 content — link to likec4-c4 for shared model concepts.

---

### Phase 3: data-flow Skill
**Goal:** Create the traditional DFD skill using Mermaid flowchart notation

**Tasks:**
1. Create `references/dfd-notation.md` — DFD notation mapping to Mermaid: processes (rounded rect), data stores (cylinder/parallel lines), external entities (rectangle), data flows (arrows with labels)
2. Create `references/dfd-examples.md` — Context-level and detailed-level DFD examples in Mermaid
3. Create `SKILL.md` — Interactive workflow: identify system boundary → list external entities → map data stores → trace data flows → generate Mermaid DFD → review

**Verification:**
- [ ] SKILL.md under 300 lines
- [ ] Frontmatter matches scaffolder conventions
- [ ] Uses Mermaid flowchart notation (not LikeC4)
- [ ] Clear explanation of when DFD vs C4 vs dynamic views are appropriate
- [ ] Reference files linked from SKILL.md

#### Agent Context
- **Files to create:** `plugins/scaffolder/skills/data-flow/SKILL.md`, `plugins/scaffolder/skills/data-flow/references/dfd-notation.md`, `plugins/scaffolder/skills/data-flow/references/dfd-examples.md`
- **Files to read for conventions:** `plugins/scaffolder/skills/adr/SKILL.md`, `plugins/scaffolder/skills/likec4-c4/SKILL.md` (from Phase 1)
- **Source material:** `docs/plans/2026-02-22-likec4-diagram-skills-research.md` (Section 1: DFD vs Workload Flow comparison)
- **Acceptance gate:** SKILL.md exists, is under 300 lines, has correct frontmatter, references all 2 reference files
- **Architectural constraints:** Must use Mermaid, not LikeC4 (LikeC4 has no native DFD support). Include guidance on when DFD is the right choice vs C4 or dynamic views.

---

### Phase 4: Final Verification
**Goal:** Verify all three skills are complete, consistent, and follow conventions

**Tasks:**
1. Check all SKILL.md files are under 300 lines
2. Verify frontmatter consistency across all three skills
3. Confirm all reference files are linked
4. Verify no duplicate content across skills
5. Check that cross-references between skills are correct (e.g., data-flow references likec4 alternatives)

**Verification:**
- [ ] All acceptance criteria from top of plan met
- [ ] No SKILL.md exceeds 300 lines
- [ ] All reference files exist and are linked
- [ ] Consistent frontmatter format across all skills

#### Agent Context
- **Files to check:** All files created in Phases 1-3
- **Acceptance gate:** All acceptance criteria verified, all files exist and follow conventions

## Constraints & Considerations

### Architectural
- Each SKILL.md must stay under 300 lines — heavy DSL examples go in `references/`
- Skills go under `plugins/scaffolder/skills/` (architecture category)
- Follow existing frontmatter pattern: `allowed-tools: Read Glob Write`
- No code changes — this project is markdown-only content

### Content Quality
- LikeC4 DSL examples must be syntactically correct per LikeC4 documentation
- Mermaid DFD examples must render correctly in standard Mermaid renderers
- Each skill should clearly state when to use it vs the other diagram skills
- Workflows should be interactive (gather context from user before generating)

### Cross-Skill Coherence
- The two LikeC4 skills share the same model concepts — `likec4-dynamic` should reference `likec4-c4` for model/specification setup rather than duplicating
- `data-flow` should explain the DFD vs C4 distinction (from research Section 1)

## Out of Scope

- MCP server integration for LikeC4 (potential future skill)
- LikeC4 CLI commands/tooling setup (belongs in project CLAUDE.md, not skill)
- Updating `marketplace.json` (scaffolder plugin already exists; skills are auto-discovered)
- Structurizr DSL support (separate tool, separate skill if needed)
- Interactive diagram editing or live preview workflows

## Approval Checklist

Before implementing, verify:
- [ ] Three skills with clear boundaries (structural C4, dynamic flows, DFDs)
- [ ] All files to create listed with purpose
- [ ] Each phase has Agent Context with file paths and acceptance gates
- [ ] Deployment views covered in likec4-c4 (not separate)
- [ ] Mermaid chosen for DFD notation
- [ ] Under scaffolder plugin

## Next Steps

After review and approval:
1. Run `/craft` to execute — agents will create skill files phase by phase
2. Each phase creates one complete skill (SKILL.md + references/)
3. Phase 4 validates all three skills together
