#!/bin/bash

REPO_PATH="$1"
BRANCH="$2"
LOG_PATH="$3"

if [ ! -d "$REPO_PATH" ] || [ -z "$BRANCH" ] || [ -z "$LOG_PATH" ]; then
    echo "Usage: $0 REPO_PATH BRANCH LOG_PATH"
    exit 1
fi

cd "$REPO_PATH"

if [ -f .git/index.lock ] && ! pidof git; then
    unlink .git/index.lock
fi

git fetch --force --depth=100 --no-tags origin $BRANCH:$BRANCH || exit 1

git log --pretty=format:"%h %an - %s" HEAD..FETCH_HEAD > "$LOG_PATH"
if [ ! -s "$LOG_PATH" ]; then
    echo "(empty log)" > "$LOG_PATH"
fi

git checkout -qf FETCH_HEAD
