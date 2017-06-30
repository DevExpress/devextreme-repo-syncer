@echo off
cls

set WORK_DIR=%TEMP%\2a4c0b3c4e24492db23a7f3f92506647
set SYNCER_LOG_FILE=%WORK_DIR%\syncer_log.txt
set COMMIT_MESSAGE_FILE=%WORK_DIR%\commit_message.txt
if exist "%WORK_DIR%" rd /q /s "%WORK_DIR%"

set /p HG_TAG="Existing Mercurial tag used to build installations (e.g. 17_1_2): "
echo downloading...
hg archive --no-decode --cwd \\hg\repos\mobile -r "tag('%HG_TAG%')" --include GitHub "%WORK_DIR%\hg" || goto error

set /p GITHUB_TAG="GitHub tag to be created (e.g. 17.1.2-pre-beta): "

echo preparing commit message...
echo Release %GITHUB_TAG% > "%COMMIT_MESSAGE_FILE%"
hg log --cwd \\hg\repos\mobile -r "branch(tagged('%HG_TAG%')) and user('GitHub Syncer')" --template "  {desc}\r\n" > "%SYNCER_LOG_FILE%"

for /f %%i in ("%SYNCER_LOG_FILE%") do set SYNCER_LOG_FILE_SIZE=%%~zi
if %SYNCER_LOG_FILE_SIZE% gtr 0 (
    echo Cherry-picked changesets: >> "%COMMIT_MESSAGE_FILE%"
    type "%SYNCER_LOG_FILE%" >> "%COMMIT_MESSAGE_FILE%"
)

echo.
echo Text editor with a pending commit message must open now.
echo If needed, edit and save.
explorer "%COMMIT_MESSAGE_FILE%"
pause

echo.
echo ----------
hg log --cwd \\hg\repos\mobile -r "last(ancestors(first(branch(tagged('%HG_TAG%')))) and author('GitHub Syncer'), 5)" --template "{date|date} {desc}\n"
echo ----------
echo From the list above, choose a parent commit for this release.
echo The topmost should work.
set /p GITHUB_PARENT="commit sha: "

echo.
echo cloning...
git clone https://github.com/DevExpress/DevExtreme.git "%WORK_DIR%\github" || goto error

cd /d "%WORK_DIR%\github"

git checkout "%GITHUB_PARENT%" || goto error
git rm -rf . || goto error

robocopy "%WORK_DIR%\hg\GitHub" "%WORK_DIR%\github" /s /nfl /ndl
IF %ERRORLEVEL% LEQ 1 goto error

git add . || goto error
git update-index --chmod=+x docker-ci.sh testing/launch || goto error

git commit -F "%COMMIT_MESSAGE_FILE%" --allow-empty || goto error
git tag "%GITHUB_TAG%" || goto error

echo ------------------
echo OK, now examine "%WORK_DIR%\github" in SourceTree and push the new tag!
pause

exit /b 0

:error
echo ERRORS
exit /b 1