# Directory bookmarking system
# Source this file in your .bashrc or .zshrc

# File to store bookmarks
GOTO_BOOKMARKS_FILE="${HOME}/.goto_bookmarks"

# Initialize bookmarks file if it doesn't exist
[ ! -f "$GOTO_BOOKMARKS_FILE" ] && touch "$GOTO_BOOKMARKS_FILE"

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
    
    # Return formatted line
    printf " %2d  %s  %s" "$index" "$formatted_name" "$display_path"
}

mk() {
    local name="$1"
    local current_dir=$(pwd)
    
    # Check if this directory is already bookmarked
    local existing_entry=""
    local line_num=0
    while IFS='|' read -r bookmark_name bookmark_path; do
        ((line_num++))
        if [ "$bookmark_path" = "$current_dir" ]; then
            if [ -n "$bookmark_name" ]; then
                existing_entry="$line_num) $bookmark_name $bookmark_path"
            else
                existing_entry="$line_num) $bookmark_path"
            fi
            break
        fi
    done < "$GOTO_BOOKMARKS_FILE"
    
    if [ -n "$existing_entry" ]; then
        echo "Already bookmarked: $existing_entry"
        return
    fi
    
    # If no name provided, just save the path
    if [ -z "$name" ]; then
        echo "|$current_dir" >> "$GOTO_BOOKMARKS_FILE"
        echo "✓ Marked"
    else
        # Check if name already exists and update it
        if grep -q "^${name}|" "$GOTO_BOOKMARKS_FILE"; then
            # Update existing bookmark
            local temp_file=$(mktemp)
            grep -v "^${name}|" "$GOTO_BOOKMARKS_FILE" > "$temp_file"
            echo "${name}|${current_dir}" >> "$temp_file"
            \mv "$temp_file" "$GOTO_BOOKMARKS_FILE"
            echo "✓ Updated '$name'"
        else
            # Add new bookmark
            echo "${name}|${current_dir}" >> "$GOTO_BOOKMARKS_FILE"
            echo "✓ Marked '$name'"
        fi
    fi
}

gt() {
    local target="$1"
    
    if [ -z "$target" ]; then
        if [ ! -s "$GOTO_BOOKMARKS_FILE" ]; then
            echo "No bookmarks saved."
            return
        fi
        
        local index=1
        while IFS='|' read -r bookmark_name bookmark_path; do
            _format_bookmark "$index" "$bookmark_name" "$bookmark_path"
            echo
            ((index++))
        done < "$GOTO_BOOKMARKS_FILE"
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
        if [ -d "$bookmark_path" ]; then
            cd "$bookmark_path"
            pwd
        else
            echo "Path not found"
            return 1
        fi
    else
        # Target is a name
        local line=$(grep "^${target}|" "$GOTO_BOOKMARKS_FILE")
        if [ -z "$line" ]; then
            echo "Unknown bookmark"
            return 1
        fi
        local bookmark_path=$(echo "$line" | cut -d'|' -f2)
        if [ -d "$bookmark_path" ]; then
            cd "$bookmark_path"
            pwd
        else
            echo "Path not found"
            return 1
        fi
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
}

# Clear all bookmarks (shortened)
mkc() {
    echo -n "Clear all bookmarks? (y/N) "
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        > "$GOTO_BOOKMARKS_FILE"
        echo "✓ Cleared"
    else
        echo "Cancelled"
    fi
}

# Shortcut to list bookmarks
ml() {
    gt
}

# Auto-completion for gt (if using bash)
if [ -n "$BASH_VERSION" ]; then
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
    compdef _gt gt
    compdef _gt mkr
fi