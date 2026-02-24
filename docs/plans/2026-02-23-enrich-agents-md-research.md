# Research: Enrich AGENTS.md with Anthropic Best Practices

**Date:** 2026-02-23
**Status:** Complete

## Context

The AGENTS.md file (55 lines) provided basic skill creation guidance. The user supplied a comprehensive guide (~500 lines) distilled from Anthropic's official documentation on building and testing skills. The goal was to enrich AGENTS.md with the highest-value tips while keeping the file concise and clean.

## Source Material Analyzed

- Current AGENTS.md (55 lines)
- Current CLAUDE.md (frontmatter format, authoring guidelines)
- docs/architecture.md (RPI methodology, key concepts)
- Existing skills (tdd, draft, research, etc.) for pattern validation
- User-provided Anthropic best practices guide (~500 lines)

## Key Additions Made

### 1. Description Writing Guidance (High Value)
- Third-person voice requirement
- WHAT + WHEN + trigger phrases structure
- Debug triggering technique ("When would you use...?")
- Max 1024 chars, no XML in frontmatter

### 2. Extended Frontmatter Fields (Medium Value)
- `context: fork` for isolated subagents
- `agent: Explore/Plan` for specific agent types
- `disable-model-invocation: true` for manual-only skills
- Dynamic context injection with `!` prefix

### 3. Body Writing Principles (High Value)
- Conciseness as core principle
- Degrees of freedom (high/medium/low) matching task fragility
- Progressive disclosure patterns
- Feedback loops for quality-critical tasks

### 4. Common Skill Patterns (Medium Value)
- Seven patterns as a reference table (sequential, iterative refinement, etc.)

### 5. Testing Methodology (High Value)
- Claude A/B development method
- Three testing areas: triggering, functional, performance
- Cross-model testing guidance (Haiku/Sonnet/Opus)
- Skill navigation observation signals

### 6. Expanded Pre-Ship Checklist (Medium Value)
- Split into Structure / Content / Testing sections
- Added degrees-of-freedom check, feedback loops, terminology consistency

## What Was Intentionally Omitted

- **Full skill structure diagram with scripts/assets** — kept simpler since this project is markdown-only
- **Detailed evaluation JSON format** — too prescriptive for a guide file
- **MCP coordination patterns** — not relevant to current skills
- **Content guidelines about time-sensitive info** — included as checklist item only
- **Verbose examples of good/bad descriptions** — kept one-liner examples instead

## Result

AGENTS.md grew from 55 lines to ~170 lines — a 3x increase that adds substantial guidance while staying scannable. The file is organized in a logical flow: creating → writing → testing → shipping → tracking → session management.
