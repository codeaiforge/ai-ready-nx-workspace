# Commit message conventions

The format `.github/prompts/commit.prompt.md` generates against, and the one
`.githooks/commit-msg` and the PR gate read. Branching, PR titles and merge strategy
live in [`.github/git-workflow.md`](../.github/git-workflow.md); this file is only about
the message itself.

## Format

```text
type(scope): subject

body

trailers
```

[Conventional Commits](https://www.conventionalcommits.org/). Only the first line is
required.

## Rules

- **Subject** — imperative mood ("add", not "added" or "adds"), lowercase after the
  colon, no trailing period, under 70 characters. The squash merge uses the PR title as
  the commit message, so the same limit applies in both places.
- **Scope** — optional, lowercase, one word. Omit it rather than invent one.
- **Body** — optional, wrapped at 72 columns, separated from the subject by a blank
  line. Say _why_, not _what_: the diff already says what.
- **Trailers** — separated from the body by a blank line, one `Key: value` per line.

One commit is one logical change. A commit that needs "and" in its subject is usually
two commits.

## Types

Observed in this repository, most used first:

| Type       | For                                              |
| ---------- | ------------------------------------------------ |
| `docs`     | documentation, standards, ADRs, playbooks        |
| `feat`     | a new capability                                 |
| `fix`      | a defect repair                                  |
| `chore`    | housekeeping that is neither a feature nor a fix |
| `ci`       | pipeline and workflow changes                    |
| `refactor` | behaviour-preserving restructuring               |
| `test`     | tests only                                       |
| `style`    | formatting only, no behaviour change             |

## Scopes

Not a closed set — these are the ones in use. Prefer an existing scope to a new one:

`adr`, `ai`, `architecture`, `ci`, `claude`, `context`, `core`, `demo`, `github`,
`prompts`, `readme`, `roles`, `specs`, `sprints`, `standards`, `tasks`, `tooling`,
`tools`, `vscode`, `workflows`

An Nx project name is also a valid scope when the change is confined to one project.

## AI provenance trailers

A commit an AI assisted declares it. `.githooks/commit-msg` refuses a message that
declares AI involvement without naming the tool, and the PR gate fails the change:

```text
AI-Assisted: true
AI-Tool: claude-code
AI-Session: <a real session id, or omit the line>
Prompt-Ref: <issue or task, e.g. #12>
```

`AI-Tool` is required whenever any AI trailer is present. Never invent a session id —
omit `AI-Session` instead. The full convention is
[`.ai/standards/ai-provenance.md`](../.ai/standards/ai-provenance.md).

## Examples

```text
feat(api): add root router with health check
```

```text
fix(core): reject a criticality tag the binary would not accept

A typo like `criticality: critcal` tiered a critical component at T0 and
passed the change. Fail the map build instead, where the typo is readable.

AI-Assisted: true
AI-Tool: claude-code
```

```text
docs(standards): state which ADR block a stack branch claims
```
