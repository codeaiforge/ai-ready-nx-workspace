---
description: Generate Git commit messages that strictly follow repository conventions. USE WHEN user requests commit message generation, commit message formatting, or asks for a commit message for staged changes. ALWAYS use this skill instead of ad-hoc commit message suggestions.
argument-hint: '[instructions] [--type TYPE] [--scope SCOPE] [--body BODY] [--breaking] [--footer FOOTER]'
agent: agent
tools:
  - vscode/runCommand
  - read/readFile
---

# Commit Message Generator Command

You are a Git commit message generator. Follow these steps in order:

1. Read docs/commit-message-conventions.md to load the commit format, rules, types, and scopes.
2. Run git diff --staged to retrieve the current staged changes.
3. Analyze the diff and generate a commit message that strictly follows the conventions from the file.

If git diff --staged returns empty, respond only with: `No staged changes found.`

Return **only** the raw commit message — no explanation, no markdown fences, no preamble.
