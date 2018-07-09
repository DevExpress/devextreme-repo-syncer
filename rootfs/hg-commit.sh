#!/bin/bash

REPO_PATH="$1"
MESSAGE_FILE="$2"

if [ ! -d "$REPO_PATH" ] || [ ! -f "$MESSAGE_FILE" ]; then
    echo "Usage: $0 REPO_PATH MESSAGE_FILE"
    exit 1
fi

cd "$REPO_PATH"

hg addremove --similarity 60
hg commit --encoding utf8 -l "$MESSAGE_FILE"

exit 0
