# Tidy Report Template

Optional artifact saved to `docs/plans/YYYY-MM-DD-tidy-report.md` when the user requests a written report.

```markdown
# Tidy Report

**Date:** YYYY-MM-DD
**Project:** {project name}

## Summary

{1-2 sentence overview of findings.}

**Findings:** {total} total — {N} must-fix, {N} should-fix, {N} nice-to-have

## Findings

### Finding: {short description}
**Severity:** must-fix | should-fix | nice-to-have
**File:** `{path/to/file.md}`
**Details:** {what's wrong}
**Fix:** {specific action taken or recommended}

## Notes

- {Any observations that don't rise to finding level}
```

## Severity Definitions

| Severity | Definition | Examples |
|----------|-----------|---------|
| **must-fix** | Actively misleading. Agent will make wrong decisions. | Wrong build command, broken link, incorrect file paths |
| **should-fix** | Outdated. Won't cause wrong behavior but reduces clarity. | Missing test command, outdated architecture description |
| **nice-to-have** | Would improve readability. Absence isn't harmful. | Better section ordering, minor wording improvements |
