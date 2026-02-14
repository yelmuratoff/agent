# Error Handling Rules

## Exceptions (Typed, Explicit)

- Throw typed exceptions for expected failure modes: network, timeout, parse, cache/storage.
- Do not throw raw strings; do not swallow exceptions.

## Where Errors Are Mapped

- Datasources/clients: throw low-level errors.
- Repositories: translate low-level failures into explicit, feature-meaningful exceptions.

## Logging & Privacy

- For caught exceptions, call `ISpect.logger.handle` and include `exception`, `stackTrace`, `message`.
- Never log PII or secrets (tokens, credentials, session IDs).
