---
name: craft
description: Implement phase of RPI methodology. Executes a yaks-driven task graph using isolated agents with strict RED/GREEN/VALIDATE gate enforcement. Use when executing an implementation plan from the draft skill.
triggers:
  - "implement the plan"
  - "execute plan"
  - "build from plan"
  - "implement from plan"
allowed-tools: Read Glob Write Bash Task TaskOutput Skill
---

# Craft Implement Skill

**RPI Phase 3 of 3:** Research → Plan → **Implement**

Use this skill to execute an implementation plan using yaks-driven orchestration with isolated agents for strict test-first discipline.

## Phase Contract

**Receives:** Yaks task graph (epic yak + per-agent-step child yaks) created by `/draft` — or creates it from the plan file if the yaks graph doesn't exist yet
**Produces:** Working feature with passing tests + `craft-execution-log.md` execution audit trail + session artifact at `.claude/sessions/`
**Does NOT read:** The plan file during execution — yak contexts are self-contained

## Purpose

The Implement phase executes a yaks task graph created by `/draft`. Each yak's context contains everything needed for agent dispatch. The naming convention enforces ordering. Readiness is computed from `yx list --format json`.

Three registered agents per TDD phase (see `plugins/crafter/agents/`):
- **agent-test** (RED): Creates failing tests from the yak's test spec — knows nothing about the implementation
- **agent-impl** (GREEN): Writes minimal code to make tests pass + YAGNI simplification — guided only by the tests
- **agent-validate** (VALIDATE): Runs the full test suite — confirms nothing is broken

Plus **agent-remediate** for fixing failures and **agent-no-test** for non-TDD phases.

## When to Use

Use this skill when:
- Have a complete yaks task graph from `/draft`
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
[DISPATCHED] {yak name} — agent type: {agent-test|agent-impl|agent-validate}, mode: {sync|parallel}
[GATE PASS] {yak name} — {RED|GREEN|VALIDATE} gate passed
[GATE FAIL] {yak name} — {RED|GREEN|VALIDATE} gate failed: {reason}
[CLOSED] {yak name}
[REMEDIATION] {yak name} — attempt {N}: {description}
[BLOCKED] {yak name} — escalating to user: {reason}
```

## Yaks Availability

Before starting the orchestration loop, check whether yaks is available by running `yx list --format json`.

- **Yaks available:** Follow the standard yaks-driven orchestration loop below.
- **Yaks unavailable:** Switch to **Inline Execution Mode** — treat the epic context provided inline (in the task prompt or plan file) as if it were returned by `yx context`. Process tasks in the order described in the inline context. Use `craft-execution-log.md` as the sole record of progress. Skip all `yx` commands but follow all other workflow steps identically (agent dispatch, gates, remediation).

## Workflow

### 1. Identify the Epic (or Create Yaks Graph)

Find the target epic yak via user input or `yx list --format json`. Verify the epic has child yaks with agent-type fields set.

**If no yaks epic exists yet:** The plan was approved but yaks decomposition hasn't run. Read the plan file (Claude Code session plan or user-provided path) and create the yaks task graph now — epic yak + per-agent-step child yaks with contexts piped in. See the [yaks-decomposition procedure](../draft/references/yaks-decomposition.md). This makes craft resilient whether invoked after draft's yaks creation or directly after plan approval.

If yaks is unavailable, use the inline epic context provided in the task prompt.

If resuming a previous session, this step is the same — the readiness computation skips done yaks automatically.

### 2. Yaks-Driven Orchestration Loop

This is the core execution loop. It runs until all yaks in the epic are done or an unrecoverable error occurs.

```
Loop:
  a. Compute ready tasks (see Readiness Computation below)
  b. If no ready tasks and non-done tasks remain → something is stuck, escalate to user
  c. If no ready tasks and all tasks are done → all done, proceed to final verification
  d. For each ready task:
     - Read yak context via: yx context "{yak name}"
     - Determine agent type from field: agent-type (agent-test, agent-impl, agent-validate, no-test)
     - Dispatch Task with agent prompt built from yak context
     - If multiple ready tasks: dispatch in parallel (single message, multiple Task calls)
  e. Wait for agent(s) to complete
  f. For each completed agent:
     - If gate PASSED → mark done: yx done "{yak name}"
     - If RED gate FAILED (tests pass immediately) → STOP, report to user
     - If GREEN gate FAILED → proceed to validation anyway
     - If VALIDATE found failures → create remediation yaks (see Remediation)
  g. Loop back to (a)
