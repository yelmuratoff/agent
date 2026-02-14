---
applyTo: '**'
---

# Performance Rules

## General

- Measure before optimizing; use Flutter DevTools and real metrics.
- Avoid work on the UI thread that can be moved to isolates (parsing, heavy transforms).

## UI & Rendering

- Prefer const widgets and stable keys where appropriate to reduce rebuild cost.
- Use lazy lists for large collections; avoid building huge widget trees at once.
- Avoid expensive effects (saveLayer-heavy patterns, excessive opacity/clip) unless justified.

## Data

- Cache and paginate large datasets; do not load “everything” by default.
- Do not block frames with synchronous I/O.
