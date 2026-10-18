# Claude Code Multi-Agent Framework

A framework for orchestrating Claude Code sub-agents — born from months of real multi-agent development. It used to be ~7,000 lines of rules and failure catalogs. It is now under 600 lines of *meaning*, because rules don't scale and understanding does.

> Working language of the framework files is German; the concepts are language-agnostic. This README is in English.

## What it solves

- Agents say "done" with bugs — nobody reviewed the work.
- The same question gets answered in two places in the code, and they drift apart.
- Fixes compensate for bad input in every consumer instead of fixing the source.
- Checks that can never fail (return code 0, `HTTP 200`, `running`) are taken as proof.
- Parallel agents overwrite each other's files or wipe shared work (`stash`, `reset`, `add -A`).
- Nobody tracks what was spawned; tasks silently die.

## The core: six thoughts (`CLAUDE.md`)

1. **One question has exactly one answering place, and it serves everyone who asks.** Two places are a defect even if both are right today.
2. **Source before processing.** Garbage input is fixed at the source or rejected by *one* gate — "I don't know" is its own state, not a placeholder value.
3. **A check must be able to turn red.** Break it by hand once; if the check doesn't catch it, it isn't one.
4. **Claim only what is proven.** "Not found" is not "doesn't exist"; user perception is fact.
5. **Build only what was ordered — but fix errors structurally, and a gate completely.**
6. **What you spawn, you carry.** Every task is done and accepted, blocked and reported, or actively monitored.

Everything else follows from these.

## Layout

```
CLAUDE.md                     # the core: six thoughts, roles, self-optimization  → ~/.claude/CLAUDE.md
frameworks/betrieb.md         # non-negotiable operating rules (git, processes, devices)
frameworks/lane.md            # how a coordinating instance works: task card, spawn, monitoring, acceptance
frameworks/graphify-grenzen.md · performance-trigger.md
agents/*.md                   # one file per role, its complete rule set (sub-agents run with omitClaudeMd)
skills/                       # framework-refresh, postmortem, new-project-bootstrap
hooks/leitplanken.py          # PreToolUse hook: technically blocks the (H) rules in betrieb.md
hooks/session_start.py        # SessionStart hook: local time, project, git summary, open issues
tools/deckel.sh               # line cap per file + total ≤600; red = no commit
tools/githooks/pre-commit     # runs deckel.sh
examples/issues.md.example    # minimal issue file format (read by session_start.py)
```

## Roles (`agents/`)

| subagent_type | Role | Model |
|---|---|---|
| `code-buddy` | builds per task card in its own worktree | Sonnet |
| `code-auditor` | read-only; *counts* how many places answer the card's question after the merge | Sonnet |
| `research-buddy` | first choice for anything that produces raw data; burns its own tokens, returns a digest | Sonnet |
| `ui-auditor` | accepts UI on the device/browser, by screenshot | Sonnet |
| `architecture-reviewer` | structure and topology; double verdict with the code auditor | Opus |
| `ui-designer` | design advisor, max 15 lines | Opus |

Sub-agents don't see `CLAUDE.md` — each agent file carries its role's whole rule set, and the **task card** carries the project knowledge (`lane.md` §Karte).

## Install

```bash
git clone https://github.com/YOUR_USERNAME/claude-code-framework.git
```

Link (preferred, so edits land in git) or copy into `~/.claude/`:

```bash
ln -s "$PWD/claude-code-framework/CLAUDE.md"  ~/.claude/CLAUDE.md
ln -s "$PWD/claude-code-framework/frameworks" ~/.claude/frameworks
ln -s "$PWD/claude-code-framework/agents"     ~/.claude/agents
ln -s "$PWD/claude-code-framework/skills"     ~/.claude/skills
```

On Windows use directory junctions (`mklink /J`). Remove a junction only with `cmd /c rmdir "<path>"` (no `/s`) — recursive delete follows the link and empties the target.

Hooks in `~/.claude/settings.json` (point to the repo path):

```json
{
  "hooks": {
    "SessionStart": [{ "hooks": [{ "type": "command", "command": "python3 /path/to/claude-code-framework/hooks/session_start.py" }] }],
    "PreToolUse":   [{ "hooks": [{ "type": "command", "command": "python3 /path/to/claude-code-framework/hooks/leitplanken.py" }] }]
  }
}
```

`leitplanken.py` blocks writes under `.claude/`, so edit framework files in the repo, not via `~/.claude/`. Self-test: `python hooks/leitplanken.py --test`.

Per project: run the `new-project-bootstrap` skill — it creates the project `CLAUDE.md` with what task cards need (build/test, tracker, card location, quality guards, building-block index).

## Maintenance

- **Relapse → a guard (executable scan), never new prose.** A new rule only against a removed one.
- `bash tools/deckel.sh` must stay green; enable the commit lock once per clone: `git config core.hooksPath tools/githooks`.
- Git is the archive: the old rule catalog (R-rules, failure-trap catalog, playbook) is in the history before this version.

## FAQ

**Why so short?** The old 7,000 lines were read, quoted and not applied. Six thoughts that are understood beat a catalog that is cited.

**Why not TeamCreate?** Persistent team members fall asleep after their mandatory reading (measured 10:0 in favor of ad-hoc spawns). Spawn, execute, done, gone.

**Why Sonnet by default?** Speed, focus, cost. Opus only for genuine judgment (structure, design).

## License

MIT — use it, adapt it, share it.
