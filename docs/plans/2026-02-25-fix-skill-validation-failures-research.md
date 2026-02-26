# Research: Fix 17 Pre-Existing Skill Validation Failures

**Date:** 2026-02-25
**Scope:** 11 single-word trigger violations + 6 trigger phrase vocabulary mismatches
**Detected by:** `tests/local/validate-skills.sh` (Check 3 and Check 6)

## Summary

The deterministic validator detects 17 failures across two categories:
- **11 single-word triggers** across 11 of 13 skills (only `hexagonal-architecture` is clean)
- **6 vocabulary mismatches** where positive scenario phrases share no words with their skill's description

These are real quality issues, not false positives. Fixes span three domains: skill frontmatter (triggers), skill frontmatter (descriptions), and the validator algorithm.

## Relevant Files

| File | Role |
|------|------|
| `plugins/crafter/skills/*/SKILL.md` | Skill frontmatter with `triggers` and `description` |
| `tests/scenarios/*.yaml` | Scenario files with `triggering.positive` phrases |
| `tests/local/validate-skills.sh` | Validator (Check 3: lines 211-242, Check 6: lines 270-318) |

## Existing Patterns

### Validator Algorithm — Check 3 (Single-Word Detection)

Tests whether a trigger string contains at least one literal space: `[[ "${trigger}" != *" "* ]]`. No tokenization, no normalization. One TAP failure per skill (additional violations reported as diagnostics).

### Validator Algorithm — Check 6 (Vocabulary Matching)

Word-level intersection between scenario phrases and skill `description`:
1. Lowercase both phrase and description
2. Split phrase on whitespace, strip `.,!?;:` from each token
3. `grep -qw` each token against description (whole-word match)
4. Pass if ANY single word matches

**No stemming, no stopword filtering, no hyphen splitting.** This means:
- "reflect" does not match "reflection" (stemming gap)
- "test-first" is one token, not split into "test" and "first"
- Common words like "the", "a", "for" can satisfy the check (false positive risk)

## Failure Analysis

### Category 1: Single-Word Trigger Violations (11 skills, 16 triggers)

| Skill | Single-Word Triggers | False-Positive Risk | Suggested Replacement |
|-------|---------------------|--------------------|-----------------------|
| draft | `plan` | **Critical** — fires on any planning discussion | `"draft a plan"` |
| research | `research`, `investigate` | **High** — fires on "I did some research..." | `"start research"`, `"investigate codebase"` |
| reflect | `reflect`, `retrospective` | **High** — fires on "let me reflect on that" | `"run reflection"`, `"run retrospective"` |
| craft | `implement` | **High** — fires on "how do I implement this?" | `"implement the plan"` |
| refactor | `refactor`, `refactoring` | **High** — fires on questions about refactoring | `"refactor code"`, `"start refactoring"` |
| pair | `pair` | **Medium** — fires on "key-value pair" | `"start pairing"` |
| scaffold | `scaffold` | **Medium** | `"scaffold a project"` |
| tidy | `tidy` | **Medium** — fires on "tidy that up" | `"tidy up docs"` |
| tdd | `TDD` | **Low** — acronym, unlikely false positive | `"use TDD"` |
| adr | `ADR` | **Low** — acronym | `"write an ADR"` |
| diagram | `LikeC4`, `DFD` | **Low** — product name / acronym | `"use LikeC4"`, `"create DFD"` |

**Pattern:** In 8 of 11 skills, the single-word trigger is the first (primary) trigger in the array. Skills tend to be named after their primary trigger word, making single-word triggers feel natural to authors but creating collision risk.

### Category 2: Vocabulary Mismatches (6 phrases)

| # | Scenario | Failing Phrase | Root Cause | Fix Domain |
|---|----------|---------------|------------|------------|
| 1 | draft | `draft docs/plans/2026-02-24-add-oauth-research.md` | "draft" absent from description (uses "Plan phase") | Description |
| 2 | reflect | `reflect on what we built today` | "reflect" vs "reflection" — stemming gap | Description or Validator |
| 3 | reflect | `we're done with the feature — let's do a post-mortem before the next one` | Zero vocabulary overlap; "post-mortem" synonym not in description | Description |
| 4 | research | `before implementing OAuth support, help me understand what's already here` | Zero overlap; natural utterance with no description vocabulary | Description |
| 5 | tdd | `red green refactor the new authentication middleware` | "red", "green", "refactor" absent from description | Description |
| 6 | tdd | `help me do a thorough test-first implementation of the refund flow` | "implementation" vs "implementing" stemming gap; "test-first" unsplit | Validator + Description |

## Open Questions

1. **Should acronym triggers (ADR, TDD, DFD, LikeC4) be exempt?** They have low false-positive risk and are well-understood domain terms. The validator could allow single-word triggers that are ALL-CAPS or contain mixed-case.
2. **How aggressive should stemming be?** Naive suffix stripping (-ing, -ion, -tion, -ed, -ly, -er) covers the observed failures but could introduce false positives. A conservative approach (only strip the 5-6 most common suffixes) is safer for a shell script.
3. **Should Check 6 add stopword filtering?** Currently any word can satisfy the match, including "a", "the", "for". This creates false passes. Adding a stopword list (words < 4 chars + a small explicit list) would tighten the check without over-constraining it.
4. **Should the validator split hyphenated tokens?** "test-first" → "test" + "first" would help scenario phrases containing compound terms. But this changes the semantics of the check.

## Recommendations — Prioritized

### Fix Group A: Update Skill Descriptions (4 changes)

These are genuine description quality gaps where the description omits its own skill's core vocabulary:

| Skill | Current Description (excerpt) | Proposed Change |
|-------|------------------------------|-----------------|
| draft | "Plan phase of RPI methodology..." | Add "draft" → "Plan/draft phase of RPI methodology..." |
| reflect | "Post-session reflection skill..." | Add "reflect" → "...to reflect on any substantive session, sprint, or post-mortem." |
| tdd | "Boundary-focused TDD workflow..." | Add red-green-refactor → "...following the red-green-refactor cycle." Add "test-first" |
| research | "Research phase of RPI methodology..." | Add "understand" → "...to understand existing patterns before building." |

### Fix Group B: Update Single-Word Triggers (16 changes across 11 skills)

Replace each single-word trigger with a multi-word phrase using the suggestions in the table above. Every skill already has multi-word triggers that serve as backup, so no activation coverage is lost.

### Fix Group C: Improve Validator Algorithm (optional, lower priority)

1. Add basic suffix stemming to Check 6 (strip -ing, -ion, -tion, -ed, -ly, -er)
2. Add stopword filtering to Check 6 (skip words < 4 chars + explicit list: "the", "this", "that", "with", "from", "have", "been", "will", "would", "could", "should")
3. Split hyphenated tokens in Check 6
4. Consider an acronym exemption in Check 3 (ALL-CAPS single-word triggers are lower risk)

## Next Steps

1. Run `/clear` to reset the context window
2. Run `/draft docs/plans/2026-02-25-fix-skill-validation-failures-research.md` to create the implementation plan
3. After draft completes, run `/craft` to execute
