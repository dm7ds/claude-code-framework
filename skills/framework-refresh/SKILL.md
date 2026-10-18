---
name: framework-refresh
description: Lädt die Framework-Files neu in den Session-Kontext. Nutzen, wenn während einer laufenden Session Framework-Änderungen eingespielt wurden und die Instanz die neuen Regeln noch nicht kennt. User triggert mit "/framework-refresh" oder "refresh framework".
---

# Framework Refresh

Eine laufende Session sieht Framework-Änderungen auf Disk nicht — sie hat ihre Regeln beim Start gelesen. Der Refresh ist das explizite „lies jetzt X".

## Ablauf

1. `git -C <framework-repo> log --oneline -10` — was hat sich seit Session-Start geändert?
2. Neu lesen:
   - `~/.claude/CLAUDE.md` — die sechs Gedanken, Rollen, Selbstoptimierung
   - `~/.claude/frameworks/betrieb.md` — unverhandelbar
   - `~/.claude/frameworks/lane.md` — Karte, Spawn, Monitoring, Abnahme
   - die eigene Rolle unter `~/.claude/agents/*.md`, falls du eine bist
   - bei Bedarf: `frameworks/performance-trigger.md`, `frameworks/graphify-grenzen.md`, Projekt-`CLAUDE.md`
3. Kurz melden: gelesene Dateien, was sich gegenüber dem bisherigen Stand geändert hat (mit Commit), was du ab jetzt anders machst.

Kein Kontext-Reset, kein rückwirkendes Nachholen — die neuen Regeln gelten ab jetzt.
