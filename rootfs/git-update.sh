#!/bin/bash

REPO_PATH="$1"
BRANCH="$2"
LOG_PATH="$3"

if [ ! -d "$REPO_PATH" ] || [ -z "$BRANCH" ] || [ -z "$LOG_PATH" ]; then
    echo "Usage: $0 REPO_PATH BRANCH LOG_PATH"
    exit 1
fi

cd "$REPO_PATH"

if ! pidof git; then
    [ -f .git/index.lock ]   && unlink .git/index.lock
    [ -f .git/shallow.lock ] && unlink .git/shallow.lock
fi

echo "syncing $REPO_PATH $BRANCH $LOG_PATH"
remote_url=$(git remote -v | grep -Po '(?<=origin\s).*(?=\s\(fetch\))' | head -n 1)

if [ "$(git ls-remote --heads $remote_url $BRANCH | wc -l)" == "1" ]; then

    git fetch --update-head-ok --force --depth=100 --no-tags origin $BRANCH:$BRANCH || exit 1

    git log --pretty=format:"%h %an - %s" HEAD..FETCH_HEAD > "$LOG_PATH"
    if [ ! -s "$LOG_PATH" ]; then
        echo "(empty log)" > "$LOG_PATH"
    fi

    git checkout -qf FETCH_HEAD
else
    echo "The $BRANCH does not exist on $remote_url"
fi
