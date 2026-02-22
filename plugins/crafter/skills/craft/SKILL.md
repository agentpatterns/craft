---
name: craft
description: Implement phase of RPI methodology. Executes beads-driven task graph using isolated agents for test-first discipline. Use when executing an implementation plan from the draft skill.
triggers:
  - "implement"
  - "execute plan"
  - "build from plan"
allowed-tools: Read Glob Write Bash Task TaskOutput Skill
---

# Craft Implement Skill

**RPI Phase 3 of 3:** Research → Plan → **Implement**

Use this skill to execute an implementation plan using beads-driven orchestration with isolated agents for strict test-first discipline.

## Purpose

The Implement phase executes a beads task graph created by `/draft`. Each beads issue is a self-contained agent task with everything needed for dispatch. The dependency graph enforces ordering. `beads:ready` drives execution.

Three agent types per TDD phase:
- **Agent 1 (Write Test):** Creates failing tests from the issue's test spec — knows nothing about the implementation
- **Agent 2 (Implement):** Writes minimal code to make tests pass — guided only by the tests
- **Agent 3 (Validate):** Runs the full test suite — confirms nothing is broken

**Input:** Beads epic with per-agent-step issues (created by `/draft`)
**Output:** Working feature with passing tests

## When to Use

Use this skill when:
- Have a complete beads task graph from `/draft`
- Ready to execute plan phase by phase
- Want strict test/implementation isolation enforced
- Resuming an interrupted implementation session

**Don't use** for:
- Exploratory coding without a plan
- Simple bug fixes
- Research or planning tasks

## Execution Log

**REQUIRED:** Create `craft-execution-log.md` in the project root at the start of every craft session. Append entries throughout orchestration. This provides an observable audit trail of agent dispatch and gate results.

Entry format (one per line, append-only):
```
[DISPATCHED] {issue title} — agent type: {agent-test|agent-impl|agent-validate}, mode: {sync|parallel}
[GATE PASS] {issue title} — {RED|GREEN|VALIDATE} gate passed
[GATE FAIL] {issue title} — {RED|GREEN|VALIDATE} gate failed: {reason}
[CLOSED] {issue title}
[REMEDIATION] {issue title} — attempt {N}: {description}
[BLOCKED] {issue title} — escalating to user: {reason}
```

## Beads Availability

Before starting the orchestration loop, check whether beads is available by attempting `beads:search`.

- **Beads available:** Follow the standard beads-driven orchestration loop below.
- **Beads unavailable:** Switch to **Inline Execution Mode** — treat the epic context provided inline (in the task prompt or plan file) as if it were returned by `beads:show`. Process issues in dependency order as described in the inline context. Use `craft-execution-log.md` as the sole record of progress. Skip all `beads:*` commands but follow all other workflow steps identically (agent dispatch, gates, remediation).

## Workflow

### 1. Identify the Epic

Find the target epic via user input or `beads:search`. Verify the epic has issues with dependencies wired. If beads is unavailable, use the inline epic context provided in the task prompt.

If resuming a previous session, this step is the same — `beads:ready` will return only unblocked, uncompleted tasks.

### 2. Beads-Driven Orchestration Loop

This is the core execution loop. It runs until all issues in the epic are closed or an unrecoverable error occurs.

```
Loop:
  a. Run beads:ready for the epic → list of unblocked tasks
  b. If no ready tasks and open tasks remain → something is blocked, escalate to user
  c. If no ready tasks and no open tasks remain → all done, proceed to final verification
  d. For each ready task:
     - Read issue description (contains full Agent Context)
     - Determine agent type from label (agent-test, agent-impl, agent-validate, no-test)
     - Dispatch Task with agent prompt built from issue description
     - If multiple ready tasks: dispatch in parallel (single message, multiple Task calls)
  e. Wait for agent(s) to complete
  f. For each completed agent:
     - If gate PASSED → close the issue via beads:close → unblocks dependents
     - If RED gate FAILED (tests pass immediately) → STOP, report to user
     - If GREEN gate FAILED → proceed to validation anyway
     - If VALIDATE found failures → create remediation issues (see Remediation)
  g. Loop back to (a)
```

See [workflow-detail.md](references/workflow-detail.md) for agent prompt templates and dispatch details.

#### Dispatching Agents

For each ready issue, build the agent prompt from the issue description:

