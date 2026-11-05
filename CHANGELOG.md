# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.2.0] - 2026-11-05

Knowledge layer: where decisions live and how an outsider gets from install to the first guard. Minor release: new capabilities and docs, no existing interface removed or changed incompatibly.

### Added
- `tools/decisions-check.sh`: guard that every `docs/decisions/*.md` has the five required sections with content, is linked in the building-block index (link target must resolve), and that allowlist entries carry a reason; messages name owner and remedy; `--selftest` runs positive and negative cases.
- `examples/decision.md.example`, `examples/project-CLAUDE.md.example`: an invented decision that passes the guard and a filled-in project `CLAUDE.md`.
- `README.md`: "Knowledge layer" (immune system vs. memory, question-to-place table, memory vs. `docs/decisions/` rule), "Quickstart: the first hour" with the task-card schema in English, and a note on what needs Claude Code Desktop.
- `skills/new-project-bootstrap/SKILL.md`: section `## Entscheidungen` in the project `CLAUDE.md` template, the memory-vs-decisions rule, and the number of decisions in the bootstrap report.

### Changed
- `frameworks/lane.md`: the task card's project context also lists the relevant `docs/decisions/` paths, so the reasoning reaches the buddy.
- `README.md`: the install URL placeholder points to the real repository; layout lists the new files.

## [2.1.0] - 2026-11-05

Guard operation: how quality guards are run, proven and owned.

### Added
- `agents/code-auditor.md`: every guard must carry its own positive and negative probes (its pattern hits every positive line and no negative one), and its message must name an owner and a remedy; a missing one is a finding.
- `agents/code-auditor.md`: the auditor writes its own report with the `Write` tool, restricted to paths under `docs/audits/`.
- `hooks/leitplanken.py`: blocks `code-auditor` from writing anywhere but `docs/audits/` (path-normalized against `..` traversal).
- `hooks/leitplanken.py`: blocks bypassing the commit hook (`--no-verify`, `core.hooksPath`).
- `hooks/leitplanken.py`: explicit allow for writing agent memory, so it no longer triggers an invisible permission dialog; paths are normalized so `memory/../../settings.json` cannot slip through.
- `frameworks/lane.md`: mutation probes run only through a tool that compares the tree before and after (the tool itself is project-specific); the manual "break it once" rule stays.

### Changed
- `frameworks/lane.md`, `skills/new-project-bootstrap/SKILL.md`: the task card's project context points to a single guard register (pattern and allowlist with reason live there and only there); guards run as part of the project's normal test run, not as an extra step.
- `frameworks/betrieb.md`, `frameworks/lane.md`, `hooks/leitplanken.py`: worktrees are created under a project-defined `<worktree-root>` (next to the repo, or inside it as an ignored folder) instead of a fixed path.
- `README.md`: role table reflects the auditor's report-only write access; layout lists this changelog.

## [2.0.0] - 2026-10-18

### Changed
- **Breaking:** the framework is rebuilt around six thoughts instead of a numbered rule catalog (`R1`...). `CLAUDE.md` is now the short core; the old rule numbers, playbook, failure-trap catalog and protocols are removed (they remain in git history).

### Added
- `frameworks/betrieb.md` (non-negotiable operating rules) and `frameworks/lane.md` (how a coordinating instance works: task card, acceptance, monitoring).
- `agents/*.md`: one file per role with its complete rule set (`architecture-reviewer`, `code-auditor`, `code-buddy`, `research-buddy`, `ui-auditor`, `ui-designer`).
- `hooks/leitplanken.py`: PreToolUse hook with self-test, technically blocking the (H) rules.
- `tools/deckel.sh`: line cap per file and in total.

## [1.2.0] - 2026-05-02

### Added
- Commit-discipline railguards: explicit file paths only, mandatory `git diff --staged` before commit, hands off foreign unstaged changes (prevents global commit blasts via `git add -A`).

## [1.1.1] - 2026-04-14

### Fixed
- `CronCreate` timers do not survive context compaction; the Compact Instructions now flag active timers for re-creation afterwards.

## [1.1.0] - 2026-04-13

### Added
- Compact Instructions in the `CLAUDE.md` template: what to preserve and what to drop during context compaction.

## [1.0.0] - 2026-04-13

### Added
- Initial release: ownership principle, 22 rules, 26 failure traps, delegation roles, spawn templates, audit protocol, issue tracking and a session-start hook.

[2.2.0]: https://github.com/dm7ds/claude-code-framework/compare/v2.1.0...v2.2.0
[2.1.0]: https://github.com/dm7ds/claude-code-framework/compare/v2.0.0...v2.1.0
[2.0.0]: https://github.com/dm7ds/claude-code-framework/compare/v1.2.0...v2.0.0
[1.2.0]: https://github.com/dm7ds/claude-code-framework/compare/v1.1.1...v1.2.0
[1.1.1]: https://github.com/dm7ds/claude-code-framework/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/dm7ds/claude-code-framework/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/dm7ds/claude-code-framework/releases/tag/v1.0.0
