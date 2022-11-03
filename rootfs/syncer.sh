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

        if ! [[ "$branch" =~ ^[1-9][0-9]_[1-9]$ ]]; then
            echo Unsupported branch name
            exit 1
        fi

        echo "Syncing $branch -----------------------------------------"

        hg_path=/repos/$branch/hg
        gh_path=/repos/$branch/github
        demos_on_github_path=/repos/$branch/demos-on-github
        dxvcs_path=/repos/$branch/dxvcs
        tools_github_path=/repos/$branch/tools-on-github

        tools_hg_path=$hg_path/Tools
        demos_on_github_hg_path=$hg_path/GitHub_Demos
        wg_external_path=$hg_path/Demos/WidgetsGallery/ExternalDemoSources
        data_portions_path=$hg_path/Tools/DevExpress.Data.Portions

        if [[ "$branch" > "20_1" ]]; then
            aspnetcore_shell_path=$hg_path/Demos/WidgetsGallery/AspNetCoreDemos.DemoShell
        else
            aspnetcore_shell_path=$hg_path/Demos/WidgetsGallery/WidgetsGallery.MVC/DevExtreme.NETCore.Demos
        fi

        if ! /hg-update.sh $hg_path $branch; then
            echo "Failed to update HG repo"
            break
        fi

        /git-update.sh $gh_path $branch $gh_path.log \
            && /rsync-multi.sh $gh_path $hg_path/GitHub / \
            && /hg-commit.sh $hg_path $gh_path.log \
            || echo "Sync failed: DevExtreme main repo"

        if [ -d "$dxvcs_path" ]; then
            /git-update.sh $dxvcs_path 20${branch/_/.} $dxvcs_path.log
            asp_demos_path=$dxvcs_path/Demos.ASP
            win_path=$dxvcs_path/Win

            if [ -d "$asp_demos_path" ]; then
                /rsync-multi.sh $asp_demos_path/AspNetCoreDemos.DemoShell $aspnetcore_shell_path DemoShell/ wwwroot/DemoShell/ .editorconfig
                /rsync-multi.sh $asp_demos_path $wg_external_path AspNetCoreDemos.Reporting/ AspNetCoreDemos.RichEdit/ AspNetCoreDemos.Spreadsheet/
                find $wg_external_path -type f -regextype posix-egrep -not -regex ".*(README|menuMeta\.json|DemosStyles.*css|DemosScripts.*js|\.(cs|cshtml|md))$" -delete
            fi

            if [ -d "$win_path" ]; then
                /rsync-multi.sh $win_path/DevExpress.Data/DevExpress.Data $data_portions_path AssemblyVersion.cs Utils/
            fi

            if [ -d $asp_demos_path ] || [ -d $win_path ]; then
                /hg-commit.sh $hg_path $dxvcs_path.log
            fi
        fi

        if [ -d $demos_on_github_path ]; then
            /git-update.sh $demos_on_github_path $branch $demos_on_github_path.log \
            && /rsync-multi.sh $demos_on_github_path $demos_on_github_hg_path / \
            && /hg-commit.sh $hg_path $demos_on_github_path.log \
            || echo "Sync failed: DevExtreme demos repo"
        fi

        if [ -d $tools_github_path ]; then
            /git-update.sh $tools_github_path $branch $tools_github_path.log \
            && /rsync-multi.sh $tools_github_path $tools_hg_path Declarations.json Descriptions.json \
            && /hg-commit.sh $hg_path $tools_github_path.log \
            || echo "Sync failed: devextreme-hgmirror-tools"
        fi

        if ! /hg-push.sh $hg_path $branch; then
            echo "Failed to push HG repo"
        fi
    done

done
