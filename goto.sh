# Directory bookmarking system
# Source this file in your .bashrc or .zshrc

# Clean up any existing functions before redefining
unset -f mk gt g1 g2 g3 g4 g5 g6 g7 g8 g9 g10 g11 g12 g13 g14 g15 mkr mkc mkclean ml _update_bookmark_vars _format_bookmark _variable_exists _goto_bookmark_path 2>/dev/null || true

# File to store bookmarks
GOTO_BOOKMARKS_FILE="${HOME}/.goto_bookmarks"

# Initialize bookmarks file if it doesn't exist
[ ! -f "$GOTO_BOOKMARKS_FILE" ] && touch "$GOTO_BOOKMARKS_FILE"

# Function to update bookmark variables
_update_bookmark_vars() {
    # Clear existing numbered variables
    for i in {1..15}; do
        unset g$i 2>/dev/null || true
    done
    
    # Clear existing named variables (we'll track them)
    if [ -n "$_GOTO_NAMED_VARS" ]; then
        # Split the variable names and unset each one individually
        echo "$_GOTO_NAMED_VARS" | tr ' ' '\n' | while read -r var; do
            [ -n "$var" ] && unset "$var" 2>/dev/null || true
        done
    fi
    _GOTO_NAMED_VARS=""
    
    # Set new variables
    local count=1
    while IFS='|' read -r name bookmark_path && [ $count -le 15 ]; do
        if [ -n "$bookmark_path" ]; then
            # Export numbered variable
            eval "export g$count=\"$bookmark_path\""
            
            # Export named variable if name exists
            if [ -n "$name" ]; then
                # Check if this is a variable we created vs an external one
                local is_our_var=0
                case " $_GOTO_NAMED_VARS " in
                    *" $name "*) is_our_var=1 ;;
                esac
                
                if [ $is_our_var -eq 1 ]; then
                    # This is our variable, always update it
                    eval "export $name=\"$bookmark_path\""
                    _GOTO_NAMED_VARS="$_GOTO_NAMED_VARS $name"
                else
                    # Check if variable exists and would conflict with external variable
                    if _variable_exists "$name"; then
                        echo "Warning: Bookmark '$name' would override existing variable \$$name, skipping named export" >&2
                    else
                        # Set and export the variable
                        eval "export $name=\"$bookmark_path\""
                        _GOTO_NAMED_VARS="$_GOTO_NAMED_VARS $name"
                    fi
                fi
            fi
        fi
        ((count++))
    done < "$GOTO_BOOKMARKS_FILE"
}

# Helper function to check if a variable exists in the current shell
_variable_exists() {
    local name="$1"
    if [ -n "$BASH_VERSION" ]; then
        [ -n "${!name+x}" ]
    elif [ -n "$ZSH_VERSION" ]; then
        (( ${+parameters[$name]} ))
    else
        false
    fi
}

# Helper function to navigate to a bookmark path
_goto_bookmark_path() {
    local bookmark_path="$1"
    local target="$2"
    
    if [ -d "$bookmark_path" ]; then
        cd "$bookmark_path"
        pwd
        return 0
    else
        echo "Path not found: $bookmark_path"
        echo "Use 'mkr $target' to remove this bookmark"
        return 1
    fi
}

# Update variables on sourcing
_update_bookmark_vars

# Format bookmark display line
_format_bookmark() {
    local index="$1"
    local name="$2"
    local path="$3"
    
    # Replace home directory with ~
    local display_path="${path/#$HOME/~}"
    local display_name="${name:----------}"
    
    # Format name to be exactly 10 characters (pad or truncate)
    local formatted_name=$(printf "%-10.10s" "$display_name")
    
    # Check if path exists and add indicator
    local path_status=""
    if [ ! -d "$path" ]; then
        path_status=" [missing]"
    fi
    
    # Return formatted line with fixed-width columns
    printf " %2d  %-12s %-30s%s" "$index" "$formatted_name" "$display_path" "$path_status"
}

