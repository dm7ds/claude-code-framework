"""PreToolUse-Leitplanken (Claude-Code-Hook, Event PreToolUse).

Blockt per exit 2, was betrieb.md als unverhandelbar fuehrt. Die Meldung auf stderr
sagt dem Agenten den Sinn, damit er einen erlaubten Weg sucht statt umzuformulieren.
Selbsttest: python leitplanken.py --test
"""
import json
import re
import sys

# Memory gehoert zum Harness, nicht zur Workload -- einzige erlaubte .claude-Ablage.
CLAUDE_ERLAUBT = re.compile(r"[/\\]\.claude[/\\]projects[/\\][^/\\]+[/\\]memory[/\\]", re.I)
CLAUDE_PFAD = re.compile(r"[/\\]?\.claude([/\\]|$)", re.I)

GIT_OPTS = r"git(?:\s+-[cC]\s+\S+)*\s+"
BASH_VERBOTE = [
    (GIT_OPTS + r"(stash|reset|clean|restore)\b", "kein stash/reset/clean/restore im geteilten Baum -- fremde Arbeit geht verloren"),
    (GIT_OPTS + r"checkout\s+(\S+\s+)?--(\s|$)", "kein checkout -- : verwirft Aenderungen anderer"),
    (GIT_OPTS + r"add\s+(-A|--all|\.)(\s|$)", "nur Einzelpfade stagen (git status lesen, dann git add <datei>)"),
    (GIT_OPTS + r"commit\s+(-a\b|-am\b|--all\b)", "nur Einzelpfade committen"),
    (GIT_OPTS + r"worktree\s+remove\s+.*--force", "worktree remove --force zerstoert ungesicherte Arbeit"),
    (r"\bfind\s+/(\s|$)", "kein find / -- durchsucht alle Worktrees; git ls-files nehmen"),
    (r"\bpython3?(\.exe)?\s*(-(\s|$)|<<|$|[;&|])", "kein python mit stdin-Skript (-, Heredoc, ohne Argument): Datei per Write anlegen und ausfuehren"),
    (r"\btaskkill\b.*\s/IM\s", "Prozesse nur per eigener PID beenden, nie per Name"),
    (r"(>>?|\btee\b|\brm\b|\bmv\b|\bcp\b|\bmkdir\b|\btouch\b|worktree\s+add)[^|;&\n]*[/\\]\.claude([/\\]|\s|$)",
     ".claude ist tabu fuer Workload -- Scratchpad, build/ oder Worktree"),
]

# Nur Subagenten (Hook-Eingabe traegt agent_id): was sonst einen Bestaetigungsdialog beim User
# ausloest, den niemand sieht. Hart abweisen statt fragen.
SUB_VERBOTE = [
    (r"(^|[;&|(]|&&|\|\|)\s*(rm|rmdir|del|mv)\s", "kein rm/rmdir/del/mv -- melden statt loeschen/verschieben"),
    (r"\bsed\s+(-\w*\s+)*-i", "kein sed -i -- Dateien per Edit/Write aendern"),
    (r"(?<![=\-\d&<])\d?>>?\s*(?!&|/dev/null)[^\s|;&]", "keine Ausgabe-Umleitung in Dateien -- Ausgabe direkt lesen, Dateien per Write"),
    (r"\.\.[/\\]", "kein ../ -- nichts ausserhalb des eigenen Worktrees"),
    (r"<<", "kein Heredoc -- Datei per Write anlegen"),
]


def pruefe(tool, eingabe, sub=False):
    if tool == "Bash":
        cmd = eingabe.get("command", "")
        if sub:
            # Quoted-Inhalt (Commit-Text, grep-Muster) ist keine Shell-Syntax
            roh = re.sub(r"'[^']*'|\"[^\"]*\"", "''", cmd)
            for muster, grund in SUB_VERBOTE:
                if re.search(muster, roh, re.I):
                    return grund
        if CLAUDE_ERLAUBT.search(cmd) and not re.search(r"\brm\b|\bmv\b", cmd):
            cmd = CLAUDE_ERLAUBT.sub("/MEMORY/", cmd)
        for muster, grund in BASH_VERBOTE:
            if re.search(muster, cmd, re.I):
                return grund
    elif tool in ("Write", "Edit", "MultiEdit", "NotebookEdit"):
        pfad = eingabe.get("file_path") or eingabe.get("notebook_path") or ""
        if CLAUDE_PFAD.search(pfad) and not CLAUDE_ERLAUBT.search(pfad):
            return ".claude ist tabu fuer Workload -- Framework-Dateien im Framework-Repo bearbeiten (Junction/Symlink), Scratch ins Scratchpad"
    elif tool == "Agent":
        if eingabe.get("isolation") == "worktree":
            return "kein isolation:worktree (legt unter .claude/worktrees an) -- git worktree add ../<projekt>-worktrees/<thema>"
    return None


