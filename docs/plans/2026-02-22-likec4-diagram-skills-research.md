# Research: LikeC4 Diagram Skills for Craft Plugin

**Date:** 2026-02-22
**Topic:** Creating skills for LikeC4 C4 diagrams, data flow diagrams, and workload flow diagrams

---

## 1. Key Question: Data Flow vs. Workload Flow — Are They the Same?

**No.** They are distinct diagram families with different purposes, audiences, and notation.

| Dimension | Data Flow Diagram (DFD) | Workload Flow Diagram |
|---|---|---|
| Primary question | "Where does data transform and move?" | "In what order do services interact for this request?" |
| Time-ordered? | No (topology only) | Yes (strict temporal ordering) |
| Core elements | Processes, Data Stores, External Entities, Data Flows | Participants, Ordered Messages, Lifelines |
| Scenario-specific? | No (always-true data topology) | Yes (one use case at a time) |
| Origin | Structured analysis (Yourdon/DeMarco, 1970s) | UML sequence diagrams / runtime tracing |
| Primary use case | Requirements analysis, threat modeling (STRIDE) | Design review, debugging, incident post-mortems |

**A workload flow diagram IS effectively a C4 dynamic diagram** — both show temporal, scenario-specific service interactions. LikeC4 supports this natively via `dynamic view`.

**A DFD is NOT a C4 diagram type.** LikeC4 has no native DFD notation (processes, data stores, Yourdon/Gane-Sarson symbols). It could be approximated with custom element kinds, but this would be non-standard.

---

## 2. LikeC4 Tool Overview

LikeC4 is an open-source architecture-as-code DSL (`.likec4` / `.c4` files) inspired by C4 Model and Structurizr DSL. All files in a project merge into one unified model.

**Key differentiators from Structurizr:**
- Fully custom element kinds (not locked to Person/System/Container/Component)
- No enforced C4 level hierarchy — views are flexible projections via predicates
- Local CLI dev server, static site export, VS Code live preview
- Export to PNG, Mermaid, DrawIO, PlantUML, D2, Dot, JSON
- Native MCP server integration for AI workflows

**DSL Structure — four top-level blocks:**

```
specification { ... }   // Define element/relationship kinds
model { ... }           // Architecture elements and relationships
views { ... }           // Visualizations (predicates select what to show)
global { ... }          // Shared style predicates
```

**View types supported:**

| View Type | Keyword | Purpose | Maps To |
|---|---|---|---|
| Model view | `view` / `view of X` | Structural — "what is where" | C4 Context/Container/Component |
| Dynamic view | `dynamic view` | Temporal flow for one use case | C4 Dynamic / Sequence diagram |
| Deployment view | `deployment view` | Infrastructure/runtime topology | C4 Deployment diagram |
| Generated views | (auto) | Relationship browser/decomposition | Interactive exploration |

**Dynamic view syntax (workload flows):**

```likec4
dynamic view orderFulfillment {
  title 'Order Fulfillment Flow'
  customer -> webApp 'submits order'
  webApp -> orderService 'POST /orders'
  parallel {
    orderService -> inventory 'reserve items'
    orderService -> payment 'charge card'
  }
  orderService -> notificationSvc 'send receipt'
  webApp <- orderService 'order confirmation'   // reverse = response
}
```

Supports `parallel { }` blocks, `navigateTo` for linking views, Markdown `notes`, and a `sequence` rendering variant for classic sequence diagram layout.

**Deployment model syntax:**

```likec4
deployment {
  environment prod {
    zone eu {
      instanceOf backend.api
      db = instanceOf backend.db
    }
  }
}
```

**Tooling:** VS Code extension (`likec4.likec4`), CLI (`npx likec4 serve/build/export`), Neovim plugin, JetBrains plugin.

---

## 3. Existing Skill Patterns in the Craft Repo

**No diagram-generation skills exist yet.** This would be the first.

**Plugin structure:**
- `plugins/scaffolder/skills/` — architecture skills (`hexagonal-architecture`, `adr`)
- `plugins/crafter/skills/` — workflow skills (`tdd`, `research`, `draft`, `craft`, etc.)

