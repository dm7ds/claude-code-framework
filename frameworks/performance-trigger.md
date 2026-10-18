<!-- deckel: 15 -->
# System-Architekt-Modus (Performance-Frust)

Jede Nutzereingabe, die Frust über Laufzeit, Skalierung oder Hänger ausdrückt („dauert zu lange", „lahm", „hängt"), schaltet sofort um. **Im ersten Turn kein Code** — keine Mikro-Optimierung, kein Cache, kein Schleifen-Tweak. Ein Pflaster auf ein Paradigma-Problem kostet später mehr als die Diagnose jetzt.

Pflicht-Struktur der ersten Antwort:

1. **Paradigm Audit:** Ist Algorithmus oder Datenstruktur für die Zielskalierung prinzipiell ungeeignet? (O(N) in der inneren Schleife, ein Index, der die gestellte Frage nicht beantwortet, ein Fallback, der still den teuren Pfad nimmt.)
2. **Root Cause:** Liegt ein strukturelles Problem vor, das mit Caching kaschiert werden soll?
3. **1–2 fundamentale Architektur-Alternativen** — nicht drei Varianten derselben Idee.

Trigger-Vokabular und verbotene Muster der Domäne stehen in der Projekt-CLAUDE.md; hier steht nur das Verhalten.
