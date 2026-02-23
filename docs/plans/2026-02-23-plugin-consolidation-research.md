# Plugin Consolidation — Research

**Date:** 2026-02-23
**Status:** Research Complete
**Depth:** Standard

## Summary

The craft marketplace currently declares two plugins (`crafter` v1.3.0, `scaffolder` v1.1.0) with 14 total skills. The user wants to consolidate into a single `crafter` plugin and introduce a **subtype dispatch pattern** for diagram skills (3 → 1 with subtypes) and scaffold skills (1 → 1 with language subtypes). No subtype pattern exists in the codebase today — all reference loading is implicit via markdown links.

## Current State

### Plugin Registry

- **File:** `.claude-plugin/marketplace.json`
- Two plugins with `source` fields pointing to `./plugins/crafter` and `./plugins/scaffolder`
- Skills discovered by filesystem convention: `{source}/skills/{skill-name}/SKILL.md`
- No separate manifest per skill — frontmatter in SKILL.md is the only metadata

### Crafter Plugin (8 skills)

| Skill | Purpose | References |
|---|---|---|
| `research` | RPI Phase 1 — parallel codebase/web exploration | `agent-prompts.md`, `template.md` |
| `draft` | RPI Phase 2 — implementation plan from research | `template.md` |
| `craft` | RPI Phase 3 — beads-driven execution | `workflow-detail.md` |
| `tdd` | L3/L4 boundary-focused TDD | `boundary-testing.md`, `zombies.md` |
| `refactor` | Test-safe refactoring | `credits.md` |
| `reflect` | Post-session learning extraction | `agent-prompts.md`, `improvement-guide.md`, `template.md` |
| `tidy` | Audit agent-facing docs for staleness | `agent-prompts.md`, `claude-md-best-practices.md`, `report-template.md` |
| `pair` | Teaching-oriented pair programming | (none) |

### Scaffolder Plugin (6 skills)

| Skill | Purpose | References |
|---|---|---|
| `likec4-c4` | Structural C4 diagrams (LikeC4 DSL) | `dsl-syntax.md`, `view-examples.md`, `style-guide.md` |
| `likec4-dynamic` | Temporal flow diagrams (LikeC4 dynamic views) | `dsl-syntax.md`, `flow-examples.md` |
| `data-flow` | Data Flow Diagrams (Mermaid flowchart) | `dfd-notation.md`, `dfd-examples.md` |
| `scaffold-ts` | DDD TypeScript project scaffolding | `code-templates.md`, `fitness-tests.md` |
| `hexagonal-architecture` | Ports & adapters architecture guidance | `disclaimer.md` (placeholder) |
| `adr` | Architecture Decision Records | `template.md`, `philosophy.md`, `comparison.md` |

## Patterns Observed

### How References Are Loaded Today

1. **Inline prose links** — `see [file](references/file.md)` embedded in workflow text
2. **References section** — bibliography-style list at bottom of SKILL.md with descriptions
3. **Template loading** — explicit "Use the [template](references/template.md)" instructions
4. **Cross-skill links** — `likec4-dynamic` links to `../likec4-c4/SKILL.md` (only instance)

**No conditional/subtype dispatch exists.** All references are available to the agent simultaneously; selection relies on agent judgment, not explicit branching.

### Frontmatter Schema Variants

- **Crafter skills:** top-level `triggers:` list (except `tdd` which nests under `metadata:`)
- **Scaffolder skills:** extended format with `license`, `compatibility`, `metadata.author/version/workflow`

### Diagram Skills Share Common DNA

All three diagram skills follow the same workflow:
1. Clarify scope → 2. Check for existing files → 3. Generate diagram → 4. Validate → 5. Review

They already have a routing table between each other:
- "What exists?" → `likec4-c4`
- "In what order?" → `likec4-dynamic`
- "Where does data go?" → `data-flow`

## Proposed Subtype Dispatch Pattern

The key design decision: how does a unified skill know which subtype content to load?

### Recommended: Explicit Dispatch Table in SKILL.md

```markdown
## Diagram Type Selection

| User Intent | Subtype | Load |
|---|---|---|
| C4, architecture, system/container/component diagram | `likec4-c4` | `references/likec4-c4/` |
| Sequence, flow, temporal, service interaction | `likec4-dynamic` | `references/likec4-dynamic/` |
| Data flow, DFD, data movement/transformation | `data-flow` | `references/data-flow/` |

**After selecting the subtype**, read ALL files from the corresponding `references/{subtype}/` directory. These provide the DSL syntax, examples, and style guidance needed for generation.
```

