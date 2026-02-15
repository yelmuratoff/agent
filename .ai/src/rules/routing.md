# Routing Rules

## Libraries

- Use `go_router` exclusively for navigation and deep linking.
- Do not use `Navigator` 1.0 (push/pop) directly unless wrapping a legacy imperative flow is unavoidable.

## Structure

- Define a centralized `GoRouter` configuration (e.g., in `core/router/`).
- Use separate route files or static constants for route paths/names to avoid string literals in UI code.

## Type Safety

- Prefer typed routes (using `go_router_builder` if available in the project, or strict `extra` object definitions).
- Pass complex objects via `extra`, but prefer passing IDs and re-fetching data in the new screen's BLoC/Repository.
