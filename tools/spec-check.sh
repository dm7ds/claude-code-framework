#!/usr/bin/env bash
# SPEC-Waechter: <root>/docs/SPEC.md ist ein Was-Index ohne eigenen Inhalt.
#  (i)   jeder relative Markdown-Link in SPEC.md loest auf (Datei oder Ordner);
#  (ii)  jede Zeile im Scope-Abschnitt (feste Ueberschrift SCOPE_HEADING) verlinkt
#        eine Datei unter docs/decisions/;
#  (iii) keine *spec*.md (Gross/Klein egal) im Repo ausser docs/specs/ und docs/SPEC.md.
# Aufruf: spec-check.sh <projekt-root> [allowlist]
#         spec-check.sh --selftest
# Allowlist (zu (iii)): Zeilen "<pfad relativ zum root>  # <grund>"; ohne Grund, fuer
# fehlende oder nicht verstossende Datei -> ROT (Schwund wird sichtbar). exit 1 bei jedem ROT.
set -u
SPEC_REL="docs/SPEC.md"
SPECS_DIR_REL="docs/specs"
DECISIONS_REL="docs/decisions"
SCOPE_HEADING="## Scope und Nicht-Scope"   # einzige Stelle; Bootstrap-Skill verweist hierher
# Pfad-Ausschluesse fuer (iii): Pfade ab dem Root, nie auf tieferer Ebene (docs/build/ ist kein
# Build-Ausgabeordner). docs/audits/_by-date: Audit-Berichte sind keine Specs, ihr Name folgt dem Thema.
# Kein git ls-files als Quelle: _scratch (Ablage im Worktree) ist untracked und nicht
# ignoriert, und die Selftest-Fixtures sind keine git-Repos.
AUSSCHLUESSE=(node_modules .git _lanes build _scratch docs/audits/_by-date)

rot=0

besitzer() { # <root> <pfad>
  local b
  b=$(git -C "$1" log -1 --format='%an' -- "$2" 2>/dev/null)
  echo "${b:-unbekannt (Datei nicht in git)}"
}

meldung() { # <root> <besitz-pfad> <was> <abhilfe>
  echo "ROT $3 — Besitzer: $(besitzer "$1" "$2") — Abhilfe: $4"
  rot=1
}

# SPEC.md ohne CR und ohne Codezaeune
ohne_zaeune() {
  awk '{ sub(/\r$/, "") } /^(```|~~~)/ { f = !f; next } !f' "$1"
}

