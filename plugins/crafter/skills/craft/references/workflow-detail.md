# Craft Implement: Workflow Details

This reference provides detailed templates, examples, and procedures for executing the yaks-driven implementation workflow.

## Agent Dispatch from Yaks

Each yak contains a self-contained agent task description in its context. The craft orchestrator reads the context via `yx context "{yak name}"` and uses it to build the agent prompt. No plan file reading is needed.

### Building Agent Prompts

For each ready yak (from readiness computation):

1. Run `yx context "{yak name}"` to get the full agent context
2. The context follows the self-contained format from `/draft` (see draft template.md)
3. Dispatch via `Task` tool using the registered agent type matching the yak's `agent-type` field
4. The agent receives the yak context as its prompt — its system prompt is defined in the plugin's `agents/` directory

### Agent Dispatch Table

| agent-type Field | Agent Type (subagent_type) | Purpose |
|------------------|---------------------------|---------|
| `agent-test` | `crafter:agent-test` | Write failing tests (RED gate) |
| `agent-impl` | `crafter:agent-impl` | Minimal implementation + YAGNI check (GREEN gate) |
| `agent-validate` | `crafter:agent-validate` | Run full test suite, report only (VALIDATE gate) |
| `no-test` | `crafter:agent-no-test` | Non-TDD tasks (schema, infrastructure) |
| `agent-remediate` | `crafter:agent-remediate` | Fix implementation after validation failures |

### Dispatch Format

For each agent dispatch, pass the yak context as the prompt:

```
Task(
  description="P{N}: {Phase} — {agent role}",
  subagent_type="crafter:agent-test",  // or agent-impl, agent-validate, etc.
  prompt="{yak_context}"
)
```

The registered agents have their own system prompts defining role, rules, and report format. The yak context provides the task-specific context (file paths, test specs, gates, constraints).

See `plugins/crafter/agents/` for the full agent definitions:
- `agent-test.md` — RED gate: writes failing tests only
- `agent-impl.md` — GREEN gate: minimal implementation + YAGNI simplification pass
- `agent-validate.md` — VALIDATE gate: runs full suite, reports only, never fixes
- `agent-no-test.md` — Non-TDD tasks (schema, config, infrastructure)
- `agent-remediate.md` — Fixes implementation after validation failures (uses opus)

---

## Readiness Computation Algorithm

The craft skill computes readiness from `yx list --format json` output. This replaces the external tracker's `ready` command.

### Algorithm

```python
# Pseudocode — the craft skill implements this logic
def compute_ready(epic_json):
    phase_groups = epic_json["children"]  # top-level children of the epic

    # 1. Extract prefix number from name (e.g., "P2-Core-Logic" → 2)
    for group in phase_groups:
        group["prefix"] = int(re.match(r"P(\d+)", group["name"]).group(1))

    # 2. Group by prefix number
    by_prefix = defaultdict(list)
    for group in phase_groups:
        by_prefix[group["prefix"]].append(group)

    # 3. Find active groups (all lower-prefix groups done)
    ready = []
    for prefix in sorted(by_prefix.keys()):
        # Check all lower-prefix groups are done
        all_lower_done = all(
            g["state"] == "done"
            for p in by_prefix if p < prefix
            for g in by_prefix[p]
        )
        if not all_lower_done:
            break  # This prefix and all higher are blocked

        for group in by_prefix[prefix]:
            if group["state"] == "done":
                continue
            if not group["children"]:
                # Leaf phase group — the group itself is the task
                ready.append(group)
            else:
                # Parent phase group — find first non-done child
                for child in sorted(group["children"], key=lambda c: c["name"]):
                    if child["state"] != "done":
                        ready.append(child)
                        break

    return ready
```

### Example Walk-Through

Given this yaks tree:
```
Epic: "Add Discount Codes"
  P1-Schema-Setup         [done]
  P2-Core-Logic           [wip]
    01-write-tests        [done]
    02-implement          [done]
    03-validate           [todo]    ← READY
  P2-Feature-B            [todo]
    01-write-tests        [todo]    ← READY (P2 group independent)
  P3-Repository           [todo]        (blocked — P2 not done)
```

Ready tasks: `P2-Core-Logic/03-validate` AND `P2-Feature-B/01-write-tests` — dispatched in parallel.

---

## Parallel Dispatch

When readiness computation returns multiple tasks, dispatch them all in a **single message** with multiple `Task` tool calls.

### When Parallel Dispatch Occurs

- Two phase groups share the same prefix number (e.g., P2-Feature-A and P2-Feature-B)
- Multiple leaf phase groups are active simultaneously
- A no-test phase and a test-write phase are both ready

### When NOT to Parallelize

- Within a TDD triplet: Write Tests → Implement → Validate MUST be sequential
- Agent 2 needs Agent 1's test files on disk before it can run
- Agent 3 needs Agent 2's implementation on disk before it can run

### Example: Parallel Dispatch

If readiness returns `P1-Schema-Setup` (leaf, no-test) and `P1-Config-Setup` (leaf, no-test):

```
# Single message with two Task calls:
Task(description="P1: Schema Setup", subagent_type="crafter:agent-no-test", prompt="...")
Task(description="P1: Config Setup", subagent_type="crafter:agent-no-test", prompt="...")
```

---

## Remediation Yak Creation

When Agent 3 (Validate) reports failures, create new yaks under the same phase group parent to handle remediation.

### Procedure

