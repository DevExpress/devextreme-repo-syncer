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

        hg_path=/repos/$branch/hg
        gh_path=/repos/$branch/github
        asp_demos_path=/repos/$branch/asp-demos
        wg_external_path=$hg_path/Demos/WidgetsGallery/ExternalDemoSources

        if ! /hg-update.sh $hg_path $branch; then
            echo "Failed to update HG repo"
            break
        fi

        /git-update.sh $gh_path $branch $gh_path.log \
            && /rsync-multi.sh $gh_path $hg_path/GitHub / \
            && /hg-commit.sh $hg_path $gh_path.log \
            || echo "Sync from GitHub failed"

        if [ -d $asp_demos_path ]; then
            /git-update.sh $asp_demos_path 20${branch/_/.} $asp_demos_path.log \
                && /rsync-multi.sh $asp_demos_path/AspNetCoreDemos.DemoShell $hg_path/Demos/WidgetsGallery/WidgetsGallery.MVC/DevExtreme.NETCore.Demos DemoShell/ wwwroot/DemoShell/ .editorconfig \
                && /rsync-multi.sh $asp_demos_path $wg_external_path AspNetCoreDemos.Reporting/ AspNetCoreDemos.RichEdit/ AspNetCoreDemos.Spreadsheet/ \
                && find $wg_external_path -type f -regextype posix-egrep -not -regex ".*(README|menuMeta\.json|DemosStyles.*css|\.(js|cs|cshtml|md))$" -delete \
                && /hg-commit.sh $hg_path $asp_demos_path.log \
                || echo "Sync from ASP/Demos failed"
        fi

        if ! /hg-push.sh $hg_path $branch; then
            echo "Failed to push HG repo"
        fi
    done

done