The SKILL.md contains the shared workflow (clarify → check existing → generate → validate → review) and the dispatch table. Each subtype's references directory contains the tool-specific content.

### Proposed Directory Structure

```
plugins/crafter/skills/
├── (existing 8 skills unchanged)
├── diagram/
│   ├── SKILL.md                    # Shared workflow + dispatch table
│   └── references/
│       ├── likec4-c4/
│       │   ├── dsl-syntax.md
│       │   ├── view-examples.md
│       │   └── style-guide.md
│       ├── likec4-dynamic/
│       │   ├── dsl-syntax.md
│       │   └── flow-examples.md
│       └── data-flow/
│           ├── dfd-notation.md
│           └── dfd-examples.md
├── scaffold/
│   ├── SKILL.md                    # Shared workflow + language dispatch
│   └── references/
│       └── typescript/
│           ├── code-templates.md
│           └── fitness-tests.md
├── hexagonal-architecture/         # Stays as-is (architecture pattern, not a diagram)
│   ├── SKILL.md
│   └── references/
│       └── disclaimer.md
└── adr/                            # Stays as-is (decision records, not a diagram)
    ├── SKILL.md
    └── references/
        ├── template.md
        ├── philosophy.md
        └── comparison.md
```

### Marketplace Config Change

```json
{
  "name": "craft",
  "plugins": [
    {
      "name": "crafter",
      "source": "./plugins/crafter",
      "version": "2.0.0"
    }
  ]
}
```

Remove the `scaffolder` plugin entry entirely. Delete `plugins/scaffolder/`.

## Design Decisions

### What Merges

| Current | Becomes | Rationale |
|---|---|---|
| `likec4-c4` + `likec4-dynamic` + `data-flow` | `diagram` (one skill, 3 subtypes) | Same workflow, different DSL tooling |
| `scaffold-ts` | `scaffold` (one skill, typescript subtype) | Language is the variable; workflow is shared |
| `hexagonal-architecture` | Stays as `hexagonal-architecture` | Architecture pattern, not a scaffold or diagram |
| `adr` | Stays as `adr` | Decision records, orthogonal to both |

### Trigger Consolidation

**Diagram skill triggers** (union of all three):
`C4 diagram`, `architecture diagram`, `LikeC4`, `system diagram`, `container diagram`, `component diagram`, `deployment diagram`, `dynamic view`, `sequence diagram`, `workload flow`, `request flow`, `data flow diagram`, `DFD`, `data flow`, `diagram`

**Scaffold skill triggers** (expanded from scaffold-ts):
`scaffold`, `scaffold typescript`, `scaffold ts`, `DDD typescript`, `scaffold project`, `domain-driven`

### The Subtype Loading Contract

The SKILL.md must give the agent an explicit instruction pattern:

```markdown
**REQUIRED:** After selecting the subtype from the table above, use the Read tool to load
ALL markdown files from `references/{subtype}/`. These files are your complete reference
for generating the artifact. Do not proceed without reading them.
```

This makes the conditional loading explicit rather than relying on agent judgment.

## Open Questions

1. **Scaffold shared workflow:** The current `scaffold-ts` SKILL.md is heavily TypeScript-specific (Bun, Biome, Vitest, ArchUnitTS). How much of the workflow is genuinely language-agnostic vs. TypeScript-specific? The shared SKILL.md will need to abstract the workflow while the typescript subtype handles tool choices.

2. **LikeC4 model dependency:** `likec4-dynamic` requires an existing `model { }` from `likec4-c4`. With both as subtypes of `diagram`, the shared SKILL.md needs a prerequisite check that routes to the c4 subtype first if no model exists.

3. **Frontmatter schema normalization:** Should all skills adopt the same frontmatter format? The crafter skills use minimal format; scaffolder skills use extended. The merge is a natural cleanup point.

4. **Version bump:** Going from two plugins to one is a breaking change for anyone who installed `scaffolder` separately. The marketplace version should bump to 2.0.0.

## Constraints

- SKILL.md must stay under 300 lines (project guideline)
- Reference files are standalone documents (no back-references to parent)
- Plugin discovery is purely filesystem-based — `{source}/skills/{name}/SKILL.md`
- Skills in the `crafter` plugin that already exist (research, draft, craft, etc.) should not be modified
