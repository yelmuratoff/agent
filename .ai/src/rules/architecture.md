# Architecture Rules

## Feature Boundaries

- Each feature owns presentation + domain + data under a single feature folder.
- Dependency direction is strict: presentation → domain → data (never the reverse).

## Layer Constraints (Project Simplifications)

- No “use case” layer: BLoC talks to repository interfaces directly.
- No mapping layer by default: DTOs defined in the data layer are used across layers unless there is a concrete need to split models.

## Separation (Strict)

- Presentation depends only on domain contracts; it never imports a feature’s data layer.
- Domain has zero Flutter/framework imports.
- Data implements domain interfaces and contains all I/O details.

## Models & Serialization

- DTOs live in the feature data layer and are immutable.
- Serialization follows the Dart Data Class Generator approach; do not introduce `freezed`/`json_serializable`.

## Packages (Extract When Reused)

- Extract to packages when code is shared across features or needs independent testing:
  - clients (api_client), shared datasources, repositories used by multiple features
  - cross-feature domain contracts/models
  - core utilities (logging, analytics, secure storage wrappers)

## Public API Exports

- Use barrel files for public feature/package APIs to avoid deep, brittle imports.
- Keep exports intentional: expose stable entry points and do not export private internals.
- BLoC files with `part` directives already act as the public entry point for their state/event units.
