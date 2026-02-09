# AI Agent Configuration

`.ai/` is the single source of truth for all agent configs. Never edit tool directories directly.

## Structure

```
.ai/
├── AGENTS.md      # WHO: Identity, mindset, philosophy
├── rules/         # WHAT: Constraints, < 50 lines/file, no code
└── skills/        # HOW: Recipes with code, loaded on-demand
```

## AGENTS.md

Agent identity and philosophy. Highest priority, always active.

**Contains:** Mindset, approach, decision-making principles. Minimal code.  
**Size:** 100-200 lines

## Rules (`rules/*.md`)

Hard constraints. Always active, high priority.

**Contains:** Strict rules, restrictions, requirements. No code.  
**Size:** < 50 lines per file

For example:

```
rules/
├── core.md             # Generators, tests, security
├── architecture.md     # Layer separation
├── bloc.md             # Sealed classes, handleException
├── data-persistence.md # How to use Drift
├── logging.md          # Logger
├── analytics.md        # How to use analytics_gen
└── di.md               # How to use Scope widgets
```

## Skills (`skills/*/SKILL.md`)

Step-by-step recipes with code. Loaded when relevant.

**Contains:** Templates, commands, full code examples

For example:

```
skills/
├── analytics/SKILL.md
├── architecture/SKILL.md
├── bloc/SKILL.md
├── database/SKILL.md
├── di/SKILL.md
└── logging/SKILL.md
```

**Format:**

```markdown
---
name: skill-name
description: When to use.
---

# Title

## When to use

## Steps
```

## Sync

Apply changes to all tools:

```bash
.ai/sync/sync.sh              # Sync all
.ai/sync/sync.sh --dry-run    # Preview
.ai/sync/sync.sh --only X     # Specific tools
.ai/sync/sync.sh --help       # All options
```

See [sync/README.md](sync/README.md).

## Quick Reference

| Tier      | Purpose     | Size            | Code    | Priority  |
| --------- | ----------- | --------------- | ------- | --------- |
| AGENTS.md | Identity    | 100-200         | Minimal | Highest   |
| Rules     | Constraints | < 50 lines/file | None    | High      |
| Skills    | Recipes     | Unlimited       | Full    | On-demand |

## Guidelines

1. AGENTS.md — philosophy, not instructions
2. Rules — short, strict, no code
3. Skills — full code, templates
4. Don't duplicate between tiers
5. Update rules and related skills together
