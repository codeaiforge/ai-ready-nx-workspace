# Git Workflow

**Scope**: Branching strategy, commit rules, and PR conventions for this workspace.

---

## Branching Strategy

Trunk-based development with short-lived feature branches. `main` is the single
long-lived branch and is always deployable.

```text
main ─────●────●────●────●────●────●────●────●──▸ (always deployable)
           \       /      \       /      \   /
            feat/0.1     feat/1.3     fix/boundary-violation
```

### Why trunk-based

- No `develop`, `release/*`, or `hotfix/*` overhead for a workspace this size
- Nx `affected` works best against a single stable comparison base
- Short-lived branches reduce merge conflicts and stale code

---

## Branch Naming

```text
<type>/<sprint>.<task>-<slug>
```

| Segment | Required | Description | Examples |
| ------- | -------- | ----------- | -------- |
| type | Yes | Category of work | `feat`, `fix`, `refactor`, `chore`, `docs`, `test`, `ci` |
| sprint.task | Recommended | Roadmap task reference | `0.1`, `1.3`, `2.7` |
| slug | Yes | Short kebab-case description | `scaffold-api`, `enforce-boundaries` |

### Examples

```text
feat/0.1-scaffold-api
fix/1.3-affected-base-ref
chore/0.10-github-actions-ci
docs/adr-0003-package-manager
```

When work doesn't map to a roadmap task, omit the task number:

```text
fix/lint-config-drift
chore/bump-nx
```

---

## Workflow

### 1. Create a branch from `main`

```bash
git checkout main
git pull origin main
git checkout -b feat/0.1-scaffold-api
```

### 2. Make small, atomic commits

Use [Conventional Commits](https://www.conventionalcommits.org/) — `type(scope):
subject` — with each commit representing a single logical change.

```bash
git add packages/api/src/router.ts
git commit -m "feat(api): add root router with health check"
```

AI agents must observe the [Commit Checkpoint](#commit-checkpoint) below.

### 3. Keep the branch short-lived

Aim to merge within 1-3 days. For larger tasks, break into sequential PRs that
each leave `main` in a working state.

### 4. Push and open a PR

```bash
git push -u origin feat/0.1-scaffold-api
gh pr create --title "feat(api): scaffold the API application"
```

### 5. CI must pass

GitHub Actions runs on every PR (see `.github/workflows/ci.yml`):

- `nx format:check --base=origin/main`
- `nx affected -t lint test build typecheck --base=origin/main`

A PR cannot merge until CI is green.

### 6. Squash merge into `main`

Squash merge keeps `main` history linear, with each commit representing one
complete unit of work.

```bash
gh pr merge --squash
```

### 7. Delete the branch

```bash
git push origin --delete feat/0.1-scaffold-api
```

GitHub can do this automatically: Settings > General > Automatically delete head
branches.

---

## Commit Checkpoint

**AI agents working in this repo must not execute `git add`, `git commit`,
`git commit --amend`, or `git stash` on the changeset on their own.** For every
change — trivial one-file edits included — the agent presents a commit plan and
the human performs the actual commit.

### What the plan contains

- Files grouped by concern (one group per intended commit)
- A Conventional Commit message (subject + body) for each group
- Required trailers (`Co-Authored-By:` etc.)

### Why

- Keeps the human in control of `main` history and branch state
- Catches mis-grouped or mislabeled commits before they're hard to unwind —
  amend, rebase, and force-push are destructive
- Slows down the moment where mistakes become expensive

### Agent responsibilities

- Verify the relevant gate is green (`pnpm nx affected -t lint test build`)
  before presenting the plan
- Present the plan in a single message; wait for the human to respond
- Do not touch the working tree with `git add` / `git commit` /
  `git commit --amend` / `git stash` until instructed
- After the human commits, resume follow-up work (update task output, sprint
  progress, open a PR draft, etc.)
- Applies to every pipeline phase, including re-commits after a Phase ④ Review
  blocker fix

### Scope of permission

The human may delegate a commit back to the agent explicitly for a specific task
("go ahead and commit this one"). That permission applies to the task at hand
only; it does not carry forward to later tasks or later commits in the same
branch.

---

## Pull Request Conventions

### Title

Same format as commit messages — the squash merge uses the PR title as the
commit message.

```text
type(scope): brief description under 70 chars
```

### Description template

```markdown
## Summary

Brief description of what this PR does and why.

## Task reference

Sprint X, Task X.Y — [task name from roadmap]

## Changes

- Specific change 1
- Specific change 2

## Testing

- [ ] Unit tests pass (`pnpm nx test <project>`)
- [ ] Lint + typecheck pass (`pnpm nx affected -t lint typecheck`)
```

### PR size guidelines

| Size | Lines changed | Approach |
| ---- | ------------- | -------- |
| Small | < 200 | Single PR |
| Medium | 200-500 | Single PR, clear description |
| Large | 500+ | Split into sequential PRs if possible |

---

## Merge Strategy

| Setting | Value | Reason |
| ------- | ----- | ------ |
| Merge method | **Squash merge** | Linear history on `main`, one commit per feature |
| Delete branch on merge | **Enabled** | Keeps remote clean |
| Require CI to pass | **Enabled** | No broken code on `main` |
| Require branch to be up-to-date | **Enabled** | Prevents merge conflicts on `main` |

Configure in GitHub repo settings:

- Settings > General > Pull Requests: allow only "Squash merging"
- Settings > Branches > Add rule for `main`:
  - Require status checks to pass before merging
  - Require branches to be up to date before merging

---

## Working with Nx Affected

CI compares the PR branch against `main`. To replicate locally:

```bash
# See what changed
pnpm nx affected -t lint test build --base=origin/main --head=HEAD

# Run only affected tests
pnpm nx affected -t test --base=origin/main
```

Only the projects touched by your branch are checked, which keeps feedback fast.

---

## Handling Conflicts

If `main` has moved ahead of your branch:

```bash
# Preferred: rebase onto main (clean history)
git fetch origin
git rebase origin/main

# Alternative: merge main into your branch (if rebase is complex)
git fetch origin
git merge origin/main
```

Prefer rebase for small branches. Use merge if the branch has been open long
enough that rebasing would require resolving the same conflicts repeatedly.

---

## Sprint Tagging (Optional)

At the end of each sprint, tag the last commit on `main`:

```bash
git tag -a sprint-0 -m "Sprint 0: scaffolding and infrastructure complete"
git push origin sprint-0
```

Clean reference points in history without the overhead of release branches.

---

## Quick Reference

```text
Branch:    git checkout -b feat/0.1-scaffold-api
Commit:    git commit -m "feat(api): add root router"
Push:      git push -u origin feat/0.1-scaffold-api
PR:        gh pr create --title "feat(api): scaffold the API application"
Merge:     gh pr merge --squash
Clean up:  git push origin --delete feat/0.1-scaffold-api
Tag:       git tag -a sprint-0 -m "Sprint 0 complete"
```
