# Workflow

- Never silently fill in ambiguous requirements
- Commit using the "conventional commits" specification
- Never act on question, provide insights and wait for resolution.
- Prefer the simplest possible solution that could reasonably work
- Think like a boy scout, leave the place better than you found it
- Start with a naive, obviously correct implementation before optimizing
- Push back on incorrect, risky, or poorly-scoped instructions and propose safer or simpler alternatives

NOTE: Check the CONTRIBUTING.md file for more information on how to work with this codebase.

## Bug fixes

Every bug fix needs an accompanying regression test:
  - **Step 1**: Create a test case that reproduces/ confirms the bug (test passes)
  - **Step 2**: Adjust the test expectations so it requires the correct behavior (test fails)
  - **Step 3**: Implement the fix by making the now correct expectations work (test passes)

## Code style

- Prefer `alias __MODULE__` instead of referencing `%__MODULE__{}` directly. 
- Avoid wrapping existing Elixir/OTP primitives in abstraction modules for safety.
- Avoid pipes for single function calls, prefer: `new(Application.fetch_env!(...))`.
- Prefer returning tuples inline (e.g., `{repo.insert!(record), value}`) over separate statements.
- Avoid unnecessary block-level comments that separate "sections" of a given module
- Use `get_in/2` for safe nested access (e.g., `get_in(scope.user.id)` instead of conditional access).
- Inline `if` and `with` when short/single line results, eg: `if ..., do: ..., else: ...` / `with ..., do: {:ok, result}`
- Ensure functions are ordered as: public functions first (sorted alphabetically) and private functions last (sorted by calling order)
- Remember that `with` only requires `else` if you want to modify the failure case result (since it automatically returns that) 
- When semantic permits (without changing behavior), organize code by grouping logically related elements (and splitting unrelated ones). Arrange lines that looks visually balanced and easy to scan. Mind variables and functions width. Notice that often times, organization can be done by simply using newlines or re-arranging the code so that statements compose a clear "visual rhythm".
- This is not a Typescript codebase, so avoid leaking unrelated idioms into Elixir code. For instance, patter matching (structs and guards) should never be used to emulate a type-system, specially when the shape of the data is known up front (or otherwise enforced from the flow). Use pattern-matching when differentiating clauses based on the shape of the data makes sense and communicates intent clearly. You must also avoid using defensive programming at all costs and should prefer to embrace the "let is crash" philosophy. 

## Testing

- Prefer to use `refute` instead of `assert value == nil`.
- Don't write tests for trivial implementation details, focus on high-level functionality.
- Use the pin operator for matching known values (e.g., `assert %{id: ^id} = result`).

## Refactoring

When editing code, aways preserve the original semantics. Before editing, think: What's the simplest possible diff that achieves the same result Avoid meaningless refactors such as variable or function names changes without prior confirmation. Also, never mix behavior (what the code achieves) and structural (how the code achieves) changes. Here's a non-exhaustive list of examples to avoid: 
  - Droping pre-existing variables
  - Inlining code while altering behavior
  - Renaming variables while fixing a bug
  - Reformatting code while adding a new feature
  - Extracting a function while changing its logic
  - Moving files/modules while modifying functionality

## Documentation

### General

- Use hyphens instead of em-dashes for documentation
- Ensure /docs are kept up to date with the current state of the codebase.
- Write prose that is direct and addresses the reader without over-explaining.
- ASCII diagrams are welcome for architecture and data-flow explanations.
- Components documentation should always have 3 sections: 
  - Options: Documents available options (attrs)
  - Styling: Documents styling options (data attributes)
  - Examples: Documents how to use components (non comprehensive)

### Elixir-specific

- Lead every doc with a single sentence, then expand with context below.
- Keep examples practical and compact, demonstrating real use cases of usage.
- Document options as a bullet list as: `* name - description` and include enough detail about the option at hand.
- Use `##` headers to break module docs into logical sections when a module covers multiple concepts.
- Cross-reference related modules with backtick links (e.g., "See `Module.function/2` for more details.").
- Don't document the obvious, if a function's name and typespec make the behavior clear, a one-liner is enough.
