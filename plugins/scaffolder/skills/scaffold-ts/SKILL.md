---
name: scaffold-ts
description: Scaffold a DDD TypeScript project from Gherkin feature files. Use when scaffolding TypeScript projects, creating domain-driven design structures, generating project boilerplate from acceptance tests, or when user mentions scaffold, DDD typescript, or domain-driven TypeScript.
license: MIT
compatibility: Claude Code plugin
metadata:
  author: eric-olson
  version: "1.0.0"
  workflow: scaffolding
  triggers:
    - "scaffold typescript"
    - "scaffold ts"
    - "DDD typescript"
    - "scaffold project"
    - "domain-driven typescript"
allowed-tools: Read Glob Write Bash
---

# Scaffold TypeScript DDD Project

Read the Gherkin feature files to understand the domain requirements before creating any files. The feature files define the acceptance tests — every file you scaffold must serve those tests.

## Derivation Guide

Derive the project structure from the feature files in six steps:

1. **Identify bounded contexts** — Group scenarios by aggregate root. Each aggregate root becomes a top-level directory: `src/<context>/`.

2. **Extract domain entities** — Given/When steps reveal aggregate and value-object types. Create those types in `<context>/domain/`.

3. **Identify use cases** — When verb phrases map directly to async functions in `<context>/application/`. One function per use-case step.

4. **Infer repository port shapes** — Read test imports to determine which repository methods are called. The infrastructure adapter must implement exactly those methods and no others.

5. **Identify domain events** — Then steps that assert `eventBus.getEmittedEvents()` reveal event types. Create those types in `<context>/domain/events/`.

6. **Discover required import paths** — Read every import in the acceptance tests. Create modules at exactly those paths. Do not invent paths that tests do not reference.

## Project Structure

```
src/
├── shared-kernel/
│   ├── event-bus.ts
│   ├── domain-event.ts
│   └── in-memory-event-bus.ts
└── <context>/
    ├── domain/
    │   ├── aggregates/
    │   │   └── <context>-aggregate.ts
    │   ├── value-objects/
    │   │   └── <value-object>.ts
    │   ├── repositories/
    │   │   └── <context>-repository.ts
    │   └── events/
    │       └── <context>-event.ts
    ├── application/
    │   └── <use-case>.ts
    └── infrastructure/
        └── in-memory-<context>-repository.ts
```

Repeat the `<context>/` subtree for each bounded context. If acceptance tests import from a conventional path, create proxy shim modules at those paths that re-export from the DDD structure.

## Architectural Rules

**Domain layer purity** — `domain/` must not import from `infrastructure/` or `application/`. Dependencies flow inward only.

**Bounded context isolation** — No cross-context imports. Contexts communicate exclusively through domain events dispatched via the shared-kernel `EventBus`.

**Aggregates are the consistency boundary** — State changes happen only through aggregate methods. Value objects are immutable: use `readonly` fields, factory methods, and no setters.

**Application services are functions, not classes** — Each use case is a named async function with the signature `(rawInput, deps) => result`. Return a discriminated union:
- Success: `{ success: true, ...fields }`
- Failure: `{ success: false, error: { code: string } }`

Error codes use SCREAMING_SNAKE_CASE.

**Ports are interfaces** — Every repository port is a TypeScript `interface` in the domain layer. One aggregate, one use case, and one repository interface per file.

## TDD Workflow

1. Read all acceptance tests before writing any source code.
2. Implement one test file at a time; do not scaffold ahead.
3. Follow Red → Green → Refactor for each test:
   ```
   bunx vitest run --grep "<feature>"
   ```
4. Run fitness tests after completing each file:
   ```
   bunx vitest run --grep "fitness"
   ```
5. Run the full suite after completing each use case:
   ```
   bunx vitest run
   ```

## Naming Conventions

| Artifact | File location | File suffix |
|---|---|---|
| Aggregate | `src/<context>/domain/aggregates/` | `-aggregate.ts` |
| Value object | `src/<context>/domain/value-objects/` | (free-form) |
| Repository interface | `src/<context>/domain/repositories/` | `-repository.ts` |
| Domain event union | `src/<context>/domain/events/` | `-event.ts` |
| Application use case | `src/<context>/application/` | (free-form) |
| Infrastructure adapter | `src/<context>/infrastructure/` | starts with `in-memory-` |

TypeScript names: aggregates and value objects use PascalCase classes or type aliases; use-case functions use camelCase; files use kebab-case.

## TypeScript Compiler Constraints

The scaffolded project must satisfy these compiler options:

- **`noUncheckedIndexedAccess`** — Array and record lookups return `T | undefined`. Handle both branches explicitly.
- **`verbatimModuleSyntax`** — Use `import type { ... }` for type-only imports.
- **`strict: true`** — All strict checks are enabled. No `any` without a comment justifying the exception.

## Verification

Run the following commands in order. All must pass before the scaffold is considered complete:

1. **Acceptance and fitness tests**
   ```
   bunx vitest run
   ```
2. **Lint**
   ```
   bunx @biomejs/biome ci .
   ```
3. **Type check**
   ```
   bunx tsc --noEmit
   ```

## References

- [Fitness test templates (ArchUnitTS)](references/fitness-tests.md)
- [Code templates (shared kernel, domain events, Zod)](references/code-templates.md)
