---
name: draft
description: Plan phase of RPI methodology. Consumes research artifact or topic and produces compact implementation plan with test specs and Agent Context blocks. Use after research or to start planning a non-trivial feature.
triggers:
  - "plan"
  - "draft plan"
  - "implementation plan"
allowed-tools: Read Glob Write Bash AskUserQuestion Skill
---

# Craft Plan Skill

**RPI Phase 2 of 3:** Research → **Plan** → Implement

Use this skill after research (or standalone) to create a compact implementation plan with behavioral test specifications and Agent Context blocks for each phase.

## Purpose

The Plan phase creates a compact spec that fits in context by:
- Defining files to create/modify in order of operations
- Specifying test specs as behavioral descriptions at architectural boundaries
- Including Agent Context blocks so `/craft` can dispatch isolated agents per phase
- Setting clear acceptance criteria
- Identifying phase boundaries for incremental implementation

**Output:** Compact plan (~200 lines) at `docs/plans/YYYY-MM-DD-{topic}-plan.md`

## When to Use

Use this skill when:
- Completing research phase (has research artifact)
- Starting a non-trivial feature (no research artifact, will create one)
- Need a clear implementation roadmap before coding
- Want to specify test boundaries before implementing

**Don't use** for:
- Simple bug fixes
- Trivial features with obvious implementation
- Exploratory spikes

## Workflow

### 1. Consume Research Artifact (If Exists)

If research artifact exists:
```
Read: docs/plans/YYYY-MM-DD-{topic}-research.md
```

If no research artifact, create an inline summary (condensed):
- Identify relevant files
- Note existing patterns
- List integration points

### 2. Define Plan Scope

Ask the user to clarify if needed:
- What are the acceptance criteria?
- Are there specific constraints or preferences?
- What's the priority (MVP vs full feature)?

### 3. Create Implementation Plan (Audit Trail)

Write the plan directly to `docs/plans/YYYY-MM-DD-{topic}-plan.md` using the `Write` tool and the [template structure](references/template.md). Use kebab-case for the topic slug (e.g., `2026-02-21-add-discount-codes-plan.md`).

**Note:** The plan file serves as a **human-readable audit trail** for code review, PR descriptions, and design understanding. It is NOT the runtime source of truth for `/craft` — beads issues are (see Step 3b).

**Required sections:**
- **Goal** — 1-2 sentence description of what we're building and why
- **Acceptance Criteria** — Testable outcomes as checklist
- **Files to Create** — Organized by layer (Core, Features, Shell, Tests)
- **Files to Modify** — What changes in existing files
- **Implementation Phases** — Ordered steps, each with:
  - Clear goal
  - Behavioral test specification (what to test, not how)
  - Tasks list
  - Verification checklist
  - **Agent Context block** (file paths, test command, gates, constraints)
- **Constraints & Considerations** — Architectural, testing, performance, security
- **Out of Scope** — Explicitly deferred features
- **Approval Checklist** — Pre-implementation verification
- **Next Steps** — Path to `/craft`

**Phase ordering:**
1. Database Schema (if needed)
2. Core Logic (L3 boundary — property/invariant tests)
3. Repository Layer (if needed)
4. Feature Use Cases (L3 boundary — behavioral assertions)
5. HTTP Routes (L4 boundary — contract tests)
6. Full Integration (verification)

See [template.md](references/template.md) for the complete template with Agent Context block reference.

### 3b. Create Beads Task Graph (Execution Source of Truth)

After writing the plan file, create a beads epic and per-agent-step issues that `/craft` will execute. The beads task graph is the **contract between draft and craft** — each issue is self-contained with everything an agent needs.

#### Beads Availability Check

Before creating beads issues, verify beads is available by attempting `beads:epic`.

- **Beads available:** Proceed with the standard procedure below.
- **Beads unavailable:** Switch to **Inline Task Graph** mode. Instead of creating beads issues, embed the full task graph directly in the plan file as an additional section:

```markdown
## Inline Task Graph (beads unavailable)

### P1: Apply Schema [no-test] [no blockers]
- **Agent Context:** {full agent context as would appear in beads issue}

### P2: Write Tests — Core Logic [agent-test, L3] [blocked-by: P1]
- **Agent Context:** {full agent context}

### P2: Implement — Core Logic [agent-impl] [blocked-by: P2-Write-Tests]
- **Agent Context:** {full agent context}
...
```

Each inline issue follows the same description format as beads issues — self-contained with everything an agent needs. `/craft` will consume this inline graph when beads is unavailable.

**Procedure (when beads is available):**

1. **Create the epic** via `beads:epic` with the feature name as the title
2. **For each phase**, create beads issues per the agent-step decomposition:
   - **TDD phases** get 3 issues: Write Tests → Implement → Validate
   - **Non-TDD phases** (schema, infrastructure) get 1 issue
   - **Final verification** gets 1 issue
3. **Wire dependencies** via `beads:dep` so ordering is enforced:
   - Within a TDD triplet: Write Tests → Implement → Validate (sequential)
   - Across phases: Phase N's last issue blocks Phase N+1's first issue
   - Independent phases with no data dependency can run in parallel
4. **Label each issue** via `beads:label`:
   - `rpi-phase` on all issues
   - `agent-test`, `agent-impl`, `agent-validate`, or `no-test` per agent type
   - `L3` or `L4` for boundary test level (TDD phases only)

