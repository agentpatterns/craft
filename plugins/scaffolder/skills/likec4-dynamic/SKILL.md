---
name: likec4-dynamic
description: Creates workload flow diagrams showing temporal service interactions using LikeC4 dynamic views. Use when creating sequence diagrams, flow diagrams, request flow diagrams, workload flows, or when user mentions dynamic view, service interaction, or temporal flow.
license: MIT
compatibility: Claude Code plugin
metadata:
  author: eric-olson
  version: "1.0.0"
  workflow: architecture
  triggers:
    - "dynamic view"
    - "sequence diagram"
    - "workload flow"
    - "request flow"
    - "service interaction"
    - "temporal flow"
    - "dynamic diagram"
allowed-tools: Read Glob Write
---

# LikeC4 Dynamic Views — Workload Flow Diagrams

## When to Use This Skill

Use this skill when the user wants to show **how a specific scenario unfolds over time** — who calls whom, in what order, and what happens in parallel:

- "Show me how a login request flows through the system"
- "Create a sequence diagram for order checkout"
- "Diagram the request/response path from browser to database"
- "Map the concurrent fan-out to downstream services"

### Choosing the Right Skill

| Question being asked | Skill to use |
|---|---|
| "What exists and how is it connected?" (static structure) | `likec4-c4` |
| "In what order do services interact for this scenario?" (temporal) | **This skill** |
| "Where does data transform and move?" (DFD notation) | `data-flow` (Mermaid) |

Dynamic views are **scenario-specific** — one view per use case. Do not try to show all scenarios in a single view.

---

## Prerequisites

Dynamic views **reference elements defined in the model**. The model must exist before creating a dynamic view.

1. Check for an existing `.likec4` model:
   ```
   Glob **/*.likec4
   Glob **/*.c4
   ```
2. If no model exists, use the **`likec4-c4`** skill first to define `specification { }` and `model { }` blocks. Dynamic views cannot invent new elements — they select participants from the model.
3. If a model exists, read it to understand the available element identifiers before writing step interactions.

---

## Workflow

### Step 1 — Identify the Scenario

Ask or infer:

- **What user journey or trigger starts the flow?** (e.g., "user clicks Pay Now", "cron job fires", "webhook received")
- **What is the successful end state?** (e.g., "order confirmed", "email delivered", "cache updated")
- **Are there important failure or error paths worth diagramming separately?**

One scenario = one dynamic view. Keep views focused; create multiple views for variants (happy path, error path, retry path).

### Step 2 — List Participants

From the model, identify which elements appear in this scenario:

- Only include elements that **actively send or receive messages** in this flow
- Prefer leaf elements (no children) when using the sequence rendering variant
- Map human names to model identifiers (e.g., "the user" → `customer`, "the API" → `cloud.backend.api`)

### Step 3 — Map Interactions in Temporal Order

List the interactions from first to last. For each interaction, capture:

- Sender identifier → Receiver identifier
- A short label (HTTP method + path, event name, or plain English)
- Whether it is a response (use `<-` instead of `->`)
- Whether it happens in parallel with adjacent steps

### Step 4 — Identify Parallel Steps

Group interactions that can happen concurrently inside `parallel { }` blocks. Common patterns:

- Fan-out: one service calls multiple downstream services simultaneously
- Independent side effects: send email AND write audit log at the same time

Constraints: parallel blocks cannot be nested; sequence variant requires leaf-only participants inside parallel blocks.

### Step 5 — Generate the Dynamic View

Assemble the view using the syntax below. Wrap in a `views { }` block if needed:

```likec4
views {
  dynamic view scenarioName {
    title 'Human-Readable Scenario Title'

    actor -> frontend 'user action'
    frontend -> backend 'API call'
    parallel {
      backend -> serviceA 'concurrent call A'
      backend -> serviceB 'concurrent call B'
    }
    frontend <- backend 'response'
    actor <- frontend 'feedback'
  }
}
```

Add `navigateTo` on any step that warrants a drill-down view:

```likec4
backend -> serviceA 'call' {
  navigateTo serviceADetail
}
```

Add `notes` on steps that need clarification:

```likec4
backend -> db 'INSERT record' {
  notes 'Wrapped in a transaction — rolled back if payment fails'
}
```

### Step 6 — Write to File

For projects using the split-file convention from `likec4-c4`:

```
docs/architecture/views/flows/scenario-name.likec4
```

For single-file projects, append the `dynamic view` inside the existing `views { }` block in `docs/architecture/architecture.likec4`.

### Step 7 — Review and Refine

After writing, summarize:

- Scenario modeled and the view identifier
- Participants (count and identifiers)
- Number of steps, parallel groups, and navigateTo links
- File written

Ask: "Would you like to add an error path variant, add step notes, or link to a drill-down view?"

---

## Syntax Quick Reference

| Construct | Syntax |
|---|---|
| View declaration | `dynamic view id { }` |
| Title | `title 'string'` |
| Forward step (call) | `a -> b 'label'` |
| Reverse step (response) | `b <- a 'label'` |
| Step with body | `a -> b 'label' { ... }` |
| Parallel group | `parallel { }` or `par { }` |
| Drill-down link | `navigateTo viewId` (inside step body) |
| Step note | `notes 'markdown'` (inside step body) |
| Sequence layout | `sequence` (inside view body) |

Full syntax details: [references/dsl-syntax.md](references/dsl-syntax.md)

---

## Rendering Options

**Default layout** — Numbered edges in a flow graph. Best for complex flows with many parallel groups or navigateTo links.

**Sequence variant** — Add `sequence` inside the view body for a UML-style lifeline diagram. Best for request/response chains with clear temporal ordering and no deeply nested participants.

---

## Anti-Patterns

**Overloading one view** — Combining the happy path, error path, and edge cases into a single dynamic view creates an unreadable tangle. Create one view per scenario variant.

**Missing temporal ordering** — Writing steps in an arbitrary order defeats the purpose. Every step should follow naturally from the previous one — if two steps have no ordering dependency, put them in `parallel { }`.

**Duplicating model elements** — Do not re-declare `specification` or `model` blocks in view files. Element kinds and identifiers are defined once in the model; dynamic views only reference them.

**Using dynamic views as structural diagrams** — If you find yourself adding elements that have no message exchange, you want a structural C4 view (`likec4-c4`), not a dynamic view.

**Trying to show the entire system in one flow** — Dynamic views are most valuable when scoped to a single user story or API endpoint. A 40-step view spanning every system in the architecture is a warning sign.

---

## References

- [DSL Syntax — declaration, messages, parallel, navigateTo, notes](references/dsl-syntax.md)
- [Flow Examples — request/response, fan-out, error paths, saga](references/flow-examples.md)
- [likec4-c4 skill — model and specification setup](../likec4-c4/SKILL.md)
