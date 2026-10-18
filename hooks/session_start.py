#!/usr/bin/env python3
"""
Session Start Hook for Claude Code.

Injects project context, local time, git summary, and open issues
at the start of every session. This gives the agent immediate awareness
of where it is and what's going on.

Installation:
  Add to ~/.claude/settings.json under "hooks" → "SessionStart"
  See README.md for full setup instructions.
"""

import subprocess
import json
import os
import re
import sys

# ─── Configuration ────────────────────────────────────────────────────
# Map project directory prefixes to human-readable project names.
# Customize this to match YOUR project structure.

PROJECT_MAP = {
    # "C:\\code\\my-app": ("My App", "React SPA with Express backend"),
    # "C:\\code\\api-server": ("API Server", "Go REST API"),
    # "/home/user/projects/webapp": ("WebApp", "Next.js full-stack"),
}

# Fallback when no project matches
DEFAULT_PROJECT = ("Unknown Project", "No project mapping configured — add your projects to PROJECT_MAP in this file")

# Path to framework files (adjust if you installed elsewhere)
FRAMEWORK_DIR = os.path.expanduser("~/.claude/frameworks")

# Windows console default is often cp1252 - the hook output must be UTF-8.
try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass

# ─── Helpers ──────────────────────────────────────────────────────────

def run(cmd, timeout=5):
    """Execute shell command with UTF-8 decoding."""
    try:
        result = subprocess.run(
            cmd, shell=True, capture_output=True, timeout=timeout
        )
        # Try UTF-8 first, fall back to system encoding
        for encoding in ("utf-8", "cp1252", "latin-1"):
            try:
                return result.stdout.decode(encoding).strip()
            except UnicodeDecodeError:
                continue
        return result.stdout.decode("utf-8", errors="replace").strip()
    except (subprocess.TimeoutExpired, FileNotFoundError):
        return ""


def local_time():
    """Get actual local time via system command (not LLM's internal clock)."""
    # Windows
    t = run('powershell -NoProfile -Command "Get-Date -Format \'yyyy-MM-dd HH:mm (dddd)\'"')
    if t:
        return t
    # Unix/Mac fallback
    t = run('date "+%Y-%m-%d %H:%M (%A)"')
    if t:
        return t
    return "unknown"


def detect_project(cwd):
    """Detect project from current working directory."""
    cwd_normalized = os.path.normpath(cwd)
    # Check longest prefix first for specificity
    for prefix, info in sorted(PROJECT_MAP.items(), key=lambda x: -len(x[0])):
        if cwd_normalized.startswith(os.path.normpath(prefix)):
            return info
    return DEFAULT_PROJECT


def git_summary():
    """Get git branch, status, and recent commits."""
    branch = run("git branch --show-current")
    if not branch:
        return None

    status = run("git status --short")
    dirty = f" ({len(status.splitlines())} dirty files)" if status else " (clean)"

    log = run('git log --oneline -5 2>/dev/null')
    commits = f"\nRecent commits:\n{log}" if log else ""

    return f"Branch: {branch}{dirty}{commits}"


def load_issues(project_root):
    """Load top open issues from docs/issues.md."""
    issues_path = os.path.join(project_root, "docs", "issues.md")
    if not os.path.isfile(issues_path):
        return None

    issues = []
    try:
        with open(issues_path, "r", encoding="utf-8") as f:
            content = f.read()

        # Parse table rows with "open" or "in-progress" status
        for line in content.splitlines():
            if re.search(r"\|\s*(open|in-progress)\s*\|", line, re.IGNORECASE):
                # Clean up table formatting
                cells = [c.strip() for c in line.split("|") if c.strip()]
                if len(cells) >= 4:
                    issues.append(f"  {cells[0]} [{cells[1]}] {cells[2]}: {cells[3]}")
                if len(issues) >= 5:
                    break
    except (IOError, UnicodeDecodeError):
        return None

    if not issues:
        return None
    return "Open issues:\n" + "\n".join(issues)


# ─── Framework Cheatsheet ────────────────────────────────────────────

# Only what CLAUDE.md cannot do (timing). The rules live in ~/.claude/CLAUDE.md;
# injecting them twice cost ~3 KB per session.
FRAMEWORK_CHEATSHEET = "_Time above = session START; fetch it again from the system clock before any time statement. Rules: ~/.claude/CLAUDE.md; refresh with the framework-refresh skill._"


# ─── Main ─────────────────────────────────────────────────────────────

def build_context(cwd=None):
    """Assemble the session start context injection."""
    cwd = cwd or os.getcwd()
    time = local_time()
    project_name, project_desc = detect_project(cwd)
    git = git_summary()
    issues = load_issues(cwd)

    parts = [
        f"**Local time:** {time}",
        f"**Active project:** {project_name} ({project_desc})",
        f"**Project root:** `{cwd}`",
    ]

    if git:
        parts.append(f"\n**Git:**\n{git}")

    if issues:
        parts.append(f"\n**{issues}**")

    parts.append(f"\n{FRAMEWORK_CHEATSHEET}")
    parts.append("\n_(Auto-injected by session_start.py hook)_")

    return "\n".join(parts)


if __name__ == "__main__":
    # Read stdin (required by Claude Code hook protocol)
    input_data = sys.stdin.read() if not sys.stdin.isatty() else ""

    cwd = None
    if input_data:
        try:
            payload = json.loads(input_data)
            cwd = payload.get("cwd") or payload.get("workspace", {}).get("cwd")
        except Exception:
            pass

    print(build_context(cwd))
