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

# Function to prompt the user to select a commit type
select_commit_type () {
    local commit_types=("feat" "fix" "chore" "docs" "style" "refactor" "test" "perf" "build")
    printf "%s\n" "${commit_types[@]}" | fzf --prompt="Select a commit type: "
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
    # Get ticket number
    default_ticket=$(get_ticket_from_branch)
    echo "Enter ticket ID [${default_ticket}]: "
    read ticket
    ticket=${ticket:-$default_ticket}

    # Format the empty commit message
    formatted_message="chore: [${ticket}] empty commit to trigger CI"

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

echo "Enter commit scope [none]: "
read commit_scope
[[ -n $commit_scope ]] && commit_scope="(${commit_scope})"

default_ticket=$(get_ticket_from_branch)
echo "Enter ticket ID [${default_ticket}]: "
read ticket
ticket=${ticket:-$default_ticket}

echo "Enter commit message: "
read commit_message

formatted_message="${commit_type}${commit_scope}: [${ticket}] ${commit_message}"

echo "$formatted_message" > "$cache_file"

git commit -m "$formatted_message"
