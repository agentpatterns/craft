# Craft Implement: Workflow Details

This reference provides detailed templates, examples, and procedures for executing the beads-driven implementation workflow.

## Agent Dispatch from Beads Issues

Each beads issue contains a self-contained agent task description. The craft orchestrator reads the issue description via `beads:show` and uses it to build the agent prompt. No plan file reading is needed.

### Building Agent Prompts

For each ready issue from `beads:ready`:

1. Run `beads:show {issue-id}` to get the full description
2. The description follows the self-contained format from `/draft` (see draft template.md)
3. Wrap the description in a Task tool call with `subagent_type: general-purpose`
4. The agent receives the issue description as its complete instructions

### Agent 1: Write Test (label: agent-test)

**Purpose:** Create failing tests for the current phase.
**Agent type:** `general-purpose` (subagent_type)
**Model:** `sonnet`
**Mode:** Synchronous (not background)

Prompt template — substitute `{issue_description}` with the full beads issue description:

```
You are executing a test-writing task from the project's issue tracker.

YOUR ROLE: Write failing tests ONLY. Do NOT write any implementation code.

{issue_description}

IMPORTANT: If tests pass immediately, something is wrong. Report this as a RED gate FAIL.
```

### Agent 2: Implement (label: agent-impl)

**Purpose:** Write minimal code to make tests pass.
**Agent type:** `general-purpose` (subagent_type)
**Model:** `sonnet`
**Mode:** Synchronous (not background)

```
You are executing an implementation task from the project's issue tracker.

YOUR ROLE: Write minimal implementation to make existing tests pass. Do NOT modify test files.

{issue_description}

IMPORTANT: Do NOT modify test files. If a test seems wrong, report it and let a human decide.
```

### Agent 3: Validate (label: agent-validate)

**Purpose:** Run the full test suite to ensure nothing is broken.
**Agent type:** `general-purpose` (subagent_type)
**Model:** `haiku`
**Mode:** Synchronous (not background)

```
You are executing a validation task from the project's issue tracker.

YOUR ROLE: Run the full test suite and report results. Do NOT modify any files.

{issue_description}

IMPORTANT: Do NOT fix anything. Only report.
```

### No-Test Agent (label: no-test)

**Purpose:** Execute non-TDD phase tasks (schema, infrastructure).
**Agent type:** `general-purpose` (subagent_type)
**Model:** `sonnet`
**Mode:** Synchronous (not background)

```
You are executing a setup task from the project's issue tracker.

YOUR ROLE: Execute the task as described. Verify the acceptance gate.

{issue_description}
```

### Agent 2-R: Remediation (label: agent-remediate)

**Purpose:** Fix implementation after validation finds failures.
**Agent type:** `general-purpose` (subagent_type)
**Model:** `opus`
**Mode:** Synchronous (not background)

```
You are executing a remediation task from the project's issue tracker.

YOUR ROLE: Fix the implementation to make all tests pass. Do NOT modify test files.

{issue_description}

IMPORTANT: Do NOT modify test files. Tests define the contract.
```

---

## Parallel Dispatch

When `beads:ready` returns multiple issues, dispatch them all in a **single message** with multiple `Task` tool calls.

### When Parallel Dispatch Occurs

- Two independent phases have no dependency between them (e.g., Phase 1 schema + Phase 2 of an unrelated feature)
- Multiple no-test setup tasks are unblocked simultaneously
- Two TDD write-test agents for phases that don't depend on each other

### When NOT to Parallelize

- Within a TDD triplet: Write Tests → Implement → Validate MUST be sequential
- Agent 2 needs Agent 1's test files on disk before it can run
- Agent 3 needs Agent 2's implementation on disk before it can run

### Example: Parallel Dispatch

If `beads:ready` returns issues #5 (no-test setup) and #8 (write tests for independent phase):

```
# Single message with two Task calls:
Task(description="P1: Apply Schema", subagent_type="general-purpose", model="sonnet", prompt="...")
Task(description="P3: Write Tests — Repository", subagent_type="general-purpose", model="sonnet", prompt="...")
```

