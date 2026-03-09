# Session: Tracker Fallback Chain + Artifact Directory Migration

**Date:** 2026-03-09
**Epic:** tracker-fallback-chain-artifact-directory-migration-01kn

## Research Summary

Research identified two concerns:
1. All crafter skills hardcoded `.claude/scratch/` and `.claude/sessions/` paths, coupling to Claude Code internals rather than crafter's own namespace
2. The draft and craft skills were yaks-only — no fallback when yaks is unavailable, and no support for beads or native Claude Code tasks as alternative trackers

## Plan Summary

**Phases:** 8 sequential no-test phases (content/documentation migration, no code)
**Acceptance criteria:** Zero stale path references, three-tier tracker support throughout, all files under 300-line limit

**Architectural decisions:**
- Three-tier detection chain: yaks → beads → native tasks → inline (edge case)
- Tracker is an infrastructure detail, not a workflow change — agent isolation discipline unchanged
- Beads and yaks are cross-session durable; native tasks are session-scoped only

## Execution Log

| Phase | Task | Result |
|-------|------|--------|
| P1 | Artifact Directory Migration | PASS — 8 files updated, zero stale `.claude/` paths |
| P2 | Rename + Expand Decomposition Reference | PASS — new file with 3 tracker sections, old file deleted |
| P3 | Update Draft SKILL.md | PASS — 212 lines, tracker-agnostic language |
| P4 | Update Craft SKILL.md | PASS — 293 lines, three execution paths |
| P5 | Update Workflow Detail | PASS — 6 sections with YAKS/BEADS/NATIVE variants |
| P6 | Fix Stale References | PASS — 2 stale strings replaced |
| P7 | Update Test Scenarios + Evals | PASS — 3 fallback scenarios in both files |
| P8 | Update Plan Template | PASS — tracker field added, checklist generalized |

**Remediations:** 0
**Total agents dispatched:** 8

## Outcome

- All 8/8 tasks completed successfully with zero remediations
- All acceptance gates passed
- Key files modified: 4 SKILL.md files, 2 reference docs, 1 architecture doc, 2 test files, 1 template, 1 hooks config, 1 README
- File renamed: `yaks-decomposition.md` → `task-graph-decomposition.md`
- File deleted: `yaks-decomposition.md`