**Issue description format:** Each issue description MUST contain the full Agent Context — everything an agent needs to execute without reading the plan file or any other external document. See [template.md](references/template.md) for the self-contained issue description templates for each agent type.

**Example decomposition for a 6-phase feature:**

```
Epic: "Add Discount Codes"

Phase 1 (no-test):
├── P1: Apply Schema                         [no blockers]

Phase 2 (TDD, L3):
├── P2: Write Tests — Core Logic             [blocked-by P1]
├── P2: Implement — Core Logic               [blocked-by P2-Write-Tests]
├── P2: Validate — Core Logic                [blocked-by P2-Implement]

Phase 3 (no-test):
├── P3: Repository Layer                     [blocked-by P2-Validate]

Phase 4 (TDD, L3):
├── P4: Write Tests — Apply Discount         [blocked-by P3]
├── P4: Implement — Apply Discount           [blocked-by P4-Write-Tests]
├── P4: Validate — Apply Discount            [blocked-by P4-Implement]

Phase 5 (TDD, L4):
├── P5: Write Tests — POST /orders           [blocked-by P4-Validate]
├── P5: Implement — POST /orders             [blocked-by P5-Write-Tests]
├── P5: Validate — POST /orders              [blocked-by P5-Implement]

Phase 6 (verification):
└── P6: Full Integration                     [blocked-by P5-Validate]
```

### 4. Present Plan for Review

Tell the user:
- The file path where the plan was saved (audit trail)
- The beads epic name and issue count (execution source of truth)
- A brief summary of the key sections (goal, phases, acceptance criteria)
- Ask if they want any changes before proceeding to `/craft`

### 5. Prompt Next Steps

```
Implementation plan saved. Next steps:
- Plan file (audit trail): docs/plans/YYYY-MM-DD-{topic}-plan.md
- Beads epic created: {epic name} ({N} issues, dependencies wired)
- Run `/craft` to execute — it will dispatch agents from beads issues
- Session recovery: if interrupted, `/craft` picks up where it left off via beads:ready
- If changes needed, clarify what to adjust and I'll update both the plan and beads issues
```

## Test Specifications at Boundaries

Test specs in the plan MUST be behavioral descriptions, not tool-specific code. The agents executing `/craft` will consult the project's CLAUDE.md for testing tools and patterns.

### L3 Core Tests (Property/Invariant)

Describe invariant properties that must hold:
- **Good:** "Splitting a total into N parts preserves the total"
- **Bad:** Code snippet using a specific testing library

### L3 Feature Tests (Behavioral)

Describe behavior at the use case boundary:
- **Good:** "Creating an order returns success with an order ID and correct total"
- **Bad:** `expect(mockRepository.create).toHaveBeenCalledWith(...)`

### L4 HTTP Tests (Contract)

Describe the HTTP contract:
- **Good:** "POST /orders returns 201 with `{ id, total }` on success, 400 with `{ error }` on validation failure"
- **Bad:** Testing internal handler implementation details

See [template.md](references/template.md) for detailed guidelines.

## Agent Context Blocks

Every implementation phase with tests MUST include an `#### Agent Context` subsection in the plan file (for audit). The same Agent Context is embedded in each beads issue description (for execution). This is the contract between `/draft` and `/craft`.

**Required fields:**
- **Files to create/modify** — explicit paths
- **Test spec** — behavioral description (what to test)
- **Test command** — shell command to run
- **RED gate / GREEN gate** — observable success criteria
- **Architectural constraints** — boundaries the agent must respect

See [template.md](references/template.md) for the Agent Context block reference and beads issue description templates.

## Phase Boundaries

Each phase should:
1. **Have a clear goal** — What capability is being added?
2. **Be independently verifiable** — Can you confirm it works?
3. **Be in logical order** — Database → Core → Features → Routes
4. **Have a self-contained Agent Context** — An isolated agent can execute it

Good boundaries: Database schema, Core functions, Repository, Feature use cases, HTTP routes

Bad boundaries: "Implement everything", mixing multiple layers

## Anti-Patterns to Avoid

- **Don't write full implementations** — Specs only, not code
- **Don't skip Agent Context blocks** — Each phase needs one for `/craft` to dispatch agents
- **Don't prescribe testing tools** — Describe behavior, reference project CLAUDE.md for tools
- **Don't create giant phases** — Keep phases small and focused
- **Don't omit verification steps** — Each phase needs concrete, observable checks

## After Planning

Once plan is complete and reviewed:
1. User reviews plan at `docs/plans/YYYY-MM-DD-{topic}-plan.md` (audit trail)
2. User verifies beads epic and issues via `beads:list` or `beads:epic`
3. User approves or requests changes (both plan file and beads issues are updated)
4. Run `/craft` — it executes purely from beads issues, not the plan file

## Context Compaction

**Why plan after research?** The plan phase is a compaction point:
- **Before planning:** Research artifact (~200 lines of findings)
- **After planning:** Implementation spec (~200 lines of actionable phases with Agent Context)
- **Implementation phase** works from self-contained beads issues, not raw research or the plan file

## Session Recovery

The beads task graph provides durable state across sessions:
- **Closed issues** = completed work (agents ran, gates passed, files on disk)
- **Ready issues** = next tasks to dispatch (use `beads:ready`)
- **Blocked issues** = waiting on dependencies
- If a session is interrupted, running `/craft` again picks up exactly where it left off
