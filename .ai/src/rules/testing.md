# Testing Rules

## What Must Be Tested

- Business logic: repositories/services and any pure transformation logic.
- State orchestration: BLoCs for success + expected failure paths.
- Error mapping: low-level failures must map to explicit exception types deterministically.

## Test Quality

- Use Given/When/Then structure and clear naming.
- Tests must be deterministic (no real HTTP, no real clocks, no randomness).
- Prefer fakes/stubs over mocks; use mocks only when interaction verification is required.
- Mock I/O boundaries (HTTP, database, preferences, secure storage).
- Keep `setUp`/`tearDown` scoped to `group(...)` blocks, not at file top level.
- Initialize mutable collaborators per test; never share mutable/static state across tests.

## Coverage Expectations

- Prioritize meaningful coverage over percent goals; always cover error cases for critical flows.

## Assertions & Integration

- Use `package:checks` for assertions (clear failure messages, fluent API) where possible.
- Use `integration_test` for critical user flows that span multiple screens/features.
- Tag golden tests consistently (for example `golden`) so they can run separately in CI.
- Run randomized ordering periodically in CI to expose hidden test coupling (`--test-randomize-ordering-seed random`).
