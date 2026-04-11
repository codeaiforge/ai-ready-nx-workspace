# Prompts

Phase-specific prompt templates for the SDLC pipeline. Each template defines the composable blocks that assemble into a complete agent prompt.

## Contents

| File | Phase | Lead Agent | Tiers |
| ---- | ----- | ---------- | ----- |
| [analyze-task.md](analyze-task.md) | ① Analyze | Business Analyst | All |
| [design-spec.md](design-spec.md) | ② Design | Architect + specialist | Standard, Complex |
| [implement.md](implement.md) | ③ Implement | Specialist by layer | All |
| [review-code.md](review-code.md) | ④ Review | Code Reviewer | All |
| [test-feature.md](test-feature.md) | ⑤ Test | QA Engineer | Standard, Complex |
| [security-assess.md](security-assess.md) | ⑥ Security | Security Engineer | Complex |
| [verify-acceptance.md](verify-acceptance.md) | ⑧ Verify | Business Analyst | All |

## Prompt Composition

Each prompt is assembled from 6 composable blocks:

1. **Role Identity** — from `roles/{role}.md`
2. **Task Template** — from `tasks/{task}.md`
3. **Standards** — from `standards/{relevant}.md`
4. **Iteration Context** — from roadmap section + task row
5. **Input Artifacts** — output from the previous phase
6. **Output Format** — artifact template defined in each prompt file below

## Usage

These templates define the **Output Format** block and the **phase-specific instructions**. The other 5 blocks are injected from existing `.ai/` definitions at composition time.

## Customization

Replace `{placeholders}` with your project-specific values:

- `{package-manager}` — your package manager (`npm`, `pnpm`, `yarn`)
- `{requirements-doc}` — path to your requirements specification
- `{roadmap-doc}` — path to your implementation roadmap
- `{commit-conventions-doc}` — path to your commit message conventions
