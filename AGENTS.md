# Agent Instructions

This project is a Claude Code plugin marketplace containing **skills** — structured markdown workflow documents. There is no application code, build system, or test suite.

For project architecture, key concepts (RPI methodology, testing philosophy, hexagonal architecture), and installation commands, see `docs/architecture.md`.

## Creating New Skills

Use the Anthropic `/skill-creator` skill to guide you through creating new skills. It provides an interactive workflow for designing effective skill documents.

Before creating a skill, review these project conventions in `CLAUDE.md`:

- **Skill Authoring Guidelines** — 300-line limit, `references/` subdirectory for supporting content
- **Frontmatter Format** — Required YAML frontmatter (`name`, `description`, `triggers`, `allowed-tools`)
- **Subtype Dispatch Pattern** — How to handle skills with multiple related use cases

### Where Skills Live

```
plugins/crafter/skills/{skill-name}/
├── SKILL.md              # Main skill document (≤300 lines)
└── references/           # Optional supporting markdown (one level deep)
```

### Writing Effective Descriptions

The `description` field is the single most important frontmatter field — Claude uses it to decide whether to load the skill.

- **Write in third person.** The description is injected into the system prompt.
- **Structure:** `[What it does] + [When to use it] + [Key trigger phrases]`
- **Max 1024 chars.** No XML angle brackets in frontmatter.

Good: `"Extract text and tables from PDF files, fill forms, merge documents. Use when working with PDF files or when the user mentions PDFs, forms, or document extraction."`

Bad: `"Helps with documents."`

**Debug triggering:** Ask Claude *"When would you use the [skill-name] skill?"* — it will quote the description back. Adjust based on what's missing.

### Extended Frontmatter Fields

Beyond the standard fields (`name`, `description`, `triggers`, `allowed-tools`), Claude Code supports:

| Field | Effect |
|-------|--------|
| `context: fork` | Run skill in isolated subagent (no conversation history) |
| `agent: Explore` | Use a specific subagent type (`Explore`, `Plan`, or custom) |
| `disable-model-invocation: true` | Prevent auto-loading; user must invoke via `/skill-name` |

**Warning:** `triggers` MUST be a top-level frontmatter key. Do not nest it inside `metadata:` or any other block — Claude Code's parser will not find it. Undocumented fields (e.g., `license`, `metadata`) are passed through but have no effect on skill loading.

**Dynamic context injection** — prefix commands with `!` to preprocess data:

```markdown
- PR diff: !`gh pr diff`
- Changed files: !`gh pr diff --name-only`
```

Claude receives the fully-rendered prompt with actual data.

### Writing the Skill Body

**Core principle: concise is key.** The context window is shared. Only add context Claude doesn't already have.

- Challenge each paragraph: "Does Claude need this explanation?"
- See CLAUDE.md Skill Authoring Guidelines for the 300-line rule and `references/` pattern.
- Keep references one level deep from `SKILL.md` — deeply nested references cause partial reads.

**Match specificity to task fragility (degrees of freedom):**

| Freedom | Format | When |
|---------|--------|------|
| High | Text instructions | Multiple valid approaches, context-dependent |
| Medium | Pseudocode / parameterized scripts | Preferred pattern exists but variation is OK |
| Low | Exact scripts, no parameters | Fragile operations, consistency is critical |

**Progressive disclosure** — don't front-load everything:

```markdown
## Advanced features
**Form filling**: See [FORMS.md](references/forms.md) for complete guide
```

**Feedback loops** — for quality-critical tasks, provide a checklist with validation:

```markdown
- [ ] Step 1: Create plan
- [ ] Step 2: Validate (run scripts/validate.py)
- [ ] Step 3: Fix errors → repeat step 2
```

### Common Skill Patterns

