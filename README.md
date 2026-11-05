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

## Knowledge layer

Two systems, kept apart:

- **Immune system** — what keeps work correct: the six thoughts, guards (executable scans), hooks.
- **Memory** — what keeps knowledge: agent memory, `docs/SPEC.md`, `docs/decisions/`, domain sources (API docs, routing tables), the issue tracker.

Three parts, three jobs: `docs/SPEC.md` = **what** (an index: scope sentences that each link a decision, plus a question → source table, no content of its own), `docs/decisions/` = **why**, domain sources = **content**.

| Question | The one place |
|---|---|
| How should the instance behave? | agent memory (`~/.claude/projects/<p>/memory/`) |
| Why was a project decision made, how do I undo it? | `docs/decisions/<date>_<topic>.md` (five fixed sections), linked from the building-block index |
| What does the project cover, and where is each topic specified? | `docs/SPEC.md` (what-index; feature specs live only in `docs/specs/`) |
| Which code answers question X? | building-block index in the project `CLAUDE.md` |
| What is open, who owns it? | issue tracker / `docs/issues.md` |
| What happened in this task? | the buddy's report file under `docs/reports/` |

Rule: memory describes the instance's *behavior*. A project decision with architectural consequences goes to `docs/decisions/`; memory only points to it. There is deliberately no `DECISIONS.md`, and `SPEC.md` holds no content — a content-bearing SPEC would be a second answering place (thought 1). Buddies see neither `CLAUDE.md` nor memory, so the task card's `## Projektkontext` lists the relevant `docs/decisions/` paths and `docs/SPEC.md`. `tools/decisions-check.sh` guards the shape: every decision file has all five sections with content and is linked in the index. `tools/spec-check.sh` guards the index: every link in `SPEC.md` resolves, every scope sentence links a file under `docs/decisions/`, and no `*spec*.md` lies outside `docs/specs/` (legacy files only via an allowlist with a reason). See `examples/decision.md.example` and `examples/SPEC.md.example`.

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
tools/decisions-check.sh      # guard: docs/decisions/*.md have all five sections and are indexed (--selftest)
tools/spec-check.sh           # guard: docs/SPEC.md is a what-index (links resolve, scope sentences link decisions, no stray specs) (--selftest)
tools/githooks/pre-commit     # runs deckel.sh
examples/issues.md.example    # minimal issue file format (read by session_start.py)
examples/decision.md.example  # an invented decision that passes decisions-check.sh
examples/SPEC.md.example      # an invented what-index that passes spec-check.sh with the decision above
examples/project-CLAUDE.md.example  # a filled-in project CLAUDE.md (neutral example project)
CHANGELOG.md                  # release notes (Keep a Changelog, SemVer)
```

## Roles (`agents/`)

| subagent_type | Role | Model |
|---|---|---|
| `code-buddy` | builds per task card in its own worktree | Sonnet |
| `code-auditor` | read-only on source (writes only its report under `docs/audits/`); *counts* how many places answer the card's question after the merge | Sonnet |
| `research-buddy` | first choice for anything that produces raw data; burns its own tokens, returns a digest | Sonnet |
| `ui-auditor` | accepts UI on the device/browser, by screenshot | Sonnet |
| `architecture-reviewer` | structure and topology; double verdict with the code auditor | Opus |
| `ui-designer` | design advisor, max 15 lines | Opus |

Sub-agents don't see `CLAUDE.md` — each agent file carries its role's whole rule set, and the **task card** carries the project knowledge (`lane.md` §Karte).

## Install

```bash
git clone https://github.com/dm7ds/claude-code-framework.git
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

## Quickstart: the first hour

1. **Install** (above): link the framework into `~/.claude/`, add the two hooks. Check: `python hooks/leitplanken.py --test` and `bash tools/decisions-check.sh --selftest` and `bash tools/spec-check.sh --selftest` end green.
2. **Bootstrap** your project: run the `new-project-bootstrap` skill. Result: a project `CLAUDE.md` (see `examples/project-CLAUDE.md.example`).
3. **First task card.** One file per task, written before any spawn (`frameworks/lane.md` §Karte). The schema, in English:
   - *The question in one sentence* — what question does the code answer afterwards?
   - *`## Tatsachen`* (facts) — table `path:line | form | return | fit? YES/NO + why`: every place that answers that question today.
   - *`## Projektkontext`* (project context) — build/test command, guards, paths, relevant rules and `docs/decisions/` paths, building-block index. The buddy sees nothing else.
   - *Acceptance criteria*, each with the mutation that turns it red.
   - *Worktree path*, branch, approval wording.
4. **First spawn:** a `code-buddy` builds the card in its own worktree and writes a report file; then a separate `code-auditor` checks it (read-only, counts the answering places after the merge). Self-audit is not an audit.
5. **First guard:** `bash <framework>/tools/deckel.sh` (size caps of the framework files; from inside the framework clone: `bash tools/deckel.sh`), then your first project guard from the bootstrap; for decisions copy `examples/decision.md.example` into `docs/decisions/` of your project, link it in the index and run `bash <framework>/tools/decisions-check.sh <project-root> <index>` (e.g. `<project-root>` = `.`, `<index>` = `CLAUDE.md`); for the what-index copy `examples/SPEC.md.example` to `docs/SPEC.md` and run `bash <framework>/tools/spec-check.sh <project-root> [allowlist]`. Break it once by hand (delete a section) and watch it turn red — a guard that cannot fail is not one.

### What needs Claude Code Desktop

Works with any Claude Code: the six thoughts, task cards, buddy/auditor spawns, `leitplanken.py`, `deckel.sh`, `decisions-check.sh`, `spec-check.sh`, `session_start.py`.
Desktop-app specific: the per-session `CronCreate` monitoring job and the messaging between sessions described in `lane.md` §Monitoring and §Kommunikation (thought 6). Without the app, keep the same duty by hand: check your open tasks at least every 20 minutes.

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
