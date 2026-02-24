# Research: Minimal ADR Skill for Scaffolder Plugin

**Date:** 2026-02-22
**Feature:** Create a scaffolder skill for writing minimal markdown ADRs, informed by Andrew Harmel-Law's "Facilitating Software Architecture"

---

## 1. Existing Skill Patterns (Codebase)

### Scaffolder Plugin Structure

The scaffolder plugin (`plugins/scaffolder/`) currently has one skill: `hexagonal-architecture`. A new skill goes at `plugins/scaffolder/skills/<skill-name>/SKILL.md` with an optional `references/` subdirectory.

### Required SKILL.md Structure

- **YAML frontmatter**: `name`, `description` (verbose — serves as AI routing signal), `allowed-tools` (space-separated, scoped to only what the skill needs)
- **Optional frontmatter**: `license`, `metadata.author`, `metadata.version`, `metadata.workflow`, `triggers` list
- **Line limit**: Under 300 lines. Supporting content goes in `references/`
- **Section order**: Purpose -> When to Use / When NOT to Use -> Workflow (numbered steps) -> Anti-Patterns -> After/Handoff

### hexagonal-architecture Skill (99 lines)

The existing scaffolder skill is a good model: concise, directive, uses ASCII diagrams, bullet-based rules, and named anti-patterns. No heavy prose. The `references/disclaimer.md` is a stub.

### Registration

New skills within an existing plugin need only a directory and an update to `plugins/scaffolder/skills/README.md`. No `marketplace.json` change required.

---

## 2. Harmel-Law's ADR Approach (High Confidence)

### Core Philosophy

Architecture is a **distributed practice**, not a centralized role. Anyone can make architectural decisions provided they follow the **advice process**: seek advice from (1) those meaningfully affected and (2) subject matter experts. Advice is not consent — the decision-maker listens, records, and decides.

### ADR Template (from companion GitHub repo)

```markdown
# [TITLE]

Date: YYYY-MM-DD
Status: DRAFT | PROPOSED | ACCEPTED | ADOPTED | SUPERSEDED | EXPIRED
Author: [Name]

## Decision
Summary in a few sentences.

## Context
Forces, constraints, circumstances.

## Options Considered

### [Selected Option] (SELECTED)
Description.
**Consequences**: Reasons for adoption, drawbacks.

### [Option N]
Description.
**Consequences**: Reasons for rejection.

## Advice
- [Name, Role, Date]: Advice given

## Supporting Material
- Links
```

### Key Differentiators from Standard Nygard ADR

| Element | Nygard Original | Harmel-Law Extension |
|---------|----------------|---------------------|
| Sections | Title, Context, Decision, Status, Consequences | Adds: Options Considered, Advice (attributed) |
| Status values | Proposed, Accepted, Deprecated, Superseded | Adds: DRAFT, EXPIRED; adds ADOPTED |
| Decision authority | Implicit | Explicit: anyone, via advice process |
| Advice tracking | Not a concept | Recorded with name/role/date |
| Purpose | Documentation artifact | Facilitation artifact + learning mechanism |

### When to Write an ADR (Harmel-Law signals)

- Decision requires consulting many people (scope = significance)
- Introduces a new technology or changes radar stance
- Conflicts with an existing architectural principle
- Affects more than one team's autonomy
- **No minimum size threshold** — the template itself is the filter

### The Advice Process Mechanics

- Borrowed from Laloux's "Reinventing Organizations"
- Decision-maker seeks advice, records it with attribution, then decides
- Advice section makes dissent visible and auditable
- Architecture Advisory Forum (AAF) = weekly 1-hour meeting for collective advice
- ADR library becomes organizational "decision lore" for onboarding

---

## 3. Minimal ADR Formats (High Confidence)

### Nygard Original (2011)

Five fields: Title, Status, Context, Decision, Consequences. "One or two pages long." ADRs are immutable once accepted — new ADR supersedes, never edit. Stored at `doc/arch/adr-NNN.md`.

### MADR (Markdown Architectural Decision Records)

Minimal variant:

```markdown
# [short title of solved problem and solution]

## Context and Problem Statement
[2-3 sentences or a question]

## Considered Options
* Option 1
* Option 2

## Decision Outcome
Chosen option: "Option 1", because [justification].

### Consequences
* Good, because [positive]
* Bad, because [negative]
```

Full variant adds: Decision Drivers, Pros/Cons per option, Confirmation, YAML frontmatter (status, date, decision-makers, consulted, informed).

### Y-Statement (Zdun et al.)

