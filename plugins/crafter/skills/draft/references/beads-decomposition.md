# Beads Task Graph Decomposition

After writing the plan file, create a beads epic and per-agent-step issues that `/craft` will execute. The beads task graph is the **contract between draft and craft** — each issue is self-contained with everything an agent needs.

## Beads Availability Check

Before creating beads issues, verify beads is available by attempting `beads:search`.

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

### P2: Validate — Core Logic [agent-validate] [blocked-by: P2-Implement]
- **Agent Context:** {full agent context}

### P3: Write Tests — Feature Use Case [agent-test, L3] [blocked-by: P2-Validate]
- **Agent Context:** {full agent context}
```

Each inline issue follows the same description format as beads issues — self-contained with everything an agent needs. `/craft` will consume this inline graph when beads is unavailable.

## Procedure (when beads is available)

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

## Issue Description Format

Each issue description MUST contain the full Agent Context — everything an agent needs to execute without reading the plan file or any other external document. See [template.md](template.md) for the self-contained issue description templates for each agent type.

## Example Decomposition (6-phase feature)

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
