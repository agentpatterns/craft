# Yaks Task Graph Decomposition

After writing the plan file, create a yaks epic (parent yak) with per-agent-step child yaks that `/craft` will execute. The yaks task graph is the **contract between draft and craft** — each yak's context contains everything an agent needs.

## Yaks Availability Check

Before creating yaks, verify yaks is available by running `yx list --format json`.

- **Yaks available:** Proceed with the standard procedure below.
- **Yaks unavailable:** Switch to **Inline Task Graph** mode. Instead of creating yaks, embed the full task graph directly in the plan file as an additional section:

```markdown
## Inline Task Graph (yaks unavailable)

### P1-Apply-Schema [no-test] [no prerequisites]
- **Agent Context:** {full agent context as would appear in yak context}

### P2-Core-Logic / 01-write-tests [agent-test, L3] [after: P1]
- **Agent Context:** {full agent context}

### P2-Core-Logic / 02-implement [agent-impl] [after: 01-write-tests]
- **Agent Context:** {full agent context}

### P2-Core-Logic / 03-validate [agent-validate] [after: 02-implement]
- **Agent Context:** {full agent context}

### P3-Feature-Use-Case / 01-write-tests [agent-test, L3] [after: P2]
- **Agent Context:** {full agent context}
```

Each inline task follows the same description format as yak contexts — self-contained with everything an agent needs. `/craft` will consume this inline graph when yaks is unavailable.

## Naming Convention

The naming convention drives ordering. The craft skill uses these names to compute readiness.

### Phase Groups (parent yaks under the epic)

Use `P{N}-{Name}` format:
- **Numeric prefix** determines ordering: P1 must complete before P2 starts
- **Same prefix number** = independent, can run in parallel (e.g., `P2-Feature-A` and `P2-Feature-B`)
- **Leaf phase groups** (no children): the phase group itself is the task (e.g., `P1-Schema-Setup`)
- **Parent phase groups** (with children): contain the TDD triplet as numbered children

### Children (individual agent tasks)

Use `NN-{role}` format within each phase group:
- `01-write-tests` — RED gate agent
- `02-implement` — GREEN gate agent
- `03-validate` — VALIDATE gate agent

Children execute sequentially by their numeric prefix within the parent.

## Procedure (when yaks is available)

1. **Create the epic** yak: `yx add "{Feature Name}"`
2. **For each phase**, create yaks per the agent-step decomposition:
   - **Leaf phases** (schema, infrastructure): single yak under the epic with `--field "agent-type=no-test"`
   - **TDD phases**: parent yak under epic + 3 children (write-tests, implement, validate)
   - **Final verification**: single yak under epic with `--field "agent-type=agent-validate"`
3. **Set custom fields** on each yak: `--field "agent-type={agent-test|agent-impl|agent-validate|no-test}"`
4. **Pipe context** into each leaf yak (the Agent Context block from the plan):
   ```bash
   echo "{agent context markdown}" | yx context "{yak name}"
   ```

### Creating a TDD Phase Group

```bash
# Create the phase group parent
yx add "P2-Core-Logic" --under "{Feature Name}"

# Create TDD triplet children
yx add "01-write-tests" --under "P2-Core-Logic" --field "agent-type=agent-test"
yx add "02-implement" --under "P2-Core-Logic" --field "agent-type=agent-impl"
yx add "03-validate" --under "P2-Core-Logic" --field "agent-type=agent-validate"

# Pipe agent context into each child
echo "{write-tests agent context}" | yx context "01-write-tests"
echo "{implement agent context}" | yx context "02-implement"
echo "{validate agent context}" | yx context "03-validate"
```

### Creating a Leaf Phase

```bash
yx add "P1-Schema-Setup" --under "{Feature Name}" --field "agent-type=no-test"
echo "{agent context}" | yx context "P1-Schema-Setup"
```

## Readiness Convention

The craft skill computes readiness from `yx list --format json` using these rules:

1. **Phase groups ordered by prefix**: P1 < P2 < P3 (extracted from name)
2. **Same-prefix groups are independent**: P2-Feature-A and P2-Feature-B can run in parallel
3. **A phase group is "active"** when all lower-prefix groups are done
4. **Within an active group**:
   - Leaf (no children): the yak itself is ready if state != done
   - Parent (has children): the first child by name sort with state != done is ready
5. **All ready tasks** from all active groups are dispatched in parallel

## Example Decomposition (6-phase feature)

```
Epic: "Add Discount Codes"

P1-Schema-Setup              (leaf, agent-type=no-test)

P2-Core-Logic                (parent, TDD L3)
├── 01-write-tests           (agent-type=agent-test)
├── 02-implement             (agent-type=agent-impl)
╰── 03-validate              (agent-type=agent-validate)

P3-Repository-Layer          (leaf, agent-type=no-test)

P4-Apply-Discount            (parent, TDD L3)
├── 01-write-tests           (agent-type=agent-test)
├── 02-implement             (agent-type=agent-impl)
╰── 03-validate              (agent-type=agent-validate)

P5-HTTP-Routes               (parent, TDD L4)
├── 01-write-tests           (agent-type=agent-test)
├── 02-implement             (agent-type=agent-impl)
╰── 03-validate              (agent-type=agent-validate)

P6-Full-Integration          (leaf, agent-type=agent-validate)
```

**Readiness walk-through:**
1. Start: P1 is ready (no prerequisites)
2. P1 done → P2 active → `01-write-tests` ready
3. P2/01-write-tests done → P2/02-implement ready
4. P2/03-validate done → P3 ready (all P2 groups done)
5. P3 done → P4 active → `01-write-tests` ready
6. ...and so on until P6 completes

**With parallel phases** (same prefix number):
```
P2-Feature-A / 01-write-tests  AND  P2-Feature-B / 01-write-tests  → both ready when P1 done
```
