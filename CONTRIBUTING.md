# Contributing to EzAuth

Thanks for considering a contribution.

Read [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) before making changes to understand the module boundaries, data model, and auth flows.

## Ways to Contribute

You do not need to be technical to help.

- Add focused tests for existing behavior.
- Improve docs for beginner-friendly readability.
- Submit code changes for bugs or security fixes.
- Report bugs with steps, expected behavior, and error output.

## Before You Start

- For larger changes, open an issue or discussion first.
- Prefer incremental improvements over broad rewrites (if at all).
- Keep scope small and focused. Smaller changes have a much better chance of being reviewed and merged quickly.

## Contribution Workflow

1. Create a branch from `main`.
2. Implement one clear change at a time.
3. Follow existing project structure and naming conventions.
4. Add or update tests when behavior changes.
5. Run all quality checks locally before opening a PR.
6. Commit using [Conventional Commits](https://www.conventionalcommits.org/).
7. Keep history linear before opening a PR (`git rebase`)
8. Run `mix quality` before opening a PR and ensure tests pass.
8. Open a PR with context and evidence and link to related issue.

## Testing

Every bug fix needs an accompanying regression test:

1. Create a test case that reproduces the bug (test passes).
2. Adjust the test expectations so it requires the correct behavior (test fails).
3. Implement the fix (test passes).

## Pull Request Guidelines

Include in your PR:

- What changed and why.
- Which model/tooling you used (if AI-assisted work was involved).
- Validation evidence (`mix test`, `mix quality`).
- Any tradeoffs, known issues, or follow-up ideas.

Respond to review feedback with additional commits (or a clean rebase before merge).