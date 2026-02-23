---
name: data-flow
description: Creates Data Flow Diagrams (DFDs) using Mermaid flowchart notation. Use when creating DFDs, data flow diagrams, showing data movement and transformation, or when user needs to visualize where data moves through a system.
license: MIT
compatibility: Claude Code plugin
metadata:
  author: eric-olson
  version: "1.0.0"
  workflow: architecture
  triggers:
    - "data flow diagram"
    - "DFD"
    - "data flow"
    - "data movement"
    - "data transformation"
    - "where does data go"
allowed-tools: Read Glob Write
---

# Data Flow Diagrams (DFD)

## When to Use DFD vs C4 vs Dynamic Views

| Question | Diagram Type | Tool |
|---|---|---|
| "Where does data transform and move?" | Data Flow Diagram | This skill (Mermaid) |
| "What is the system architecture?" | C4 structural (Context/Container/Component) | `likec4-c4` skill |
| "In what order do services interact?" | Dynamic / sequence view | `likec4-dynamic` skill |

**Key distinction:**

- **DFD** — topological, not time-ordered. Shows *what data exists*, *where it is stored*, and *which processes transform it*. Always true regardless of which request triggered it. The right tool for requirements analysis and threat modeling (STRIDE trust boundaries).
- **C4 structural** — answers "what components exist and how are they connected?" Not data-centric — uses containers and relationships, not processes and data stores.
- **Dynamic view** — temporal and scenario-specific. Shows the sequence of messages for one use case. Not the right tool when you want to see all data flows at once.

If the user wants to show one specific request flowing through services in order, use `likec4-dynamic`. If they want to understand data movement across the whole system topology, use this skill.

---

## DFD Levels

| Level | Scope | When to Use |
|---|---|---|
| Level 0 (Context) | Entire system as one process bubble | Scope discussions, threat modeling boundary, executive audience |
| Level 1 | Top-level sub-processes + data stores | Engineering design, data sensitivity analysis |
| Level 2+ | Decompose one Level 1 process further | When a sub-process is complex enough to warrant it |

**Decomposition rule:** Every data flow that crosses the Level 0 boundary must appear at Level 1. A data store that appears in a Level 1 sub-process must also appear in the Level 0 context if it crosses the trust boundary.

---

## Notation Quick Reference

| DFD Element | Mermaid Syntax | Shape |
|---|---|---|
| External Entity | `id[Label]` | Rectangle |
| Process | `id(Label)` | Rounded rectangle |
| Data Store | `id[(Label)]` | Cylinder |
| Data Flow | `source -->|label| target` | Labeled arrow |
| System Boundary | `subgraph id ["Label"] ... end` | Box grouping |

Full syntax reference: [references/dfd-notation.md](references/dfd-notation.md)

---

## Workflow

### Step 1 — Identify the System Boundary

Ask: "What is the system we are diagramming? What is inside it vs. outside it?"

Define the outer boundary. Everything inside is modeled as processes and data stores. Everything outside is an external entity.

### Step 2 — List External Entities

External entities are people, organizations, or external systems that send data to or receive data from the system. They are not decomposed — only their interactions with the boundary matter.

Examples: `Customer`, `Payment Gateway`, `LDAP Directory`, `Partner API`

### Step 3 — Map Data Stores

Data stores are where data persists — databases, file systems, caches, message queues (when acting as durable storage). They are named by what they store, not how they store it.

Rule: A data store cannot be connected directly to an external entity — data must pass through a process first.

### Step 4 — Identify Processes

Processes transform data. Each process has at least one data flow in and at least one data flow out. Name processes with a verb phrase: `Validate Order`, `Process Payment`, `Generate Report`.

Start with the minimum set. You can decompose to Level 2 later if a process is complex.

### Step 5 — Trace Data Flows

Label every arrow with the name of the data being moved, not the action. Good: `order request`, `payment result`, `session token`. Bad: `sends`, `calls`, `updates`.

Each flow should have a clear direction. Avoid bidirectional arrows — split into two explicit labeled flows.

### Step 6 — Choose the DFD Level

- Start with Level 0 to agree on scope.
- Produce Level 1 for engineering discussions.
- Only decompose to Level 2 if a Level 1 process has more than 5-7 internal flows.

### Step 7 — Generate the Mermaid Diagram

Use `flowchart LR` for pipeline-style flows, `flowchart TD` for hierarchical flows.

Apply `classDef` styling to visually distinguish element types:

```
classDef entity fill:#dae8fc,stroke:#6c8ebf,color:#000
classDef process fill:#d5e8d4,stroke:#82b366,color:#000
classDef store fill:#fff2cc,stroke:#d6b656,color:#000
```

### Step 8 — Write to a Markdown File

Embed the Mermaid diagram in a markdown file:

```
docs/architecture/data-flow-{level}.md
```

Example path: `docs/architecture/data-flow-context.md`, `docs/architecture/data-flow-level1.md`

Wrap the diagram in a fenced code block with `mermaid` language tag. Add a brief narrative above the diagram explaining scope and key data flows.

### Step 9 — Review and Refine

After writing, confirm:

- Every external entity has at least one inbound and one outbound flow (or document why not)
- Every data store has both read and write flows (or document the exception)
- Every process has at least one input and one output
- Data flow labels describe data, not actions
- The diagram fits on a screen — if not, consider decomposing or scoping to one sub-system

Ask: "Would you like to decompose any process to Level 2, or create a separate diagram scoped to a specific sub-system?"

---

## Anti-Patterns

**Data store with no inputs** — A store that is only read from has no origin. Either add the write path or remove the store and inline the data on the flow.

**Process with no outputs** — A process that consumes data and produces nothing is a data sink. This is usually a modeling error — every transformation produces something (even an audit log).

**Mixing temporal with topological concerns** — DFDs show topology, not sequence. Do not add step numbers to flows or attempt to show "first this, then that" ordering. Use a dynamic view for that.

**Connecting external entities directly to data stores** — External entities must always interact with the system through a process. A direct entity-to-store connection means a process is missing.

**Using vague flow labels** — `sends data`, `calls service`, `updates record` are not data names. Label flows with the data: `order request`, `inventory count`, `payment result`.

**Over-decomposing at Level 0** — The context diagram should have exactly one process bubble representing the whole system. Showing sub-processes at Level 0 defeats its purpose.

---

## References

- [DFD Notation Mapped to Mermaid Syntax](references/dfd-notation.md) — shapes, arrows, subgraphs, classDef styling
- [DFD Examples — Context and Detailed Levels](references/dfd-examples.md) — complete renderable Mermaid code blocks