---

## Remediation Issue Creation

When Agent 3 (Validate) reports failures, create new beads issues to handle remediation.

### Procedure

1. **Create remediation issue:**
   ```
   beads:create
   Title: P{N}: Remediate — {Phase Name} (attempt {M})
   Label: agent-remediate, rpi-phase
   Description: (see template below)
   Blocked-by: {validate issue id}
   ```

2. **Create re-validation issue:**
   ```
   beads:create
   Title: P{N}: Re-Validate — {Phase Name} (attempt {M})
   Label: agent-validate, rpi-phase
   Blocked-by: {remediation issue id}
   ```

3. **Rewire dependencies:**
   - The next phase's first issue should now be blocked-by the re-validation issue
   - Use `beads:dep` to update the dependency

4. **Close the original validate issue** — it completed its job (reporting failures)

### Remediation Issue Description Template

```markdown
## Agent Task: Remediate — {Phase Name} (Phase {N}, attempt {M})

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
1. Update the re-validation issue to `blocked` status via `beads:update`
2. Report the failure to the user with full context
3. Wait for user guidance before proceeding

---

## Progress Reporting

### After Each Issue Closes

Report the issue closure and overall epic progress:

```markdown
**Closed:** P2: Write Tests — Core Logic
**Next:** P2: Implement — Core Logic (now unblocked)

**Epic Progress:** 3/12 issues closed
```

### Periodic Summary

Use `beads:list` to show full epic status:

```markdown
**Progress Update:**
- [closed] P1: Apply Schema
- [closed] P2: Write Tests — Core Logic
- [closed] P2: Implement — Core Logic
- [open]  P2: Validate — Core Logic (dispatched)
- [open]  P3: Repository Layer (blocked by P2-Validate)
- [open]  P4: Write Tests — Apply Discount (blocked by P3)
- [open]  P4: Implement — Apply Discount (blocked by P4-Write-Tests)
- [open]  P4: Validate — Apply Discount (blocked by P4-Implement)

**Progress:** 3/8 issues closed (37%)
```

---

## Error Handling Procedures

### If Agent 1 RED Gate Fails

If tests pass immediately (before implementation):
1. **STOP** — the test is not testing new behavior
2. **Do NOT close the issue** — leave it open
3. **Report to user** — explain that tests pass without implementation
4. **Do NOT dispatch Agent 2** — the phase is broken

### If Phase Cannot Be Completed

If a phase cannot be completed after remediation:
1. **Update the issue to blocked** via `beads:update`
2. **Document the issue** in a comment via `beads:comments`
3. **Ask for guidance** — should we adjust the approach?
4. **Don't skip ahead** — beads dependency graph prevents this automatically

### If Beads State is Inconsistent

If `beads:ready` returns no tasks but open tasks remain:
1. Check `beads:blocked` to see what's stuck
2. Look for circular dependencies or missing closures
3. Report to user with the blocked issue details

---

## Session Recovery

Recovery requires no special logic:

1. User runs `/craft` in a new session
2. Identify the epic (user provides name or use `beads:search`)
3. Run `beads:ready` — returns exactly the next dispatchable tasks
4. Resume the orchestration loop from Step 2

Closed issues represent completed work (files already on disk). The orchestration loop picks up seamlessly.

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
- [ ] Respects architectural constraints from issue description

### Phase Verification
- [ ] Each phase validated by Agent 3 before proceeding
- [ ] Full test suite passes (not just new tests)
- [ ] Remediation attempts tracked (max 2 per phase)
- [ ] Issues closed only after gates pass

## Final Verification Template

Use this template after all issues in the epic are closed:

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
| 2     | closed    | closed    | closed   | 0            |
| 3     | n/a       | n/a       | n/a      | 0 (no-test)  |
| ...   | ...       | ...       | ...      | ...          |

**Total issues:** {count}
**Remediations:** {count}
**Session recoveries:** {count}

---

## Implementation Complete

All beads issues closed:
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
