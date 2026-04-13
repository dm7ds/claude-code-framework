# Project Bootstrap Checklist

**What a new project needs to work with this framework.**

---

## Minimal Setup (Required)

### 1. Project CLAUDE.md

Create `CLAUDE.md` in the project root. See `templates/project-CLAUDE.md.example` for a starter.

### 2. Issues File

Create `docs/issues.md`:
```markdown
# Issues

| ID | Status | Severity | Title |
|----|--------|----------|-------|
```

### 3. .gitignore Entries

Add to your `.gitignore`:
```
# Framework artifacts
.tasks/
```

### 4. Task Directory (if using task cards)

```bash
mkdir -p .tasks/{pending,in-progress,done,audit,archive,blocked}
```

---

## Nice-to-Have

### 5. Pitfalls Knowledge Base

Create `docs/pitfalls.md` — starts empty, grows from resolved issues:
```markdown
# Pitfalls

Project-specific knowledge base. Each entry is a distilled learning
from resolved issues, grouped by code area.
```

### 6. Build Gate

If your project has a build step, document the build command in CLAUDE.md so code buddies can verify their work:
```markdown
## Build
Run `npm run build` (or equivalent) after every change. Must pass with zero errors.
```

---

## Verification

After bootstrapping, run a smoke test:
1. Start a Claude Code session in the project
2. Verify the session start hook fires and shows project context
3. Create a trivial task card (T000)
4. Spawn a code buddy with that card
5. Spawn an auditor on the result
6. Verify the full cycle works: task → implement → audit → done

If the cycle completes without issues, the project is ready.
