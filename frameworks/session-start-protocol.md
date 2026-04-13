# Session Start Protocol

**What every agent should do at the start of a session.** Takes <5 minutes, prevents hours of rework.

---

## Steps

### 1. Read Project CLAUDE.md
Load the project's CLAUDE.md for coding conventions, tech stack, and project-specific rules.

### 2. Check Open Issues
Read `<project>/docs/issues.md` for known bugs and open problems. Don't duplicate resolved work.

### 3. Check Active Tasks
Look for any in-progress task cards. Are there tasks that were started but not completed?

### 4. Check Recent Git History
`git log --oneline -10` — What happened recently? Any relevant changes?

### 5. Load Relevant Context
Read project-specific knowledge (pitfalls.md, design decisions, etc.) that's relevant to the current work.

### 6. Report to User
Give a 3-5 sentence summary:
- What's the current state of the project?
- Any open issues or active tasks?
- What was the last significant change?
- Ready to start — what's the task?

---

## When to Skip

- Pure information questions ("what does function X do?")
- Trivial single-file edits
- Continuing an active session (not a fresh start)

---

## Automated via Hook

The `session_start.py` hook automates most of this by injecting:
- Current local time
- Active project detection
- Git summary
- Open issues
- Framework cheatsheet

See `hooks/session_start.py` for the implementation.
