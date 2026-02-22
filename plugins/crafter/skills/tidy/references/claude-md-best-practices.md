# CLAUDE.md Best Practices

Reference checklist for the CLAUDE.md Auditor agent. Use this to evaluate a project's CLAUDE.md against known best practices for agent-facing documentation.

## Required Sections

Every CLAUDE.md should include these sections, roughly in this order:

### 1. Project Overview

**What:** 2-5 sentences explaining what the project is, what it does, and its primary technology stack.

**Why agents need it:** Without this, agents guess at project purpose and make assumptions that lead to wrong architectural decisions.

**Check for:**
- Is there a clear "What This Project Is" or equivalent section?
- Does it name the primary language/framework?
- Does it describe the project's purpose (not just its structure)?

### 2. Key Commands

**What:** The essential commands for building, testing, linting, and running the project.

**Why agents need it:** Agents need to run tests, build, and verify their changes. Without documented commands, they guess or search, wasting context.

**Check for:**
- Build command
- Test command (all tests and single-file/filtered)
- Lint/format command
- Run/start command (if applicable)
- Any common development commands (db migrations, seed data, etc.)
- Commands actually work (not outdated)

### 3. Architecture Summary

**What:** High-level description of the project's architecture — layers, patterns, directory conventions.

**Why agents need it:** Agents need to know where to put new code and how existing code is organized. Without this, they create files in wrong locations or violate layering rules.

**Check for:**
- Directory structure overview or key directories explained
- Architectural pattern named (MVC, hexagonal, microservices, monolith, etc.)
- Dependency direction rules (if applicable)
- Layer descriptions (what goes where)

### 4. Conventions

**What:** Naming conventions, coding patterns, file organization rules that the project follows.

**Why agents need it:** Agents generate code that matches existing patterns only if those patterns are documented. Undocumented conventions lead to inconsistent code.

**Check for:**
- Naming conventions (files, classes, functions, variables)
- Import/export patterns
- Error handling conventions
- Testing conventions (where tests go, naming, what to test)

### 5. Key Files

**What:** Entry points, configuration files, and important modules that agents frequently need.

**Why agents need it:** In large codebases, finding the right starting point is half the battle. Listing key files saves context and prevents wrong-file edits.

**Check for:**
- Entry point(s) listed
- Configuration files mentioned
- Important shared modules or utilities identified

## Optional but Valuable Sections

These improve agent effectiveness but aren't strictly required:

| Section | When to Include |
|---------|----------------|
| **Environment Variables** | When the project uses any env vars for configuration |
| **Database Schema** | When the project has a database |
| **API Overview** | When the project exposes or consumes APIs |
| **Deployment** | When deployment has non-obvious steps |
| **Common Pitfalls** | When there are known gotchas that trip up developers |
| **Dependencies** | When specific dependency choices need explanation |

## Anti-Patterns

Things that make CLAUDE.md worse for agents:

| Anti-Pattern | Problem | Fix |
|-------------|---------|-----|
| **Too long (>500 lines)** | Agents lose focus. Important info buried in noise. | Split into CLAUDE.md + linked docs. Keep CLAUDE.md as an index. |
| **Too short (<20 lines)** | Agents lack critical context. | Add the 5 required sections at minimum. |
| **Copy of README** | README targets humans, not agents. Different audiences need different content. | Write CLAUDE.md specifically for agent consumption. |
| **Stale commands** | Agents run wrong commands, get confusing errors. | Verify all commands work. |
| **No architecture info** | Agents put code in wrong places. | Add even a brief architecture section. |
| **Listing every file** | Noise. Agents can discover files themselves. | List only key entry points and config. |
| **Aspirational content** | Describes what the project *should* be, not what it *is*. | Document current reality only. |
| **Duplicate info** | Same info in multiple places drifts. | Single source of truth, link from CLAUDE.md. |

## Cross-Reference Guidelines

When CLAUDE.md references other documents:

- **Every link must resolve** — broken links are worse than no links
- **Link to specific docs, not directories** — `docs/architecture.md` not `docs/`
- **Prefer relative paths** — they survive repo moves
- **Keep the reference list short** — link to 3-5 key docs, not every file in `docs/`
- **Describe what each link contains** — `[Architecture](docs/arch.md) — hexagonal layers and dependency rules`

## Evaluation Checklist

Use this when auditing a CLAUDE.md:

- [ ] Project overview present and accurate
- [ ] Key commands listed and verified working
- [ ] Architecture summary describes current reality
- [ ] Conventions section covers naming and patterns
- [ ] Key files listed with brief descriptions
- [ ] All cross-reference links resolve to existing files
- [ ] Length is appropriate (50-300 lines for most projects)
- [ ] Content describes what IS, not what SHOULD BE
- [ ] No duplicate information (single source of truth)
- [ ] Sections ordered by importance (most critical context first)
