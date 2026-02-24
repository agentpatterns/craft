# Skill Testing Framework - Implementation Plan

**Date:** 2026-02-23
**Status:** Plan - Ready for Review
**Beads Epic:** Skill Testing Framework
**Research:** `docs/plans/2026-02-23-skill-testing-research.md`

## Goal

Create a structured testing framework for 5 crafter skills (research, draft, craft, tdd, reflect) with machine-readable YAML scenarios, grading rubrics, and a lightweight automation scaffold for Claude API-driven test execution.

## Acceptance Criteria

- [ ] `tests/` directory with README documenting methodology
- [ ] YAML scenario format defined with triggering + functional sections
- [ ] Trigger scenarios (positive + negative) for all 5 skills
- [ ] Functional scenarios (Given/When/Then) for all 5 skills (min 3 each)
- [ ] Grading rubrics for structured-output and behavioral skill categories
- [ ] Automation scaffold script that reads scenarios and invokes Claude API

## Files to Create

```
tests/
├── README.md                          # Testing methodology, format spec, how to run
├── scenarios/
│   ├── research.yaml                  # Trigger + functional scenarios
│   ├── draft.yaml
│   ├── craft.yaml
│   ├── tdd.yaml
│   └── reflect.yaml
├── rubrics/
│   ├── structured-output.md           # Category A grading (research, draft, craft, tdd)
│   └── behavioral.md                  # Category B grading (reflect)
└── runner/
    └── run-scenarios.sh               # Automation scaffold (Claude API invocation)
```

## Implementation Phases

### Phase 1: Test Infrastructure [no-test]
**Goal:** Create directory structure, README with methodology, and YAML format definition

**Tasks:**
1. Create `tests/` directory tree
2. Write `tests/README.md` covering:
   - Three testing areas (Triggering, Functional, Performance)
   - YAML scenario format spec with field definitions
   - Grading tiers (code > LLM-judge > human)
   - Claude A/B method workflow reference
   - How to run tests (manual + automated)
3. Define YAML schema by example (embedded in README)

**Verification:**
- [ ] README covers all three testing areas
- [ ] YAML format spec includes triggering and functional sections
- [ ] Example scenario demonstrates all fields

#### Agent Context
- **Files to create:** `tests/README.md`
- **Reference files to read:** `AGENTS.md` (Testing Skills section), research artifact
- **Acceptance gate:** README exists with methodology, format spec, and example scenario
- **Constraints:** Keep README under 150 lines; format spec must match research findings 1-5

---

### Phase 2: Trigger Scenarios [no-test]
**Goal:** Create trigger test datasets for all 5 skills (positive + negative phrases)

**Tasks:**
1. Read each skill's `SKILL.md` frontmatter for `description` and `triggers`
2. For each skill, write 5+ positive triggers and 5+ negative triggers
3. Include edge cases: ambiguous phrases, partial matches, cross-skill confusion

**Verification:**
- [ ] Each skill file has `triggering` section with `positive` and `negative` arrays
- [ ] Negative triggers include phrases that should activate a *different* skill
- [ ] At least 10 trigger phrases per skill (5 positive, 5 negative)

#### Agent Context
- **Files to create:** `tests/scenarios/research.yaml`, `tests/scenarios/draft.yaml`, `tests/scenarios/craft.yaml`, `tests/scenarios/tdd.yaml`, `tests/scenarios/reflect.yaml`
- **Files to read:** Each skill's `SKILL.md` (frontmatter `description` + `triggers`)
- **Acceptance gate:** All 5 YAML files exist with `triggering.positive[]` and `triggering.negative[]` arrays
- **Constraints:** Test the `description` field (not `triggers` array) — description is the testable unit per research Finding 3

---

### Phase 3: Functional Scenarios — Research & Draft [no-test]
**Goal:** Add functional test scenarios for the two artifact-producing planning skills

**Tasks:**
1. For `research`: 3+ scenarios testing output structure, section presence, web research handling, ~200-line target, parallel agent dispatch
2. For `draft`: 3+ scenarios testing plan file structure, Agent Context blocks, beads task graph creation, TDD phase decomposition
3. Each scenario: Given (setup context), When (invocation), Then (assertions with grading method)

**Verification:**
- [ ] Each skill has `functional` section with 3+ scenarios
- [ ] Assertions reference testable contracts from research artifact
- [ ] Grading method specified per assertion (code-check, llm-judge, human)

#### Agent Context
- **Files to modify:** `tests/scenarios/research.yaml`, `tests/scenarios/draft.yaml`
- **Files to read:** Research artifact (Testable Contracts section), `plugins/crafter/skills/research/SKILL.md`, `plugins/crafter/skills/draft/SKILL.md`
- **Acceptance gate:** Both YAML files have `functional[]` with 3+ scenarios each, assertions include grading method
- **Constraints:** Assertions must be behavioral (what the output contains/looks like), not procedural (what steps Claude took)

---

### Phase 4: Functional Scenarios — Craft & TDD [no-test]
**Goal:** Add functional test scenarios for the two execution-discipline skills

**Tasks:**
1. For `craft`: 3+ scenarios testing execution log creation, gate evaluation, lint fast path, remediation limits, final verification
2. For `tdd`: 3+ scenarios testing session log creation, ZOMBIES coverage, phase separation, test-before-code discipline
3. Each scenario: Given/When/Then with grading method

**Verification:**
- [ ] Each skill has `functional` section with 3+ scenarios
- [ ] Craft scenarios cover gate pass + gate fail paths
- [ ] TDD scenarios cover ZOMBIES letter coverage

