#!/bin/bash

github_user="Philgerb93"
repos=$(curl "https://api.github.com/users/$github_user/repos?per_page=100" -s | grep -o 'git@[^"]*' | cut -d '/' -f 2 | cut -d '.' -f 1)

function rate_exceeded {
    err_msg=$(curl "https://api.github.com/users/$github_user/repos?per_page=100" -s | grep 'API rate limit exceeded')
    
    if [ -z "$1" ] && [ -n "$err_msg" ]; then
        return 0
    else
        return 1
    fi
}

function file_exists {
    if [ -d "$1" ] && [ -e "$1/.git" ]; then
        return 0
    else
        return 1
    fi
}

function test_project {
    if clean; then
        echo "OK: Nothing to commit"
    else
        echo "WARNING: Uncommitted changes detected"
    fi

    if up_to_date; then
        echo "OK: Up to date"
    else
        echo "WARNING: Behind repository, pull needed"
    fi
}

function clean {
    git diff-index --quiet HEAD
    return "$?"
}

function up_to_date {
    git ls-remote origin -h refs/heads/master >& /dev/null
    return "$?"
}

if rate_exceeded "$repos"; then
    echo "You exceeded Github's rate limit. Try again later."
    exit
fi

while read -r repo; do
    repo_link="https://github.com/$github_user/$repo"

    if file_exists "$repo"; then
        echo -e "\n$repo: FOLDER FOUND"
        
        (
        cd "$repo" || exit
        test_project
        )
    else
        echo -e "\n$repo: FOLDER MISSING"
        
        git clone "$repo_link"
        echo -e "Project has been cloned into current directory."
    fi
done <<< "$repos"
