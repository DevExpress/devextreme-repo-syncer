#!/bin/bash

REPO_PATH="$1"
BRANCH="$2"

if [ ! -d "$REPO_PATH" ] || [ -z "$BRANCH" ]; then
    echo "Usage: $0 REPO_PATH BRANCH"
    exit 1
fi

cd "$REPO_PATH"

if [ -L .hg/wlock ]; then
    unlink .hg/wlock
    hg recover
fi

hg pull -r $BRANCH && hg update -C $BRANCH
