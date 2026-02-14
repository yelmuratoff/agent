# AI Config Sync

Syncs `.ai/src/` configs to all AI tool directories.

> **User Manual**: For high-level philosophy and writing guides, see [../README.md](../README.md).
> This document covers technical details, configuration schema, and tooling.

## Source

```
.ai/src/
├── AGENTS.md       # Identity/context → copied as main file
├── rules/*.md      # Rule files → copied/transformed per tool
└── skills/         # Skill folders → copied as-is
```

## Usage

### 1. Synchronization (Local)

To generate configurations for all enabled tools:

```bash
.ai/system/sync.sh
```

### 2. Git Strategy (Recommended)

We commit the generated configurations to Git to ensure all team members stay in sync without running scripts manually.

1.  Run `sync.sh` after modifying `.ai/src/` contents.
2.  Commit the changes (both `.ai/src/` source and generated targets).
3.  Team members effectively get updates via `git pull`.

### 3. Automated Sync (Hooks)

Install Git hooks to sync automatically on `pull` and `checkout`:

```bash
.ai/system/setup_hooks.sh
```

### 4. Dynamic Gitignore

`sync.sh` automatically updates `.gitignore` to exclude generated artifacts.

- It looks for `tool.yaml` configs with `enabled: true`.
- It updates the block between `# --- AI SYNC GENERATED START ---` markers.
- Manual entries in `.gitignore` are preserved.

### 5. CI / Validation

To verify that configurations are in sync (e.g., in CI or pre-commit hook):

```bash
.ai/system/check.sh
```

This script exits with `0` if synced, `1` if changes are detected.

## Config

```
.ai/system/
├── config.yaml       # Source paths
├── sync.sh           # Main script
├── lib/              # Helper functions
└── tools/*.yaml      # Per-tool configs
```

## Adding New Tool

1. Create `.ai/system/tools/newtool.yaml`
2. Set `enabled: true`
3. Define `targets.agents.dest`, `targets.rules.dest`, `targets.skills.dest`
4. Run `.ai/system/sync.sh`