1. **Create remediation yak:**
   ```bash
   yx add "04-remediate-attempt-1" --under "P2-Core-Logic" --field "agent-type=agent-remediate"
   echo "{remediation context}" | yx context "04-remediate-attempt-1"
   ```

2. **Create re-validation yak:**
   ```bash
   yx add "05-revalidate-attempt-1" --under "P2-Core-Logic" --field "agent-type=agent-validate"
   echo "{revalidation context}" | yx context "05-revalidate-attempt-1"
   ```

3. **Mark the original validate yak as done** — it completed its job (reporting failures):
   ```bash
   yx done "03-validate"
   ```

4. The sequential naming (`04-`, `05-`) ensures remediation runs next, then re-validation

### Remediation Yak Context Template

```markdown
## Agent Task: Remediate — {Phase Name} (attempt {M})

**Role:** Fix the implementation to make all tests pass. Do NOT modify test files.

### Agent Context
- **Files to modify (implementation):** `{implementation file path(s)}`
- **Files to read (tests, DO NOT MODIFY):** `{test file path(s)}`
- **Full test command:** `{full test suite command}`
- **Failure output from validation:**

{paste Agent 3's failure output here}

### Instructions
1. Read the failing tests to understand expected behavior
2. Read the implementation files to find the issue
3. Fix the implementation — minimal changes only
4. Run the full test suite
5. Verify ALL tests pass

### Report
- Files modified: [list paths]
- What was fixed: [brief description]
- Test command output: [paste]
- Result: ALL PASS or STILL FAILING
```

### Escalation

If attempt count reaches 2 and re-validation still fails:
1. Report the failure to the user with full context
2. Wait for user guidance before proceeding

---

## Progress Reporting

### After Each Yak Completes

Report the completion and overall epic progress:

```markdown
**Done:** P2-Core-Logic / 01-write-tests
**Next:** P2-Core-Logic / 02-implement (now ready)

**Epic Progress:** 3/12 tasks done
```

### Periodic Summary

Use `yx list` to show full epic status:

```markdown
**Progress Update:**
- [done] P1-Schema-Setup
- [done] P2-Core-Logic / 01-write-tests
- [done] P2-Core-Logic / 02-implement
- [wip]  P2-Core-Logic / 03-validate (dispatched)
- [todo] P3-Repository-Layer (waiting for P2)
- [todo] P4-Apply-Discount / 01-write-tests (waiting for P3)
- [todo] P4-Apply-Discount / 02-implement
- [todo] P4-Apply-Discount / 03-validate

**Progress:** 3/8 tasks done (37%)
```

---

## Error Handling Procedures

### If Agent 1 RED Gate Fails

If tests pass immediately (before implementation):
1. **STOP** — the test is not testing new behavior
2. **Do NOT mark the yak as done** — leave it
3. **Report to user** — explain that tests pass without implementation
4. **Do NOT dispatch Agent 2** — the phase is broken

### If Phase Cannot Be Completed

If a phase cannot be completed after remediation:
1. **Report to user** with full failure context
2. **Ask for guidance** — should we adjust the approach?
3. **Don't skip ahead** — the naming convention prevents this (lower numbers must complete first)

### If Yaks State is Inconsistent

If readiness computation returns no tasks but non-done tasks remain:
1. Check `yx list --format json` for the full tree
2. Look for phase groups where all children are done but the parent isn't
3. Mark completed parents as done: `yx done "{parent name}"`
4. Report to user with details

---

## Session Recovery

Recovery requires no special logic:

1. User runs `/craft` in a new session
2. Identify the epic (user provides name or check `yx list`)
3. Compute readiness from `yx list --format json` — returns exactly the next dispatchable tasks
4. Resume the orchestration loop from Step 2

Done yaks represent completed work (files already on disk). The orchestration loop picks up seamlessly.

---

## Quality Standards Checklists

### Test Quality
- [ ] Tests written by Agent 1 without knowledge of implementation
- [ ] Tests assert at L3/L4 boundaries
- [ ] Tests verify behavior, not implementation calls
- [ ] No internal mocks — only boundary testing

### Implementation Quality
- [ ] Implementation written by Agent 2 guided only by test expectations
- [ ] Uses existing patterns from project CLAUDE.md
- [ ] Minimal code to pass tests
- [ ] Respects architectural constraints from yak context

### Phase Verification
- [ ] Each phase validated by Agent 3 before proceeding
- [ ] Full test suite passes (not just new tests)
- [ ] Remediation attempts tracked (max 2 per phase)
- [ ] Yaks marked done only after gates pass

## Final Verification Template

Use this template after all yaks in the epic are done:

```markdown
## Final Verification

### Full Test Suite
{Run full test suite command}

**Result:** {All passing / Failures found}

### Acceptance Criteria

From epic:
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

### Agent Execution Summary

| Phase | Write Test | Implement | Validate | Remediations |
|-------|-----------|-----------|----------|--------------|
| 1     | n/a       | n/a       | n/a      | 0 (no-test)  |
| 2     | done      | done      | done     | 0            |
| 3     | n/a       | n/a       | n/a      | 0 (no-test)  |
| ...   | ...       | ...       | ...      | ...          |

**Total tasks:** {count}
**Remediations:** {count}
**Session recoveries:** {count}

---

## Implementation Complete

All yaks done:
- All tests passing
- All acceptance criteria met
- No test skips
- Code follows architectural patterns
- Test/implementation isolation maintained across all phases

**Next steps:**
- Run `/commit` to create commit
- Create PR if needed
- Document any follow-up work
```
