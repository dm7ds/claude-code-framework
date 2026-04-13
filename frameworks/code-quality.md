# Code Quality Standards

## No Magic Literals (NML)

**If a value is already defined in a data source (config, theme, database, constants), it must NEVER be duplicated as a literal elsewhere.**

### Prohibited
- Colors/hex values directly in markup — must come from theme token or variable
- Font sizes, spacing as magic numbers — must come from design tokens
- Type-specific branching (switch/case, if/else) mapping values that live in an external source
- Repeated code blocks differing only in one value — must be template, loop, or generic component
- String constants appearing identically in multiple places — must be named constant or resource

### Allowed
- **The ONE defining location** (theme file, constants class, config schema) — the value MUST live there
- **Fallback defaults** as last resort when the primary source is missing — explicitly marked as `/* Fallback */`
- **One-off values** that aren't defined anywhere else and only appear in one place

### Short Rule
> One piece of information, one source. If you write a value in two places, you've built a bug that just hasn't been noticed yet.

---

## DRY for Templates/Components

When markup or code blocks differ only in binding paths, labels, or config values:
- **Must** use a reusable template, component, or loop
- Copy-paste with minimal changes is ALWAYS a design defect
- Applies to: UI templates, components, HTML partials, CSS classes, etc.

---

## SSOT (Single Source of Truth)

Every piece of configuration, every constant, every design token has exactly one canonical source. Everything else references that source. When the source changes, all consumers automatically get the update.

### SSOT Hierarchy
1. **Global CLAUDE.md** (`~/.claude/CLAUDE.md`) — cross-project rules
2. **Project CLAUDE.md** (`<project>/CLAUDE.md`) — project-specific rules
3. **Framework files** — detailed protocols and templates

Project-specific rules can extend global rules but must not contradict them.

---

## How Quality Flows Through the Workflow

| Stage | Quality Gate |
|-------|-------------|
| **Orchestrator** | Task card with cross-scope check, machine-verifiable criteria |
| **Code Buddy** | NML/DRY via system prompt, scope compliance |
| **Auditor** | Scope check, DRY check, NML check, Zero-Grep-Gate |

---

## Allowed Exceptions

- **Fallback defaults** with explicit `/* Fallback */` comment
- **Performance-critical code** where indirection measurably hurts
- **Platform quirks** that require literal values (documented with comment)
- **One-off values** that genuinely only appear once
