# Core Rules

## Style

- Follow Effective Dart for naming, structure, and API design.
- Prefer flow analysis and early returns over non-null assertions.
- Prefer existing project dependencies and native SDK capabilities before adding new packages.

## Codegen Policy

- Do not use `freezed`, `json_serializable`, or `build_runner` for models or BLoCs.
- Allowed: Dart Data Class Generator for DTOs only (see architecture skill for directives).

## Design

- Prefer small, explicit Dart 3 code: immutable models, sealed hierarchies, exhaustive switches.
- Apply SOLID/DRY/KISS/YAGNI to keep code changeable and simple.
- Consistency: specific metric - aim for functions < 100 lines to ensure readability and single responsibility.
- Keep `build()` methods side-effect free (no network calls, I/O, or heavy computation).

## Null Safety

- Avoid the non-null assertion operator (`!`) unless guarded by prior checks/assertions in the same control flow.
- Prefer nullable-aware operators and explicit guards over forced casts.

## Testing

- Write tests for business logic and error cases; mock I/O (network, database, preferences).
- Use Given/When/Then structure; keep tests fast and deterministic.

## Verification Gates

- Run `dart format` for modified files before finalizing.
- Run `dart fix --apply` for safe, automated lint cleanup when relevant.
- Run `dart analyze` and keep the result warning-free.
- Run targeted `flutter test` for changed features; run full suite before merge when possible.

## Error Handling

- Use specific error types (network/parse/cache/timeout) and do not swallow exceptions.
- Wrap async boundaries; handle errors at the layer that can recover or translate to UI state.

## Security & Privacy

- Never hardcode secrets; always use HTTPS for network calls.
- Never log PII or secrets (tokens, credentials); sanitize user-provided strings before logging.
