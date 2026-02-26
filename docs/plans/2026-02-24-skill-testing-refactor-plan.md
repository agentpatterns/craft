# Skill Testing Refactor — Implementation Plan

**Date:** 2026-02-25
**Status:** Plan - Ready for Review
**Beads Epic:** skill-testing-refactor
**Research:** `docs/plans/2026-02-24-skill-testing-refactor-research.md`

## Goal

Replace the slow, flaky 754-line bash test runner with a three-layer testing model: deterministic local tests (seconds, CI-gated), Promptfoo-based LLM evals (per-release), and manual human review (unchanged). This eliminates 104 unnecessary API calls for trigger testing and provides a CI gate for structural validation.

## Acceptance Criteria

- [ ] Deterministic local tests validate all 12 skill structures (frontmatter, directory layout, description constraints)
- [ ] Deterministic local tests validate all 5 existing YAML scenario schemas
- [ ] Trigger phrases tested via pure regex/string matching against `description` field (no API calls)
- [ ] Promptfoo config wired to existing scenario YAMLs for LLM eval tier
- [ ] GitHub Actions workflow runs deterministic tests on every push
- [ ] Old `tests/runner/run-scenarios.sh` deleted
- [ ] `tests/README.md`, `AGENTS.md`, and `docs/architecture.md` updated to reflect new model
- [ ] All deterministic tests pass

## Files to Create

- `tests/local/validate-skills.sh` — Deterministic local test runner (schema, triggers, structure validation)
- `tests/evals/README.md` — Instructions for running Promptfoo-based LLM evals
- `tests/evals/promptfooconfig.yaml` — Promptfoo configuration pointing to existing scenario YAMLs
- `.github/workflows/test-skills.yml` — CI workflow for deterministic tests on push

## Files to Modify

- `tests/README.md` — Rewrite to reflect three-layer model, remove bash runner references
- `AGENTS.md` — Update "Testing Skills" (lines 103-150) and "Pre-Ship Checklist" (lines 152-178)
- `docs/architecture.md` — Remove "no test suite" claim, describe deterministic test suite

## Files to Delete

- `tests/runner/run-scenarios.sh` — Replaced by `tests/local/validate-skills.sh` + Promptfoo

## Implementation Phases

All phases are `[no-test]` — this is a content-only repo with no application code.

---

### Phase 1: Create Deterministic Local Test Runner
**Goal:** Replace API-calling trigger/structure tests with pure local validation

**Tasks:**
1. Create `tests/local/validate-skills.sh` with these checks:
   - **Skill structure validation:** Each skill dir under `plugins/crafter/skills/` has `SKILL.md` with valid YAML frontmatter containing `name`, `description`, `triggers`, `allowed-tools`
   - **Description constraints:** `description` < 1024 chars, no XML angle brackets
   - **Trigger validation:** `triggers` is a non-empty array, each trigger is multi-word (no bare single-word triggers)
   - **Name consistency:** Frontmatter `name` matches directory name (kebab-case)
   - **Line count:** `SKILL.md` ≤ 300 lines
   - **Trigger phrase matching:** All positive trigger phrases from existing scenario YAMLs match against skill `description` via regex/string containment (no API call)
   - **YAML schema validation:** All scenario files in `tests/scenarios/` have required fields (`skill`, `category`, `triggers.positive`, `triggers.negative`, `functional`)
   - **Rubric completeness:** Every skill with scenarios has entries in the appropriate rubric file
2. Make executable, use `yq` for YAML parsing (existing dependency)
3. Exit non-zero on any failure, human-readable TAP-like output

**Verification:**
- [ ] Script runs in < 5 seconds
- [ ] Catches intentionally broken frontmatter
- [ ] All current skills pass

