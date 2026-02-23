---
name: likec4-c4
description: Creates structural C4 architecture diagrams (Context, Container, Component, Deployment) using LikeC4 DSL. Use when creating C4 diagrams, architecture diagrams, system diagrams, container diagrams, or when user mentions LikeC4, C4 model, or architecture-as-code.
license: MIT
compatibility: Claude Code plugin
metadata:
  author: eric-olson
  version: "1.0.0"
  workflow: architecture
  triggers:
    - "C4 diagram"
    - "architecture diagram"
    - "LikeC4"
    - "system diagram"
    - "container diagram"
    - "component diagram"
    - "deployment diagram"
    - "architecture-as-code"
allowed-tools: Read Glob Write
---

# LikeC4 C4 Structural Diagrams

## When to Use This Skill

Use this skill for **structural** C4 diagrams — diagrams that answer "what exists and how is it connected":

- **Context** (C4 L1) — system in relation to users and external systems
- **Container** (C4 L2) — internal containers of one system (apps, services, DBs, queues)
- **Component** (C4 L3) — internal components of one container
- **Deployment** (C4 L4) — infrastructure topology

Use **`likec4-dynamic`** instead when the user wants to show a time-ordered request/response flow for a specific scenario (e.g., "show me how a login request travels through the system").

Use a **data flow diagram** approach (Mermaid flowchart) when the user wants Yourdon/DeMarco DFD notation — LikeC4 does not natively support DFD symbols (processes, data stores, external entities in DFD style).

---

## View Type Decision Tree

```
What question is the user asking?
│
├── "What systems interact with X and who uses it?"
│   └── Context view  (view index / view of nothing — top level)
│
├── "What's inside system X?"
│   └── Container view  (view of systemIdentifier)
│
├── "What's inside container X?"
│   └── Component view  (view of containerIdentifier)
│
├── "How is this deployed on infrastructure?"
│   └── Deployment view  (deployment view of environment)
│
└── "How does a request flow through the system?"
    └── Use likec4-dynamic skill instead
```

---

## Workflow

### Step 1 — Gather System Context

Ask (or infer from context) before writing any DSL:

1. **What is the system being modeled?** (name, brief purpose)
2. **What is the scope?** (which C4 level — see decision tree above)
3. **Who are the actors?** (human users, external systems that interact with the system)
4. **What are the key containers or components?** (for L2/L3 only)
5. **Is there an existing `.likec4` model file to extend?** (check with `Glob **/*.likec4 **/*.c4`)

### Step 2 — Check for Existing Model Files

```
Glob **/*.likec4
Glob **/*.c4
```

If existing files are found, read them to understand the current model before adding to it. LikeC4 merges all `.likec4` files in a project — do not duplicate element definitions.

### Step 3 — Define the Model

Structure the DSL in this order:

1. `specification { }` — define element kinds, relationship kinds, tags, custom colors
2. `model { }` — declare all elements with nesting (parent → child = containment relationship)
3. Relationships inside `model { }` using `->` syntax

**Naming conventions:**
- Identifiers: `camelCase` (e.g., `orderService`, `primaryDb`)
- Display names: Title Case strings (e.g., `'Order Service'`)
- File names: `kebab-case.likec4` (e.g., `order-platform.likec4`)

### Step 4 — Create the View

Add a `views { }` block with the appropriate view type:

- Context: `view index { include *; include -> systemName -> }`
- Container: `view name of systemIdentifier { include *; include externalActors }`
- Component: `view name of containerIdentifier { include *; include -> * -> }`
- Deployment: `deployment view name of environmentIdentifier { include * }`

Use `autoLayout TopBottom` (default) or `LeftRight` for horizontal flows.

### Step 5 — Write the File

For new projects, use this file structure:

```
docs/architecture/
  spec.likec4          # specification block only
  model.likec4         # model block only
  views/
    context.likec4     # context view
    containers.likec4  # container views
    deployment.likec4  # deployment views and deployment block
```

For small or single-diagram projects, one file is acceptable:

```
docs/architecture/architecture.likec4
```

### Step 6 — Review and Refine

After writing, present the diagram summary:

- View type and scope
- Elements included (count and kinds)
- Key relationships modeled
- Which file was written

Ask: "Would you like to add styling, adjust the scope, or drill into a specific container?"

---

## File Organization

| Scope | Recommended file |
|---|---|
| Full model (spec + model + views) | `docs/architecture/architecture.likec4` |
| Specification only | `docs/architecture/spec.likec4` |
| Model only | `docs/architecture/model.likec4` |
| Context views | `docs/architecture/views/context.likec4` |
| Container views | `docs/architecture/views/containers.likec4` |
| Component views | `docs/architecture/views/components.likec4` |
| Deployment views | `docs/architecture/views/deployment.likec4` |

All files in the same directory are automatically merged by LikeC4 — split for readability, not for any technical reason.

---

## Anti-Patterns

**Duplicating element definitions across files** — Each identifier must be declared once. LikeC4 merges all files; duplicate definitions cause errors.

**Mixing structural and dynamic views in one skill** — Structural C4 views (`view`, `view of`) and dynamic views (`dynamic view`) serve different purposes. Keep them in separate view files.

**Including too many elements in one view** — A context view with 30 systems is unreadable. Use `exclude` predicates or scope to `view of X` to keep diagrams focused.

**Skipping the specification block** — Element kinds without a `specification` entry default to generic rectangles. Define kinds explicitly so all diagrams share consistent vocabulary and styling.

**Hardcoding styles per-element instead of per-kind** — Prefer `style element.kind == database` over styling each database element individually. Changes then propagate to all diagrams automatically.

**Deep nesting in context views** — Context views should show top-level systems only. Include `cloud.*` only in container views, not in context views.

**Using deployment view for logical architecture** — Deployment views show infrastructure (`instanceOf` references to model elements). Use `view of` for logical structure.

---

## References

- [DSL Syntax — specification, model, views, deployment, predicates](references/dsl-syntax.md)
- [View Examples — context, container, component, deployment](references/view-examples.md)
- [Style Guide — colors, shapes, icons, predicates, global styles](references/style-guide.md)
