# Crafter Skills

Skills for day-to-day software development best practices.

## Core Flow (Plan Mode Native)

The primary workflow aligns with Claude Code's native plan mode:

1. **Research** (outside plan mode) — Explore codebase + web, write temporary artifact to `.claude/scratch/`
2. **Plan** (inside plan mode) — Draft behavior activates, produces plan with Agent Context blocks
3. **Execute** (`/craft`) — Beads-driven orchestration with three-agent TDD isolation
4. **Reflect** (`/reflect`) — Post-session learning loop

## All Skills

| Skill | Command | Description |
|-------|---------|-------------|
| [research](research/) | `/research` | Spawns parallel subagents to explore a codebase and produce a compact research artifact |
| [draft](draft/) | `/draft` | Produces a compact implementation plan with L3/L4 test specs and Agent Context blocks |
| [craft](craft/) | `/craft` | Executes an implementation plan phase by phase with strict test-first discipline |
| [tdd](tdd/) | `/tdd` | Boundary-focused TDD workflow for interactive, human-in-the-loop development |
| [refactor](refactor/) | `/refactor` | Refactoring process with test safety and incremental commits |
| [pair](pair/) | `/pair` | Guided pair-programming mode where Claude teaches rather than writes code |
| [reflect](reflect/) | `/reflect` | Post-session reflection that extracts learnings and produces improvement proposals |
| [diagram](diagram/) | `/diagram` | Creates architecture diagrams using LikeC4 (C4, dynamic) or Mermaid (DFD) |
| [scaffold](scaffold/) | `/scaffold` | Scaffolds DDD projects from Gherkin feature files (TypeScript) |
| [hexagonal-architecture](hexagonal-architecture/) | `/hexagonal-architecture` | Architectural guidance for hexagonal (ports and adapters) patterns |
| [adr](adr/) | `/adr` | Guides writing minimal Architecture Decision Records |
