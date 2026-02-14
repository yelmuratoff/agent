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

# Check if file matches include/exclude patterns
# Usage: matches_filter "filename" "include_glob" "exclude_glob"
matches_filter() {
    local filename="$1"
    local include="$2"
    local exclude="$3"
    
    # Default to match if no include pattern
    local matches_include=true
    if [[ -n "$include" ]]; then
        # Check against include pattern
        # shellcheck disable=SC2053
        if [[ $filename != $include ]]; then
            matches_include=false
        fi
    fi
    
    # Check exclude pattern
    if [[ -n "$exclude" ]]; then
        # shellcheck disable=SC2053
        if [[ $filename == $exclude ]]; then
            return 1 # Excluded
        fi
    fi
    
    if [[ "$matches_include" == "true" ]]; then
        return 0 # Matched
    else
        return 1 # Not matched
    fi
}

# Copy rules with optional extension change, header, and filtering
# Usage: copy_rules "src_dir" "dest_dir" "new_extension" "header" "dry_run" "include" "exclude"
# Pass empty string "" for optional args to skip
copy_rules() {
    local src_dir="$1"
    local dest_dir="$2"
    local new_ext="$3"
    local header="$4"
    local dry_run="${5:-false}"
    local include="${6:-}"
    local exclude="${7:-}"
    local count=0
    
    if [[ ! -d "$src_dir" ]]; then
        log_warning "Rules source not found: $src_dir"
        return 1
    fi
    
    # Prepare list of files to process (for counting in dry-run)
    local files_to_process=()
    for src_file in "$src_dir"/*.md; do
        [[ -f "$src_file" ]] || continue
        
        local basename
        basename=$(basename "$src_file")
        
        if matches_filter "$basename" "$include" "$exclude"; then
            files_to_process+=("$src_file")
        fi
    done
    
    if [[ "$dry_run" == "true" ]]; then
        local extra=""
        [[ -n "$header" ]] && extra="${extra}, +header"
        [[ -n "$include" ]] && extra="${extra}, include='$include'"
        [[ -n "$exclude" ]] && extra="${extra}, exclude='$exclude'"
        
        log_step "$src_dir/ → $dest_dir/ (${#files_to_process[@]} files${extra}) (dry-run)"
        return 0
    fi
    
    # Ensure destination exists
    # We don't wipe the whole directory if filtering is used, to allow mixing sources?
    # No, clean sync philosophy says we own the directory. Filtering is for what goes IN.
    # But if we have multiple sources filling one dir, full wipe hurts.
    # For now, stick to simple "wipe and fill" logic. if filtering reduces set, so be it.
    rm -rf "$dest_dir" 2>/dev/null || true
    ensure_dir "$dest_dir"
    
    # Process valid files
    for src_file in "${files_to_process[@]}"; do
        local basename
        basename=$(basename "$src_file")
        local dest_file
        
        # Handle extension change
        if [[ -n "$new_ext" ]]; then
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
    [[ -n "$header" ]] && extra="${extra}, +header"
    log_step "$src_dir/ → $dest_dir/ ($count files${extra})"
}
