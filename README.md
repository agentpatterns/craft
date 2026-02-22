# Craft

A Claude Code plugin providing skills for software development best practices.

## Overview

This plugin offers curated skills that guide Claude through proven software development workflows including test-driven development, architectural patterns, refactoring techniques, and AI development practices.

## Installation

### From GitHub

In Claude Code, add the marketplace and install the plugin:

```
/plugin marketplace add agentpatterns/craft
/plugin install crafter
```

### From Local Directory

1. Clone the repository:
   ```bash
   git clone https://github.com/agentpatterns/craft
   ```

2. In Claude Code, add the marketplace and install:
   ```
   /plugin marketplace add /path/to/craft
   /plugin install crafter@craft
   ```

### Updating

To get the latest version:

```
/plugin marketplace update craft
```

After installation, skills become available as `crafter:skill-name` and are automatically triggered when relevant to your task.

## Available Skills

### Crafter Plugin

The `crafter` plugin provides skills for day-to-day software development:

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

#### RPI Methodology (Research → Draft → Craft)

The crafter plugin's core workflow for non-trivial features:

1. **Research** (`/research`) — Explore the codebase with parallel subagents, output a compact research artifact
2. **Draft** (`/draft`) — Consume the research artifact, produce a compact implementation plan with test specs
3. **Craft** (`/craft`) — Execute the plan phase by phase with strict RED → GREEN → REFACTOR discipline

### Scaffolder Plugin

The `scaffolder` plugin provides skills for software architecture:

| Skill | Command | Description |
|-------|---------|-------------|
| **hexagonal-architecture** | `/hexagonal-architecture` | Applies hexagonal (ports & adapters) architecture with domain-first design |

Install each plugin independently:

```
/plugin install crafter
/plugin install scaffolder
```
