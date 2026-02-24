# Skill Testing Framework - Research

**Date:** 2026-02-23
**Status:** Research Complete
**Depth:** Standard

## Summary

This project has 12 skills — pure markdown workflow documents with no application code or existing test suite. AGENTS.md defines a testing framework (Triggering, Functional, Performance) with the Claude A/B method, but no structured test artifacts exist yet. Web research confirms the project's testing philosophy aligns with industry eval practices (Anthropic, LangSmith, DeepEval) but identifies gaps in test data format, regression tracking, and grading rubrics.

## Skills Inventory

| Skill | Triggers | Subtype Dispatch | Key Output |
|-------|----------|-----------------|------------|
| `research` | research, explore codebase, investigate | No | `docs/plans/YYYY-MM-DD-{topic}-research.md` |
| `draft` | plan, draft plan, implementation plan | No | Plan file + beads task graph |
| `craft` | implement, execute plan, build from plan | No | Working feature + `craft-execution-log.md` |
| `tdd` | TDD, test driven development, red green refactor | No | `tdd-session-log.md` + passing tests |
| `refactor` | refactor, refactoring, clean up code | No | `REFACTORING_SUMMARY.md` + atomic commits |
| `diagram` | C4, architecture diagram, sequence, DFD | Yes (3 subtypes) | `.likec4` or `.md` diagram files |
| `scaffold` | scaffold, DDD typescript | Yes (1 subtype) | DDD project structure + fitness tests |
| `reflect` | reflect, retrospective, session reflection | No | `docs/plans/YYYY-MM-DD-{topic}-reflection.md` |
| `tidy` | tidy, audit docs, update claude.md | No | Atomic `tidy:` commits |
| `pair` | pair, teach me, guide me | No | Guided session + structured summary |
| `adr` | ADR, architecture decision record | No | `docs/decisions/NNNN-title.md` |
| `hexagonal-architecture` | hexagonal, ports and adapters, clean architecture | No | Design guidance (reference, not generative) |

## Existing Testing Framework (AGENTS.md)

### Three Testing Areas

1. **Triggering** — Does skill load for relevant queries and NOT for unrelated ones?
2. **Functional** — Does skill produce correct outputs? (Given/When/Then assertions)
3. **Performance** — Does skill improve over baseline? (token usage, turn count, error rate)

### Claude A/B Method
- Claude A (expert) designs and refines the skill
- Claude B (tester) tests on real tasks, reports failures
- Iterate between A and B with specific failure descriptions

### Pre-Ship Checklist Requirements
- At least 3 evaluation scenarios
- Triggering: positive and negative
- Functional: correct outputs for all scenarios
- Tested across models (Haiku, Sonnet, Opus)
- Tested with real usage scenarios

## Web & Pattern Research

### Finding 1: Eval-Driven Development (EDD)
**Sources:** Anthropic eval docs, Eugene Yan eval framework, AGENTS.md
**Confidence:** High
**Summary:** Write evaluations BEFORE writing the skill. Define success criteria first, write 3-5 test scenarios, verify skill passes, then refine.
**Implication:** Each skill should have test scenarios authored alongside or before the skill itself.

### Finding 2: Tiered Grading (Code > LLM-Judge > Human)
**Sources:** Anthropic cookbook (`building_evals.ipynb`), Confident-AI, DeepEval
**Confidence:** High
**Summary:** Prefer code-based grading (string matching, regex, structure checks) for deterministic outputs. Use LLM-as-judge for subjective qualities. Reserve human grading as last resort.
**Implication:** Skills with structured outputs (research, draft, tdd, refactor, adr) can use code-based grading. Skills with open-ended outputs (pair, reflect) need LLM-as-judge.

### Finding 3: Triggering as Binary Classification
**Sources:** Anthropic eval docs, Confident-AI, AGENTS.md
**Confidence:** High
**Summary:** Create labeled dataset of `{input_phrase, expected_trigger: true/false}`. Measure precision (false positives = over-triggering) and recall (false negatives = under-triggering) separately.
**Implication:** The `description` field is the testable unit — not the `triggers` array. Test via "When would you use the X skill?" probe.

### Finding 4: Self-Consistency Sampling
**Sources:** Lilian Weng prompt engineering guide, Eugene Yan eval patterns
**Confidence:** Medium
**Summary:** Run same skill + same input multiple times at temperature > 0. High output variance = ambiguous instructions. Low variance = reliable skill.
**Implication:** Useful for skills with strict output formats (tdd session log, adr template, research artifact).

### Finding 5: Separate Test Data from Test Logic
**Sources:** OpenAI evals framework, hamel.dev
**Confidence:** High
**Summary:** Store test cases as structured data (YAML/JSON), separate from grading logic. Enables versioning, CI/CD integration, and re-running against evolving skills.
**Implication:** Need a `tests/` directory per skill with machine-readable scenario files.

## Skill Categories by Testing Approach

### Category A: Structured Output Skills (code-grading viable)
- `research` — artifact has required sections, ~200 lines, confidence levels on web findings
- `draft` — plan file has required sections, beads task graph created
- `tdd` — session log has `[PLAN]`, `[RED-PREDICT]`, `[GREEN]` entries; ZOMBIES coverage
- `refactor` — `REFACTORING_SUMMARY.md` created; `- r` commit prefix; tests pass before/after
- `adr` — file at `docs/decisions/NNNN-*.md`; required sections present; status = Proposed
- `scaffold` — DDD directory structure correct; fitness tests generated; all tests pass
- `craft` — `craft-execution-log.md` populated; all beads closed; final verification passes

### Category B: Behavioral/Interactive Skills (LLM-judge needed)
- `pair` — teaching behavior (questions before answers); strictness adherence; session summary quality
- `reflect` — improvement proposals relevant to session; proposals categorized correctly

