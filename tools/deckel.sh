#!/usr/bin/env bash
# Deckel-Waechter: jede Framework-Datei traegt in den ersten 10 Zeilen
# "<!-- deckel: N -->" (nach dem Agent-Frontmatter, deshalb nicht Zeile 1-3).
# Vergleicht mit wc -l, Summe <= GESAMT. exit 1 bei Ueberschreitung.
set -u
cd "$(dirname "$0")/.."
GESAMT=600
DATEIEN="CLAUDE.md frameworks/*.md agents/*.md"
rot=0; summe=0
for f in $DATEIEN; do
  deckel=$(head -10 "$f" | sed -n 's/.*<!-- deckel: \([0-9]\+\) -->.*/\1/p' | head -1)
  zeilen=$(wc -l < "$f")
  summe=$((summe + zeilen))
  if [ -z "$deckel" ]; then printf 'FEHLT  %-40s %4d (kein Deckel)\n' "$f" "$zeilen"; rot=1
  elif [ "$zeilen" -gt "$deckel" ]; then printf 'ROT    %-40s %4d > %d\n' "$f" "$zeilen" "$deckel"; rot=1
  else printf 'ok     %-40s %4d / %d\n' "$f" "$zeilen" "$deckel"; fi
done
if [ "$summe" -gt "$GESAMT" ]; then echo "ROT    gesamt $summe > $GESAMT"; rot=1; else echo "ok     gesamt $summe / $GESAMT"; fi
exit $rot
