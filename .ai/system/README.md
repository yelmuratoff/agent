# AI Config Sync System

This directory contains the sync engine that maps `.ai/src/*` to tool-specific config layouts.

For authoring guidelines, see `.ai/README.md`.

## Inputs and Outputs

### Source inputs (from `config.yaml`)

```yaml
source:
  agents: ".ai/src/AGENTS.md"
  rules: ".ai/src/rules"
  skills: ".ai/src/skills"
  tools: ".ai/src/tools"
```

### Generated outputs

Outputs are defined per tool in `.ai/src/tools/*.yaml` (configurable via `source.tools` in `.ai/system/config.yaml`).

Enabled/disabled tool outputs are controlled by each file's `enabled` flag in `.ai/src/tools/*.yaml`.

## Commands

Run from repo root.

Full sync:

```bash
.ai/system/sync.sh
```

Preview only:

```bash
.ai/system/sync.sh --dry-run
```

Filter tools:

```bash
.ai/system/sync.sh --only claude,copilot
.ai/system/sync.sh --skip gemini
```

Install git hooks:

```bash
.ai/system/setup_hooks.sh
```

Validation helper:

```bash
.ai/system/check.sh
```

## `.ai/src/tools/*.yaml` Schema

Minimal:

```yaml
name: "Tool Name"
enabled: true
targets:
  agents:
    dest: ".tool/AGENTS.md"
  rules:
    dest: ".tool/rules"
  skills:
    dest: ".tool/skills"
```

Supported optional fields:

- `targets.agents.source`: override AGENTS source file
- `targets.rules.source`: override rules source directory
- `targets.rules.extension`: rename rule extension (example: `.mdc`, `.instructions.md`)
- `targets.rules.header`: prepend text to each rule file
- `targets.rules.include`: include glob for source rule file names
- `targets.rules.exclude`: exclude glob for source rule file names
- `targets.rules.append_imports`: append `@rules/...` lines into agents file (used by Claude)
- `targets.skills.source`: override skills source directory
- `targets.skills.include`: include glob for skill folder names
- `targets.skills.exclude`: exclude glob for skill folder names
- `post_sync`: shell command run after successful sync of that tool

Reference template: `.ai/src/tools/_TEMPLATE.yaml`

## Sync Behavior

For each `.ai/src/tools/*.yaml` file:

1. Read `name`, `enabled`, and target paths.
2. If disabled, clean existing generated paths for that tool.
3. Apply CLI filters (`--only`, `--skip`).
4. Sync `agents` file.
5. Sync `rules` with optional extension/header/filtering and differential cleanup.
6. Sync `skills` directories with filtering and differential cleanup.
7. Run optional `post_sync`.
8. After all tools, update generated block in `.gitignore`.

## `.gitignore` Integration

`sync.sh` rewrites the block between:

- `# --- AI SYNC GENERATED START ---`
- `# --- AI SYNC GENERATED END ---`

It inserts generated paths for all enabled tools and keeps the rest of `.gitignore` intact.

## Files in This Directory

```
.ai/system/
├── config.yaml        # Global source path mapping
├── sync.sh            # Main sync entrypoint
├── setup_hooks.sh     # Installs post-merge and post-checkout hooks
├── check.sh           # Verification helper
├── lib/files.sh       # Copy/sync/filter operations
├── lib/yaml.sh        # Lightweight YAML parser
└── lib/gitignore.sh   # Generated block updater
```

## Add a New Tool

1. Copy `.ai/src/tools/_TEMPLATE.yaml` to `.ai/src/tools/<tool>.yaml`.
2. Fill `name`, set `enabled: true`, and configure all target destinations.
3. Add optional transforms (`extension`, `header`, `include/exclude`) only if needed.
4. Run `.ai/system/sync.sh --only <tool>`.
5. Verify output and rerun full `.ai/system/sync.sh`.
