#!/bin/bash

REPO_PATH="$1"
BRANCH="$2"

if [ ! -d "$REPO_PATH" ] || [ -z "$BRANCH" ]; then
    echo "Usage: $0 REPO_PATH BRANCH"
    exit 1
fi

cd "$REPO_PATH"

while true; do
    hg outgoing || exit 0
    hg push && break

    sleep 1
    hg pull -r $BRANCH && hg merge --tool 'internal:local' && hg commit -m "Auto-merge"
done
