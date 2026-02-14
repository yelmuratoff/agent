---
applyTo: '**'
---

# Networking Rules

## Boundaries

- UI (widgets) never performs network calls directly.
- Repositories call datasources/clients; datasources own request/response details.
- All networking dependencies are injected (no singletons in feature code).

## Reliability

- Set explicit timeouts for requests and parsing.
- Translate low-level failures into explicit error types (network/timeout/parse).
- Do not retry blindly; retries must be intentional and bounded.

## Parsing

- Do not parse large JSON on the UI thread; use background parsing (compute/isolates).
- DTO construction must be deterministic and testable.

## Testing

- Unit test repositories with mocked clients/datasources.
- Avoid real HTTP in unit tests; use integration tests only when explicitly requested.