#### Agent Context
- **Files to create:** `tests/local/validate-skills.sh`
- **Files to read:** `plugins/crafter/skills/*/SKILL.md`, `tests/scenarios/*.yaml`, `tests/rubrics/*.md`
- **Commands to run:** `chmod +x tests/local/validate-skills.sh && bash tests/local/validate-skills.sh`
- **Acceptance gate:** Script exits 0 with all checks passing; exits non-zero when a check fails
- **Architectural constraints:** Shell script only. Dependencies: `yq`, `grep`, `wc`. No `claude` CLI invocations. No network calls.

---

### Phase 2: Create Promptfoo Eval Configuration
**Goal:** Wire existing scenario YAMLs to Promptfoo for LLM eval tier

**Tasks:**
1. Create `tests/evals/promptfooconfig.yaml` with:
   - Provider: `claude` CLI
   - Test cases derived from the 5 existing scenario YAML files (24 functional scenarios)
   - `llm-rubric` assertion type for the 10 llm-judge scenarios
   - `contains`/`icontains`/`regex` assertions for the 14 code-graded scenarios
   - Reference to rubric files for judge prompt templates
2. Create `tests/evals/README.md` with:
   - Prerequisites (`npm install -g promptfoo`)
   - How to run evals (`promptfoo eval`)
   - How to view results (`promptfoo view`)
   - Cost expectations and recommended frequency (per-release or nightly)
   - How to add new eval scenarios

**Verification:**
- [ ] `promptfoo eval --dry-run` succeeds (validates config without running)
- [ ] README is clear and complete

#### Agent Context
- **Files to create:** `tests/evals/promptfooconfig.yaml`, `tests/evals/README.md`
- **Files to read:** `tests/scenarios/*.yaml`, `tests/rubrics/behavioral.md`, `tests/rubrics/structured-output.md`
- **Commands to run:** `cd tests/evals && promptfoo eval --dry-run` (if promptfoo installed)
- **Acceptance gate:** Config is valid YAML; dry-run doesn't error; README covers prerequisites, usage, and adding scenarios
- **Architectural constraints:** Config only — no custom code. Reference existing scenario YAMLs as data source. Promptfoo is the only new dependency (dev-only, not committed to repo deps).

---

### Phase 3: Create GitHub Actions CI Workflow
**Goal:** Gate pushes with deterministic skill validation

**Tasks:**
1. Create `.github/workflows/test-skills.yml`:
   - Trigger: push to any branch, PR to main
   - Install `yq` via `apt-get` or action
   - Run `bash tests/local/validate-skills.sh`
   - Fail the workflow if script exits non-zero
2. Keep it minimal — no caching, no matrix, no Promptfoo (evals are separate)

**Verification:**
- [ ] Workflow YAML is valid (passes `actionlint` or manual review)
- [ ] Workflow references correct script path

#### Agent Context
- **Files to create:** `.github/workflows/test-skills.yml`
- **Files to read:** `.github/workflows/bump-versions.yml` (follow existing patterns)
- **Commands to run:** None required locally — validation is structural
- **Acceptance gate:** Valid GitHub Actions YAML; triggers on push/PR; installs `yq`; runs `tests/local/validate-skills.sh`
- **Architectural constraints:** Minimal workflow. No secrets needed. No Promptfoo — evals run separately.

---

### Phase 4: Update Documentation
**Goal:** Align docs with three-layer testing model

**Tasks:**
1. **`tests/README.md`** — Rewrite to describe:
   - Three-layer model (deterministic → Promptfoo evals → human review)
   - How to run local tests (`bash tests/local/validate-skills.sh`)
   - How to run evals (link to `tests/evals/README.md`)
   - YAML scenario format (preserve existing documentation)
   - Grading tiers (preserve existing documentation)
2. **`AGENTS.md`** — Update:
   - "Testing Skills" section: reference local runner for structure/triggers, Promptfoo for functional/behavioral
   - "Pre-Ship Checklist" Testing subsection: require `validate-skills.sh` pass, recommend Promptfoo eval for new scenarios
