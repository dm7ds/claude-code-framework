---
name: new-project-bootstrap
description: Hebt ein neues Projekt auf das Claude-Framework. Legt die Projekt-CLAUDE.md mit allem an, was Karten und Buddys aus dem Projekt brauchen (Build/Test, Tracker, Kartenablage, Güte-Wächter, Bausteine-Index), und trägt das Projekt in die Workspace-CLAUDE.md ein (falls vorhanden).
---

# New Project Bootstrap

Das Framework (`~/.claude/CLAUDE.md`, `frameworks/lane.md`, `frameworks/betrieb.md`, `agents/*.md`) ist global. Pro Projekt fehlt nur, was die Karte nach `lane.md` §Karte aus der Projekt-`CLAUDE.md` holt — Buddys laufen mit `omitClaudeMd: true` und sehen nur die Karte.

## 1. Diagnose — dem User vorstellen, bevor etwas angelegt wird

- Gibt es schon eine `CLAUDE.md`? Dann **nicht überschreiben**, Ergänzungen vorschlagen.
- Git-Repo? Remote? (`git rev-parse --is-inside-work-tree`, `git remote -v`). Kein `git init` ohne Ja.
- Build-System, Testbefehl, UI ja/nein (Preview, Gerät)?
- Issue-Kanal: Tracker-CLI oder `docs/issues.md`?

## 2. Projekt-`CLAUDE.md` anlegen

Nur Projektwissen, keine Framework-Regeln wiederholen (Gedanke 1):

```markdown
# <Projekt> — Projektwissen

Framework: `~/.claude/CLAUDE.md` (Orchestrator-Modus). Hier steht nur, was Karten aus diesem Projekt brauchen.

## Bauen und Prüfen
- Build: `<befehl>` — Exit 0, 0 Warnings
- Test: `<befehl>`
- Güte-Wächter: `<aufruf>`, Allowlist `<pfad>`, Ist-Zahl <n> (Datum)

## Ablage
- Issue-Kanal: <Tracker-Aufruf | docs/issues.md>
- Karten: `<pfad>` (nie unter `.claude/`)
- Berichte, Audits, Worktrees: Pfade nach `lane.md` bzw. `betrieb.md`, nur Abweichungen hier

## Bausteine-Index
| Frage | antwortende Stelle |
|---|---|

## Locks und Heartbeat
- Lock-Block (z. B. Gradle, Gerät), wörtlich übernehmbar in Karten: <block | keiner>
- Heartbeat-Skript: <pfad | keins>

## Projektregeln
<Abweichungen, Ruhezeiten — mit Quelle>

## Projektmanifest (nur UI)
<Form-Faktoren, Listenverbot, Bedienkanten, Design-Memory, Skill-Pfad>
```

## 3. Workspace-Eintrag

Falls es eine Workspace-`CLAUDE.md` über den Projekten gibt: Zeile in ihrer Projekttabelle (Projekt, Pfad, Repo, Issue-Kanal). Sonst entfällt der Schritt.

## 4. Probelauf

Ein Tracker-Vorgang mit trivialer Karte (z.B. ein Satz in die README) durch `code-buddy` → `code-auditor` schicken. Läuft die Kette bis PASS, ist das Projekt fertig; die Änderung danach per neuem Commit zurücknehmen.

## Bericht

```
Bootstrap <projekt>: CLAUDE.md <neu | ergänzt>, Workspace-Eintrag <ja>, Probelauf <PASS | FAIL + Grund>
Offen: <z.B. Güte-Wächter fehlt noch, Bausteine-Index leer>
```
