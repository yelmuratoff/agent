---
name: design
description: When implementing UI components, themes, or responsive layouts.
---

# Design System

## When to use

- Creating new UI widgets or screens.
- Updating the app's theme or color palette.

## Core Principles

- **Strict Theming**: No hardcoded colors. Use `Theme.of(context)` and `ColorScheme`.
- **Responsive**: Adapt to screen size using `LayoutBuilder` or standard breakpoints.

## Implementation Guide

### 1) Theming & Extensions

Extend `ThemeData` for custom tokens instead of hardcoding constants.

```dart
@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color brandGlow;
  // ... implementation ...
}

extension AppThemeX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
  TextTheme get text => Theme.of(this).textTheme;
}

// Usage
final glow = context.colors.brandGlow;
Text(
  'Title',
  style: context.text.displayLarge,
);
```

### 2) Responsive Layouts

Use `LayoutBuilder` to switch between mobile and desktop/tablet layouts.

```dart
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth > 600) {
      return const WideLayout();
    }
    return const NarrowLayout();
  },
)
```