```

See [workflow-detail.md](references/workflow-detail.md) for agent prompt templates and dispatch details.

### Readiness Computation

Parse `yx list --format json` for the epic and apply these rules:

1. **Extract phase prefix** from each top-level child's name (e.g., `P2` from `P2-Core-Logic`)
2. **Group by prefix number**: P1 group, P2 group, etc.
3. **A group is active** when ALL yaks in ALL lower-numbered groups are done
4. **Within an active group**:
   - **Leaf yak** (no children): ready if state != `done`
   - **Parent yak** (has children): first child by name sort with state != `done` is ready
5. **Collect all ready tasks** across all active groups → dispatch in parallel

This replaces the external tracker's `ready` command with ~20 lines of in-skill logic, enabling parallel dispatch across independent phase groups while enforcing sequential ordering within TDD triplets.

#### Dispatching Agents

For each ready yak, build the agent prompt from its context:

1. Read the yak context via `yx context "{yak name}"`
2. The context contains the full Agent Context — file paths, test specs, commands, gates, constraints
3. Dispatch via `Task` tool using the registered agent type matching the yak's `agent-type` field (e.g., `subagent_type: crafter:agent-test`)
4. The agent does NOT need to read the plan file — the yak context is self-contained

#### Parallel Dispatch

When readiness computation returns multiple tasks, dispatch them all in a **single message with multiple `Task` tool calls**. This happens naturally when:
- Two independent phase groups have the same prefix number (e.g., P2-Feature-A and P2-Feature-B)
- A no-test phase and a test-write phase are both ready

TDD phases can't parallelize internally (Implement needs Write Test's output on disk), but independent phases parallelize across each other automatically via the naming convention.

#### Remediation

When Agent 3 (Validate) finds failures:

1. Create a remediation yak via `yx add` with `--field "agent-type=agent-remediate"`:
   - Name: `04-remediate-attempt-{M}` under the same phase group parent
   - Pipe context: failure output from Agent 3 (see [workflow-detail.md](references/workflow-detail.md) for template)
2. Create a re-validation yak via `yx add` with `--field "agent-type=agent-validate"`:
   - Name: `05-revalidate-attempt-{M}` under the same phase group parent
3. Mark the original validate yak as done (it completed its job — reporting failures)
4. The sequential naming convention ensures remediation runs before re-validation
5. If attempt count reaches 2 and re-validation still fails, **STOP — ask the user**

### 3. Report Progress

After each yak completes, report status. Use `yx list` to show overall progress:
```markdown
**Progress Update:**
- [done] P1-Schema-Setup
- [done] P2-Core-Logic / 01-write-tests
- [done] P2-Core-Logic / 02-implement
- [wip]  P2-Core-Logic / 03-validate (dispatched)
- [todo] P3-Repository-Layer (waiting for P2)
- [todo] P4-Apply-Discount (waiting for P3)
```

### 4. Final Verification

After all yaks in the epic are done:
1. Run the full test suite one final time
2. Verify all acceptance criteria from the epic are met
3. Report the agent execution summary (yaks closed, remediations)

Check plannotator availability: `Bash: plannotator --version`

**If available:** Run `plannotator review` via Bash to open the full git diff in the browser code review UI. Wait for the result:
- **"LGTM" returned:** Proceed to the next-steps prompt.
- **Feedback returned:** Address each item — fix code, NOT tests. Re-run the full test suite after fixes. Then re-run `plannotator review`. Repeat until LGTM.

**If unavailable:** Skip browser review; proceed to next-steps prompt.

### 5. Write Session Artifact

After final verification passes, write a single session artifact to `.claude/sessions/YYYY-MM-DD-{topic}.md`. This is the ONLY persistent artifact from the entire research → plan → implement flow.

**Required sections:**
- **Research Summary** — Key findings from the plan's inline research section (or "No research phase" if skipped)
- **Plan Summary** — Phases, acceptance criteria, architectural decisions
- **Execution Log** — Agent dispatches, gate results, remediations (from `craft-execution-log.md`)
- **Outcome** — Final test suite result, acceptance criteria status

Use kebab-case for the topic slug (e.g., `2026-03-07-add-discount-codes.md`).

### 6. Post-Execution Recommendations

Use `AskUserQuestion` to present:

```
Implementation complete. All {N} tasks done, tests passing.
Session artifact: .claude/sessions/YYYY-MM-DD-{topic}.md

