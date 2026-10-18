---
name: postmortem
description: Nach einem Fehler/Incident analysieren, was passiert ist, Root Cause finden, an der antwortenden Stelle beheben und einen Wächter vorschlagen statt neuer Prosa. Keine Schuldzuweisung — Prozess-Verbesserung.
---

# Postmortem

Aufrufen nach Audit-FAIL, Bug nach Merge, Delegationsfehler oder Beschwerde des Users — erst wenn das Problem nicht mehr aktiv ist (erst fixen, dann Postmortem). Grundlage: die sechs Gedanken in `~/.claude/CLAUDE.md`, Abschnitt „Selbstoptimierung".

## Ablauf

1. **Incident in drei Zeilen:** was passiert ist, wer beteiligt war (Rollen), wann.
2. **Symptom:** woran es sichtbar wurde — die Wahrnehmung des Users ist Fakt (Gedanke 4).
3. **Root Cause:** nicht beim ersten Symptom stehen bleiben. Prüffragen:
   - Gab es zwei antwortende Stellen für eine Frage (Gedanke 1)? Das ist der häufigste Grund — die Metrik in CLAUDE.md zählt genau diesen Anteil.
   - Wurde eine falsche Eingabe kompensiert statt an der Quelle behoben (Gedanke 2)?
   - Konnte die Prüfung überhaupt rot werden (Gedanke 3)?
   - Hatte die Karte `## Tatsachen`, Mutationen je Akzeptanzkriterium, propagierte WARN (`lane.md` §Karte)?
   „Der Buddy war schlampig" ist Symptom; Root Cause ist ein Prozess- oder Strukturloch.
4. **Beheben an der antwortenden Stelle:** Code-/Config-Fix als Tracker-Vorgang mit Karte (`lane.md`), nicht nebenbei.
5. **Rückfall verhindern:** Wächter statt Prosa, Regel nur gegen eine gestrichene — wie, steht in `CLAUDE.md` §Selbstoptimierung. Regeländerungen schlägst du dem User vor, `bash tools/deckel.sh` muss danach grün sein.

## Bericht an den User

```
Was passiert ist: <ein Satz>
Root Cause: <ein Satz, welcher Gedanke>
Fix: <Tracker-ID | keiner nötig>
Wächter: <Pfad/Vorschlag | keiner möglich, weil …>
Regel-Vorschlag: <alt → neu → warum, gestrichen: … | keiner>
```

Kein Ritual: nur bei echten Incidents.
