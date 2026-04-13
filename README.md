# Claude Code Multi-Agent Framework

A battle-tested framework for orchestrating multiple Claude Code agents. Born from months of real-world multi-agent development — every rule exists because a specific failure happened without it.

## What This Solves

When you use Claude Code's Agent tool to spawn sub-agents, things go wrong in predictable ways:

- Agents "forget" context and produce contextually wrong fixes
- Nobody reviews the work — agents say "done" with bugs
- Parallel agents overwrite each other's files
- You lose track of what's running and what's stuck
- The same mistakes repeat every session because agents have no cross-session memory

This framework addresses all of these with a system of principles, rules, and templates injected via CLAUDE.md files, hooks, and structured workflows.

## Philosophy

**Rules don't scale. Understanding does.**

This framework has 22 rules and 26 documented failure traps. But the entire thing rests on a single principle:

> **What you spawn, you carry to completion. Actively, not passively.**

An agent that internalizes this principle avoids most traps naturally. The rules are the safety net for when understanding lapses.

## Quick Start (15 minutes)

### 1. Clone the repo

```bash
git clone https://github.com/YOUR_USERNAME/claude-code-framework.git
cd claude-code-framework
```

### 2. Install framework files

Copy the framework files to your Claude Code config directory:

```bash
# Create the frameworks directory
mkdir -p ~/.claude/frameworks

# Copy framework files
cp frameworks/*.md ~/.claude/frameworks/

# Copy the session start hook
mkdir -p ~/.claude/hooks
cp hooks/session_start.py ~/.claude/hooks/
```

### 3. Configure the session start hook

Add to your `~/.claude/settings.json`:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "type": "command",
        "command": "python3 ~/.claude/hooks/session_start.py"
      }
    ]
  }
}
```

### 4. Create your global CLAUDE.md

```bash
cp templates/CLAUDE.md.example ~/.claude/CLAUDE.md
```

Then edit `~/.claude/CLAUDE.md` and personalize:
- Add your role and experience level under "About the User"
- List your active projects under "Active Projects"
- Add any personal rules under "Custom Rules"

### 5. Configure your projects

For each project you want to use the framework with:

```bash
cd /path/to/your/project

# Create project CLAUDE.md from template
cp /path/to/claude-code-framework/templates/project-CLAUDE.md.example CLAUDE.md
# Edit CLAUDE.md with your project's details

# Create issue tracking
mkdir -p docs
echo '# Issues

| ID | Status | Severity | Title |
|----|--------|----------|-------|' > docs/issues.md