3. **`docs/architecture.md`** — Update line about "no test suite" to describe the deterministic test suite and eval pipeline

**Verification:**
- [ ] No references to `run-scenarios.sh` remain in any doc
- [ ] Three-layer model clearly documented
- [ ] Instructions are actionable (copy-pasteable commands)

#### Agent Context
- **Files to modify:** `tests/README.md`, `AGENTS.md` (lines 103-178), `docs/architecture.md` (line 5)
- **Files to read:** `tests/local/validate-skills.sh` (for accurate command references), `tests/evals/README.md`
- **Acceptance gate:** All three files updated; no stale references to old runner; `grep -r "run-scenarios" .` returns no results
- **Architectural constraints:** Preserve existing content that remains accurate (YAML format spec, rubric documentation, Claude A/B method). Only update what changed.

---

### Phase 5: Delete Old Runner
**Goal:** Remove superseded test infrastructure

**Tasks:**
1. Delete `tests/runner/run-scenarios.sh`
2. Delete `tests/runner/` directory if empty after deletion

**Verification:**
- [ ] `tests/runner/` no longer exists
- [ ] No remaining references in docs (covered by Phase 4)

#### Agent Context
- **Files to delete:** `tests/runner/run-scenarios.sh`, `tests/runner/` (directory)
- **Commands to run:** `rm tests/runner/run-scenarios.sh && rmdir tests/runner`
- **Acceptance gate:** Directory removed; `find . -path "*/runner/run-scenarios.sh"` returns nothing

---

### Phase 6: Verification
**Goal:** Confirm everything works end-to-end

**Tasks:**
1. Run `bash tests/local/validate-skills.sh` — all checks pass
2. Run `promptfoo eval --dry-run` in `tests/evals/` (if installed) — config valid
3. Verify no stale references: `grep -r "run-scenarios" .` returns nothing
4. Review GitHub Actions workflow for correctness
5. Confirm all acceptance criteria from plan are met

**Verification:**
- [ ] All acceptance criteria pass
- [ ] Local tests green
- [ ] No stale references

#### Agent Context
- **Full test command:** `bash tests/local/validate-skills.sh`
- **Acceptance gate:** All acceptance criteria from top of plan verified

## Constraints & Considerations

### Architectural
- This is a content-only repo — no build system, no application code
- Dependencies must be minimal: `yq` (existing), `promptfoo` (dev-only, optional)
- Preserve the existing YAML scenario format — it's well-designed
- Preserve rubric content as-is

### Testing
- Deterministic layer must complete in seconds (no API calls)
- Eval layer (Promptfoo) is opt-in and not gated in CI
- Trigger testing moves from LLM-based to regex-based — accepts the trade-off that regex matching against `description` is less accurate than an LLM deciding, but eliminates 104 API calls and non-determinism

### Coverage
- 7 of 12 skills lack scenario coverage — this is out of scope for this refactor
- Missing scenarios can be added incrementally using the new framework

## Out of Scope

- Adding scenarios for uncovered skills (pair, tidy, diagram, scaffold, hexagonal-architecture, adr)
- Pre-commit hooks (CI workflow is sufficient for now)
- Promptfoo CI integration (evals remain manual/per-release)
- Cost tracking or regression baselines for evals
- Self-consistency sampling or performance benchmarking

## Approval Checklist

Before implementing, verify:
- [x] All files to create/modify/delete listed
- [x] Implementation phases have clear boundaries
- [x] Each phase has an Agent Context block
- [x] No application code — all phases are `[no-test]`
- [x] Acceptance criteria are testable
- [x] Constraints documented
- [x] Out of scope items noted

## Next Steps

After review and approval:
1. Run `/craft` to execute — dispatches agents from beads issues
2. Each phase runs sequentially via dependency chain
3. If interrupted, `/craft` picks up where it left off via `beads:ready`
4. If changes needed, clarify what to adjust and I'll update both the plan and beads issues
