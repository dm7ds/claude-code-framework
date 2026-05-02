# Falltraps Catalog

## Before All Traps: Read the Ownership Principle

**If this file looks long, that's due to its history, not the number of actual error patterns.** Almost all entries here are variants of the same root: a task gets spawned or taken on, and nobody actively carries it to completion. The real antidote is in `ownership-principle.md` — it explains *why* these traps all taste the same and *how* to avoid entering them in the first place.

**Read the ownership principle first, this catalog only when needed.** This is a reference for *"I'm in this situation right now, what's the pattern?"* — not for "let me memorize 26 rules". Reading this as a checklist means you've already lost: checklists get processed mechanically, principles get understood and applied to new situations.

## Anti-Linear-Growth Rule

This file grew linearly — every incident produced a new entry, and eventually the sheer length became part of the problem. **New incidents are primarily integrated as precision of an existing entry, not as a new entry.** A new entry is only justified when the symptom, root cause, **and** countermeasure are significantly different from everything already documented. When in doubt: extend the existing entry, document the case variant.

---

## The Traps

### #1 — Cross-Scope Consumer Overlooked

**Symptom:** You change a function, component, or type. Build passes. But 3 other files that import/call it now break — and you didn't know they existed.

**Root cause:** No grep before editing. The definition site looked self-contained, so the change felt safe.

**Countermeasure:** Before ANY modification to shared code: global grep for all consumers. List them. Decide if they need updating. This is R4/R5 in the playbook.

**Recognition:** Any edit to an exported function, type, constant, or component without a preceding grep is a #1 candidate.

---

### #2 — Token/Symbol Deletion Without Global Grep (Zero-Grep-Gate)

**Symptom:** You delete a function, rename a variable, remove an export. Build passes locally. Somewhere else, an import fails or a reference returns undefined.

**Root cause:** Deletion felt "obviously safe" because the immediate file looked clean.

**Countermeasure:** Hard gate: before any deletion, run a project-wide grep. Zero external references = safe to delete. Any references = update them first or coordinate.

**Variant — Residual artifacts:** After renaming/deleting, leftover references in config files, test fixtures, or documentation that grep would have caught.

---

### #3 — Runtime Writes to Config Directories

**Symptom:** You write runtime data (logs, state, task cards) to a config directory (e.g., `.claude/`). Every write triggers a permission dialog or config reload.

**Root cause:** Config directories are watched by the system. They're for configuration, not runtime data.

**Countermeasure:** Use a separate directory for runtime data (e.g., `.tasks/`, `docs/`). Add it to `.gitignore`. Never store mutable state in config directories.

---

### #4 — Audit Findings Not Propagated

**Symptom:** Auditor finds a WARN. It's noted in the report. Nobody reads the report again. The warning becomes reality two tasks later.

**Root cause:** Findings stay in audit reports, which are write-once-read-never documents.

**Countermeasure:** WARN → next task card's "Propagated Findings" section. FAIL → immediate fix task. See R7.

---

### #5 — Shared Working Tree With Parallel Agents

**Symptom:** Two code buddies run simultaneously. Both edit files. One overwrites the other's changes. Merge produces garbage.

**Root cause:** Both agents work in the same git working directory.

**Countermeasure:** Worktree isolation. Each parallel agent gets `isolation: "worktree"` in the spawn call. Merge after completion. See R6.

---

### #6 — DRY Violation / No Magic Literals

**Symptom:** Copy-pasted code blocks that differ in one value (a color, a label, a binding path). Changing the pattern requires finding and updating N copies.

**Root cause:** It was "faster" to copy-paste than to create a template/component/loop.

**Countermeasure:** If markup/code blocks differ only in binding paths, labels, or config values → reusable template, component, or loop. Copy-paste with minimal changes is ALWAYS a design defect.

---

### #7 — Acceptance Criteria Too Vague

**Symptom:** Task card says "improve X" or "fix the layout". Buddy delivers something. Nobody can objectively say whether it meets the criteria because the criteria are subjective.

**Root cause:** Criteria describe intent, not measurable outcomes.

**Countermeasure:** Machine-verifiable criteria: "Component renders without console errors", "API returns 200 for input X", "Slider updates value in store on change". If you can't write a test for it, the criterion is too vague.

---

### #8 — Code Buddy Context Vacuum

**Symptom:** Buddy spawned with "fix the bug in file X". Buddy doesn't know why the bug matters, what the user flow is, or what related components exist. Produces a technically correct but contextually wrong fix.

**Root cause:** Spawn prompt contains WHAT but not WHY. The buddy operates without understanding.

