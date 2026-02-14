# AI Configuration Manual

The `.ai/` directory is the **Single Source of Truth (SSOT)** for all AI agent behaviors, rules, and skills in this repository.

## 🧠 Philosophy

Instead of configuring each AI tool (Cursor, Copilot, Claude, etc.) individually, we define **everything** here.
The **Sync System** then propagates these configs to the specific locations required by each tool (e.g., `.cursor/rules`, `.github/copilot-instructions.md`).

**Benefits:**

- **Consistency:** All agents follow the same rules.
- **Maintainability:** Change a rule once, update everywhere.
- **Scalability:** Easily add new tools or shared skills.

## 📂 Structure

```
.ai/
├── src/                # INPUTS: Source of truth (edit this).
│   ├── AGENTS.md       # Identity and philosophy.
│   ├── rules/          # Rules and constraints.
│   └── skills/         # Capabilities and recipes.
│
├── system/             # SYSTEM: Sync logic and tooling (do not edit).
└── README.md           # This manual.
```

## 📝 How to Write Configurations

### 1. AGENTS.md (The "Who")

This file defines the persona and high-level approach of the AI.

- **Focus:** Mindset, philosophy, decision-making frameworks (e.g., "Favor composition over inheritance").
- **Content:** Abstract principles, not specific tech recipes.
- **Size:** Keep it under 200 lines to save context window.

### 2. Rules (The "What")

Located in `.ai/src/rules/*.md`. These are **hard constraints** and **context** that must always be active.

- **Focus:** "Do this," "Don't do that," "Project structure is X."
- **Content:**
  - Naming conventions.
  - Architectural boundaries.
  - Forbidden patterns (e.g., "No `print` statements").
- **Constraints:**
  - **No Code Blocks:** Use pseudocode or short snippets if absolutely necessary. Logic belongs in Skills.
  - **Short:** < 50 lines per file.
  - **Modular:** One file per topic (e.g., `performance.md`, `testing.md`).

### 3. Skills (The "How")

Located in `.ai/src/skills/*/SKILL.md`. These are **on-demand recipes** that the agent loads when needed.

- **Focus:** "How to implement X," "How to run Y."
- **Content:**
  - Step-by-step instructions.
  - Full code templates.
  - Command-line examples.
- **Structure:**
  - Each skill is a folder: `.ai/src/skills/<skill-name>/`.
  - Main file: `SKILL.md` (Frontmatter + Markdown).
  - Can contain resource files (templates, scripts) in the folder.

## 🔄 The Sync System

The sync system ensures your `.ai/` configs are applied to all tools.

### Why Sync?

Different tools expect configs in different formats:

- **Cursor** wants individual `.mdc` files in `.cursor/rules/`.
- **Copilot** wants a single `.github/copilot-instructions.md`.
- **Claude** wants a `.claude/CLAUDE.md`.

Transitioning manually is error-prone. The sync script handles transformation and copying.

### How to Sync

Run the sync script from the repository root:

```bash
# Sync all tools
.ai/system/sync.sh

# Preview changes (Dry Run)
.ai/system/sync.sh --dry-run

# Sync specific tools only
.ai/system/sync.sh --only cursor,copilot
```

### 4. Clean Sync Workflow (Recommended)

To keep your repository clean and ensure everyone has the latest configs:

1.  **Setup (Once):**
    Run the setup script to install git hooks. This ensures `sync.sh` runs automatically on `git pull` or `checkout`.

    ```bash
    .ai/system/setup_hooks.sh
    ```

2.  **Gitignore:**
    The `.gitignore` is configured to exclude generated files (like `.cursor/rules/`) but allow manual configs (like `.cursor/settings.json`) to be committed.

3.  **Workflow:**
    - Edit files in `.ai/src/`.
    - Run `.ai/system/sync.sh` to test locally.
    - Commit changes to `.ai/src/`.
    - When teammates pull, their local tools update automatically.

### Manual Usage

If you don't use hooks, run the sync script manually after pulling changes:

```bash
.ai/system/sync.sh
```

### Manual vs Automated (CI/CD)

- **Recommended:** Use the Clean Sync Workflow above.
- **CI/CD:** Use `.ai/system/check.sh` in your CI pipeline to ensure everything is in sync.

For more details on the sync internals, see [.ai/system/README.md](system/README.md).