**Skill conventions (from codebase exploration):**
- Each skill = directory with `SKILL.md` + optional `references/` subdirectory
- `SKILL.md` must stay under 300 lines; overflow goes to `references/*.md`
- YAML frontmatter: `name`, `description`, `triggers`, `allowed-tools` (space-separated)
- Architecture skills use `allowed-tools: Read Glob Write`
- Existing skills use ASCII art for diagrams, not DSL code
- No `skill-creator` skill exists in the repo despite being referenced in CLAUDE.md

**Frontmatter pattern (scaffolder):**

```yaml
---
name: skill-name
description: One sentence with "Use when..." trigger guidance.
license: MIT
compatibility: Claude Code plugin
metadata:
  author: eric-olson
  version: "1.0.0"
  workflow: architecture
  triggers:
    - "trigger phrase 1"
    - "trigger phrase 2"
allowed-tools: Read Glob Write
---
```

---

## 4. Proposed Skill Architecture

### Option A: Three Separate Skills (Recommended)

| Skill | Directory | Purpose | LikeC4 Feature Used |
|---|---|---|---|
| `likec4-c4` | `plugins/scaffolder/skills/likec4-c4/` | Structural C4 diagrams (Context, Container, Component) | `view`, `view of`, predicates |
| `likec4-dynamic` | `plugins/scaffolder/skills/likec4-dynamic/` | End-to-end workload/request flows | `dynamic view`, parallel blocks, sequence variant |
| `data-flow` | `plugins/scaffolder/skills/data-flow/` | Traditional DFDs (not LikeC4) | Mermaid flowchart or ASCII — LikeC4 cannot do DFDs natively |

**Rationale:** C4 structural vs. dynamic views have different workflows and mental models. DFDs are a completely different diagram family that LikeC4 doesn't natively support.

### Option B: Two Skills (LikeC4 unified + DFD separate)

| Skill | Directory | Purpose |
|---|---|---|
| `likec4` | `plugins/scaffolder/skills/likec4/` | All LikeC4 diagram types (structural, dynamic, deployment) |
| `data-flow` | `plugins/scaffolder/skills/data-flow/` | Traditional DFDs using Mermaid or ASCII |

**Rationale:** Since all LikeC4 views share the same model, a unified skill keeps the model coherent. Risk: SKILL.md may exceed 300-line limit without heavy use of `references/`.

### Option C: Two Skills (LikeC4 C4 + LikeC4 Dynamic/Flow)

Drop the DFD skill entirely. Use LikeC4 dynamic views for data flow concerns, accepting the mismatch with traditional DFD notation.

---

## 5. Open Questions

1. **DFD tooling choice:** If we create a DFD skill, should it use Mermaid flowchart notation, ASCII art, or something else? LikeC4 can't do DFDs natively.
2. **Skill plugin placement:** Should LikeC4 skills go under `scaffolder` (architecture) or a new plugin (e.g., `diagrammer`)?
3. **Reference material volume:** LikeC4 DSL syntax examples will need significant `references/` content — how many reference files are acceptable?
4. **Deployment views:** Should the C4 skill include deployment views, or should that be a separate skill?
5. **Model reuse across views:** Should the skill workflow guide users to build one unified `.c4` model file set, or treat each diagram as standalone?

---

## 6. Key Constraints

- **SKILL.md must be under 300 lines** — LikeC4 DSL syntax examples must go in `references/`
- **LikeC4 dynamic view limitations:** Sequence variant only supports leaf elements; no nested parallel blocks; no BPMN-style swimlanes
- **DFD is not C4:** Any DFD skill would be a different tool/notation, not LikeC4
- **No existing diagram skill precedent** in the repo — this is the first diagram-generation workflow

---

## Sources

| Source | Confidence | Key Finding |
|---|---|---|
| LikeC4 GitHub + docs (likec4.dev) | High | DSL syntax, view types, dynamic view support |
| Structurizr DSL docs | High | C4 dynamic diagram definition and scope rules |
| C4 model (c4model.com) | High | C4 level definitions, dynamic diagram as official type |
| Mermaid sequence diagram docs | High | Sequence diagram notation elements |
| Codebase exploration (4 agents) | High | Skill authoring patterns, frontmatter, no existing C4 skills |
| DFD literature (multiple sources, many 404s) | Medium | DFD notation standards, DFD vs sequence distinction |