# Create task directory (optional, for larger projects)
mkdir -p .tasks/{pending,in-progress,done,audit,archive,blocked}
echo '.tasks/' >> .gitignore
```

### 6. Configure the session hook for your projects

Edit `~/.claude/hooks/session_start.py` and add your projects to the `PROJECT_MAP`:

```python
PROJECT_MAP = {
    "/path/to/my-app": ("My App", "React SPA with Express backend"),
    "/path/to/api-server": ("API Server", "Go REST API"),
}
```

### 7. Verify

Start a new Claude Code session in one of your projects. You should see the session start hook inject project context, local time, and the framework cheatsheet.

## What's Included

### Framework Files (`frameworks/`)

| File | What It Does |
|------|-------------|
| `ownership-principle.md` | **The core.** Meta-principle above all rules. Read this first. |
| `playbook.md` | 22 rules (R1–R22), each born from a real incident |
| `falltraps.md` | 26 failure patterns with recognition and countermeasures |
| `delegation-roles.md` | Role catalog with model selection (Sonnet vs Opus) |
| `spawn-templates.md` | Copy-paste Agent tool templates for each role |
| `task-card-spec.md` | Task card format — the contract between orchestrator and agent |
| `audit-protocol.md` | How to audit work (PASS/WARN/FAIL) with evidence requirements |
| `issue-tracking.md` | Issue tracking protocol with three-layer knowledge model |
| `code-quality.md` | NML, DRY, SSOT rules |
| `session-start-protocol.md` | What to do at session start |
| `project-bootstrap.md` | How to set up a new project |

### Hook (`hooks/`)

| File | What It Does |
|------|-------------|
| `session_start.py` | Injects local time, project context, git summary, open issues, and framework cheatsheet at session start |

### Templates (`templates/`)

| File | What It Does |
|------|-------------|
| `CLAUDE.md.example` | Starter for your global `~/.claude/CLAUDE.md` |
| `project-CLAUDE.md.example` | Starter for project-level `CLAUDE.md` |

### Examples (`examples/`)

| File | What It Does |
|------|-------------|
| `issues.md.example` | Example issue tracking file |
| `pitfalls.md.example` | Example project knowledge base |

## How It Works

```
You (Human Orchestrator)
├── Session Start Hook fires → context injected
├── CLAUDE.md loaded → rules active
├── You describe the work
│
├── Spawn Code Buddy (Agent tool, Sonnet, worktree-isolated)
│   ├── Gets task card with scope + acceptance criteria
│   ├── Implements, builds, commits
│   └── Reports back
│
├── Spawn Code Auditor (Agent tool, Sonnet)
│   ├── Reviews work against task card
│   ├── Checks: scope, DRY, cross-scope consumers, build
│   └── Reports: PASS / WARN / FAIL
│
├── If PASS → merge/commit
├── If FAIL → fix task → re-audit
└── Track issues, update pitfalls, next task
```

## Key Concepts

### Three Task States

Every task is in exactly one state:
- **(a) Done and accepted** — finished, verified
- **(b) Blocked and reported** — can't continue, user informed
- **(c) Active monitoring** — running, checked every 5-10 min with real tool calls

Everything else is an ownership gap.

### Three-Layer Knowledge Model

1. **`issues.md`** — Open issues only. Lean, current.
2. **`pitfalls.md`** — Distilled learnings from resolved issues. 3-5 lines per entry.
3. **`issues-archive.md`** — Full text of resolved issues. Rarely read, always available.

### Anti-Blame-Shift

When a bug is reported: grep and read code first, respond after. Never deflect with "clear the cache" or "are you sure?". User perception is fact.

## Adapting to Your Workflow

### Start Small

Don't adopt everything at once. Start with:
1. The ownership principle
2. A CLAUDE.md with your anti-blame-shift rule
3. The session start hook
4. Issue tracking in `docs/issues.md`

This covers 80% of the failure modes.

### Grow From Your Own Mistakes

The falltraps catalog documents failures from a specific development context. Your failures will be different. Start your own `pitfalls.md` and add entries when things go wrong. A rule you write after experiencing the failure is worth ten rules you copied from someone else.

### Customize Roles

The role catalog (Code Buddy, Auditor, UI Designer, etc.) is a starting point. Add roles that match your domain. Remove roles you don't need.

### Adjust Model Selection

The framework defaults to Sonnet for most roles (speed + focus) and Opus only for design judgment. Adjust based on your needs and budget. The key insight: bigger models with long mandatory reading tend to lose focus. Faster models often produce better results for scoped tasks.

## FAQ

**Do I need all 22 rules?**
No. Start with R1 (scope first), R5 (zero-grep-gate), R6 (worktree isolation), R13 (no teams), R14 (track issues). Add others when you hit the problems they solve.

**Why not use TeamCreate?**
Empirically, persistent teams produce 0% success rate vs 100% for ad-hoc sub-tasks. Teams create idle members, diffused responsibility, and stale context. Spawn, execute, done, gone.

**Why Sonnet over Opus for most roles?**
Speed, focus, and cost. Opus with long mandatory reading loses focus. Sonnet does the same code audit in 1/3 the time. Use Opus only where genuine creative judgment is needed (design decisions).

**Can I use this with other AI coding tools?**
The principles (ownership, three task states, anti-blame-shift) are universal. The implementation (CLAUDE.md, Agent tool, hooks) is Claude Code specific.

## License

MIT — use it, adapt it, share it.