# Link-Ziele einer Textzeile/-datei auf stdin: ein Ziel pro Zeile, ohne Anker, nur relative
ziele() {
  local z
  while IFS= read -r z; do
    z=${z#\](}; z=${z%\)}; z=${z%%#*}
    case $z in ''|http://*|https://*|mailto:*) continue ;; esac
    echo "$z"
  done < <(grep -o '\]([^)]*)')
}

# (i) Links aufloesen
pruefe_links() { # <root>
  local root=$1 docs z n=0
  docs="$root/$(dirname "$SPEC_REL")"
  while IFS= read -r z; do
    n=$((n + 1))
    [ -e "$docs/$z" ] || meldung "$root" "$SPEC_REL" "$SPEC_REL: Link '$z' loest nicht auf" "Ziel korrigieren oder Link entfernen (SPEC.md verweist nur auf vorhandene Quellen)"
  done < <(ohne_zaeune "$root/$SPEC_REL" | ziele)
  LINKS=$n
}

# (ii) Scope-Saetze verlinken Entscheidungen
scope_zeilen() { # <datei> : nicht-leere Zeilen unter SCOPE_HEADING bis zur naechsten "## "
  ohne_zaeune "$1" | awk -v h="$SCOPE_HEADING" '
    $0 == h { s = 1; gefunden = 1; next }
    /^## / { s = 0 }
    s && NF > 0 { print }
    END { if (!gefunden) print "\001KEIN-ABSCHNITT" }'
}

pruefe_scope() { # <root>
  local root=$1 docs sollverz zeile z zdir ok n=0
  docs="$root/$(dirname "$SPEC_REL")"
  sollverz=$(cd "$root/$DECISIONS_REL" 2>/dev/null && pwd)
  while IFS= read -r zeile; do
    if [ "$zeile" = $'\001KEIN-ABSCHNITT' ]; then
      meldung "$root" "$SPEC_REL" "$SPEC_REL: Abschnitt '$SCOPE_HEADING' fehlt" "Abschnitt mit dieser Ueberschrift anlegen (Scope-Saetze, je mit Link auf $DECISIONS_REL/...)"
      continue
    fi
    n=$((n + 1)); ok=0
    while IFS= read -r z; do
      zdir=$(cd "$docs/$(dirname "$z")" 2>/dev/null && pwd)
      [ -n "$sollverz" ] && [ "$zdir" = "$sollverz" ] && [ -f "$docs/$z" ] && ok=1
    done < <(printf '%s\n' "$zeile" | ziele)
    [ $ok -eq 1 ] || meldung "$root" "$SPEC_REL" "$SPEC_REL: Scope-Satz ohne Link auf $DECISIONS_REL/: '${zeile:0:60}'" "Entscheidungsdatei unter $DECISIONS_REL/ anlegen und im Satz verlinken, oder den Satz streichen"
  done < <(scope_zeilen "$root/$SPEC_REL")
  SAETZE=$n
  if [ $n -eq 0 ] && [ "$(scope_zeilen "$root/$SPEC_REL")" != $'\001KEIN-ABSCHNITT' ]; then
    meldung "$root" "$SPEC_REL" "$SPEC_REL: Abschnitt '$SCOPE_HEADING' ist leer" "Scope-Saetze eintragen oder den Abschnitt mit Begruendung im Projekt streichen lassen"
  fi
}

# (iii) lose Specs: gefundene Pfade (relativ), eine je Zeile
lose_specs() { # <root>
  local root=$1 a f rel
  local prune=()
  for a in "${AUSSCHLUESSE[@]}"; do prune+=(-path "./$a" -o); done
  unset 'prune[${#prune[@]}-1]'
  # relativ zum Root suchen: "./<name>" trifft nur die oberste Ebene (und keine Glob-Zeichen aus dem Root-Pfad)
  (cd "$root" && find . \( "${prune[@]}" \) -prune -o -type f -iname '*spec*.md' -print) | while IFS= read -r f; do
    rel=${f#./}
    case $rel in "$SPEC_REL"|"$SPECS_DIR_REL"/*) continue ;; esac
    echo "$rel"
  done
}

pruefe_specs() { # <root> <allowlist-oder-leer>
  local root=$1 allow=$2 zeile datei grund rel
  declare -A erlaubt=()
  if [ -n "$allow" ]; then
    while IFS= read -r zeile || [ -n "$zeile" ]; do
      zeile=${zeile%$'\r'}
      case $zeile in ''|'#'*) continue ;; esac
      datei=${zeile%%#*}; datei=${datei%"${datei##*[![:space:]]}"}
      grund=""; case $zeile in *'#'*) grund=${zeile#*#}; grund=${grund//[[:space:]]/} ;; esac
      [ -z "$grund" ] && meldung "$root" "$datei" "$datei: Allowlist-Eintrag ohne Grund" "'  # <Grund>' anhaengen oder Eintrag loeschen"
      erlaubt[$datei]=1
    done < "$allow"
  fi
  AUSNAHMEN=0
  while IFS= read -r rel; do
    [ -z "$rel" ] && continue
    if [ -n "${erlaubt[$rel]:-}" ]; then
      echo "erlaubt $rel (Allowlist)"; AUSNAHMEN=$((AUSNAHMEN + 1)); unset 'erlaubt[$rel]'
    else
      meldung "$root" "$rel" "$rel: Spec-Datei ausserhalb $SPECS_DIR_REL/" "nach $SPECS_DIR_REL/ verschieben (git mv, Verweise mitziehen) oder mit Grund in die Allowlist"
    fi
  done < <(lose_specs "$root")
  for datei in "${!erlaubt[@]}"; do
    if [ -e "$root/$datei" ]; then
      meldung "$root" "$datei" "$datei: steht in der Allowlist, ist aber keine lose Spec" "Eintrag aus der Allowlist loeschen"
    else
      meldung "$root" "$datei" "$datei: Allowlist-Eintrag, Datei existiert nicht mehr" "Eintrag aus der Allowlist loeschen"
    fi
  done
}

pruefe() { # <root> <allowlist-oder-leer>
  local root=${1%/} allow=${2:-}
  [ -d "$root" ] || { echo "ROT $root: Projekt-Root nicht gefunden — Besitzer: Projekt — Abhilfe: Pfad korrigieren"; return 1; }
  if [ -n "$allow" ]; then
    [ -f "$root/$allow" ] && allow="$root/$allow"
    [ -f "$allow" ] || { echo "ROT Allowlist $allow: nicht gefunden — Besitzer: Projekt — Abhilfe: Datei anlegen oder Argument weglassen"; return 1; }
  fi
  LINKS=0; SAETZE=0; AUSNAHMEN=0
  if [ -f "$root/$SPEC_REL" ]; then
    pruefe_links "$root"
    pruefe_scope "$root"
  else
    meldung "$root" "$SPEC_REL" "$SPEC_REL: fehlt" "SPEC.md als Was-Index anlegen (Vorlage: skills/new-project-bootstrap)"
  fi
  pruefe_specs "$root" "$allow"
  [ $rot -eq 0 ] && echo "ok $LINKS Links, $SAETZE Scope-Saetze, $AUSNAHMEN Ausnahmen"
  return $rot
}

# ---------- Selbsttest ----------
fixture() { # <dir> : saubere Basis
  mkdir -p "$1/docs/decisions" "$1/docs/specs"
  printf '# a\n' > "$1/docs/decisions/a.md"
  printf '# x\n' > "$1/docs/specs/x-spec.md"
  printf '# r\n' > "$1/README.md"
  printf '# SPEC\n\n%s\n- Satz eins. ([E](decisions/a.md))\n\n## Frage\n| F | Q |\n|---|---|\n| a | [R](../README.md), [S](specs/), [A](decisions/a.md#x) |\n' "$SCOPE_HEADING" > "$1/docs/SPEC.md"
}

erwarte() { # <name> <soll-exit> <muss-enthalten|-> <cmd...>
  local name=$1 soll=$2 muster=$3 out ist; shift 3
  out=$("$@" 2>&1); ist=$?
  if [ "$ist" -ne "$soll" ]; then echo "SELBSTTEST ROT $name: exit $ist statt $soll"; echo "$out"; selfrot=1; return; fi
  if [ "$muster" != "-" ] && ! printf '%s\n' "$out" | grep -q "Besitzer: .*Abhilfe: "; then echo "SELBSTTEST ROT $name: Meldung ohne Besitzer/Abhilfe"; echo "$out"; selfrot=1; return; fi
  if [ "$muster" != "-" ] && ! printf '%s\n' "$out" | grep -qF -- "$muster"; then echo "SELBSTTEST ROT $name: '$muster' nicht gemeldet"; echo "$out"; selfrot=1; return; fi
  echo "selftest ok  $name"
}

selftest() {
  local tmp; tmp=$(mktemp -d "${TEMP:-/tmp}/spec-selftest.XXXXXX") || exit 1
  trap 'rm -rf "$tmp"' EXIT
  selfrot=0
  local self; self=$(cd "$(dirname "$0")" && pwd)/$(basename "$0")

  fixture "$tmp/pos"
  erwarte "positiv: alles da" 0 - bash "$self" "$tmp/pos"

  fixture "$tmp/n1"; printf '\n[kaputt](gibts-nicht.md)\n' >> "$tmp/n1/docs/SPEC.md"
  erwarte "negativ (i): Link loest nicht auf" 1 "Link 'gibts-nicht.md' loest nicht auf" bash "$self" "$tmp/n1"

  fixture "$tmp/n2"; printf '# SPEC\n\n%s\n- Satz ohne Entscheidung. ([R](../README.md))\n' "$SCOPE_HEADING" > "$tmp/n2/docs/SPEC.md"
  erwarte "negativ (ii): Link, aber nicht auf decisions" 1 "Scope-Satz ohne Link auf $DECISIONS_REL/" bash "$self" "$tmp/n2"

  fixture "$tmp/n3"; printf '# SPEC\n\n%s\n- Satz ganz ohne Link.\n' "$SCOPE_HEADING" > "$tmp/n3/docs/SPEC.md"
  erwarte "negativ (ii): Scope-Satz ohne Link" 1 "Scope-Satz ohne Link auf $DECISIONS_REL/" bash "$self" "$tmp/n3"

  fixture "$tmp/n4"; printf '# SPEC\n\n## Scope\n- Satz. ([E](decisions/a.md))\n' > "$tmp/n4/docs/SPEC.md"
  erwarte "negativ (ii): Abschnitt fehlt" 1 "Abschnitt '$SCOPE_HEADING' fehlt" bash "$self" "$tmp/n4"

  fixture "$tmp/n5"; printf '# SPEC\n\n%s\n\n## Frage\n' "$SCOPE_HEADING" > "$tmp/n5/docs/SPEC.md"
  erwarte "negativ (ii): Abschnitt leer" 1 "ist leer" bash "$self" "$tmp/n5"

  fixture "$tmp/n6"; printf '# s\n' > "$tmp/n6/docs/foo-spec.md"
  erwarte "negativ (iii): lose Spec in docs/" 1 "docs/foo-spec.md: Spec-Datei ausserhalb" bash "$self" "$tmp/n6"

  fixture "$tmp/n7"; mkdir -p "$tmp/n7/sub"; printf '# s\n' > "$tmp/n7/sub/Bar-SPEC.MD"
  erwarte "negativ (iii): Gross/Klein egal, auch in Unterordner" 1 "sub/Bar-SPEC.MD: Spec-Datei ausserhalb" bash "$self" "$tmp/n7"

  fixture "$tmp/n8"; printf '# s\n' > "$tmp/n8/docs/foo-spec.md"; printf 'docs/foo-spec.md\n' > "$tmp/n8/allow.txt"
  erwarte "negativ: Allowlist ohne Grund" 1 "Allowlist-Eintrag ohne Grund" bash "$self" "$tmp/n8" "$tmp/n8/allow.txt"

  fixture "$tmp/n9"; printf 'docs/weg-spec.md  # war mal da\n' > "$tmp/n9/allow.txt"
  erwarte "negativ: Allowlist fuer fehlende Datei" 1 "existiert nicht mehr" bash "$self" "$tmp/n9" "$tmp/n9/allow.txt"

  fixture "$tmp/n10"; printf 'README.md  # Altbestand\n' > "$tmp/n10/allow.txt"
  erwarte "negativ: Allowlist fuer Datei ohne Verstoss" 1 "ist aber keine lose Spec" bash "$self" "$tmp/n10" "$tmp/n10/allow.txt"

  fixture "$tmp/n11"; rm "$tmp/n11/docs/SPEC.md"
  erwarte "negativ: SPEC.md fehlt" 1 "docs/SPEC.md: fehlt" bash "$self" "$tmp/n11"

  fixture "$tmp/n12"
  erwarte "negativ: Allowlist nicht gefunden" 1 "Allowlist $tmp/n12/weg.txt: nicht gefunden" bash "$self" "$tmp/n12" "$tmp/n12/weg.txt"

  fixture "$tmp/p2"; printf '# s\n' > "$tmp/p2/docs/foo-spec.md"; printf 'docs/foo-spec.md  # Altbestand, wird verschoben\n' > "$tmp/p2/allow.txt"
  erwarte "positiv: Allowlist mit Grund deckt lose Spec" 0 - bash "$self" "$tmp/p2" "$tmp/p2/allow.txt"

  fixture "$tmp/p3"; mkdir -p "$tmp/p3/node_modules/x" "$tmp/p3/_lanes"; printf '# s\n' > "$tmp/p3/node_modules/x/a-spec.md"; printf '# s\n' > "$tmp/p3/_lanes/b-spec.md"
  erwarte "positiv: ausgeschlossene Ordner zaehlen nicht" 0 - bash "$self" "$tmp/p3"

  fixture "$tmp/p4"; printf '\n```\n[kaputt](gibts-nicht.md)\n```\n' >> "$tmp/p4/docs/SPEC.md"
  erwarte "positiv: Link im Codezaun wird ignoriert" 0 - bash "$self" "$tmp/p4"

  fixture "$tmp/n13"; mkdir -p "$tmp/n13/docs/build"; printf '# s\n' > "$tmp/n13/docs/build/foo-spec.md"
  erwarte "negativ (iii): Ausschluss gilt nur am Root (docs/build)" 1 "docs/build/foo-spec.md: Spec-Datei ausserhalb" bash "$self" "$tmp/n13"

  fixture "$tmp/n14"; mkdir -p "$tmp/n14/pkg/node_modules"; printf '# s\n' > "$tmp/n14/pkg/node_modules/foo-spec.md"
  erwarte "negativ (iii): node_modules unter Unterordner zaehlt" 1 "pkg/node_modules/foo-spec.md: Spec-Datei ausserhalb" bash "$self" "$tmp/n14"

  fixture "$tmp/p5"; mkdir -p "$tmp/p5/docs/audits/_by-date/x"; printf '# s\n' > "$tmp/p5/docs/audits/_by-date/x/foo-spec.md"
  erwarte "positiv: Audit-Berichte (docs/audits/_by-date) sind keine Specs" 0 - bash "$self" "$tmp/p5"

  fixture "$tmp/n16"; mkdir -p "$tmp/n16/docs/audits"; printf '# s\n' > "$tmp/n16/docs/audits/real-spec.md"
  erwarte "negativ (iii): docs/audits ausserhalb _by-date zaehlt" 1 "docs/audits/real-spec.md: Spec-Datei ausserhalb" bash "$self" "$tmp/n16"

  fixture "$tmp/n15"; mkdir -p "$tmp/n15/pkg/docs/audits"; printf '# s\n' > "$tmp/n15/pkg/docs/audits/foo-spec.md"
  erwarte "negativ (iii): docs/audits gilt nur am Root" 1 "pkg/docs/audits/foo-spec.md: Spec-Datei ausserhalb" bash "$self" "$tmp/n15"

  [ $selfrot -eq 0 ] && echo "selftest ok gesamt" || echo "SELBSTTEST ROT"
  exit $selfrot
}

if [ "${1:-}" = "--selftest" ]; then selftest; fi
if [ $# -lt 1 ]; then echo "Aufruf: $0 <projekt-root> [allowlist] | --selftest" >&2; exit 2; fi
pruefe "$1" "${2:-}"
exit $?
