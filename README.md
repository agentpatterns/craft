# Craft

A Claude Code plugin providing skills for software development best practices.

## Getting Started

### Install

```
/plugin marketplace add agentpatterns/craft
/plugin install crafter
```

After installation, skills are available as `crafter:skill-name` and activate automatically when relevant to your task.

### Install from Local Clone

```bash
git clone https://github.com/agentpatterns/craft
```

```
/plugin marketplace add /path/to/craft
/plugin install crafter@craft
```

### Update

```
/plugin marketplace update craft
```

## Available Skills

The `crafter` plugin provides skills for software development, architecture, and diagramming:

| Skill | Command | Description |
|-------|---------|-------------|
| **tdd** | `/tdd` | Boundary-focused TDD workflow enforcing L3/L4 altitude testing and property-based tests |
| **research** | `/research` | Spawns parallel subagents to explore a codebase and produce a compact research artifact |
| **draft** | `/draft` | Consumes research artifact and produces a compact implementation plan with L3/L4 test specs |
| **craft** | `/craft` | Executes an implementation plan phase by phase with strict test-first discipline |
| **refactor** | `/refactor` | Refactoring process with test safety and incremental commits |
| **pair** | `/pair` | Guided pair-programming mode where Claude teaches rather than writes code |
| **tidy** | `/tidy` | Audit agent-facing documentation (CLAUDE.md, READMEs) for staleness and recommend fixes |
| **reflect** | `/reflect` | Post-session reflection that mines git history and artifacts to produce improvement proposals |
| **diagram** | `/diagram` | Creates architecture diagrams (C4 structural, dynamic flows, data flow) with subtype dispatch |
| **scaffold** | `/scaffold` | Scaffolds DDD projects from Gherkin feature files with language subtype dispatch |
| **hexagonal-architecture** | `/hexagonal-architecture` | Applies hexagonal (ports & adapters) architecture with domain-first design |
| **adr** | `/adr` | Guides writing minimal Architecture Decision Records |

#### RPI Methodology (Research → Draft → Craft)

The crafter plugin's core workflow for non-trivial features:

1. **Research** (`/research`) — Explore the codebase with parallel subagents, output a compact research artifact
2. **Draft** (`/draft`) — Consume the research artifact, produce a compact implementation plan with test specs
3. **Craft** (`/craft`) — Execute the plan phase by phase with strict RED → GREEN → REFACTOR discipline

## Testing

Skills are validated by a three-layer pipeline. See `tests/README.md` for full methodology.

**Layer 1 — Deterministic (local + CI):** Validates skill structure, frontmatter, triggers, and scenario schemas. No API calls. Runs on every push via GitHub Actions.

```bash
bash tests/local/validate-skills.sh
```

**Layer 2 — Promptfoo evals:** Functional and behavioral evaluation using real Claude API calls. See `tests/evals/README.md` for setup and cost.

```bash
cd tests/evals && promptfoo eval
```

**Layer 3 — Human review:** Manual review for subjective quality and calibrating LLM-judge rubrics.

## Contributing

See `AGENTS.md` for skill authoring guidelines, testing workflows, and the pre-ship checklist.

See `docs/architecture.md` for project structure and key concepts.