**Countermeasure:** Every spawn prompt needs: what to do, why it matters, what NOT to touch, and which files are in scope. See R3 and R11.

---

### #9 — Persistent Team Anti-Pattern

**Symptom:** You create a team with named members for ongoing work. Members sit idle between tasks. Context grows stale. Responsibility diffuses.

**Root cause:** Teams feel organized but produce overhead. Idle members consume resources. "Someone on the team will handle it" = nobody handles it.

**Countermeasure:** Ad-hoc sub-tasks only. Spawn, execute, done, gone. No persistent teams. See R13. TEAM = **T**errific, **E**veryone's **A**voiding **M**aking progress.

---

### #10 — Hotfix on Structural Problem

**Symptom:** A bug keeps recurring in slightly different forms. Each time you patch the symptom. The patches accumulate into a fragile tower.

**Root cause:** The root cause is architectural, but fixing it feels "too big" so you keep band-aiding.

**Countermeasure:** When a bug recurs in variants: stop, diagnose the structural root, escalate. See R8.

---

### #11 — Locale/Culture Trap

**Symptom:** Number parsing, date formatting, or string comparison works on your machine but breaks in production or on machines with different locale settings.

**Root cause:** Using culture-dependent formatting/parsing without explicit culture specification.

**Countermeasure:** Always use `InvariantCulture` (or equivalent) for data processing. Use locale-specific formatting only for display.

---

### #12 — DateTime Kind Confusion (UTC vs Local)

**Symptom:** Timestamps are off by hours. Comparisons produce wrong results. Sorting is inconsistent.

**Root cause:** Mixing UTC and local times without explicit conversion. `DateTime.Kind` is `Unspecified` and gets treated as both.

**Countermeasure:** Store and process in UTC. Convert to local only for display. Always be explicit about the kind.

---

### #13 — Status Sugarcoating

**Symptom:** Agent reports "almost done" or "minor issues remaining" when significant problems exist. User trusts the report and is surprised by the actual state.

**Root cause:** Optimism bias. The agent believes it will fix the remaining issues shortly, so it reports the anticipated state rather than the current state.

**Countermeasure:** Report facts, not predictions. "3 of 5 tests pass" not "almost there". See R9.

**Variant — Known bug ignored:** Agent knows about a bug (it was mentioned in briefing) but doesn't address it, hoping nobody will notice. When confronted, addresses it silently. The not-addressing is worse than the bug.

---

### #14 — Scope Creep by Sub-Agent + Global Commit Blast

**Symptom:** Buddy was tasked with fixing bug A. Delivers fix for A plus "while I was there, I also refactored B and updated C". B and C were not in scope, not audited, and may introduce new issues.

**Variant (commit blast):** Buddy runs `git add -A` or `git add .` and commits everything in the working tree — including unstaged changes from other agents, half-finished work, or files completely outside their scope. This is worse than code scope creep because it silently ships unreviewed changes.

**Root cause:** The buddy saw "improvements" and made them without asking. Or worse: didn't even look at what it was committing because `git add -A` is the lazy default.

**Countermeasure:**
- Task card must include "Prohibited" section.
- Buddy prompt must emphasize: out-of-scope changes are violations, not bonuses.
- **Commit discipline:** Never `git add -A`/`.`/`--all`. Always `git add <specific files>`. Always `git diff --staged` before commit to verify only own changes are staged. See spawn templates for the full commit discipline block.

---

### #15 — Documentation Sync Forgotten

**Symptom:** User-facing feature changed, but README/help text/inline docs still describe the old behavior.

**Root cause:** Code change was the "real work", docs update was "I'll do it after".

**Countermeasure:** If a task changes user-facing behavior, the docs update is part of the acceptance criteria, not a follow-up.

---

### #16 — Model Parameter Forgotten on Spawn

**Symptom:** A sub-agent that should run on a specific model (e.g., Sonnet for code, Opus for design) runs on the default model instead.

**Root cause:** The `model:` parameter was omitted in the Agent tool call.

**Countermeasure:** Every spawn template must include the explicit `model:` parameter. Default should be documented (typically the faster/cheaper model for code work).

---

### #17 — No Task Card Before Spawn

**Symptom:** "Quickly fix X" spawned without written scope. Buddy asks clarifying questions mid-work, or delivers something that doesn't match expectations.

**Root cause:** "It's simple, doesn't need a card." It wasn't simple.

**Countermeasure:** Even a 5-line task card is better than none. Scope + acceptance criteria + prohibited actions. See R11.

---

### #18 — Decision Ping-Pong With User