mk() {
    local name="$1"
    local current_dir=$(pwd)
    
    # Check if this directory is already bookmarked
    local existing_line_num=0
    local existing_name=""
    local line_num=0
    while IFS='|' read -r bookmark_name bookmark_path; do
        ((line_num++))
        if [ "$bookmark_path" = "$current_dir" ]; then
            existing_line_num=$line_num
            existing_name="$bookmark_name"
            break
        fi
    done < "$GOTO_BOOKMARKS_FILE"
    
    if [ $existing_line_num -gt 0 ]; then
        # Directory already bookmarked
        if [ -n "$name" ]; then
            # Update the existing bookmark with new name
            local temp_file=$(mktemp)
            awk -v line="$existing_line_num" -v new_name="$name" -v path="$current_dir" '
                NR == line { print new_name "|" path; next }
                { print }
            ' "$GOTO_BOOKMARKS_FILE" > "$temp_file"
            \mv "$temp_file" "$GOTO_BOOKMARKS_FILE"
            echo "✓ Updated bookmark name to '$name'"
            _update_bookmark_vars
            return
        else
            # No new name provided, just inform about existing bookmark
            if [ -n "$existing_name" ]; then
                echo "Already bookmarked: $existing_line_num) $existing_name $current_dir"
            else
                echo "Already bookmarked: $existing_line_num) $current_dir"
            fi
            return
        fi
    fi
    
    # If no name provided, just save the path
    if [ -z "$name" ]; then
        echo "|$current_dir" >> "$GOTO_BOOKMARKS_FILE"
        echo "✓ Marked"
    else
        # Check if name already exists and update it
        if grep -q "^${name}|" "$GOTO_BOOKMARKS_FILE"; then
            # Update existing bookmark - remove ALL instances of this name first
            local temp_file=$(mktemp)
            local old_path=$(grep "^${name}|" "$GOTO_BOOKMARKS_FILE" | head -1 | cut -d'|' -f2)
            grep -v "^${name}|" "$GOTO_BOOKMARKS_FILE" > "$temp_file"
            echo "${name}|${current_dir}" >> "$temp_file"
            \mv "$temp_file" "$GOTO_BOOKMARKS_FILE"
            if [ "$old_path" != "$current_dir" ]; then
                echo "✓ Updated '$name' (was: $old_path)"
            else
                echo "✓ Updated '$name'"
            fi
        else
            # Add new bookmark
            echo "${name}|${current_dir}" >> "$GOTO_BOOKMARKS_FILE"
            echo "✓ Marked '$name'"
        fi
    fi
    
    # Update bookmark variables
    _update_bookmark_vars
}

gt() {
    local target="$1"
    
    if [ -z "$target" ]; then
        if [ ! -s "$GOTO_BOOKMARKS_FILE" ]; then
            echo "No bookmarks saved."
            echo ""
            echo "Commands:"
            echo "  mk [name]     - bookmark current directory"
            echo "  gt [n|name]   - go to bookmark (or list all)"
            echo "  mkr [n|name]  - remove bookmark"
            echo "  mkc           - clear all bookmarks"
            echo "  mkclean       - remove non-existing paths"
            return
        fi
        
        local index=1
        while IFS='|' read -r bookmark_name bookmark_path; do
            _format_bookmark "$index" "$bookmark_name" "$bookmark_path"
            echo
            ((index++))
        done < "$GOTO_BOOKMARKS_FILE"
        
        echo ""
        echo "Commands: mk [name] | gt [n|name] | mkr [n|name] | mkc | mkclean"
        return 0
    fi
    
    if [ ! -s "$GOTO_BOOKMARKS_FILE" ]; then
        echo "No bookmarks"
        return 1
    fi
    
    # Check if target is a number
    if [[ "$target" =~ ^[0-9]+$ ]]; then
        local line=$(sed -n "${target}p" "$GOTO_BOOKMARKS_FILE")
        if [ -z "$line" ]; then
            echo "Invalid bookmark"
            return 1
        fi
        local bookmark_path=$(echo "$line" | cut -d'|' -f2)
        _goto_bookmark_path "$bookmark_path" "$target"
    else
        # Target is a name
        local line=$(grep "^${target}|" "$GOTO_BOOKMARKS_FILE")
        if [ -z "$line" ]; then
            echo "Unknown bookmark"
            return 1
        fi
        local bookmark_path=$(echo "$line" | cut -d'|' -f2)
        _goto_bookmark_path "$bookmark_path" "$target"
    fi
}

# Quick number shortcuts for common bookmarks
g1() { gt 1; }
g2() { gt 2; }
g3() { gt 3; }
g4() { gt 4; }
g5() { gt 5; }
g6() { gt 6; }
g7() { gt 7; }
g8() { gt 8; }
g9() { gt 9; }
g10() { gt 10; }
g11() { gt 11; }
g12() { gt 12; }
g13() { gt 13; }
g14() { gt 14; }
g15() { gt 15; }

# Remove a bookmark by number or name (shortened)
mkr() {
    local target="$1"
    
    if [ -z "$target" ]; then
        echo "Usage: mkr <number|name>"
        return 1
    fi
    
    if [[ "$target" =~ ^[0-9]+$ ]]; then
        # Remove by index
        local temp_file=$(mktemp)
        awk "NR != $target" "$GOTO_BOOKMARKS_FILE" > "$temp_file"
        \mv "$temp_file" "$GOTO_BOOKMARKS_FILE"
        echo "✓ Removed"
    else
        # Remove by name
        local temp_file=$(mktemp)
        grep -v "^${target}|" "$GOTO_BOOKMARKS_FILE" > "$temp_file"
        \mv "$temp_file" "$GOTO_BOOKMARKS_FILE"
        echo "✓ Removed"
    fi
    
    # Update bookmark variables
    _update_bookmark_vars
}

