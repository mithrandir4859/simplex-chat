set shell := ["bash", "-cu"]

# List available recipes
default:
    @just --list

claude-yolo:
    claude --dangerously-skip-permissions

# Pull with rebase; fails and aborts if rebase has conflicts
[no-cd]
pull:
    #!/usr/bin/env bash
    set -e
    if ! git pull --rebase; then
        git rebase --abort 2>/dev/null || true
        echo "Pull --rebase failed (e.g. conflicts). Rebase aborted. Fix conflicts or merge manually."
        exit 1
    fi
    echo "Pull --rebase done."

# Git push w/o "no upstream branch" bullshit with git pull --rebase first
[no-cd]
push-with-pull-rebase-first:
    #!/usr/bin/env bash
    set -e
    if ! git pull --rebase; then
        git rebase --abort 2>/dev/null || true
        echo "Pull --rebase failed; aborting. Push cancelled."
        exit 1
    fi
    git push --set-upstream origin $(git branch --show-current)

[no-cd]
commit-push-auto:
    #!/usr/bin/env bash
    dir="$(basename "$PWD")"
    echo "Committing and pushing $dir"
    git status
    git add .
    if git diff --cached --quiet; then
        echo "No changed files in $dir"
        exit 0
    fi
    git commit -m "Mystery commit"
    just push-with-pull-rebase-first
