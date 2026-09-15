# AI Provenance Standard (CAF-SDLC-010)

Every commit an agent produces in this workspace declares that it did, which tool did it,
and where the work came from. The PR gate reads these declarations and puts them in the
evidence record; see [`docs/sdlc-controls-integration.md`](../../docs/sdlc-controls-integration.md).

This is a **declaration, not a detection**. Nothing here proves a human wrote a commit.
The point is to make the honest case cheap to record and the dishonest case an explicit,
attributable act — which is what a git-level control can offer, and no more.

## The trailers

Git trailers, at the end of the commit message, after a blank line:

```
feat(payments): add idempotency key to the charge path

AI-Assisted: true
AI-Tool: claude-code
AI-Session: 4f2c1a80-7d3e-4b19-9c55-0ae61b2d8f34
Prompt-Ref: #12
```

| Trailer       | Required        | Value                                                      |
| ------------- | --------------- | ---------------------------------------------------------- |
| `AI-Assisted` | yes, if AI used | `true`                                                      |
| `AI-Tool`     | **yes**, if AI used | `claude-code`, `codex`, `gemini-cli`, `cursor`, `opencode` |
| `AI-Session`  | optional        | the tool's own session id, verbatim                         |
| `Prompt-Ref`  | optional        | the issue or task the work came from, e.g. `#12`            |

Keys are case-insensitive. A change counts as AI-assisted if **any** commit in it says
so, so squashing does not lose the declaration.

### `AI-Tool` is not optional

An AI-assisted change carrying no `AI-Tool` **fails the gate**. Provenance that records
only "an AI was involved" is not provenance — it names no accountable tool, so nothing
can be traced back.

Naming a tool or a session implies assistance, so forgetting `AI-Assisted: true` cannot
understate provenance. The gate reads a tool trailer alone as AI-assisted.

### `AI-Session` is a pointer, not a label

Record the tool's real session identifier, verbatim, or leave it out. A hand-written
label reads well in a log and resolves to nothing, and an identifier nobody can resolve
is decoration on an audit field.

Where several sessions produced one change, omit it. There is no single session that
produced the change, and naming whichever one came last is a claim about how the work
was done that is not true. `AI-Assisted` and `AI-Tool` still say everything the control
requires.

### `Prompt-Ref` points at the work item, never the prompt

Reference the issue or task. Do **not** paste prompts into commit messages: prompts carry
the context around them, and that is how client detail and internal material end up in a
repository by accident.

## For agents

When you commit in this workspace, append the trailers. Take `AI-Tool` from the agent you
are, and `AI-Session` from your own session id if you have one — never invent either.

Read this file, not a copy of it. Per the authority order in `AGENTS.md`, agent folders
(`.claude/`, `.codex/`, `.gemini/`, `.cursor/`, `.opencode/`) are adapters and must point
here rather than restate the convention, so there is one place to change when the control
changes.

## For humans

A commit you wrote yourself needs none of these trailers. Their absence is the normal
case, and the gate records `ai_assisted: false`.

If you are committing work an agent produced — you reviewed an agent's patch and are
landing it — declare it. The trailer describes the change, not the person typing
`git commit`.

## The hook

[`.githooks/commit-msg`](../../.githooks/commit-msg) checks two things. Enable it once
per clone:

```sh
git config core.hooksPath .githooks
```

It refuses a commit that declares AI involvement without naming a tool, and a commit made
inside an agent session that declares nothing at all.

It will **not** write a trailer for you. A declaration a tool invented on your behalf is
worth nothing in an audit — the value of the control is that the declaration is
deliberate. So the hook prints the lines to add, including your live session id, and
stops. You add them.

Humans committing by hand are unaffected: no agent environment, no AI trailers, no check.
