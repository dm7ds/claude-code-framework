# Audit Protocol

**Core principle: An audit without evidence is not an audit.**

---

## Audit Types

| Type | When | Focus |
|------|------|-------|
| Code Audit | After every code change | Scope compliance, DRY/NML, cross-scope, build |
| UI Audit | After every UI change | Visual correctness, responsive, interactions |

---

## Status Values

| Status | Meaning | Action |
|--------|---------|--------|
| **PASS** | All checks pass, merge-ready | Proceed to merge/commit |
| **WARN** | Minor issues, merge-ready with notes | Note in next task card's Propagated Findings |
| **FAIL** | Must fix before merge | Create fix task, re-audit after |
| **INVALID** | Audit itself is flawed | Re-audit with different approach |

---

## Severity Levels

| Severity | Meaning |
|----------|---------|
| **MAJOR** | Functional bug, scope violation, missing acceptance criterion |
| **MINOR** | Style issue, minor DRY violation, non-blocking concern |
| **INFO** | Observation, suggestion for future improvement |

---

## Audit Report Structure

```markdown
# Audit Report: T{ID}

## Executive Summary
{1-2 sentences: what was audited, overall verdict}

## Checks Performed

| # | Check | Status | Evidence |
|---|-------|--------|----------|
| 1 | Scope compliance | PASS/FAIL | {file list, diff summary} |
| 2 | Acceptance criteria met | PASS/FAIL | {per-criterion evidence} |
| 3 | DRY/NML compliance | PASS/FAIL | {any violations found} |
| 4 | Cross-scope consumers | PASS/FAIL | {grep results} |
| 5 | Build passes | PASS/FAIL | {build output} |
| 6 | No deleted symbols without grep | PASS/FAIL | {grep results} |

## Findings

| # | Severity | Finding | Evidence | Recommendation |
|---|----------|---------|----------|----------------|
| 1 | MAJOR | {description} | {file:line} | {fix suggestion} |

## Cross-Scope Check
{List of exports/types/functions that were changed, with grep results
showing all consumers and whether they were updated.}

## Decision
**{PASS | WARN | FAIL}**

{Reasoning for the decision.}
```

---

## Prohibited Statements (Make Audit INVALID)

These phrases in an audit report automatically make it INVALID — they indicate the auditor didn't actually check:

1. *"I trust that this works correctly"*
2. *"The code looks clean"* (without listing specific checks)
3. *"No issues found"* (without evidence of what was searched)
4. *"Looks good to me"* (without specific findings or checks)
5. *"The implementation follows best practices"* (without naming which ones)
6. *"Based on the task card, everything is in order"* (without verification)
7. *"I assume the tests pass"* (without running them)

**Evidence means:** file paths, line numbers, grep results, build output, screenshots. Not adjectives.

---

## UI Audit: Additional Checks

| # | Check | Tool |
|---|-------|------|
| 1 | Visual matches expectation | preview_screenshot |
| 2 | No console errors | preview_console_logs |
| 3 | Responsive at common breakpoints | preview_resize |
| 4 | Interactive elements work | preview_click, preview_fill |
| 5 | CSS values correct | preview_inspect |
| 6 | Content/structure correct | preview_snapshot |

**"Looks good in the diff" is never sufficient for UI changes.** Visual evidence is mandatory.

---

## Findings Propagation

- **WARN** → noted in the next task card's "Propagated Findings" section
- **FAIL** → immediate fix task, no continuation until resolved
- **INFO** → optional, at orchestrator's discretion

An audit finding that nobody reads is a finding that was wasted. The propagation mechanism ensures findings survive beyond the audit report.

---

## Self-Audit is Not an Audit

The person who wrote the code cannot audit it. They have the same blind spots that produced the issues. Always spawn a separate auditor agent. This is a hard rule — the only exception is pure parameter changes (config values, thresholds) where there's no logic to review.
