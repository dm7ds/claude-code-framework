#!/usr/bin/env bash
# Entscheidungs-Waechter: jede <root>/docs/decisions/*.md traegt genau die fuenf
# Abschnitte (je mit Inhalt) und ist im Bausteine-Index verlinkt.
# Aufruf: decisions-check.sh <projekt-root> <bausteine-index> [allowlist]
#         decisions-check.sh --selftest
# Allowlist: Zeilen "<datei>  # <grund>"; ohne Grund, fuer fehlende oder saubere
# Datei -> ROT (Schwund wird sichtbar). exit 1 bei jedem ROT.
set -u
FELDER=("Kontext" "Entscheid" "Verworfen" "Woran man den Fehler merkt" "Wie zurückdrehen")
DIR_REL="docs/decisions"

# Ausgabe je "## "-Zeile: "<Titel>|<Anzahl nicht-leerer Zeilen darunter>"
abschnitte() {
  awk '
    { sub(/\r$/, "") }
    /^(```|~~~)/ { fence = !fence }
    !fence && /^## / { if (t != "") print t "|" n; t = substr($0, 4); sub(/[ \t]+$/, "", t); n = 0; if (t == "") t = "(leer)"; next }
    NF > 0 && t != "" { n++ }
    END { if (t != "") print t "|" n }
  ' "$1"
}

# Funde zu einer Datei, je Zeile ein "was fehlt"; leer = sauber.
funde() {
  local root=$1 index=$2 datei=$3 f="$1/$DIR_REL/$3" abs feld titel anz gefunden
  abs=$(abschnitte "$f")
  for feld in "${FELDER[@]}"; do
    gefunden=$(printf '%s\n' "$abs" | awk -F'|' -v k="$feld" '$1 == k { c++; n = $2 } END { print c + 0 " " n + 0 }')
    case $gefunden in
      "0 "*) echo "Abschnitt '## $feld' fehlt" ;;
      "1 0") echo "Abschnitt '## $feld' ist leer" ;;
      "1 "*) ;;
      *) echo "Abschnitt '## $feld' kommt mehrfach vor" ;;
    esac
  done
  while IFS='|' read -r titel anz; do
    [ -z "$titel" ] && continue
    local bekannt=0
    for feld in "${FELDER[@]}"; do [ "$titel" = "$feld" ] && bekannt=1; done
    [ $bekannt -eq 0 ] && echo "unbekannter Abschnitt '## $titel' (erlaubt sind nur die fuenf Felder)"
  done <<< "$abs"
  link_fund "$root" "$index" "$datei"
}

# Link im Index: Ziel (nicht Linktext) muss auf die existierende Entscheidungsdatei aufloesen.
link_fund() {
  local root=$1 index=$2 datei=$3 ziel zdir sollverz kandidat=0 idxdir
  idxdir=$(cd "$(dirname "$index")" && pwd)
  sollverz=$(cd "$root/$DIR_REL" && pwd)
  while IFS= read -r ziel; do
    ziel=${ziel#\](}; ziel=${ziel%\)}; ziel=${ziel%%#*}
    [ "${ziel##*/}" = "$datei" ] || continue
    kandidat=1
    zdir=$(cd "$idxdir/$(dirname "$ziel")" 2>/dev/null && pwd)
    [ "$zdir" = "$sollverz" ] && [ -f "$zdir/$datei" ] && return 0
  done < <(grep -o '\]([^)]*)' "$index")
  if [ $kandidat -eq 0 ]; then echo "nicht im Bausteine-Index verlinkt ($DIR_REL/$datei)"
  else echo "Link-Ziel im Index loest nicht auf $DIR_REL/$datei auf"; fi
}

besitzer() {
  local b
  b=$(git -C "$1" log -1 --format='%an' -- "$DIR_REL/$2" 2>/dev/null)
  echo "${b:-unbekannt (Datei nicht in git)}"
}

pruefe() {
  local root=$1 index=$2 allow=${3:-} rot=0 n=0 f datei fund grund
  [ -d "$root/$DIR_REL" ] || { echo "ROT $root/$DIR_REL: Ordner fehlt — Besitzer: Projekt-Lane — Abhilfe: Ordner anlegen und Entscheidungen dort ablegen (Vorlage: skills/new-project-bootstrap)"; return 1; }
  [ -f "$root/$index" ] && index="$root/$index"
  [ -f "$index" ] || { echo "ROT Bausteine-Index $index: nicht gefunden — Besitzer: Projekt-Lane — Abhilfe: Pfad zum Index als zweites Argument angeben"; return 1; }
  if [ -n "$allow" ]; then [ -f "$root/$allow" ] && allow="$root/$allow"; [ -f "$allow" ] || { echo "ROT Allowlist $allow: nicht gefunden — Besitzer: Projekt-Lane — Abhilfe: Datei anlegen oder Argument weglassen"; return 1; }; fi

  declare -A erlaubt=()
  if [ -n "$allow" ]; then
    while IFS= read -r zeile || [ -n "$zeile" ]; do
      zeile=${zeile%$'\r'}
      case $zeile in ''|'#'*) continue ;; esac
      datei=${zeile%%#*}; datei=${datei%"${datei##*[![:space:]]}"}
      grund=""; case $zeile in *'#'*) grund=${zeile#*#}; grund=${grund//[[:space:]]/} ;; esac
      if [ -z "$grund" ]; then
        echo "ROT $datei: Allowlist-Eintrag ohne Grund — Besitzer: $(besitzer "$root" "$datei") — Abhilfe: '  # <Grund>' anhaengen oder Eintrag loeschen"; rot=1
      fi
      erlaubt[$datei]=1
    done < "$allow"
  fi

  for f in "$root/$DIR_REL"/*.md; do
    [ -e "$f" ] || continue
    datei=$(basename "$f"); n=$((n + 1))
    fund=$(funde "$root" "$index" "$datei")
    if [ -n "${erlaubt[$datei]:-}" ]; then
      if [ -z "$fund" ]; then echo "ROT $datei: steht in der Allowlist, ist aber sauber — Besitzer: $(besitzer "$root" "$datei") — Abhilfe: Eintrag aus der Allowlist loeschen"; rot=1
      else echo "erlaubt $datei (Allowlist)"; fi
      unset 'erlaubt[$datei]'
    elif [ -n "$fund" ]; then
      while IFS= read -r z; do
        echo "ROT $datei: $z — Besitzer: $(besitzer "$root" "$datei") — Abhilfe: $(abhilfe "$z" "$datei")"
      done <<< "$fund"
      rot=1
    fi
  done
  for datei in "${!erlaubt[@]}"; do
    echo "ROT $datei: Allowlist-Eintrag, Datei existiert nicht mehr — Besitzer: $(besitzer "$root" "$datei") — Abhilfe: Eintrag aus der Allowlist loeschen"; rot=1
  done
  [ $rot -eq 0 ] && echo "ok $n Entscheidungen"
  return $rot
}

abhilfe() {
  case $1 in
    *"Link-Ziel"*) echo "Ziel des Links im Index auf den relativen Pfad zu $DIR_REL/$2 korrigieren" ;;
    *"fehlt"*) echo "Abschnitt mit Inhalt ergaenzen; Quelle unbekannt: 'offen — Quelle fehlt' schreiben, nicht raten" ;;
    *"leer"*) echo "unter der Ueberschrift mindestens eine Zeile Inhalt schreiben ('offen — Quelle fehlt' ist erlaubt)" ;;
    *"Index"*) echo "Link $DIR_REL/$2 in den Bausteine-Index aufnehmen" ;;
    *"mehrfach"*) echo "doppelten Abschnitt zusammenfuehren" ;;
    *) echo "Abschnitt umbenennen oder in eines der fuenf Felder einordnen" ;;
  esac
}

# ---------- Selbsttest ----------
fixture() { # <dir> : saubere Basis mit einer Entscheidung "a.md"
  mkdir -p "$1/$DIR_REL"
  { for fd in "${FELDER[@]}"; do printf '## %s\nText zu %s.\n\n' "$fd" "$fd"; done; } > "$1/$DIR_REL/a.md"
  printf '| Frage | Entscheidung |\n|---|---|\n| Was? | [a](%s/a.md) |\n' "$DIR_REL" > "$1/INDEX.md"
}

erwarte() { # <name> <soll-exit> <muss-enthalten|-> <cmd...>
  local name=$1 soll=$2 muster=$3 out ist; shift 3
  out=$("$@" 2>&1); ist=$?
  if [ "$ist" -ne "$soll" ]; then echo "SELBSTTEST ROT $name: exit $ist statt $soll"; echo "$out"; selfrot=1; return; fi
  if [ "$muster" != "-" ] && ! printf '%s\n' "$out" | grep -q "Besitzer: .*Abhilfe: " ; then echo "SELBSTTEST ROT $name: Meldung ohne Besitzer/Abhilfe"; echo "$out"; selfrot=1; return; fi
  if [ "$muster" != "-" ] && ! printf '%s\n' "$out" | grep -qF -- "$muster"; then echo "SELBSTTEST ROT $name: '$muster' nicht gemeldet"; echo "$out"; selfrot=1; return; fi
  echo "selftest ok  $name"
}

selftest() {
  local tmp; tmp=$(mktemp -d "${TEMP:-/tmp}/decisions-selftest.XXXXXX") || exit 1
  trap 'rm -rf "$tmp"' EXIT
  selfrot=0
  local self; self=$(cd "$(dirname "$0")" && pwd)/$(basename "$0")
  local fd

  fixture "$tmp/pos"
  erwarte "positiv: alles da" 0 - bash "$self" "$tmp/pos" INDEX.md

  fixture "$tmp/n1"; sed -i '/^## Verworfen/,/^$/d' "$tmp/n1/$DIR_REL/a.md"
  erwarte "negativ: Feld fehlt" 1 "Abschnitt '## Verworfen' fehlt" bash "$self" "$tmp/n1" INDEX.md

  fixture "$tmp/n2"; sed -i '/^Text zu Entscheid\./d' "$tmp/n2/$DIR_REL/a.md"
  erwarte "negativ: Feld leer" 1 "Abschnitt '## Entscheid' ist leer" bash "$self" "$tmp/n2" INDEX.md

  fixture "$tmp/n3"; printf '| Frage | Entscheidung |\n|---|---|\n' > "$tmp/n3/INDEX.md"
  erwarte "negativ: nicht im Index" 1 "nicht im Bausteine-Index" bash "$self" "$tmp/n3" INDEX.md

  fixture "$tmp/n4"; printf 'a.md\n' > "$tmp/n4/allow.txt"
  erwarte "negativ: Allowlist ohne Grund" 1 "Allowlist-Eintrag ohne Grund" bash "$self" "$tmp/n4" INDEX.md "$tmp/n4/allow.txt"

  fixture "$tmp/n5"; printf 'a.md  # Altbestand\n' > "$tmp/n5/allow.txt"
  erwarte "negativ: Allowlist fuer saubere Datei" 1 "ist aber sauber" bash "$self" "$tmp/n5" INDEX.md "$tmp/n5/allow.txt"

  fixture "$tmp/n6"; printf 'a.md  # Altbestand\nweg.md  # war mal da\n' > "$tmp/n6/allow.txt"
  erwarte "negativ: Allowlist fuer fehlende Datei" 1 "existiert nicht mehr" bash "$self" "$tmp/n6" INDEX.md "$tmp/n6/allow.txt"

  fixture "$tmp/p2"; sed -i '/^## Verworfen/,/^$/d' "$tmp/p2/$DIR_REL/a.md"; printf 'a.md  # Altbestand, Abschnitt folgt\n' > "$tmp/p2/allow.txt"
  erwarte "positiv: Allowlist mit Grund deckt Defekt" 0 - bash "$self" "$tmp/p2" INDEX.md "$tmp/p2/allow.txt"

  fixture "$tmp/n7"; printf '## Kontext\nZusatz.\n' >> "$tmp/n7/$DIR_REL/a.md"
  erwarte "negativ: Abschnitt mehrfach" 1 "kommt mehrfach vor" bash "$self" "$tmp/n7" INDEX.md

  fixture "$tmp/n8"; printf '## Sonstiges\nText.\n' >> "$tmp/n8/$DIR_REL/a.md"
  erwarte "negativ: unbekannter Abschnitt" 1 "unbekannter Abschnitt '## Sonstiges'" bash "$self" "$tmp/n8" INDEX.md

  fixture "$tmp/n9"; sed -i 's/^## Kontext$/## Kontext und mehr/' "$tmp/n9/$DIR_REL/a.md"
  erwarte "negativ: Titel mit Zusatz zaehlt nicht als Feld" 1 "Abschnitt '## Kontext' fehlt" bash "$self" "$tmp/n9" INDEX.md

  fixture "$tmp/p3"; printf '```\n## Sonstiges\n```\n' >> "$tmp/p3/$DIR_REL/a.md"
  erwarte "positiv: ## im Codezaun wird ignoriert" 0 - bash "$self" "$tmp/p3" INDEX.md

  mkdir -p "$tmp/n10"; printf 'x\n' > "$tmp/n10/INDEX.md"
  erwarte "negativ: Ordner fehlt" 1 "Ordner fehlt" bash "$self" "$tmp/n10" INDEX.md

  fixture "$tmp/n11"
  erwarte "negativ: Index nicht gefunden" 1 "nicht gefunden" bash "$self" "$tmp/n11" GIBTS-NICHT.md

  fixture "$tmp/n12"
  erwarte "negativ: Allowlist nicht gefunden" 1 "Allowlist $tmp/n12/weg.txt: nicht gefunden" bash "$self" "$tmp/n12" INDEX.md "$tmp/n12/weg.txt"

  fixture "$tmp/n13"; printf '| Frage | Entscheidung |\n|---|---|\n| Was? | [%s/a.md](%s/zz/a.md) |\n' "$DIR_REL" "$DIR_REL" > "$tmp/n13/INDEX.md"
  erwarte "negativ: Linktext stimmt, Linkziel loest nicht auf" 1 "Link-Ziel im Index" bash "$self" "$tmp/n13" INDEX.md

  [ $selfrot -eq 0 ] && echo "selftest ok gesamt" || echo "SELBSTTEST ROT"
  exit $selfrot
}

if [ "${1:-}" = "--selftest" ]; then selftest; fi
if [ $# -lt 2 ]; then echo "Aufruf: $0 <projekt-root> <bausteine-index> [allowlist] | --selftest" >&2; exit 2; fi
pruefe "$1" "$2" "${3:-}"
exit $?