### Category C: Audit/Fix Skills (hybrid grading)
- `tidy` — findings grouped by severity; atomic commits with `tidy:` prefix; AskUserQuestion before fixes
- `diagram` — valid LikeC4/Mermaid syntax; correct subtype dispatch; no duplicate declarations

### Category D: Reference Skills (minimal testing)
- `hexagonal-architecture` — guidance document; test triggering + non-triggering only

## Testable Contracts per Skill

### research
- Output file exists at `docs/plans/YYYY-MM-DD-{topic}-research.md`
- Contains sections: Summary, Relevant Files, Existing Patterns, Web Research (with confidence levels), Open Questions, Next Steps
- Target ~200 lines
- All agents dispatched in a single message (parallel)
- AskUserQuestion called for user review
- Hard stop after presenting next steps (no code, no planning)

### draft
- Output file exists at `docs/plans/YYYY-MM-DD-{topic}-plan.md`
- Contains Agent Context blocks per phase
- Beads task graph created (or inline task graph if beads unavailable)
- Each beads issue is self-contained (does not reference plan file)
- TDD phases have 3 issues each (test/impl/validate)

### craft
- `craft-execution-log.md` created with structured entries
- Gate evaluation: RED fail = hard stop; GREEN fail = proceed to validate
- Lint fast path: biome-only failures auto-fixed before remediation
- Max 2 remediation attempts before escalation
- Final verification: full test suite passes

### tdd
- `tdd-session-log.md` created before any code
- `[TEST]` comments written as first artifact (before production code)
- Every ZOMBIES letter (Z/O/M/B/I/E/S) appears at least once
- Phase separation enforced: failing test written before implementation
- No production code without a test requiring it

### refactor
- `REFACTORING_SUMMARY.md` created with baseline section
- Tests pass before first change and after every change
- Each commit uses `- r <description>` format
- One refactoring per commit
- Test code not modified (except renames following production renames)
- Final evaluation in critic mode

### diagram
- Correct subtype selected based on user intent
- All reference files loaded before generation
- likec4-c4: specification → model → views block ordering; camelCase identifiers
- likec4-dynamic: references existing model identifiers only; no re-declaration
- data-flow: Mermaid flowchart with classDef for entity/process/store styling

### scaffold
- Only modules at paths referenced by acceptance tests created
- DDD hexagonal layout: domain/application/infrastructure
- All four fitness test files generated first
- TDD order: read tests → implement one at a time → red/green/refactor
- Zod validation with INVALID_INPUT error mapping

### reflect
- 4 parallel agents dispatched before plan mode
- Artifact contains Agent Dispatch Manifest table
- Max 5 improvement proposals, priority-ordered
- Each proposal has: Type, Priority (P1-P3), Target file, Current/Proposed/Rationale
- Atomic commits per approved proposal prefixed `reflect:`

### tidy
- Findings grouped by severity: must-fix, should-fix, nice-to-have
- AskUserQuestion REQUIRED before applying fixes
- Atomic commits per fix prefixed `tidy:`
- Scope strictly documentation (no code analysis)

### pair
- Strictness level selected via AskUserQuestion (Strict/Pseudocode/Collaborative)
- Never volunteers answer first — asks a question before providing information
- Strictness boundaries enforced (Strict = no code at all)
- Session exit produces structured summary

### adr
- Harmel-Law signal check before writing
- Y-statement formulated ("In the context of...")
- File at `docs/decisions/NNNN-kebab-case-title.md`
- Required sections: Context (value-neutral), Decision (active voice), Options Considered (>=2), Consequences (good + bad)
- Status set to Proposed

### hexagonal-architecture
- Reference/guidance only — no generative output
- Core rule: "Does it do I/O?" determines placement
- Scope gate: not for CRUD apps

## Gaps Between Current State and Best Practices

1. **No test data format** — AGENTS.md requires 3 scenarios but no machine-readable format exists
2. **No regression suite** — Pre-ship covers development scenarios but nothing accumulates over time
3. **No grading rubrics** — Given/When/Then assertions described but evaluation method unspecified
4. **No baseline measurements** — Performance comparison mentioned but no guidance on capturing baselines
5. **No self-consistency testing** — Not mentioned in AGENTS.md; low-cost way to detect ambiguous instructions

## Proposed Test Structure

```
tests/
├── README.md                    # Testing methodology and how to run
├── scenarios/                   # Per-skill test scenario files
│   ├── research.yaml
│   ├── draft.yaml
│   ├── craft.yaml
│   ├── tdd.yaml
│   ├── refactor.yaml
│   ├── diagram.yaml
│   ├── scaffold.yaml
│   ├── reflect.yaml
│   ├── tidy.yaml
│   ├── pair.yaml
│   ├── adr.yaml
│   └── hexagonal-architecture.yaml
└── rubrics/                     # Grading rubrics for LLM-judge evaluation
    ├── structured-output.md     # For Category A skills
    └── behavioral.md            # For Category B skills
```

Each scenario YAML file contains:
- Triggering tests (positive + negative phrases)
- Functional tests (Given/When/Then with grading method)
- Cross-model notes (Haiku/Sonnet/Opus expectations)

## Open Questions

- Should tests be run manually (Claude A/B method) or automated via a script that invokes Claude API?
- What temperature setting for self-consistency sampling? (0.7 is standard but skills may benefit from 0.3-0.5)
- Should the test suite live in the plugin (`plugins/crafter/tests/`) or at the project root (`tests/`)?
- How to handle cross-skill integration testing (e.g., research → draft → craft pipeline)?

## Next Steps

Hand off to `/draft` with this research artifact.
