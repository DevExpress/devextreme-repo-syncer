#!/bin/bash -e

echo "Syncer started";

STOP_REQUESTED=false
trap "STOP_REQUESTED=true" TERM INT

ITERATIONS_DONE=0

while true; do

    ITERATIONS_DONE=$((ITERATIONS_DONE + 1))
    if (( ITERATIONS_DONE > 5000 )); then
        echo "Recycling. Docker restart policy must restart the container!"
        exit 0
    fi

    for i in $(seq 1 10); do
        $STOP_REQUESTED || sleep 1
    done

    for branch in $(cat /repos/branches.txt); do

        if $STOP_REQUESTED; then
            echo "Terminating due to signal"
            exit 0
        fi

        echo "Syncing $branch -----------------------------------------"

        if [ ! -d "/repos/$branch/github/.git" ]; then
            echo "Missing github for branch $branch"
            break
        fi

        if [ ! -d "/repos/$branch/hg/.hg" ]; then
            echo "Missing hg for branch $branch"
            break
        fi

        cd /repos/$branch/github

        if ! git fetch --no-tags origin +refs/heads/$branch; then
            echo "Fetch failed"
            break
        fi

        git log --pretty=format:"%h %an - %s" HEAD..FETCH_HEAD > /repos/$branch/git-log
        if [ ! -s /repos/$branch/git-log ]; then
            echo "(empty log)" > /repos/$branch/git-log
        fi

        if ! git checkout -qf FETCH_HEAD; then
            echo "Checkout failed"
            break
        fi

        cd /repos/$branch/hg

        if [ -L .hg/wlock ]; then
            unlink .hg/wlock
            hg recover || true
        fi

        if ! { hg pull -r $branch && hg update -C $branch; }; then
            echo "Failed to update hg repo for $branch"
            break
        fi

        rm -rf GitHub
        rsync -a /repos/$branch/github/ /repos/$branch/hg/GitHub --exclude .git

        if hg addremove --similarity 60 && hg commit --encoding utf8 -l /repos/$branch/git-log; then
            while true; do
                hg push && break
                hg pull -r $branch && hg merge --tool 'internal:local' && hg commit -m "Auto-merge" || true
            done
        fi

    done

done
