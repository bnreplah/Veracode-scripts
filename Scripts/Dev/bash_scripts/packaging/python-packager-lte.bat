@echo off
setlocal enabledelayedexpansion
REM GPT Created script
REM Define the frameworks/packages to check for along with supported versions
set "frameworks=aws-sdk-python:boto3:1 azure-functions:azure-functions:3 cryptography:cryptography:0.6-1 django:django:1 3 4 flask:flask:0 1 2 httplib2:httplib2:0.9.2 jinja:jinja2:2 requests:requests:2 sqlalchemy:sqlalchemy:0.9-1"

REM Function to check if a directory contains a framework/package
:contains_framework
set "dir=%~1"
set "framework=%~2"
set "version=%~3"
set "pipfile_lock=!dir!\Pipfile.lock"

if exist "!pipfile_lock!" (
    for %%a in (!framework!) do (
        findstr /C:"\"%%~a\"" "!pipfile_lock!" >nul 2>&1
        if not errorlevel 1 (
            if "!version!" == "any" (
                exit /b 0
            ) else (
                findstr /C:"\"version\": \"!version!\"" "!pipfile_lock!" >nul 2>&1
                if not errorlevel 1 (
                    exit /b 0
                )
            )
        )
    )
)
exit /b 1

REM Function to zip up the code and HTML files
:zip_project
set "project_dir=%~1"
set "framework_name=%~2"
set "zip_name=!project_dir!_!framework_name!_project.zip"

powershell Compress-Archive -Path "!project_dir!\*.py", "!project_dir!\*.html" -DestinationPath "!zip_name!"
echo Zip created: "!zip_name!"

REM Main script
for /D %%d in (*) do (
    for %%f in (%frameworks%) do (
        for /f "tokens=1,2,3 delims=:" %%a in ("%%f") do (
            call :contains_framework "%%d" "%%a" "%%c"
            if !errorlevel! equ 0 (
                call :zip_project "%%d" "%%a"
                goto :next_project
            )
        )
    )
    :next_project
)
