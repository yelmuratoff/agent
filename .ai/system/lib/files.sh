#!/usr/bin/env bash
# File operation utilities for AI Sync Script
# Cross-platform compatible (Unix/macOS/Git Bash)

# Ensure directory exists
# Usage: ensure_dir "/path/to/dir"
ensure_dir() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
    fi
}

# Cleanup a file or directory if it exists
# Usage: cleanup_path "/path/to/target" "dry_run"
cleanup_path() {
    local target="$1"
    local dry_run="${2:-false}"
    
    if [[ -e "$target" ]]; then
        if [[ "$dry_run" == "true" ]]; then
            log_step "Would remove: $target (dry-run)"
        else
            rm -rf "$target"
            log_step "Removed: $target"
        fi
        return 0
    fi
    return 1
}

# Copy file with cleanup (rm + cp)
# Usage: copy_file "source" "dest" ["dry_run"]
copy_file() {
    local src="$1"
    local dest="$2"
    local dry_run="${3:-false}"
    
    if [[ ! -f "$src" ]]; then
        log_warning "Source file not found: $src"
        return 1
    fi
    
    if [[ "$dry_run" == "true" ]]; then
        log_step "$src → $dest (dry-run)"
        return 0
    fi
    
    # Ensure parent directory exists
    ensure_dir "$(dirname "$dest")"
    
    # Cleanup and copy
    rm -f "$dest" 2>/dev/null || true
    cp "$src" "$dest"
    
    log_step "$src → $dest"
}

# Copy directory recursively with cleanup (rm -rf + cp -r)
# Usage: copy_dir "source_dir" "dest_dir" ["dry_run"]
copy_dir() {
    local src="$1"
    local dest="$2"
    local dry_run="${3:-false}"
    
    if [[ ! -d "$src" ]]; then
        log_warning "Source directory not found: $src"
        return 1
    fi
    
    if [[ "$dry_run" == "true" ]]; then
        log_step "$src/ → $dest/ (dry-run)"
        return 0
    fi
    
    # Ensure parent directory exists
    ensure_dir "$(dirname "$dest")"
    
    # Cleanup and copy
    rm -rf "$dest" 2>/dev/null || true
    cp -r "$src" "$dest"
    
    log_step "$src/ → $dest/"
}

# Add header to file content
# Usage: add_header "file" "header_text"
add_header() {
    local file="$1"
    local header="$2"
    local temp_file
    
    if [[ ! -f "$file" ]]; then
        log_warning "File not found for header: $file"
        return 1
    fi
    
    # Create temp file in same directory for cross-platform compatibility
    temp_file="${file}.tmp"
    
    # Write header (interpret \n escape sequences) + newline + original content
    {
        printf '%b\n' "$header"
        echo ""
        cat "$file"
    } > "$temp_file"
    
    mv "$temp_file" "$file"
}

# Append imports to a file (for Claude)
# Usage: append_imports "agents_file" "rules_dir"
append_imports() {
    local agents_file="$1"
    local rules_dir="$2"
    
    if [[ ! -f "$agents_file" ]]; then
        log_warning "Agents file not found: $agents_file"
        return 1
    fi
    
    if [[ ! -d "$rules_dir" ]]; then
        log_warning "Rules directory not found for imports: $rules_dir"
        return 1
    fi
    
    # Append imports section
    {
        echo ""
        echo "<!-- Auto-generated imports -->"
        
        # Find all .md files in rules dir and create @rules/filename imports
        for rule_file in "$rules_dir"/*.md; do
            if [[ -f "$rule_file" ]]; then
                local basename
                basename=$(basename "$rule_file")
                echo "@rules/${basename}"
            fi
        done
    } >> "$agents_file"
}

# Copy rules with optional extension change and header
# Usage: copy_rules "src_dir" "dest_dir" "new_extension" "header" "dry_run"
# Pass empty string "" for new_extension or header to skip
copy_rules() {
    local src_dir="$1"
    local dest_dir="$2"
    local new_ext="$3"
    local header="$4"
    local dry_run="${5:-false}"
    local count=0
    
    if [[ ! -d "$src_dir" ]]; then
        log_warning "Rules source not found: $src_dir"
        return 1
    fi
    
    if [[ "$dry_run" == "true" ]]; then
        # Count files for dry-run output
        for src_file in "$src_dir"/*.md; do
            [[ -f "$src_file" ]] && ((count++)) || true
        done
        local extra=""
        [[ -n "$header" ]] && extra=", +header"
        log_step "$src_dir/ → $dest_dir/ ($count files${extra}) (dry-run)"
        return 0
    fi
    
    # Ensure destination exists
    rm -rf "$dest_dir" 2>/dev/null || true
    ensure_dir "$dest_dir"
    
    # Process each .md file
    for src_file in "$src_dir"/*.md; do
        [[ -f "$src_file" ]] || continue
        
        local basename
        basename=$(basename "$src_file")
        local dest_file
        
        # Handle extension change
        if [[ -n "$new_ext" ]]; then
            # Replace .md with new extension
            dest_file="${dest_dir}/${basename%.md}${new_ext}"
        else
            dest_file="${dest_dir}/${basename}"
        fi
        
        # Copy file
        cp "$src_file" "$dest_file"
        
        # Add header if specified
        if [[ -n "$header" ]]; then
            add_header "$dest_file" "$header"
        fi
        
        ((count++))
    done
    
    local extra=""
    [[ -n "$header" ]] && extra=", +header"
    log_step "$src_dir/ → $dest_dir/ ($count files${extra})"
}
