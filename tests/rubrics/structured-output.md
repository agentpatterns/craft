# Structured Output Rubric

Grading rubric for Category A skills. All checks are automatable via filesystem inspection, regex, or YAML parsing.

## Check Types

| Type | Method | Tooling |
|------|--------|---------|
| `file-exists` | Path matches glob pattern | `glob` / `os.path.exists` |
| `section-present` | Regex `^## Section Name` in file | `re.search` |
| `string-match` | Pattern present in file content | `re.search` / `in` |
| `string-absent` | Pattern NOT present in file content | `not in` |
| `quantitative` | Line count, array length, section count | `wc -l` / line counter |

---

## research

| Check | Type | Assertion |
|-------|------|-----------|
| Artifact path | `file-exists` | `docs/plans/\d{4}-\d{2}-\d{2}-[a-z0-9-]+-research.md` |
| Sections | `section-present` | `^## Summary`, `^## Relevant Files`, `^## Existing Patterns`, `^## Web Research`, `^## Open Questions`, `^## Next Steps` |
| Confidence levels | `string-match` | Each web finding line matches `\*\*(High\|Medium\|Low)\*\*` |
| Line count | `quantitative` | `150 <= line_count <= 250` |

## draft

| Check | Type | Assertion |
|-------|------|-----------|
| Plan path | `file-exists` | `docs/plans/\d{4}-\d{2}-\d{2}-[a-z0-9-]+-plan.md` |
| Sections | `section-present` | `^## Goal`, `^## Acceptance Criteria`, `^## Files to Create`, `^## Files to Modify`, `^## Implementation Phases`, `^## Constraints`, `^## Out of Scope` |
| Agent Context blocks | `string-match` | `^#### Agent Context` present; each block contains `Files to`, `Test spec`, `Test command`, `RED gate`, `GREEN gate`, `Architectural constraints` |
| Beads fallback | `section-present` | `^## Inline Task Graph` (only when beads unavailable) |
| Line count | `quantitative` | `150 <= line_count <= 250` |

## craft

| Check | Type | Assertion |
|-------|------|-----------|
| Execution log | `file-exists` | `craft-execution-log.md` in project root |
| Log entries | `string-match` | `\[DISPATCHED\]`, `\[GATE PASS\]` or `\[GATE FAIL\]`, `\[CLOSED\]` (success), `\[REMEDIATION\]` (remediation path), `\[BLOCKED\]` (after 2 failures) |
| Lint fast path | `string-absent` | `\[REMEDIATION\]` absent when only biome failed |
| Agent types | `string-match` | At least one of: `agent-test`, `agent-impl`, `agent-validate` |

## tdd

| Check | Type | Assertion |
|-------|------|-----------|
| Session log | `file-exists` | `tdd-session-log.md` in project root |
| Phase entries | `string-match` | `\[PLAN\]`, `\[RED-PREDICT\]`, `\[RED-CONFIRM\]`, `\[GREEN\]`, `\[REFACTOR\]` present in session log |
| TEST comments | `string-match` | Lines matching `\[TEST\]` appear in test files |
| ZOMBIES | `string-match` | `<- Z`, `<- O`, `<- M`, `<- B`, `<- I`, `<- E`, `<- S` each present at least once |

---

## Scoring

Each check is binary: pass (1) or fail (0).

| Result | Rule |
|--------|------|
| PASS | All `file-exists`, `section-present`, `string-match` checks pass |
| WARN | Only a `quantitative` check fails (line count out of range) |
| FAIL | Any `file-exists`, `section-present`, or `string-match` check fails |
