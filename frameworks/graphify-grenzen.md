<!-- deckel: 20 -->
# graphify — Nutzung und Grenzen

Vor dem Bauen `explain "<Symbol>"` (gibt es das schon?), `affected "<Symbol>"` (Blast-Radius), `query "…"` (Beziehungen). Nach dem Abschluss-Commit `graphify update .`; der Auditor prüft `built_at_commit` gegen den Commit.

**Grenzen — alle antworten in die beruhigende Richtung:**

- **Keine Feld-Ebene.** Der Graph kennt Typen und Methoden; eine Abfrage nach einem Feldnamen liefert trotzdem eine Antwort, nur die falsche. „Wer schreibt dieses Feld" beantwortet Grep. Task-Karten stützen Graph-Kriterien nur auf top-level indexierte Symbole.
- **Ein leeres `affected` ist kein Beleg.** Aufrufe über Instanzfelder (`controller.tuWas()`) und Dateien mit Bindestrich im Namen (`mein-skript.py` → Node `scripts_mein_skript`) liefern „No affected nodes" trotz belegbarer Aufrufer. Live-Aufrufer-Nachweis ist immer Grep außerhalb `*/test/` und Kommentaren; ein leerer Graph-Befund gilt erst, wenn Grep oder ein Blick in `graph.json` ihn bestätigt.
- **Ein veralteter Graph ist gefährlicher als keiner.** Fehlende Kanten sehen aus wie fehlende Kopplung — er unterschätzt den Blast-Radius genau dort, wo man ihn für Cross-Scope und Löschungen braucht.
- **Pro Lane, pro Worktree.** `graphify-out/` ist gitignored; ein Graph-Ergebnis ohne Aktualitäts-Aussage ist kein Beleg.
