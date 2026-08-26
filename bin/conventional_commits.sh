#!/bin/bash
# Cache file for the last commit message
cache_file="${HOME}/.last_commit_msg"

# Function to extract the ticket from the current Git branch
get_ticket_from_branch () {
    local branch
    branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || {
        echo "Error: Not in a Git repository."
        exit 1
    }
    # Match ticket prefix and number (e.g., DPLAT-1234)
    if [[ $branch =~ ([a-zA-Z]+)-([0-9]+) ]]; then
        echo "${BASH_REMATCH[1]}-${BASH_REMATCH[2]}" | tr '[:lower:]' '[:upper:]'
    else
        echo "NOTICK"
    fi
}

# Function to capitalise the first character of a string (bash 3.2 compatible)
capitalise () {
    local str="$1"
    [[ -z $str ]] && return
    printf '%s%s' "$(printf '%s' "${str:0:1}" | tr '[:lower:]' '[:upper:]')" "${str:1}"
}

# Function to prompt the user to select a commit type
select_commit_type () {
    local commit_types=("feat" "fix" "chore" "docs" "style" "refactor" "test" "perf" "build")
    printf "%s\n" "${commit_types[@]}" | fzf --prompt="Select a commit type: "
}

# Function to resolve the scope. Prints "(TICKET)" or "" when there is no scope.
# The ticket is the scope: follow-up commits on a branch take none, so pass '-' to omit it.
resolve_scope () {
    local default_ticket ticket choice
    default_ticket=$(get_ticket_from_branch)

    if [[ $default_ticket == "NOTICK" ]]; then
        # Nothing to derive from the branch, so a blank answer is a real question
        echo "Enter scope / ticket ID, '-' for none: " >&2
        read ticket
        if [[ -z $ticket ]]; then
            choice=$(printf "%s\n" "NOTICK" "no scope" | fzf --prompt="No ticket in branch name. Scope: ")
            if [[ $choice == "NOTICK" ]]; then
                ticket="NOTICK"
            else
                ticket="-"
            fi
        fi
    else
        echo "Enter scope / ticket ID [${default_ticket}], '-' for none: " >&2
        read ticket
        ticket=${ticket:-$default_ticket}
    fi

    if [[ $ticket == "-" || $ticket == "none" ]]; then
        echo ""
    else
        echo "(${ticket})"
    fi
}

# Parse arguments
empty_flag=false
replay_flag=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -r|--replay)
            replay_flag=true
            shift
            ;;
        -e|--empty)
            empty_flag=true
            shift
            ;;
        *)
            echo "Unknown argument: $1"
            exit 1
            ;;
    esac
done

# Handle replay flag
if [[ $replay_flag == true ]]; then
    if [[ -f $cache_file ]]; then
        echo "Replaying cached commit message:"
        cat "$cache_file"
        git commit -m "$(cat "$cache_file")"
        exit 0
    else
        echo "No cached commit message found. Exiting."
        exit 1
    fi
fi

# Handle empty commit flag
if [[ $empty_flag == true ]]; then
    commit_scope=$(resolve_scope)

    # Format the empty commit message
    formatted_message="chore${commit_scope}: Empty commit to trigger CI"

    # Save the commit message to the cache
    echo "$formatted_message" > "$cache_file"

    # Create empty commit
    git commit --allow-empty -m "$formatted_message"
    exit 0
fi

# Regular commit flow continues here...
commit_type=$(select_commit_type || true)
if [[ -z $commit_type ]]; then
    echo "No commit type selected. Exiting."
    exit 1
fi

commit_scope=$(resolve_scope)

echo "Enter commit message: "
read commit_message

formatted_message="${commit_type}${commit_scope}: $(capitalise "$commit_message")"

echo "$formatted_message" > "$cache_file"

git commit -m "$formatted_message"
