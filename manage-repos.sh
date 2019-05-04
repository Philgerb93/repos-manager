#!/bin/bash

github_user="Philgerb93"
repos=$(curl "https://api.github.com/users/$github_user/repos?per_page=100" -s | grep -o 'git@[^"]*' | cut -d '/' -f 2 | cut -d '.' -f 1)

red="\033[0;31m"
green="\033[0;32m"
yellow="\033[1;33m"
reset="\033[0m"

function rate_exceeded {
    err_msg=$(curl "https://api.github.com/users/$github_user/repos?per_page=100" -s | grep 'API rate limit exceeded')
    
    if [ -z "$1" ] && [ -n "$err_msg" ]; then
        return 0
    else
        return 1
    fi
}

function file_exists {
    if [ -d "../$1" ] && [ -e "../$1/.git" ]; then
        return 0
    else
        return 1
    fi
}

function test_project {
    if clean; then
        echo -e "${green}OK${reset}: Nothing to commit"
    else
        echo -e "${red}WARNING${reset}: Uncommitted changes detected"
    fi

    if up_to_date; then
        echo -e "${green}OK${reset}: Up to date"
    else
        echo -e "${red}WARNING${reset}: Behind repository, pull needed"
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
        echo -e "\n$repo: ${yellow}FOLDER FOUND${reset}"
        
        (
        cd "../$repo" || exit
        test_project
        )
    else
        echo -e "\n$repo: ${yellow}FOLDER MISSING${reset}"
        
        git clone "$repo_link" "../$repo"
        echo -e "Project has been cloned into parent directory."
    fi
done <<< "$repos"

echo -e "\nPress ENTER to exit."
read