#### Agent Context
- **Files to modify:** `tests/scenarios/craft.yaml`, `tests/scenarios/tdd.yaml`
- **Files to read:** Research artifact (Testable Contracts section), `plugins/crafter/skills/craft/SKILL.md`, `plugins/crafter/skills/tdd/SKILL.md`
- **Acceptance gate:** Both YAML files have `functional[]` with 3+ scenarios each
- **Constraints:** Craft gate scenarios need both pass and fail expectations; TDD must test phase separation (RED before GREEN)

---

### Phase 5: Functional Scenarios — Reflect [no-test]
**Goal:** Add functional test scenarios for the behavioral/interactive skill (Category B)

**Tasks:**
1. 3+ scenarios testing parallel agent dispatch, improvement proposals, proposal categorization, session summary
2. Include LLM-judge assertions for subjective qualities (relevance, actionability)
3. Define what "good" looks like for LLM-judge evaluation

**Verification:**
- [ ] Reflect has `functional` section with 3+ scenarios
- [ ] At least 1 scenario uses `grading: llm-judge` with judge prompt
- [ ] Judge prompts are specific enough to be reproducible

#### Agent Context
- **Files to modify:** `tests/scenarios/reflect.yaml`
- **Files to read:** Research artifact (Testable Contracts section), `plugins/crafter/skills/reflect/SKILL.md`
- **Acceptance gate:** YAML file has `functional[]` with 3+ scenarios, at least one uses LLM-judge grading
- **Constraints:** LLM-judge prompts must include scoring criteria (pass/fail threshold) — not open-ended

---

### Phase 6: Grading Rubrics [no-test]
**Goal:** Create reusable grading rubrics for both skill categories

**Tasks:**
1. `tests/rubrics/structured-output.md` — code-grading checklist for Category A skills:
   - File existence checks
   - Required section presence (regex/string match)
   - Structural validation (YAML parseable, correct nesting)
   - Quantitative checks (line count ranges, array lengths)
2. `tests/rubrics/behavioral.md` — LLM-judge rubric for Category B skills:
   - Evaluation prompt template
   - Scoring dimensions (relevance, completeness, actionability)
   - Pass/fail thresholds
   - Example judge prompt + expected scoring

**Verification:**
- [ ] Structured rubric covers file, section, structure, and quantitative checks
- [ ] Behavioral rubric includes judge prompt template with scoring dimensions
- [ ] Both rubrics reference specific skills they apply to

#### Agent Context
- **Files to create:** `tests/rubrics/structured-output.md`, `tests/rubrics/behavioral.md`
- **Files to read:** Research artifact (Categories A-D, Findings 2-3)
- **Acceptance gate:** Both rubric files exist with actionable grading criteria
- **Constraints:** Rubrics must be usable by both humans and automation; structured rubric criteria should be automatable

---

### Phase 7: Automation Scaffold [no-test]
**Goal:** Create a shell script that reads YAML scenarios and invokes Claude API for automated testing

**Tasks:**
1. Create `tests/runner/run-scenarios.sh` that:
   - Reads a scenario YAML file
   - Extracts trigger phrases and functional scenarios
   - Invokes Claude API (via `claude` CLI or `curl`) with each scenario
   - Captures output and runs code-based grading checks
   - Reports pass/fail per scenario
2. Support `--skill` flag to run one skill's scenarios
3. Support `--type trigger|functional` to run subset
4. Include `--dry-run` mode that prints what would be tested

**Verification:**
- [ ] Script parses YAML scenario files correctly
- [ ] `--dry-run` lists all scenarios without invoking API
- [ ] At least trigger tests can run end-to-end against Claude CLI
- [ ] Output format shows pass/fail per scenario

#### Agent Context
- **Files to create:** `tests/runner/run-scenarios.sh`
- **Files to read:** `tests/README.md` (YAML format spec), one completed scenario file
- **Acceptance gate:** `./tests/runner/run-scenarios.sh --dry-run --skill research` lists scenarios; script is executable
- **Constraints:** Use `claude` CLI for invocation (not raw API); keep dependencies minimal (bash + yq for YAML parsing); no Python required

## Constraints & Considerations

### Architectural
- This is a content-only project — no build system, no application code test suite
- YAML scenarios are data, not code — keep them declarative
- Grading rubrics serve dual purpose: human review guide + automation criteria

### Testing
- Code-based grading (string match, regex, file existence) preferred over LLM-judge where possible
- LLM-judge reserved for Category B skills (reflect) where output quality is subjective
- Self-consistency testing (same input, multiple runs) deferred to later iteration

### Performance
- Automation scaffold should support parallel scenario execution (future enhancement)
- Trigger tests are fast (single prompt); functional tests are slow (full skill execution)

## Out of Scope

- Test scenarios for skills not in the initial 5 (diagram, scaffold, pair, tidy, adr, hexagonal-architecture, refactor)
- CI/CD integration
- Self-consistency sampling (research Finding 4)
- Baseline performance measurements
- Cross-skill integration testing (research → draft → craft pipeline)

## Approval Checklist

- [x] All files to create listed with purpose
- [x] Implementation phases have clear boundaries
- [x] Each phase has an Agent Context block
- [x] Acceptance criteria are testable
- [x] Constraints documented
- [x] Out of scope items noted

## Next Steps

After review and approval:
1. Run `/craft` to execute — dispatches agents from beads issues
2. Each phase is `[no-test]` (content creation, no application code)
3. If interrupted, `/craft` picks up where it left off via `beads:ready`
