#!/usr/bin/env bash
# Check if AgentSync configs are in sync with source
# Usage: .ai/sync/check.sh
# Exit code: 0 if synced, 1 if changes needed

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_ROOT="${AGENTSYNC_REPO_ROOT:-$DEFAULT_REPO_ROOT}"

if [[ ! -d "$REPO_ROOT" ]]; then
    echo "Error: Repository root not found: $REPO_ROOT" >&2
    exit 1
fi

REPO_ROOT="$(cd "$REPO_ROOT" && pwd)"

# Run sync in dry-run mode and check output
# We can't rely just on dry-run exit code as it always returns 0
# We need to run actual sync to a temp dir or check timestamps/checksums.
# A simpler approach: Run sync and check git status.

# If we are in CI, we assume clean state. 
# Optimized approach:
# 1. Capture current status of target files (checksums)
# 2. Run sync
# 3. Check if any target files changed

echo "Checking AgentSync configuration synchronization..."

# Ensure we are executable
chmod +x "$SCRIPT_DIR/sync.sh"

# Run sync
if ! "$SCRIPT_DIR/sync.sh"; then
    echo "❌ Sync script failed to run"
    exit 1
fi

# Check for git changes in target directories
# Define targets based on enabled tools (hardcoded list of potential targets to check)
TARGETS=(
    ".github/copilot-instructions.md"
    ".github/instructions"
    ".github/skills"
    ".cursor/AGENTS.md"
    ".cursor/rules"
    ".cursor/skills"
    ".claude/CLAUDE.md"
    ".claude/rules"
    ".claude/skills"
    ".agent/AGENTS.md"
    ".agent/rules"
    ".agent/skills"
    ".gemini/GEMINI.md"
    ".gemini/prompts"
    ".gemini/skills"
)

CHANGED=0
for target in "${TARGETS[@]}"; do
    if git status --porcelain "$target" | grep -q .; then
        echo "❌ Out of sync: $target"
        CHANGED=1
    fi
done

if [[ $CHANGED -eq 1 ]]; then
    echo ""
    echo "⚠️  AgentSync configurations are out of sync with .ai/ source."
    echo "Please run: .ai/sync/sync.sh"
    exit 1
else
    echo "✅ AgentSync configurations are safe and synced."
    exit 0
fi
