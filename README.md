# AI Agent Configuration Workspace

This repository centralizes AI agent instructions in one source and syncs them to tool-specific formats.

## Source of Truth

Edit only `.ai/src/`.
Do not edit generated tool folders directly (`.agent/`, `.claude/`, `.gemini/`, `.github/`).

```
.ai/
├── src/                  # Authoring source (edit here)
│   ├── AGENTS.md
│   ├── rules/*.md
│   ├── skills/*/SKILL.md
│   └── tools/*.yaml        # Tool enable/disable + targets (edit here)
├── system/               # Sync engine
│   ├── sync.sh
│   ├── setup_hooks.sh
│   ├── check.sh
│   └── config.yaml
└── README.md             # Authoring guide
```

## Tool Targets

Enabled tools are defined in `.ai/src/tools/*.yaml`.

## Workflow

1. Edit source files in `.ai/src/`.
2. Run sync:

```bash
.ai/system/sync.sh
```

3. Optional preview:

```bash
.ai/system/sync.sh --dry-run
```

4. Optional partial sync:

```bash
.ai/system/sync.sh --only claude,copilot
.ai/system/sync.sh --skip gemini
```

## Git Hooks (Recommended)

Install once:

```bash
.ai/system/setup_hooks.sh
```

This installs `post-merge` and `post-checkout` hooks that run `.ai/system/sync.sh` automatically.

## Gitignore Behavior

`sync.sh` updates the block between:

- `# --- AI SYNC GENERATED START ---`
- `# --- AI SYNC GENERATED END ---`

This block is rebuilt from enabled tool targets in `.ai/src/tools/*.yaml`.

## Documentation Map

- Authoring rules and conventions: `.ai/README.md`
- Sync engine details and YAML schema: `.ai/system/README.md`
