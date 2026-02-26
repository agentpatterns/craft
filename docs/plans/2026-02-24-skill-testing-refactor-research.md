# Research: Skill Testing Refactor — Speed, Determinism, and External Evals

**Date:** 2026-02-24
**Topic:** Refactor skill testing for speed and determinism; separate local tests from external evals
**Status:** Research complete

---

## Problem Statement

The current skill testing framework is slow, flaky, and expensive. Every test — including trigger tests — invokes the Claude CLI, making even basic validation non-deterministic and API-cost-bearing. Functional tests require full skill execution (multi-turn, subagent dispatches), producing unpredictable runtimes with no timeout controls. The 754-line bash runner (`run-scenarios.sh`) has no CI integration, no parallelism, and heuristic-based assertion grading that frequently produces `SKIP` results.

---

## Current State

### What Exists

| Component | Location | Purpose |
|-----------|----------|---------|
| Runner script | `tests/runner/run-scenarios.sh` (754 lines) | Bash automation scaffold |
| Scenario YAMLs | `tests/scenarios/{craft,draft,reflect,research,tdd}.yaml` | 5 of 12 skills covered |
| Rubrics | `tests/rubrics/{structured-output,behavioral}.md` | Grading criteria for code + LLM-judge |
| Tests README | `tests/README.md` | Methodology and YAML format spec |

### Test Counts

| Skill | Trigger (pos/neg) | Functional | Grading Mix |
|-------|-------------------|------------|-------------|
| research | 10/10 | 5 | 2 code, 3 llm-judge |
| draft | 11/10 | 5 | 3 code, 2 llm-judge |
| craft | 10/10 | 6 | 4 code, 2 llm-judge |
| tdd | 11/10 | 5 | 3 code, 2 llm-judge |
| reflect | 10/12 | 3 | 2 code, 1 llm-judge |
| **Total** | **52/52** | **24** | **14 code, 10 llm-judge** |

### Why Tests Are Slow and Flaky

1. **Trigger tests call Claude CLI** — Each positive/negative trigger phrase invokes `claude --print`, making 104 API calls just for trigger validation. These should be pure text-matching.
2. **No timeouts** — Runner has no `--timeout` flag; tests run until Claude returns or hangs.
3. **Sequential execution** — No parallelism; each test waits for the previous to finish.
4. **Heuristic assertion grading** — `_grade_code_assertions` pattern-matches on English assertion text (e.g., `"file exists"` → `find`). Assertions that don't match any heuristic get `SKIP`.
5. **LLM-judge is non-deterministic** — 10 of 24 functional tests use `llm-judge` grading, which can flip pass/fail between runs.
6. **No regression baselines** — No stored expected scores, so there's no way to detect degradation vs. normal variance.
7. **No CI integration** — Tests are never run automatically.

---

## Recommendation: Three-Layer Testing Model

### Layer 1: Deterministic Local Tests (keep in repo, run on every commit)

**What belongs here:**
- **Trigger phrase matching** — Test that the skill `description` field contains expected keywords. No LLM needed. Pure regex/string matching against the frontmatter `description` field.
- **YAML schema validation** — Verify scenario files conform to the expected schema (required fields, valid `grading` values, etc.).
- **Skill structure validation** — Check that each skill directory has `SKILL.md`, valid frontmatter, `description` under 1024 chars, `triggers` array present, etc.
- **Rubric completeness** — Verify every skill with scenarios has corresponding rubric entries.
- **Runner dry-run** — The `--dry-run` mode already works without API calls; codify this as a test.

**Implementation:** Replace the 754-line bash script with a lightweight shell script or simple Node/Python script that:
- Parses YAML with `yq` (already a dependency)
- Runs pure string/regex assertions without Claude CLI
- Completes in seconds, not minutes
- Exits non-zero on failure for CI integration

**What to test deterministically from existing scenarios:**
- All 104 trigger phrases → regex match against `description` field (no API call)
- `file-exists` assertions → validate the assertion text is well-formed (the actual file check happens in evals)
- `section-present` assertions → validate regex syntax
- Schema validation of all 5 YAML files

