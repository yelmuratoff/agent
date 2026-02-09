#!/usr/bin/env bash
# chmod +x .ai/sync/sync.sh
# Cross-platform AI Agent Config Sync Script
# Works in Git Bash on Windows and Unix/macOS

set -euo pipefail

# Script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source helper libraries
# shellcheck source=lib/logging.sh
source "$SCRIPT_DIR/lib/logging.sh"
# shellcheck source=lib/files.sh
source "$SCRIPT_DIR/lib/files.sh"
# shellcheck source=lib/yaml.sh
source "$SCRIPT_DIR/lib/yaml.sh"

# Global variables
DRY_RUN="false"
ONLY_TOOLS=""
SKIP_TOOLS=""
SYNCED_COUNT=0
SKIPPED_COUNT=0
TOTAL_COUNT=0

# Usage information
usage() {
    cat << EOF
AI Agent Config Sync Script

Usage: $(basename "$0") [OPTIONS]

Options:
  --only <tools>    Sync only specified tools (comma-separated)
                    Example: --only copilot,cursor
  --skip <tools>    Skip specified tools (comma-separated)
                    Example: --skip gemini,codex
  --dry-run         Show what would be copied without making changes
  --help            Show this help message

Examples:
  $(basename "$0")                       # Sync all enabled tools
  $(basename "$0") --only copilot,cursor # Sync only Copilot and Cursor
  $(basename "$0") --skip gemini         # Sync all except Gemini
  $(basename "$0") --dry-run             # Preview changes without applying
EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --only)
                ONLY_TOOLS="$2"
                shift 2
                ;;
            --skip)
                SKIP_TOOLS="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN="true"
                shift
                ;;
            --help|-h)
                usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
}

# Check if tool should be synced based on CLI filters
should_sync_tool() {
    local tool_name="$1"
    
    # Check --only filter
    if [[ -n "$ONLY_TOOLS" ]]; then
        if [[ ! ",$ONLY_TOOLS," == *",$tool_name,"* ]]; then
            return 1
        fi
    fi
    
    # Check --skip filter
    if [[ -n "$SKIP_TOOLS" ]]; then
        if [[ ",$SKIP_TOOLS," == *",$tool_name,"* ]]; then
            return 1
        fi
    fi
    
    return 0
}

# Sync a single tool based on its YAML config
sync_tool() {
    local tool_config="$1"
    local tool_basename
    tool_basename=$(basename "$tool_config" .yaml)
    
    # Read tool configuration
    local tool_name
    tool_name=$(parse_yaml_value "$tool_config" "name")
    [[ -z "$tool_name" ]] && tool_name="$tool_basename"
    
    # Read target destinations (once, reused for both cleanup and sync)
    local dest_agents dest_rules dest_skills
    dest_agents=$(parse_yaml_value "$tool_config" "targets.agents.dest")
    dest_rules=$(parse_yaml_value "$tool_config" "targets.rules.dest")
    dest_skills=$(parse_yaml_value "$tool_config" "targets.skills.dest")
    
    # Check if tool is enabled in config
    if ! parse_yaml_bool "$tool_config" "enabled"; then
        # Cleanup disabled tool directories
        local cleaned=false
        [[ -n "$dest_agents" ]] && cleanup_path "$REPO_ROOT/$dest_agents" "$DRY_RUN" && cleaned=true
        [[ -n "$dest_rules" ]] && cleanup_path "$REPO_ROOT/$dest_rules" "$DRY_RUN" && cleaned=true
        [[ -n "$dest_skills" ]] && cleanup_path "$REPO_ROOT/$dest_skills" "$DRY_RUN" && cleaned=true
        
        if [[ "$cleaned" == "true" ]]; then
            log_info "Cleaned up $tool_name (disabled)"
        else
            log_info "Skipping $tool_name (disabled in config)"
        fi
        ((SKIPPED_COUNT++)) || true
        return 0
    fi
    
    # Check CLI filters
    if ! should_sync_tool "$tool_basename"; then
        log_info "Skipping $tool_name (filtered by CLI)"
        ((SKIPPED_COUNT++)) || true
        return 0
    fi
    
    log_info "Syncing $tool_name..."
    
    # Load global config paths
    local global_config="$SCRIPT_DIR/config.yaml"
    local src_agents src_rules src_skills
    src_agents=$(parse_yaml_value "$global_config" "source.agents")
    src_rules=$(parse_yaml_value "$global_config" "source.rules")
    src_skills=$(parse_yaml_value "$global_config" "source.skills")
    
    # Read optional rule transformations
    local rule_ext rule_header append_imports
    rule_ext=$(parse_yaml_value "$tool_config" "targets.rules.extension") || true
    rule_header=$(parse_yaml_value "$tool_config" "targets.rules.header") || true
    append_imports=$(parse_yaml_value "$tool_config" "targets.rules.append_imports") || true
    
    # Sync AGENTS.md
    if [[ -n "$dest_agents" ]]; then
        copy_file "$REPO_ROOT/$src_agents" "$REPO_ROOT/$dest_agents" "$DRY_RUN"
    fi
    
    # Sync rules
    if [[ -n "$dest_rules" ]]; then
        copy_rules "$REPO_ROOT/$src_rules" "$REPO_ROOT/$dest_rules" "$rule_ext" "$rule_header" "$DRY_RUN"
        
        # Handle Claude's import appending
        if [[ "$append_imports" == "true" ]] && [[ "$DRY_RUN" != "true" ]]; then
            append_imports "$REPO_ROOT/$dest_agents" "$REPO_ROOT/$dest_rules"
            log_step "Appended @rules imports to $dest_agents"
        fi
    fi
    
    # Sync skills directory
    if [[ -n "$dest_skills" ]]; then
        copy_dir "$REPO_ROOT/$src_skills" "$REPO_ROOT/$dest_skills" "$DRY_RUN"
    fi
    
    log_success "$tool_name complete"
    ((SYNCED_COUNT++)) || true
}

# Main entry point
main() {
    parse_args "$@"
    
    log_separator
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "Starting AI Agent Config Sync (DRY RUN)..."
    else
        log_info "Starting AI Agent Config Sync..."
    fi
    log_separator
    echo ""
    
    # Verify source exists
    local global_config="$SCRIPT_DIR/config.yaml"
    if [[ ! -f "$global_config" ]]; then
        log_error "Global config not found: $global_config"
        exit 1
    fi
    
    local src_agents
    src_agents=$(parse_yaml_value "$global_config" "source.agents")
    if [[ ! -f "$REPO_ROOT/$src_agents" ]]; then
        log_error "Source AGENTS.md not found: $REPO_ROOT/$src_agents"
        exit 1
    fi
    
    # Process each tool config
    for tool_config in "$SCRIPT_DIR/tools"/*.yaml; do
        [[ -f "$tool_config" ]] || continue
        ((TOTAL_COUNT++)) || true
        sync_tool "$tool_config"
        echo ""
    done
    
    # Print summary
    log_separator
    local summary="Synced $SYNCED_COUNT/$TOTAL_COUNT tools"
    if [[ $SKIPPED_COUNT -gt 0 ]]; then
        summary="$summary ($SKIPPED_COUNT skipped)"
    fi
    if [[ "$DRY_RUN" == "true" ]]; then
        summary="$summary (dry-run)"
    fi
    log_done "$summary"
    log_separator
}

main "$@"