**Symptom:** Every small technical decision gets bounced to the user for approval. User gets frustrated by constant interruptions about things they expect the specialist to handle.

**Root cause:** Risk aversion. The agent wants to be "safe" by never deciding alone.

**Countermeasure:** Technical decisions within scope: decide. Architectural/fundamental decisions: escalate. See R10.

---

### #19 — "Looks Clean in Code" Without Visual Verification

**Symptom:** UI change reviewed only in code. "The CSS looks correct." Rendered result has visual bugs that code review can't catch.

**Root cause:** Trusting code analysis for visual outcomes.

**Countermeasure:** UI changes need screenshot evidence. Use preview tools. "Looks good in the diff" is not acceptance.

---

### #20 — Session Start Ritual Skipped

**Symptom:** Agent starts working immediately without loading project context, open issues, or current wave status. Duplicates resolved work or contradicts recent decisions.

**Root cause:** Eagerness to be productive. "I know this project."

**Countermeasure:** Session start protocol: read project CLAUDE.md, check open issues, check active tasks. Takes <5 minutes, prevents hours of rework.

---

### #21 — Blame-Shift Instead of Debugging

**Symptom:** User reports a bug. Agent's first response is "clear the cache", "are you sure you see X?", "it works on my end", "that shouldn't be possible".

**Root cause:** The agent's instinct is to defend its code rather than investigate the report.

**Countermeasure:** When a bug is reported: grep and read code for 5-10 minutes, THEN respond. User perception is fact. Your job is WHY, not WHETHER.

**Prohibited reflexive responses:**
- "There shouldn't be any X there"
- "That's by design"
- "Clear the cache"
- "Restart"
- "Are you sure you're seeing X?"
- "It works on my end"

---

### #22 — Improvement Promises Without Sustainability

**Symptom:** After a mistake, agent says "I'll make sure this doesn't happen next time." Next time: exact same mistake. The promise was sincere but worthless — the agent has no cross-session memory.

**Root cause:** Meta-promises feel like action but aren't. The next session starts fresh.

**Countermeasure:** Don't promise future improvement. Fix the issue NOW. If it's a recurring pattern, it needs a rule in CLAUDE.md (which survives sessions), not a promise in chat (which doesn't).

---

### #23 — Anticipatory Consistency Missing

**Symptom:** Agent fixes a bug in function A. Functions B and C have the same conceptual pattern but different code. Agent doesn't check them.

**Root cause:** Fixing the reported instance, not the pattern. Tunnel vision on the specific file/function mentioned.

**Countermeasure:** When fixing a bug, ask: "Is this pattern repeated elsewhere?" If yes, check all instances. This is R4 at the conceptual level.

**Variant — UX change that looks like a bug:** A code change alters user-visible behavior (element position, interaction pattern, visual appearance) without the user requesting it. The user sees the change and reports it as a bug, because from their perspective, something that worked now works differently. The fix is correct, but the UX delta was never communicated. Any UX-relevant element that requires explanation to understand is, by definition, broken UX.

---

### #24 — Resource Anxiety Avoidance

**Symptom:** Agent suggests workarounds, "pragmatic alternatives", or scope reductions to avoid using compute time. "To save resources, we could..." when the real fix is within reach.

**Root cause:** False ROI calculation. Compute time is the cheap resource. User frustration from workarounds is the expensive one.

**Countermeasure:** See R18. Fix what's in scope. Workarounds are not options when the real solution is achievable.

---

### #25 — Long-Running Pipeline Without Self-Wake

**Symptom:** Agent starts a job that takes 30+ minutes, ends the turn with "I'll continue when it's done." It's done 2 hours later. Nobody continues.

**Root cause:** "Continue later" as self-discipline illusion. LLM instances have no future self.

**Countermeasure:** See R19. Set a trigger BEFORE ending the turn. Choose the right type (same-session vs cross-session) based on semantics, not mechanics.

**Variant — Self-wake in wrong session:** Wake trigger set correctly, fires correctly, but into a parallel/new session. The original chat where the user is waiting stays silent. The agent confused cross-session wake with in-chat presence. R19 ≠ R2 — both may be needed simultaneously.

---

### #26 — Roadmap Synergy Not Reported

**Symptom:** While working on task A, agent notices that roadmap item B could be achieved with <30% additional effort. Says nothing. Opportunity passes.

**Root cause:** Staying strictly in scope (which is usually correct) but failing to REPORT the opportunity (which is always correct).

**Countermeasure:** See R20. Report in 3 lines with A/B/C decision. Don't execute without asking. Don't stay silent either.
