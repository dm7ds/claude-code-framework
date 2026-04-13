# Issue Tracking Protocol

## Core Rule

**When anyone — user OR agent — mentions a bug, issue, or problem: track it immediately.** No questions, no batching, no "I'll add it later". Track first, continue conversation after.

---

## Where to Track

Always in `<project>/docs/issues.md`. Never in config directories (e.g., `.claude/`).

---

## Issue Format

### Quick-Index (Top of File)

```markdown
# Issues

| ID | Status | Severity | Title |
|----|--------|----------|-------|
| I-001 | open | high | Date parser crashes on ISO dates |
| I-002 | fixed | medium | Sidebar overflow on mobile |
| I-003 | open | low | Typo in settings label |
```

### Detail Section (Below Index)

```markdown
## I-001 — Date parser crashes on ISO dates

**Status:** open | **Severity:** high | **Found:** 2025-03-15
**Found by:** user report / self-found / audit T003

**Description:**
Date parser throws when input contains timezone offset (+02:00).
Reproduces with: `parseDate("2025-03-15T10:00:00+02:00")`

**Root Cause:** (fill in when investigated)

**Fix:** (fill in when resolved, reference commit/PR)
```

---

## Status Values

| Status | Meaning |
|--------|---------|
| open | Known, not yet worked on |
| in-progress | Currently being fixed |
| blocked | Can't fix without external input |
| fixed | Resolved, verified |
| wontfix | Decided not to fix (with reasoning) |

---

## Severity

| Level | Meaning |
|-------|---------|
| high | Blocks user workflow, data loss risk, crash |
| medium | Annoying but workaround exists |
| low | Cosmetic, minor inconvenience |

---

## Three-Layer Knowledge Model

To prevent `issues.md` from growing endlessly while preserving knowledge:

### Layer 1: `issues.md` — Open Issues Only
Lean, current. Only contains issues with status `open`, `in-progress`, or `blocked`. This is the active work list.

### Layer 2: `pitfalls.md` — Distilled Knowledge
When an issue is resolved, the **learning** gets distilled into 3-5 lines in `pitfalls.md`, grouped by code area. This is the project's knowledge base — not a changelog, but a "things to know about this code" reference.

Example entry in `pitfalls.md`:
```markdown
### Date Parsing
- **Always use InvariantCulture for data processing.** Locale-dependent parsing
  caused I-001 (timezone offset crash). Display formatting is the only place
  where user locale should be used.
```

### Layer 3: `issues-archive.md` — Full History
The complete issue text (description, root cause, fix) moves here when resolved. This is the reference archive — rarely read, but available when you need the full story.

### Workflow
1. Bug found → track in `issues.md` (Layer 1)
2. Bug fixed → distill learning into `pitfalls.md` (Layer 2)
3. Move full issue text to `issues-archive.md` (Layer 3)
4. Remove from `issues.md` (Layer 1 stays lean)

---

## Rules

- **Sequential IDs per project.** I-001, I-002, etc. Not global across projects.
- **Never just an ID.** Always include a brief title: "I-001 Date parser crash" not just "I-001".
- **Self-found issues count.** If you notice a bug while working, track it. R14 applies to everyone, not just user reports.
- **Issues.md is not a todo list.** It tracks bugs and problems, not feature requests or tasks.
