#!/usr/bin/env bash
# chmod +x .ai/sync/sync.sh
# Cross-platform AgentSync Config Sync Script
# Works in Git Bash on Windows and Unix/macOS

set -euo pipefail

# Script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_ROOT="${AGENTSYNC_REPO_ROOT:-$DEFAULT_REPO_ROOT}"

if [[ ! -d "$REPO_ROOT" ]]; then
    echo "Error: Repository root not found: $REPO_ROOT" >&2
    exit 1
fi

REPO_ROOT="$(cd "$REPO_ROOT" && pwd)"

# Source helper libraries
# shellcheck source=lib/logging.sh
source "$SCRIPT_DIR/lib/logging.sh"
# shellcheck source=lib/files.sh
source "$SCRIPT_DIR/lib/files.sh"
# shellcheck source=lib/yaml.sh
source "$SCRIPT_DIR/lib/yaml.sh"
# shellcheck source=lib/gitignore.sh
source "$SCRIPT_DIR/lib/gitignore.sh"

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
AgentSync Config Sync Script

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
    local global_src_agents global_src_rules global_src_skills
    global_src_agents=$(parse_yaml_value "$global_config" "source.agents")
    global_src_rules=$(parse_yaml_value "$global_config" "source.rules")
    global_src_skills=$(parse_yaml_value "$global_config" "source.skills")
    
    # 1. AGENTS
    # Check for override
    local override_agents src_agents
    override_agents=$(parse_yaml_value "$tool_config" "targets.agents.source")
    src_agents="${override_agents:-$global_src_agents}"
    
    # Sync AGENTS.md
    if [[ -n "$dest_agents" ]]; then
        copy_file "$REPO_ROOT/$src_agents" "$REPO_ROOT/$dest_agents" "$DRY_RUN"
    fi
    
    # 2. RULES
    # Check for override
    local override_rules src_rules
    override_rules=$(parse_yaml_value "$tool_config" "targets.rules.source")
    src_rules="${override_rules:-$global_src_rules}"
    
    # Read optional rule transformations and filters
    local rule_ext rule_header append_imports rule_include rule_exclude
    rule_ext=$(parse_yaml_value "$tool_config" "targets.rules.extension") || true
    rule_header=$(parse_yaml_value "$tool_config" "targets.rules.header") || true
    append_imports=$(parse_yaml_value "$tool_config" "targets.rules.append_imports") || true
    rule_include=$(parse_yaml_value "$tool_config" "targets.rules.include") || true
    rule_exclude=$(parse_yaml_value "$tool_config" "targets.rules.exclude") || true
    
    # Sync rules
    if [[ -n "$dest_rules" ]]; then
        sync_rules "$REPO_ROOT/$src_rules" "$REPO_ROOT/$dest_rules" "$rule_ext" "$rule_header" "$DRY_RUN" "$rule_include" "$rule_exclude"
        
        # Handle Claude's import appending
        if [[ "$append_imports" == "true" ]] && [[ "$DRY_RUN" != "true" ]]; then
            # Note: Imports should technically only include filtered rules, but append_imports scans the DEST dir
            # so it naturally picks up only what was copied. Correct.
            append_imports "$REPO_ROOT/$dest_agents" "$REPO_ROOT/$dest_rules"
            log_step "Appended @rules imports to $dest_agents"
        fi
    fi
    
    # 3. SKILLS
    # Check for override
    local override_skills src_skills
    override_skills=$(parse_yaml_value "$tool_config" "targets.skills.source")
    src_skills="${override_skills:-$global_src_skills}"
    
    # Read skill filters
    local skills_include skills_exclude
    skills_include=$(parse_yaml_value "$tool_config" "targets.skills.include") || true
    skills_exclude=$(parse_yaml_value "$tool_config" "targets.skills.exclude") || true
    
    # Sync skills directory
    if [[ -n "$dest_skills" ]]; then
        sync_dir "$REPO_ROOT/$src_skills" "$REPO_ROOT/$dest_skills" "$DRY_RUN" "$skills_include" "$skills_exclude"
    fi
    
    # 4. POST_SYNC
    local post_sync_cmd
    post_sync_cmd=$(parse_yaml_value "$tool_config" "post_sync") || true
    
    if [[ -n "$post_sync_cmd" ]] && [[ "$DRY_RUN" != "true" ]]; then
        log_info "Running post-sync hook: $post_sync_cmd"
        # Eval command in repo root
        (cd "$REPO_ROOT" && eval "$post_sync_cmd") || log_warning "Post-sync hook failed"
    fi
     
    log_success "$tool_name complete"
    ((SYNCED_COUNT++)) || true
}

# Main entry point
main() {
    parse_args "$@"
    
    log_separator
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "Starting AgentSync Config Sync (DRY RUN)..."
    else
        log_info "Starting AgentSync Config Sync..."
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
    
    # Resolve tool configuration directory
    local tools_dir_rel tools_dir_abs
    tools_dir_rel=$(parse_yaml_value "$global_config" "source.tools") || true
    if [[ -z "$tools_dir_rel" ]]; then
        tools_dir_rel=".ai/system/tools"
        log_warning "source.tools is not set in config.yaml, falling back to $tools_dir_rel"
    fi
    tools_dir_abs="$REPO_ROOT/$tools_dir_rel"
    if [[ ! -d "$tools_dir_abs" ]]; then
        log_error "Tool config directory not found: $tools_dir_abs"
        exit 1
    fi

    # Process each tool config
    local generated_paths=""
    for tool_config in "$tools_dir_abs"/*.yaml; do
        [[ -f "$tool_config" ]] || continue
        ((TOTAL_COUNT++)) || true
        
        # Check enabled status for gitignore collection even if skipping sync (for dry-run accuracy we might need to think, 
        # but here we follow config truth)
        if parse_yaml_bool "$tool_config" "enabled"; then
             # Collect paths for gitignore
             local d_agents d_rules d_skills
             d_agents=$(parse_yaml_value "$tool_config" "targets.agents.dest")
             d_rules=$(parse_yaml_value "$tool_config" "targets.rules.dest")
             d_skills=$(parse_yaml_value "$tool_config" "targets.skills.dest")
             
             [[ -n "$d_agents" ]] && generated_paths="$generated_paths $d_agents"
             [[ -n "$d_rules" ]] && generated_paths="$generated_paths $d_rules/"
             [[ -n "$d_skills" ]] && generated_paths="$generated_paths $d_skills/"
        fi

        sync_tool "$tool_config"
        echo ""
    done
    
    # Update .gitignore if not dry-run
    if [[ "$DRY_RUN" != "true" ]]; then
        log_separator
        log_info "Updating .gitignore..."
        update_gitignore "$REPO_ROOT/.gitignore" "$generated_paths"
    fi
    
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
