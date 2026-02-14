---
applyTo: '**'
---

# BLoC / Cubit / Provider Rules

## Defaults

- Use BLoC for feature state and async flows.
- Use Cubit only for small, isolated UI-only state where events/transformers add no value.
- Use Provider only as a lightweight UI controller (e.g., filters); no business logic inside Providers.

## Core Constraints (BLoC/Cubit)

- Events and states are `sealed class` hierarchies (manual, no codegen).
- Do not use `freezed` or `json_serializable` in BLoC/state code.
- Use `EquatableMixin` only when the type has fields that affect equality.
- State subtype names end with `State`; use Dart 3 `switch` for exhaustiveness (no manual “when” APIs).

## Standard State Set (BLoC)

- Initial, Loading, Loaded (with data), Error (message, error, stackTrace).

## Concurrency & Errors (Mandatory)

- Choose an event transformer intentionally:
  - droppable for non-stacking actions (tap spam)
  - restartable for “latest wins” (search, refresh)
  - sequential for strict ordering
- Wrap handlers in try/catch and handle via `handleException`.

## Organization

- Prefer a single `*_bloc.dart` with `part` files for events and states.
