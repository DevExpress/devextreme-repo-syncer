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
        aspnet_github_path=/repos/$branch/aspnet
        aspnet_github_demos_path=$aspnet_github_path/Demos

        demos_on_github_hg_path=$hg_path/GitHub_Demos
        wg_external_path=$hg_path/Demos/WidgetsGallery/ExternalDemoSources
        data_portions_path=$hg_path/Tools/DevExpress.Data.Portions

        aspnetcore_shell_path=$hg_path/Demos/WidgetsGallery/AspNetCoreDemos.DemoShell

        if ! /hg-update.sh $hg_path $branch; then
            echo "Failed to update HG repo"
            break
        fi

        /git-update.sh $gh_path $branch $gh_path.log \
            && /rsync-multi.sh $gh_path $hg_path/GitHub / \
            && /hg-commit.sh $hg_path $gh_path.log \
            || echo "Sync failed: DevExtreme main repo"

        if [[ -d "$dxvcs_path" && "$branch" < "24_2" ]]; then
            /git-update.sh $dxvcs_path 20${branch/_/.} $dxvcs_path.log
            asp_demos_path=$dxvcs_path/Demos.ASP
            win_path=$dxvcs_path/Win

            if [[ "$branch" > "23_1" ]]; then
                xmldoc_netcore_source_path=$dxvcs_path/Builds.2005/HelpXml/HelpNetCore
            else
                xmldoc_netcore_source_path=$dxvcs_path/Builds.2005/HelpXml/HelpCore
            fi

            if [ -d "$asp_demos_path" ]; then
                /rsync-multi.sh $asp_demos_path/AspNetCoreDemos.DemoShell $aspnetcore_shell_path DemoShell/ wwwroot/DemoShell/ .editorconfig
                /rsync-multi.sh $asp_demos_path $wg_external_path AspNetCoreDemos.Reporting/ AspNetCoreDemos.RichEdit/ AspNetCoreDemos.Spreadsheet/
                find $wg_external_path -type f -regextype posix-egrep -not -regex ".*(README|menuMeta\.json|DemosStyles.*css|DemosScripts.*js|\.(cs|cshtml|md))$" -delete
            fi

            if [[ -d "$win_path" && "$branch" < "24_1" ]]; then
                if [[ "$branch" > "22_2" ]]; then
                    /rsync-multi.sh $win_path/DevExpress.Data/DevExpress.Data $data_portions_path AssemblyVersion.cs Utils/ DataController/ Filtering/ Printing/ Platform/
                else
                    /rsync-multi.sh $win_path/DevExpress.Data/DevExpress.Data $data_portions_path AssemblyVersion.cs Utils/
                fi
            fi

            if [ -d "$xmldoc_netcore_source_path" ]; then
                /rsync-multi.sh $xmldoc_netcore_source_path $hg_path/Tools/XmlDocNetCore DevExtreme.AspNet.Core.xml
            fi

            /hg-commit.sh $hg_path $dxvcs_path.log
        fi

        if [ -d $demos_on_github_path ]; then
            /git-update.sh $demos_on_github_path $branch $demos_on_github_path.log \
            && /rsync-multi.sh $demos_on_github_path $demos_on_github_hg_path / \
            && /hg-commit.sh $hg_path $demos_on_github_path.log \
            || echo "Sync failed: DevExtreme demos repo"
        fi

        if [ -d $aspnet_github_path ]; then
            /git-update.sh $aspnet_github_path $branch $aspnet_github_path.log \
            && /rsync-multi.sh -e Demos -k $aspnet_github_path $hg_path/DevExtreme.AspNet.Mvc / \
            && /hg-commit.sh $hg_path $aspnet_github_path.log \
            || echo "Sync failed: devextreme-aspnet repo"
        fi

        if [ -d $aspnet_github_demos_path ]; then
            /rsync-multi.sh $aspnet_github_demos_path $demos_on_github_hg_path / \
            && /hg-commit.sh $hg_path $aspnet_github_path.log \
            || echo "Sync failed: devextreme-aspnet demos"
        fi

        if ! /hg-push.sh $hg_path $branch; then
            echo "Failed to push HG repo"
        fi
    done

done
