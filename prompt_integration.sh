#!/bin/bash
# Shell prompt integration for goto
# Add this to your .bashrc or .zshrc

# Function to get current bookmark name
_get_bookmark_name() {
    local current_dir=$(pwd)
    local bookmark_file="${HOME}/.goto_bookmarks"
    
    if [ ! -f "$bookmark_file" ]; then
        return
    fi
    
    local line_num=0
    while IFS='|' read -r name path; do
        ((line_num++))
        if [ "$path" = "$current_dir" ]; then
            if [ -n "$name" ]; then
                echo "[$name]"
            else
                echo "[$line_num]"
            fi
            return
        fi
    done < "$bookmark_file"
}

# For bash users:
# Add this to your PS1:
# PS1='$(_get_bookmark_name)\u@\h:\w\$ '

# For zsh users:
# Enable prompt substitution and add to PROMPT:
# setopt PROMPT_SUBST
# PROMPT='$(_get_bookmark_name)%n@%m:%~%# '