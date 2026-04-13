# Task Card Specification

A task card is the contract between the orchestrator and the code buddy. It defines scope, acceptance criteria, and boundaries. Even a minimal card (5 lines) is better than a verbal "quickly fix X".

---

## Minimal Task Card (for small tasks)

```markdown
# T001 — Fix date parsing in user profile

## Scope
- `src/utils/dateParser.ts` — fix locale-dependent parsing

## Acceptance Criteria
- [ ] Date parsing uses ISO 8601 format internally
- [ ] Display formatting uses user's locale
- [ ] Existing tests pass
- [ ] No console errors

## Prohibited
- Do not refactor surrounding utility functions
- Do not change the date library dependency
```

---

## Full Task Card Template

```markdown
# T{ID} — {Descriptive Title}

| Field | Value |
|-------|-------|
| Status | pending / in-progress / done / blocked |
| Priority | high / medium / low |
| GitHub Issue | #{number} (if applicable) |
| Worktree Isolation | yes / no |
| Parallel To | T{other-id} (if applicable) |

## Why This Task Exists
{1-3 sentences of context. Why is this needed? What problem does it solve?
The buddy needs to understand the WHY to make good judgment calls.}

## Scope
**In scope (touch these files):**
- `path/to/file.ts` — what to change here
- `path/to/other.ts` — what to change here

**Out of scope (do NOT touch):**
- `path/to/unrelated.ts` — even if it looks related
- Any configuration files unless explicitly listed

## Propagated Audit Findings
{Table of findings from previous audits that affect this task.
Leave empty if none.}

| Source | Severity | Finding | Action |
|--------|----------|---------|--------|
| T{prev} Audit | WARN | Magic color in component | Use theme token |

## Acceptance Criteria
- [ ] {Machine-verifiable criterion 1}
- [ ] {Machine-verifiable criterion 2}
- [ ] {Machine-verifiable criterion 3}
- [ ] Build passes without errors
- [ ] No new console warnings

## Prohibited
- {Explicit prohibition 1 — what NOT to do}
- {Explicit prohibition 2}
- Do not refactor code outside scope
- Do not add features not listed above

## Git Workflow
- Branch: `{branch-name}`
- Commit format: `{type}: {description}`
- After completion: report to orchestrator for audit
```

---

## Directory Structure (Optional)

For larger projects with many tasks, organize task cards in a directory:

```
.tasks/
├── pending/          # Tasks not yet started
├── in-progress/      # Currently being worked on
├── done/             # Completed, awaiting audit
├── audit/            # Audit reports
│   └── screenshots/  # UI audit evidence
├── archive/          # Done + audited
└── blocked/          # Waiting on external input
```

Add `.tasks/` to `.gitignore` — task cards are process artifacts, not source code.

---

## Common Anti-Patterns

**"Improve the performance"** — Not a task card. What performance? Which metric? What's the target? Rewrite as: "Reduce initial load time of dashboard from 3s to <1s by implementing lazy loading for chart components."

**Empty "Prohibited" section** — Every task has boundaries. If you can't think of any, at minimum: "Do not refactor code outside scope."

**Criteria that require subjective judgment** — "Make it look good" is not verifiable. "Component matches the mockup within 2px margin" is.

**Scope without file paths** — "Fix the authentication" touches how many files? List them. If you don't know, that's a research task first, not a code task.

---

## Tips

- **Smaller is better.** A focused 3-file task card produces better results than a sprawling 15-file epic.
- **The "Why" section is not optional.** Without context, the buddy makes technically correct but contextually wrong decisions.
- **Propagated findings are mandatory when they exist.** An audit finding that nobody reads is a finding that was wasted.
- **Write the prohibited section from experience.** Every "the buddy also changed X" incident becomes a new prohibited item for future cards.
