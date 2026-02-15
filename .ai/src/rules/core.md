# Core Rules

## Style

- Follow Effective Dart for naming, structure, and API design.

## Codegen Policy

- Do not use `freezed`, `json_serializable`, or `build_runner` for models or BLoCs.
- Allowed: Dart Data Class Generator for DTOs only (see architecture skill for directives).

## Design

- Prefer small, explicit Dart 3 code: immutable models, sealed hierarchies, exhaustive switches.
- Apply SOLID/DRY/KISS/YAGNI to keep code changeable and simple.
- Consistency: specific metric - aim for functions < 100 lines to ensure readability and single responsibility.

## Testing

- Write tests for business logic and error cases; mock I/O (network, database, preferences).
- Use Given/When/Then structure; keep tests fast and deterministic.

## Error Handling

- Use specific error types (network/parse/cache/timeout) and do not swallow exceptions.
- Wrap async boundaries; handle errors at the layer that can recover or translate to UI state.

## Security & Privacy

- Never hardcode secrets; always use HTTPS for network calls.
- Never log PII or secrets (tokens, credentials); sanitize user-provided strings before logging.