| Pattern | Use When |
|---------|----------|
| **Sequential Workflow** | Multi-step process with dependencies and validation at each stage |
| **Iterative Refinement** | Draft → validate → fix → repeat until quality threshold |
| **Context-Aware Tool Selection** | Same outcome, different tools depending on context |
| **Domain-Specific Intelligence** | Specialized knowledge (compliance rules, heuristics) |
| **Template Pattern** | Strict output format for APIs/data; flexible for general content |
| **Examples Pattern** | Input/output pairs — examples beat descriptions for style |
| **Conditional Workflow** | Decision trees with branching paths based on context |

## Testing Skills

### Philosophy

**Build evaluations BEFORE writing extensive documentation.** Work through one challenging task until Claude succeeds, then extract the winning approach into a skill.

### The Claude A / Claude B Method

1. **Claude A** (expert): Helps design and refine the skill.
2. **Claude B** (tester): Tests the skill in real tasks.

**Workflow:**
1. Complete a task with Claude A using normal prompting — note what context you repeatedly provide.
2. Ask Claude A to create a skill capturing the reusable pattern.
3. Review for conciseness — remove explanations Claude doesn't need.
4. Test with Claude B on real tasks. Observe behavior.
5. Return to Claude A with specifics: "Claude B forgot to filter test accounts when asked for a regional report."
6. Iterate.

### Three Testing Areas

**1. Triggering** — Does the skill load at the right times?
- Test positive triggers ("Help me set up a ProjectHub workspace")
- Test negative triggers ("What's the weather?")
- Fix under-triggering: add more keywords/phrases to description
- Fix over-triggering: add negative scope, be more specific

**2. Functional** — Does the skill produce correct outputs?
- Test valid outputs, error handling, and edge cases
- Define expected behaviors as Given/When/Then assertions

**3. Performance** — Does the skill improve over baseline?
- Compare token usage, back-and-forth messages, and error rates with vs. without the skill

### Test Across Models

Skills are additions to models, so effectiveness varies:
- **Haiku**: Does the skill provide enough guidance?
- **Sonnet**: Is the skill clear and efficient?
- **Opus**: Does the skill avoid over-explaining?

### Observing Skill Navigation

Watch for these signals during testing:
- **Unexpected exploration paths** → restructure content
- **Missed references** → make links more explicit
- **Overreliance on certain sections** → promote that content to `SKILL.md`
- **Ignored content** → file is unnecessary or poorly signaled

## Pre-Ship Checklist

### Structure (per CLAUDE.md Frontmatter Format)
- [ ] Directory name matches frontmatter `name` (kebab-case)
- [ ] `SKILL.md` has valid YAML frontmatter with `---` delimiters
- [ ] `name`: kebab-case, max 64 chars, no spaces/capitals
- [ ] `description`: includes WHAT and WHEN, max 1024 chars, no XML tags
- [ ] `triggers`: top-level key with specific multi-word phrases (not bare single words)
- [ ] `allowed-tools` lists only the tools the skill actually needs
- [ ] Main file stays under 300 lines; extras go in `references/`

### Content
- [ ] Instructions are concise — only context Claude doesn't already have
- [ ] Degrees of freedom match task fragility
- [ ] Error handling included
- [ ] Examples provided (input/output pairs preferred)
- [ ] Feedback loops for quality-critical tasks
- [ ] No time-sensitive information
- [ ] Consistent terminology throughout
- [ ] Forward slashes in all file paths

### Testing
- [ ] At least 3 evaluation scenarios created
- [ ] Triggering: loads on relevant queries, doesn't load on unrelated ones
- [ ] Functional: produces correct outputs for all scenarios
- [ ] Tested with target models (Haiku, Sonnet, Opus)
- [ ] Tested with real usage scenarios (not just test scenarios)

## Issue Tracking

This project uses **bd** (beads) for issue tracking.

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --status in_progress  # Claim work
bd close <id>         # Complete work
bd sync               # Sync with git
```

## Session Completion

When ending a work session, all changes MUST be pushed to remote:

```bash
git pull --rebase
bd sync
git push
git status  # Must show "up to date with origin"
```
