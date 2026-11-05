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
- Güte-Wächter: `<aufruf>` (läuft im Test-Befehl mit), Wächter-Register `<pfad>` — genau eines je Projekt, Muster und Allowlist mit Grund stehen dort und nur dort; Ist-Zahl <n> (Datum)

## Ablage
- Issue-Kanal: <Tracker-Aufruf | docs/issues.md>
- Karten: `<pfad>` (nie unter `.claude/`)
- Berichte, Audits, Worktrees: Pfade nach `lane.md` bzw. `betrieb.md`, nur Abweichungen hier

## Bausteine-Index
| Frage | antwortende Stelle |
|---|---|

## Entscheidungen
- Ort: `docs/decisions/<yyyy-mm-dd>_<thema>.md`, genau die Abschnitte aus `FELDER` in `tools/decisions-check.sh` (einzige Stelle der Feldnamen), je mit Inhalt
- Jede Datei steht im Bausteine-Index (Abschnitt `## Entscheidungen`, Link auf `docs/decisions/<datei>`)
- Der Ordner `docs/decisions/` wird mit der ersten Entscheidung angelegt; ohne Ordner meldet der Wächter ROT „Ordner fehlt" (die Allowlist deckt das nicht), also erst einhängen, wenn eine Entscheidung existiert
- Wächter: `bash <framework>/tools/decisions-check.sh <root> <index>` (im Test-Befehl, wenn das Projekt einen zentralen Testlauf hat; sonst steht der Aufruf in der Projekt-`CLAUDE.md` und wird von Hand gefahren)

## Was-Index
- `docs/SPEC.md` ist der Einstieg für das Was: Scope-Sätze (je mit Link auf eine Entscheidung) und eine Tabelle „Frage → Quelle". SPEC = Was-Index, `docs/decisions/` = Warum, Fachquellen = Inhalt; SPEC.md hält selbst keinen Inhalt
- Feature-Specs liegen unter `docs/specs/`, nirgends sonst; Altbestand nur über eine Allowlist mit Grund
- Wächter: `bash <framework>/tools/spec-check.sh <root> [allowlist]` (Einhängen wie beim Entscheidungs-Wächter); die Überschrift des Scope-Abschnitts steht in `SCOPE_HEADING` in `tools/spec-check.sh` und nur dort

## Locks und Heartbeat
- Lock-Block (z. B. Gradle, Gerät), wörtlich übernehmbar in Karten: <block | keiner>
- Heartbeat-Skript: <pfad | keins>

## Projektregeln
<Abweichungen, Ruhezeiten — mit Quelle>

## Projektmanifest (nur UI)
<Form-Faktoren, Listenverbot, Bedienkanten, Design-Memory, Skill-Pfad>
```

Regel: Memory beschreibt das Verhalten der Instanz; eine Projektentscheidung mit Architekturfolge steht in `docs/decisions/`, das Memory ist nur Verweis.

## 3. Workspace-Eintrag

Falls es eine Workspace-`CLAUDE.md` über den Projekten gibt: Zeile in ihrer Projekttabelle (Projekt, Pfad, Repo, Issue-Kanal). Sonst entfällt der Schritt.

## 4. Probelauf

Ein Tracker-Vorgang mit trivialer Karte (z.B. ein Satz in die README) durch `code-buddy` → `code-auditor` schicken. Läuft die Kette bis PASS, ist das Projekt fertig; die Änderung danach per neuem Commit zurücknehmen.

## Bericht

```
Bootstrap <projekt>: CLAUDE.md <neu | ergänzt>, Workspace-Eintrag <ja>, Entscheidungen <n>, SPEC.md <ja | nein>, Probelauf <PASS | FAIL + Grund>
Offen: <z.B. Güte-Wächter fehlt noch, Bausteine-Index leer>
```