What would you like to do?

1. Code review — review the diff for quality issues
2. Simplify — refine recently modified code for clarity and maintainability
3. Reflect — extract learnings to improve skills, hooks, CLAUDE.md
4. Commit and push — run /commit
```

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
3. Do NOT mark the yak as done — leave it for user decision

### VALIDATE Gate Definition

The VALIDATE gate is the project's full test and lint suite. Agent 3 determines the gate command by reading the project's `CLAUDE.md` (or `package.json` / equivalent build file) for the configured test, type-check, and lint commands. All commands must exit 0.

Example for a TypeScript/Bun project: `tsc --noEmit && vitest run && biome check .`
Example for a Python project: `mypy . && pytest && ruff check .`

Agent 3 always derives the actual commands from the project rather than using hardcoded defaults.

### Lint Fast Path

If VALIDATE fails **only on the lint command** (tests pass, type-check clean), apply the lint fast path instead of creating remediation yaks:

1. Run the project's lint auto-fix command (e.g., `biome check --write --unsafe`, `ruff check --fix .`)
2. Re-run the full VALIDATE gate
3. If gate passes → mark the Validate yak as done and proceed
4. If gate still fails → fall through to standard remediation

This avoids heavyweight remediation for trivially auto-fixable lint issues.

### If GREEN Gate Fails

If Agent 2 cannot make tests pass:
1. Proceed to Agent 3 anyway (to get full failure report)
2. Enter remediation via dynamic yak creation
3. After 2 failed remediations, STOP and ask user

## Session Recovery

Recovery is trivial: run `yx list --format json` for the epic and recompute readiness.

- **Done yaks** = completed work (agents ran, gates passed, files on disk)
- **Ready yaks** = next tasks to dispatch (computed from naming convention)
- **Waiting yaks** = predecessor groups not yet done

No special recovery logic needed. The yaks state + naming convention IS the execution state.

## Anti-Patterns to Avoid

- **Don't let agents share context** — each agent starts from the yak context and files on disk
- **Don't skip Agent 3** — validation catches regressions in other tests
- **Don't modify tests during implementation** — tests define the contract
- **Don't read the plan file during execution** — yak contexts are self-contained
- **Don't improvise beyond the plan** — stick to the yak tasks or update them explicitly
- **Don't run agents in background** — synchronous dispatch ensures ordering
- **Don't treat a lint-only VALIDATE failure as a full remediation event** — use the lint fast path (auto-fix command from project CLAUDE.md) instead

## After Implementation

Once all yaks done and verified:
1. **Session artifact written** — `.claude/sessions/YYYY-MM-DD-{topic}.md` is the persistent record
2. **Post-execution recommendations presented** — code-review, simplify, reflect, commit
3. **Manual smoke test** — try key user journeys if applicable
4. **Create commit** — use `/commit` skill
5. **Document follow-up** — note any deferred work

## Context Compaction

**Why isolated agents?** Each agent loads only what it needs:
- **Agent 1:** Yak's test spec + project test patterns → writes tests
- **Agent 2:** Test files on disk + yak's constraints → writes implementation
- **Agent 3:** Test command from yak → runs and reports

No agent carries the full research or planning context. Each yak context provides exactly the information the dispatched agent needs.