Single-sentence decision capture:

```
In the context of _____, facing _____, we decided for _____,
to achieve _____, accepting _____.
```

Best as a forcing function: if you cannot write the Y-statement, the decision is not clear enough to record.

### Naming & Directory Conventions

- **Naming**: `0001-kebab-case-title.md` (4-digit numeric prefix is de facto standard)
- **Directory**: `docs/decisions/` (MADR, gaining traction) or `docs/adr/` (traditional)
- **Status progression**: Proposed -> Accepted -> (Deprecated | Superseded)

---

## 4. Synthesis: What the Skill Should Teach

### Recommended Template for the Skill

Blend Harmel-Law's advice-process awareness with MADR's structured minimalism:

```markdown
# ADR-NNNN: [Imperative verb phrase]

**Date:** YYYY-MM-DD
**Status:** Proposed | Accepted | Superseded by ADR-NNNN
**Author:** [Name]

## Context
[2-3 sentences. Forces and constraints. Value-neutral.]

## Decision
[1-2 sentences. Active voice. "We will..."]

## Options Considered
- **Option A** — [one line]
- **Option B** — [one line]

## Consequences
- Good: [positive outcome]
- Bad: [accepted tradeoff]

## Advice
- [Name, Date]: [What they said]
```

This template:
- Fits on one page (Nygard principle)
- Mandates options (MADR + Harmel-Law)
- Includes advice attribution (Harmel-Law's key contribution)
- Keeps status vocabulary simple (3 values, not 6)
- Uses imperative verb titles for consistency with MADR and this project's conventions

### Skill Workflow Concept

The skill should guide the user through:
1. **Decide if an ADR is needed** — decision filter checklist
2. **Create the ADR file** — naming, directory, template
3. **Fill in the template** — section-by-section guidance with Y-statement as warm-up
4. **Seek advice** — prompt to identify stakeholders (Harmel-Law's advice process)
5. **Finalize** — update status, commit alongside the code change

### What Goes in SKILL.md vs references/

| SKILL.md (under 300 lines) | references/ |
|----------------------------|-------------|
| Decision filter (when to write) | Full template file (copy-pasteable) |
| Workflow steps | Harmel-Law philosophy summary |
| Naming/directory conventions | Y-statement examples |
| Anti-patterns | Status lifecycle diagram |
| Template overview (abbreviated) | Comparison table (Nygard vs MADR vs Harmel-Law) |

---

## 5. Open Questions

1. **Status vocabulary**: Use Harmel-Law's 6 values (DRAFT, PROPOSED, ACCEPTED, ADOPTED, SUPERSEDED, EXPIRED) or simplify to 3 (Proposed, Accepted, Superseded)? The skill targets minimal ADRs, so fewer statuses reduce friction.

2. **Directory convention**: `docs/decisions/` (MADR default, broader scope) or `docs/adr/` (more recognized, narrower)? The skill could recommend one and note the alternative.

3. **Advice section**: Include as mandatory (true to Harmel-Law) or optional (reduces friction for solo/small teams)? Could be "recommended when multiple stakeholders are affected."

4. **Tooling mention**: Reference adr-tools or log4brains, or keep the skill tool-agnostic and focused on the markdown format? The scaffolder plugin is about patterns, not tools.

5. **Skill name**: `adr` (short, clear), `architecture-decision-records` (explicit), or `minimal-adr` (signals philosophy)?

---

## 6. Key Files

| File | Relevance |
|------|-----------|
| `plugins/scaffolder/skills/hexagonal-architecture/SKILL.md` | Template for skill structure (99 lines) |
| `plugins/scaffolder/skills/README.md` | Must add new skill entry |
| `.claude-plugin/marketplace.json` | No change needed for new skill in existing plugin |
| `CLAUDE.md` | Skill authoring guidelines to follow |

---

## 7. Sources

- **Harmel-Law ADR template**: github.com/andrewharmellaw/facilitating-software-architecture/blob/main/adr/adr-template.md (High)
- **"Scaling Architecture Conversationally"**: martinfowler.com/articles/scaling-architecture-conversationally.html (High)
- **Architecture Advisory Forum materials**: same GitHub repo, adviceforum/ directory (High)
- **Nygard original ADR**: Cognitect blog, 2011 (High)
- **MADR**: adr.github.io/madr (High)
- **Y-statement**: Zdun et al., "Sustainable Architectural Decisions" WICSA 2015 (High)
- **ThoughtWorks Technology Radar**: Lightweight ADRs at "Adopt" since May 2018 (High)