def _test():
    rot = [
        ("Bash", {"command": "git stash"}),
        ("Bash", {"command": "git pull && git stash pop"}),
        ("Bash", {"command": "git -C /d/x reset --hard"}),
        ("Bash", {"command": "git checkout -- a.kt"}),
        ("Bash", {"command": "git add -A"}),
        ("Bash", {"command": "git add ."}),
        ("Bash", {"command": "git commit -am x"}),
        ("Bash", {"command": "find / -name x"}),
        ("Bash", {"command": "python - <<EOF"}),
        ("Bash", {"command": "python3 <<'EOF'"}),
        ("Bash", {"command": "cat x.py | python"}),
        ("Bash", {"command": "taskkill /F /IM java.exe"}),
        ("Bash", {"command": "echo x > C:/Users/me/.claude/foo"}),
        ("Bash", {"command": "rm C:/Users/me/.claude/projects/p/memory/a.md"}),
        ("Write", {"file_path": "C:/code/app/.claude/tasks/k.md"}),
        ("Edit", {"file_path": "C:\\Users\\d\\.claude\\settings.json"}),
        ("Agent", {"isolation": "worktree"}),
    ]
    gruen = [
        ("Bash", {"command": "git status --short && git add docs/a.md"}),
        ("Bash", {"command": "git checkout master"}),
        ("Bash", {"command": "cat C:/Users/me/.claude/settings.json"}),
        ("Bash", {"command": "find . -name x"}),
        ("Bash", {"command": "python tracker.py list"}),
        ("Bash", {"command": "git pull -q --rebase --autostash origin main"}),
        ("Bash", {"command": "python -I tools/x.py && echo ok"}),
        ("Bash", {"command": "echo x > C:/Users/me/.claude/projects/p/memory/a.md"}),
        ("Write", {"file_path": "C:/Users/me/.claude/projects/p/memory/a.md"}),
        ("Write", {"file_path": "C:/code/claude-framework/frameworks/lane.md"}),
        ("Agent", {"prompt": "x"}),
    ]
    for t, e in rot:
        assert pruefe(t, e), f"muesste blocken: {t} {e}"
    for t, e in gruen:
        assert not pruefe(t, e), f"muesste durchlassen: {t} {e} -> {pruefe(t, e)}"
    sub_rot = ["rm -f x", "cd a && rm x", "sed -i 's/a/b/' f.ts", "cat > ../../t.txt", "echo x >> log.txt",
               "ls 2>err.txt", "cat a ../b", "cat <<'E'"]
    sub_gruen = ["git status 2>/dev/null", "bun test 2>&1 | tail -5", "grep -n '=>' a.ts", "echo x >&2",
                 "git log --format='%h -> %s'", "sed -n 1,5p a.ts", "npm run check",
                 "git commit a.ts -m \"fix: x\" -m \"Co-Authored-By: C S <n@a.com>\"", "docker rm -f app-x-pg",
                 "grep -n 'a > b' f.ts"]
    for c in sub_rot:
        assert pruefe("Bash", {"command": c}, sub=True), f"Sub muesste blocken: {c}"
        assert not pruefe("Bash", {"command": c}) or c.startswith("cat <<"), f"Haupt darf: {c}"
    for c in sub_gruen:
        assert not pruefe("Bash", {"command": c}, sub=True), f"Sub muesste durchlassen: {c} -> {pruefe('Bash', {'command': c}, True)}"
    print(f"ok: {len(rot)} rot, {len(gruen)} gruen, Sub {len(sub_rot)} rot, {len(sub_gruen)} gruen")


if __name__ == "__main__":
    if "--test" in sys.argv:
        _test()
        sys.exit(0)
    try:
        daten = json.load(sys.stdin)
    except Exception:
        sys.exit(0)  # Fallback: kaputte Eingabe blockiert nie die Arbeit
    grund = pruefe(daten.get("tool_name", ""), daten.get("tool_input") or {}, sub=bool(daten.get("agent_id")))
    if grund:
        print(f"LEITPLANKE: {grund}", file=sys.stderr)
        sys.exit(2)
