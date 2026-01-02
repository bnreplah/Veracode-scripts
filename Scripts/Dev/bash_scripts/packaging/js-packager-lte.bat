@echo off
setlocal enabledelayedexpansion
REM GPT created script
REM Check if directory argument is provided
if "%~1"=="" (
    echo Please provide the directory path as an argument.
    exit /b 1
)

REM Set the directory to zip
set "directory=%~1"
set "zip_file=%directory%.zip"

REM Set file extensions to search for
set "extensions=ASP CSS EHTML ES ES6 HANDLEBARS HBS HJS HTM HTML JS JSX JSON JSP MAP MUSTACHE PHP TS TSX VUE XHTML"
set "include_lock_files=false"
set "include_bower=false"

REM Check if package-lock.json or npm-shrinkwrap.json is present
if exist "%directory%\package-lock.json" set "include_lock_files=true"
if exist "%directory%\npm-shrinkwrap.json" set "include_lock_files=true"

REM Check if yarn.lock is present
if exist "%directory%\yarn.lock" set "include_lock_files=true"

REM Check if bower_components directory and bower.json is present
if exist "%directory%\bower_components" (
    set "include_bower=true"
    if exist "%directory%\bower.json" set "include_lock_files=true"
)

REM Prepare file list to be zipped
set "file_list="
for %%e in (%extensions%) do (
    set "file_list=!file_list! *%%e"
)

REM Include lock files if needed
if "%include_lock_files%"=="true" set "file_list=!file_list! package-lock.json npm-shrinkwrap.json yarn.lock"

REM Include bower components if needed
if "%include_bower%"=="true" set "file_list=!file_list! bower_components"

REM Zip the files
echo Zipping files...
powershell -nologo -noprofile -command "& { Add-Type -A 'System.IO.Compression.FileSystem'; [IO.Compression.ZipFile]::CreateFromDirectory('%directory%', '%zip_file%', '.*', $false, 'Default'); }"

echo Zip completed.

endlocal