1. Read the issue description via `beads:show`
2. The description contains the full Agent Context — file paths, test specs, commands, gates, constraints
3. Dispatch via `Task` tool (synchronous, `subagent_type: general-purpose`)
4. The agent does NOT need to read the plan file — the issue is self-contained

#### Parallel Dispatch

When `beads:ready` returns multiple tasks, dispatch them all in a **single message with multiple `Task` tool calls**. This happens naturally when:
- Two independent phases have no dependency between them
- A no-test phase and a test-write phase are both unblocked

TDD phases can't parallelize internally (Implement needs Write Test's output on disk), but independent phases parallelize across each other automatically via the dependency graph.

#### Remediation

When Agent 3 (Validate) finds failures:

1. Create a remediation issue via `beads:create` with label `agent-remediate`:
   - Title: `P{N}: Remediate — {Phase Name} (attempt {M})`
   - Description: includes failure output from Agent 3 (see [workflow-detail.md](references/workflow-detail.md) for template)
   - Blocked-by the failed Validate issue
2. Create a re-validation issue via `beads:create` with label `agent-validate`:
   - Title: `P{N}: Re-Validate — {Phase Name} (attempt {M})`
   - Blocked-by the remediation issue
3. Wire the next phase's first issue to be blocked-by the re-validation issue (replacing the original Validate dependency)
4. Close the original Validate issue (it completed its job — reporting failures)
5. If attempt count reaches 2 and re-validation still fails, update the issue to `blocked` status and **STOP — ask the user**

### 3. Report Progress

After each issue closes, report status. Use `beads:list` to show overall progress:
```markdown
**Progress Update:**
- [closed] P1: Apply Schema
- [closed] P2: Write Tests — Core Logic
- [closed] P2: Implement — Core Logic
- [open]  P2: Validate — Core Logic (in progress)
- [open]  P3: Repository Layer (blocked)
- [open]  P4: Write Tests — Apply Discount (blocked)
```

### 4. Final Verification

After all issues in the epic are closed:
1. Run the full test suite one final time
2. Verify all acceptance criteria from the epic are met
3. Report the agent execution summary (issues closed, remediations)
4. Suggest next steps (commit, PR, follow-up)

## Agent Isolation Discipline

**CRITICAL:** The three-agent pattern exists to maintain honest separation between tests and implementation.

### Rules

1. **Agent 1 writes tests only** — never implementation code
2. **Agent 2 writes implementation only** — never modifies test files
3. **Agent 3 modifies nothing** — only runs tests and reports
4. **Agent 2-R fixes implementation only** — never modifies test files
5. **Each agent starts fresh** — no shared context between agents

### If RED Gate Fails

If Agent 1's tests pass immediately (before implementation):
1. STOP — the test is tautological or the feature already exists
2. Report to user — explain what happened
3. Do NOT close the issue — leave it open for user decision

### If GREEN Gate Fails

If Agent 2 cannot make tests pass:
1. Proceed to Agent 3 anyway (to get full failure report)
2. Enter remediation via dynamic issue creation
3. After 2 failed remediations, STOP and ask user

## Session Recovery

Recovery is trivial: run `beads:ready` for the epic.

- **Closed issues** = completed work (agents ran, gates passed, files on disk)
- **Ready issues** = next tasks to dispatch
- **Blocked issues** = waiting on dependencies or human input

No special recovery logic needed. The beads state *is* the execution state.

## Anti-Patterns to Avoid

- **Don't let agents share context** — each agent starts from the beads issue and files on disk
- **Don't skip Agent 3** — validation catches regressions in other tests
- **Don't modify tests during implementation** — tests define the contract
- **Don't read the plan file during execution** — beads issues are self-contained
- **Don't improvise beyond the plan** — stick to the beads issues or update them explicitly
- **Don't run agents in background** — synchronous dispatch ensures ordering

## After Implementation

Once all issues closed and verified:
1. **Run full test suite** — confirm everything passes
2. **Verify acceptance criteria** — all must be met
3. **Manual smoke test** — try key user journeys if applicable
4. **Create commit** — use `/commit` skill
5. **Document follow-up** — note any deferred work

## Context Compaction

**Why isolated agents?** Each agent loads only what it needs:
- **Agent 1:** Issue's test spec + project test patterns → writes tests
- **Agent 2:** Test files on disk + issue's constraints → writes implementation
- **Agent 3:** Test command from issue → runs and reports

No agent carries the full research or planning context. Each beads issue description provides exactly the information the dispatched agent needs.
