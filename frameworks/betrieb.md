<!-- deckel: 40 -->
# Betrieb — unverhandelbar

Diese Liste fällt nur mit ausdrücklichem Ja des Users. `hooks/leitplanken.py` blockt die mit (H) markierten Punkte technisch; seine Meldung nennt den Sinn, damit man den erlaubten Weg sucht, statt den Befehl umzuformulieren.

## Dateisystem und Git

- (H) `*/.claude/` ist tabu für Workload — jeder Schreibzugriff dort kostet den User eine Bestätigung. Worktrees selbst anlegen: `git worktree add ../<repo>-worktrees/<thema> -b <branch> master` (neben dem Repo, nie darin); nie `isolation: "worktree"`. Einzige Ausnahme: Memory.
- (H) Im geteilten Baum kein `stash`/`reset`/`restore`/`clean`/`checkout --` — stash ist repo-weit, der Rest wirft fremde Arbeit weg. Rot-Beweis geht per Kopie nach `build/`, mutieren, zurückspielen.
- (H) Nie `add -A`/`add .`/`commit -a`: `git status` lesen, Einzelpfade stagen. Committet wird nur der abgenommene Scope; nie bauen und committen im selben Befehl.
- (H) `worktree remove` nur aus dem Haupt-Repo, nie `--force`; Junctions (`node_modules`) vorher mit `cmd /c rmdir` ohne `/s` lösen und prüfen, dass sie weg sind — `remove` folgt sonst der Junction und leert das Ziel.
- Kein `rm`/`mv` außerhalb des eigenen Bereichs (Worktree, Scratchpad, `build/`) — löst Bestätigungsdialoge aus, die niemand sieht. Kein `sed -i` über Blöcke; Edit-Tool.
- Push nur nach Abnahme (Auditor-PASS oder ein „passt" des Users). Wer nicht pushen will, committet nicht auf `master` — der nächste fremde Push nimmt es mit; eigener Branch. Nie `--force`, kein `--amend` auf Gepushtes, kein `--no-verify`.

## Prozesse und Läufe

- (H) Prozesse nur per eigener PID beenden, nie per Name (`taskkill /IM`, `Stop-Process -Name`, `pkill`) — trifft fremde Läufe. Beim Killen einer Kette zuerst die Eltern-Shell, sonst rückt das nächste Glied nach.
- Jeder Lauf hat ein Timeout; vor RAM-hungrigen Läufen (JVM ~4 GB) freien Speicher prüfen. Ein Lauf je exklusiver Ressource (z. B. Gradle-Daemon, Testdatenbank) gleichzeitig, Lock-Block wörtlich aus dem Projekt-Protokoll. Headless-Chrome-Profile selbst löschen, auch bei Abbruch (`trap`/`finally`), Chrome vorher per PID beenden — sonst ist das Profil gesperrt und bleibt liegen. Hintergrund-Läufe mit viel Ausgabe in eine Datei umleiten und nur gefiltert lesen (`tail`, `grep`).
- (H) Kein `find /`; kein `grep -r .` als Quelle — beides trifft alle Worktrees; `git ls-files` ist die Quelle. (H) Kein `python` mit stdin-Skript (`-`, Heredoc, ohne Argument); Datei schreiben, dann ausführen.
- Builds lokal, Server nur Deploy. Kostenpflichtige Ressourcen (VM) nur mit Freigabe des Users je Lauf, Kosten frisch aus der API; solange sie existiert, ist der Task „läuft" mit Abriss-Wecker ≤20 Min, nie „fertig".
- Ruhezeiten des Projekts (z. B. kein Build während der Arbeitszeit des Users, vorher alles committet) stehen in der Projekt-CLAUDE.md und gelten wie diese Liste. Erlaubt bleibt: lesen, antworten, messen.
- Ein Skript im Lauf nie editieren (bash liest inkrementell nach). Vor Läufen >1 h liest ein Auditor die Pipeline selbst, nicht nur ihre Eingaben — grüne Eingaben sind kein grüner Build.

## Geräte

- Ein Gerät, das der User im Alltag braucht, ist kein Labor: keine Einstellungen umlegen, keine Prefs schreiben, keine Dauerfunktion abschalten, nichts, während er es benutzt. Vor Basteln Konfiguration und Zählerstände sichern, danach wiederherstellen. Erlaubt: install, start/stop, Logs lesen, Screenshot, einzelner Tap. Welche Geräte das sind, steht in der Projekt-CLAUDE.md.

## Heartbeat

Eine Zeile, ersetzt (`>`), ISO-Zeit mit `T`, Kontrolle auf der Leser-Seite (`git show HEAD:…`). Form und Befehle stehen im Projekt-Skript, nicht hier.