# Clear all bookmarks (shortened)
mkc() {
    echo -n "Clear all bookmarks? (y/N) "
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        > "$GOTO_BOOKMARKS_FILE"
        echo "✓ Cleared"
        # Update bookmark variables
        _update_bookmark_vars
    else
        echo "Cancelled"
    fi
}

# Clean up stale bookmarks (remove non-existing paths)
mkclean() {
    local temp_file=$(mktemp)
    local removed_count=0
    local kept_count=0
    
    while IFS='|' read -r bookmark_name bookmark_path; do
        if [ -d "$bookmark_path" ]; then
            echo "${bookmark_name}|${bookmark_path}" >> "$temp_file"
            ((kept_count++))
        else
            echo "Removing: ${bookmark_name:-[unnamed]} -> $bookmark_path"
            ((removed_count++))
        fi
    done < "$GOTO_BOOKMARKS_FILE"
    
    if [ $removed_count -gt 0 ]; then
        \mv "$temp_file" "$GOTO_BOOKMARKS_FILE"
        echo "✓ Removed $removed_count stale bookmark(s), kept $kept_count"
        _update_bookmark_vars
    else
        rm "$temp_file"
        echo "All bookmarks are valid"
    fi
}

# Shortcut to list bookmarks
ml() {
    gt
}

# Auto-completion for gt (if using bash)
if [ -n "$BASH_VERSION" ]; then
    # Remove old completions if they exist
    complete -r gt 2>/dev/null || true
    complete -r mkr 2>/dev/null || true
    
    _gt_completions() {
        local cur="${COMP_WORDS[COMP_CWORD]}"
        local IFS=$'\n'
        
        if [ -f "$GOTO_BOOKMARKS_FILE" ]; then
            # If we're still typing, show all options
            if [ -n "$cur" ]; then
                local bookmarks=""
                local names=$(cut -d'|' -f1 "$GOTO_BOOKMARKS_FILE" | grep -v '^$')
                local count=$(wc -l < "$GOTO_BOOKMARKS_FILE")
                
                # Add numbers
                for i in $(seq 1 $count); do
                    bookmarks="$bookmarks $i"
                done
                
                # Add names
                bookmarks="$bookmarks $names"
                
                COMPREPLY=($(compgen -W "$bookmarks" -- "$cur"))
            else
                # Show formatted list when no input yet
                local count=1
                local displays=()
                
                while IFS='|' read -r bname bpath; do
                    local formatted=$(_format_bookmark "$count" "$bname" "$bpath")
                    displays+=("$formatted")
                    ((count++))
                done < "$GOTO_BOOKMARKS_FILE"
                
                # Display the formatted list
                printf '\n'
                printf '%s\n' "${displays[@]}"
                printf '\n%s' "${PS1@P}gt "
                
                # Set up completion candidates
                local candidates=()
                for i in $(seq 1 $((count-1))); do
                    candidates+=("$i")
                done
                
                # Add names
                local names=$(cut -d'|' -f1 "$GOTO_BOOKMARKS_FILE" | grep -v '^$')
                [ -n "$names" ] && candidates+=($names)
                
                COMPREPLY=($(compgen -W "${candidates[*]}" -- ""))
            fi
        fi
    }
    complete -F _gt_completions gt
    complete -F _gt_completions mkr
fi

# ZSH completion
if [ -n "$ZSH_VERSION" ]; then
    # Unregister old completions if they exist
    compdef -d gt 2>/dev/null || true
    compdef -d mkr 2>/dev/null || true
    
    _gt() {
        local goto_file="${HOME}/.goto_bookmarks"
        if [ -f "$goto_file" ]; then
            local count=1
            local -a displays nums names
            while IFS='|' read -r bname bpath; do
                # Build arrays for completion
                displays+=("$(_format_bookmark "$count" "$bname" "$bpath")")
                nums+=("$count")
                
                # If there's a name, save it
                if [ -n "$bname" ]; then
                    names+=("$bname")
                fi
                
                ((count++))
            done < "$goto_file"
            
            # Add numbered completions with descriptions
            compadd -ld displays -a nums
            
            # Add name completions (hidden)
            [ ${#names[@]} -gt 0 ] && compadd -Q -n -a names
        fi
    }
    
    # Set up completion - handle both cases where compinit may or may not have been called
    if (( $+functions[compdef] )); then
        compdef _gt gt
        compdef _gt mkr
    else
        # If compinit hasn't been called yet, set up autoload
        autoload -U compinit && compinit
        compdef _gt gt
        compdef _gt mkr
    fi
fi
