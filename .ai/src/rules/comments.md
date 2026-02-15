# Code Comments

## Constraints

- **Focus on Business Logic**: Comment on _why_ complex logic exists (business rules, workarounds), rather than _what_ the code does.
- **Trust the Code**: Omit comments if the code's purpose and logic are immediately clear from naming and structure.
- **Maintain Clean History**: Remove unused code and rely on version control (git) to track history.
- **Deliver Polished Code**: Ensure the final output is free of "AI thoughts", step markers, or temporary debugging notes.
- **Document Public APIs**: Use `///` documentation comments for libraries and public members.
- **Standardize Formatting**: Begin all comments with a single space `// Like this` for readability.
- **Refactor First**: Prioritize renaming variables and functions to clarify intent before resorting to comments.

## Public API Docs

- **Summary First**: Start doc comments with a single-sentence summary that ends with a period.
- **Placement**: Put doc comments before annotations.
- **Behavioral Details**: Document non-obvious side effects, constraints, and thrown exceptions for public APIs.
- **Avoid Duplication**: Do not document both getter and setter for the same property unless behavior differs.
