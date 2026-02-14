# Localization Rules

## Mandatory

- Use Flutter localization generation (gen-l10n / intl); do not load translations at runtime from JSON.
- All user-visible strings must come from localization (no hardcoded UI strings, except dev-only labels).

## Keys & Parameters

- Keys are stable and descriptive; do not encode presentation details (no “_button_”, “_title_” unless unavoidable).
- Use parameters for dynamic content; do not concatenate localized strings.

## Plurals & Gender

- Use ICU/plural rules instead of manual if/else string selection.

## Testing

- Cover critical strings and pluralization paths in unit/widget tests when logic depends on them.
