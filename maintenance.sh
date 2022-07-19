#!/bin/bash

if docker exec syncer true; then
    echo Stop syncer before running this tool
    exit 1
fi


for p in `ls -d /var/lib/docker/volumes/repos/_data/??_?/*/.git`; do
    cd "$p/.."
    pwd

    # Clean branches
    for b in `git for-each-ref refs/heads/ --format='%(refname:short)'`; do
        git branch -D "$b"
    done

    git reflog expire --expire-unreachable=now --all
    git gc --prune=now

    echo " "
done