### Layer 2: LLM Evals (move to external tool, run per-release or nightly)

**What belongs here:**
- All 10 `llm-judge` functional scenarios (research-02/04/05, draft-03/04, craft-03/06, tdd-04/05, reflect-03)
- All 14 `code`-graded functional scenarios (these still require invoking Claude to *produce* output, even though grading is deterministic)
- Self-consistency sampling (same prompt N times, measure variance)
- Performance comparison (with skill vs. without skill)

**Why external:** These tests invoke the Claude CLI to execute a full skill workflow, which is inherently slow, expensive, and non-deterministic. They belong in a dedicated eval pipeline with:
- Score thresholds rather than pass/fail
- Regression tracking over time
- Cost controls and parallelism
- Separate CI stage that doesn't block fast feedback

**Recommended tools (ranked by fit):**

| Tool | Fit | Why |
|------|-----|-----|
| **Promptfoo** | Best | YAML-native (matches existing format), `llm-rubric` assertion type, open-source CLI, native CI integration, agent testing support |
| **Braintrust** | Good | Code-first, MCP integration for Claude Code, trace capture, but requires rewriting YAML scenarios as code |
| **DeepEval** | Decent | Pytest-native, rich metrics, but Python-only and this repo has no Python infrastructure |

**tessl.io** — Confidence: Low. Eval format not publicly documented. Worth monitoring but not ready to adopt.
**skillbench.ai** — Confidence: Very Low. Site not accessible; may be pre-launch or internal-only.

### Layer 3: Human Review (keep manual, periodic)

**What belongs here:**
- Novel failure modes not yet captured in scenarios
- Calibrating LLM-judge rubrics (are the scoring dimensions right?)
- Cross-model testing (Haiku/Sonnet/Opus behavioral differences)
- The existing Claude A/B method from AGENTS.md

This layer stays manual. The current AGENTS.md documentation of the Claude A/B method is adequate.

---

## Files That Need Changes

### Delete
- `tests/runner/run-scenarios.sh` — Replace entirely with a deterministic local runner

### Rewrite
- `tests/README.md` — Update methodology to reflect three-layer model; remove references to the bash runner as the primary test mechanism; add Promptfoo/external eval instructions
- `AGENTS.md` — Update "Testing Skills" section (lines 103-150) and "Pre-Ship Checklist" (lines 152-178) to reflect new testing tiers
- `docs/architecture.md` — Line "There is no application code, build system, or test suite" is now inaccurate; update to describe the deterministic test suite

### Create
- `tests/local/validate-skills.sh` — Deterministic local test runner (schema, triggers, structure)
- `tests/evals/README.md` — Instructions for running external evals (Promptfoo or chosen tool)
- `tests/evals/promptfooconfig.yaml` — (If Promptfoo chosen) eval configuration pointing to existing scenario YAMLs

### Keep (no changes)
- `tests/scenarios/*.yaml` — The YAML format is good; scenarios serve as eval definitions for the external tool
- `tests/rubrics/*.md` — Rubric content is solid; referenced by eval tool configuration

---

## Open Questions

1. **Which external eval tool?** Promptfoo is the strongest fit given the existing YAML format, but requires the team to `npm install promptfoo`. Braintrust has MCP integration but requires rewriting scenarios as code. Need user decision.
2. **Should trigger testing remain in-repo at all?** If the `description` field is the testable unit, trigger "tests" are really just grep assertions on frontmatter. They could be a pre-commit hook rather than a test suite.
3. **CI/CD target?** GitHub Actions is the existing CI platform (bump-versions.yml exists). Should deterministic tests run as a GitHub Action? Should evals run on a schedule?
4. **Coverage gap:** 7 of 12 skills have no scenarios. Should the refactor also add missing scenarios, or just restructure what exists?

---

## Constraints

- This is a content-only repo (no build system, no application code)
- Dependencies should be minimal (currently just `yq` and `claude` CLI)
- The YAML scenario format is well-designed and should be preserved
- Rubric content should be preserved as-is
