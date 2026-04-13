# Delegation Roles

## Operating Modes

### Mode A: Ad-hoc Sub-Tasks (Default)

Ephemeral agent spawns via the `Agent` tool. Spawned, executed, done, gone. This is the default for ALL work delegation.

```
Agent(
  description: "Fix auth validation bug",
  prompt: "...",
  model: "sonnet",
  run_in_background: true,
  isolation: "worktree"  // if parallel agents
)
```

**Why default:** Zero idle cost. No context staleness. No responsibility diffusion. Empirically proven superior to persistent teams (100% success rate vs 0%).

### Mode B: Dedicated Instances (For Specialists)

Persistent Claude Code sessions for domain leads. Each specialist is a separate Claude Code chat with a role briefing. They talk directly to you (the orchestrator/user), spawn their own sub-agents, and manage their own scope.

**When to use:** When a domain requires deep context that can't be briefed in a task card (complex routing logic, design system knowledge, architectural decisions).

**Anti-TEAM compliant:** These are NOT teams. They're parallel sessions with defined scope boundaries. No idle members, no diffused responsibility.

---

## Role Catalog

### Code Buddy

| Property | Value |
|----------|-------|
| **Model** | Sonnet (always) |
| **Pattern** | Ad-hoc, background, worktree-isolated if parallel |
| **Scope** | Single task card, strict scope |
| **Spawned by** | Orchestrator or Specialist |
| **Reports to** | Spawner |

The workhorse. Gets a task card, implements it, runs the build gate, commits. Does NOT make architectural decisions. Does NOT touch files outside scope. Does NOT "improve" things that aren't in the task.

### Code Auditor

| Property | Value |
|----------|-------|
| **Model** | Sonnet (always) |
| **Pattern** | Ad-hoc, background |
| **Scope** | One completed task |
| **Spawned by** | Orchestrator or Specialist |
| **Reports to** | Spawner |

Reviews completed work against the task card. Produces a structured audit report (PASS/WARN/FAIL). Checks: scope compliance, DRY/NML, cross-scope consumers, build status. Does NOT fix issues — reports them.

### UI Auditor

| Property | Value |
|----------|-------|
| **Model** | Sonnet |
| **Pattern** | Ad-hoc, background |
| **Scope** | One completed UI task |
| **Spawned by** | Orchestrator or Specialist |
| **Reports to** | Spawner |

Reviews UI changes with visual evidence (screenshots, preview tools). Checks: visual correctness, responsive behavior, accessibility basics, design system compliance. Always required for UI changes — no "looks good in the diff" allowed.

### UI Designer (Advisory)

| Property | Value |
|----------|-------|
| **Model** | Opus (exception — design judgment needs the stronger model) |
| **Pattern** | Ad-hoc, **synchronous** (not background) |
| **Scope** | Design questions, max 15 lines response |
| **Spawned by** | Orchestrator or Specialist |
| **Reports to** | Spawner |

Design oracle for quick decisions. "Should this be a modal or a drawer?" "What spacing works here?" Synchronous because design decisions need to flow back immediately. Keep responses short — this is an advisor, not a document generator.

### UI Designer (Planning)

| Property | Value |
|----------|-------|
| **Model** | Opus |
| **Pattern** | Ad-hoc, background |
| **Scope** | Design planning, component architecture |
| **Spawned by** | Orchestrator |
| **Reports to** | Orchestrator |

For larger design tasks: component structure, layout planning, design system extensions. Produces a design document, not code.

### Research Explorer

| Property | Value |
|----------|-------|
| **Model** | Sonnet (or Haiku for cost savings) |
| **Pattern** | Ad-hoc, background, read-only |
| **Scope** | Information gathering |
| **Spawned by** | Anyone |
| **Reports to** | Spawner |

Read-only exploration. Greps, reads, searches. Never edits. Use for: "find all files that import X", "what's the current state of module Y", "search for patterns matching Z".

---

## Model Selection Rules

**Sonnet is the default. Always.** Only override to Opus for genuine design judgment tasks.

**Why:** Larger models with long mandatory reading tend to lose focus. The faster model does the same audit in 1/3 of the time. This is empirical, not theoretical.

| Role | Model | Rationale |
|------|-------|-----------|
| Code Buddy | Sonnet | Speed + focus |
| Code Auditor | Sonnet | Systematic check, doesn't need creativity |
| UI Auditor | Sonnet | Visual check with tools |
| UI Designer | **Opus** | Design taste requires the stronger model |
| Research Explorer | Sonnet/Haiku | Read-only, cheapest that works |

---

## Spawn Checklist

Before every spawn, verify:

- [ ] `model:` parameter explicitly set (don't rely on default)
- [ ] `run_in_background: true` (except synchronous UI Designer advisory)
- [ ] `isolation: "worktree"` if any other agent is running in parallel
- [ ] Task card exists (even minimal) — see R11
- [ ] Prompt contains: WHAT to do, WHY it matters, what NOT to touch
- [ ] No `TeamCreate` — see R13
