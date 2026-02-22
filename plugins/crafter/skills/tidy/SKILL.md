---
name: tidy
description: Audit agent-facing documentation for staleness and recommend fixes. Use when CLAUDE.md or READMEs may be out of date.
triggers:
  - "tidy"
  - "tidy first"
  - "audit docs"
  - "update claude.md"
  - "agent docs"
allowed-tools: Read Glob Grep Write Edit AskUserQuestion
---

# Tidy Skill

Inspired by Kent Beck's *Tidy First?* philosophy: make small structural improvements before behavioral changes. This skill audits agent-facing documentation — CLAUDE.md, READMEs, and cross-references — for staleness.

## Scope

This skill **only** touches documentation files. It does NOT:
- Analyze source code for TypeScript errors, lint issues, or code smells
- Suggest code refactoring (use `/refactor` for that)
- Scout for undocumented architectural patterns or conventions
- Write new documentation from scratch (use documentation-writer for that)

## When to Use

- CLAUDE.md may be stale after refactoring or renaming files
- README references outdated commands, paths, or features
- Before a major feature, to ensure agent-facing docs are accurate

## Workflow

### Step 1: Read Documentation Files

Read the project's agent-facing documentation:
1. `CLAUDE.md` (and `CLAUDE.local.md` if present)
2. `README.md`
3. Any other markdown files referenced by the above

### Step 2: Check for Staleness

For each documentation file, check:

| Check | What to look for |
|-------|-----------------|
| **Broken links** | Internal `[text](path)` links where the target file no longer exists |
| **Stale paths** | Inline code references to files (e.g., `src/foo/bar.ts`) that have moved or been deleted |
| **Wrong commands** | Build/test/lint commands that don't match actual config (package.json, Makefile, etc.) |
| **Outdated descriptions** | Sections describing features, structure, or behavior that no longer match reality |

Use `Glob` and `Read` to verify paths and commands referenced in the docs actually exist.

### Step 3: Present Findings

**REQUIRED:** Use `AskUserQuestion` to present findings and let the user choose which to address. **Do NOT skip this step or auto-select findings.** The user MUST have the opportunity to review and select.

Present findings grouped by severity:

| Severity | Definition |
|----------|-----------|
| **must-fix** | Actively misleading — an agent following this will make wrong decisions |
| **should-fix** | Outdated but won't cause incorrect behavior |
| **nice-to-have** | Minor improvement to clarity or completeness |

Options:
- Fix all findings
- Must-fix only
- Must-fix and should-fix
- Let me pick individually

### Step 4: Apply Fixes

For each approved finding:
1. Read the file
2. Apply the fix with `Edit`
3. One fix per commit with message format: `tidy: <description>`

Examples:
- `tidy: fix broken link to architecture.md in README`
- `tidy: update build command in CLAUDE.md`
- `tidy: remove reference to deleted utils/helpers.ts`

### Step 5: Write Fixes Applied Section

**Append a "Fixes Applied" section to the end of the tidy output.** This serves as an audit trail when git commits cannot be verified:

```markdown
## Fixes Applied
| # | Severity | Fix | Commit Message |
|---|----------|-----|----------------|
| 1 | must-fix | {description} | `tidy: {message}` |
| 2 | should-fix | {description} | `tidy: {message}` |
```

### Step 6: Summary

After all fixes, report:
- Number of findings addressed
- Commits made (or reference the "Fixes Applied" table)
- Any findings skipped and why
