#!/usr/bin/env python3
"""
gcm — Git Commit Message Generator
Reads a git diff from stdin, calls Claude Code CLI (-p mode), prints a commit message.

Usage:
  git diff --staged | gcm          # conventional commit message
  git diff --staged | gcm --pr     # PR title + body

No API key needed — uses your existing Claude Code subscription.
"""

import os
import subprocess
import sys

CLAUDE_BIN = os.path.expanduser("~/.local/bin/claude")

COMMIT_PROMPT = """\
You are an expert software engineer writing git commit messages.
Output ONLY the commit message — no explanation, no markdown, no code fences.

Follow the Conventional Commits spec:
  <type>(<scope>): <short summary>

  [optional body — bullet points, 72-char wrap]

Rules:
- type must be one of: feat, fix, refactor, style, docs, test, chore, perf, ci, build
- scope is optional but use it when it's obvious (e.g. auth, kanban, navbar)
- summary: imperative mood, lowercase, no period, ≤72 chars
- body: only if meaningful extra context exists; use "- " bullets
- Do NOT include anything other than the commit message itself

Write a commit message for this diff:

"""

PR_PROMPT = """\
You are an expert software engineer writing GitHub pull request descriptions.
Output ONLY the PR title on the first line, then a blank line, then the PR body.
No markdown fences, no extra commentary.

PR title format: <type>(<scope>): <short summary>  (Conventional Commits style)

PR body format:
## What
<1–3 sentences describing what changed>

## Why
<1–2 sentences on the motivation / problem solved>

## Changes
- <bullet per meaningful change>

Write a PR title and body for this diff:

"""

def main():
    pr_mode = "--pr" in sys.argv

    diff = sys.stdin.read().strip()
    if not diff:
        print("❌  No diff received on stdin.", file=sys.stderr)
        print("    Usage: git diff --staged | gcm", file=sys.stderr)
        sys.exit(1)

    if not os.path.isfile(CLAUDE_BIN):
        print(f"❌  Claude CLI not found at {CLAUDE_BIN}", file=sys.stderr)
        sys.exit(1)

    if len(diff) > 60_000:
        diff = diff[:60_000] + "\n[diff truncated]"

    label = "PR description" if pr_mode else "commit message"
    print(f"⠿  Generating {label}…", file=sys.stderr)

    prompt = (PR_PROMPT if pr_mode else COMMIT_PROMPT) + diff

    result = subprocess.run(
        [CLAUDE_BIN, "-p", prompt],
        capture_output=True,
        text=True,
    )

    if result.returncode != 0:
        print(f"❌  Claude CLI error:\n{result.stderr}", file=sys.stderr)
        sys.exit(1)

    print(result.stdout.strip())


if __name__ == "__main__":
    main()
