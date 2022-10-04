@echo off
echo The following arguments were passed
pause
set pth=%cd%
echo Ensure docker is running

:menu
pause

echo =============================== Menu ===============================
echo    - 1) Run a Pipeline Scan on a file 
echo    - 2) Run an SCA Scan on a file
echo    - 3) Run an SCA Scan on a repo
echo    - 4) Upload and Scan a package
echo    - 5) Run a sandbox scan on a file
echo    - 6) Generate an SBOM for an application
echo    - 7) Get a list of the applications
echo    - 8) Make a custom API Call
echo    - 9) Exit
echo =========================================================== Selected:
set /P selection=[Selected Option (1-8)]:
echo your option: %selection%
goto opt%selection%

pause
:opt1 
   
    cls
    set /P scanfile=[ Enter a file to scan with the pipeline scanner: ] C:\Users\bhalpern\Documents\dev\
    docker run -it --rm -v C:\Users\bhalpern\Documents\dev:/home/luser -v C:\Users\bhalpern\.veracode\credentials:/home/luser/.veracode/credentials veracode/pipeline-scan:cmd --file %scanfile%
    goto menu

:opt2

    echo 2
    echo Requires srcclr to be installed on the computer
    pause
    goto menu
:opt3 
    echo 3
    echo Requires srcclr to be installed on the computer
    pause
    goto menu
:opt4
    pause
    echo 4
    echo was selected
    set createappprofile=false
    set createsanprofile=false
    set /P scanfile2=[ Enter a file to scan with the pipeline scanner: ] C:\Users\bhalpern\Documents\dev\
    set /P appname=[ Enter the application name: ] 
    set /P versioninfo=[ Enter the version info (Scan name): ] 
    docker run -it --rm -v C:\Users\bhalpern\Documents\dev:/home/luser -v C:\Users\bhalpern\.veracode\credentials:/home/luser/.veracode/credentials veracode/api-wrapper-java:cmd -action UploadAndScan -createprofile %createappprofile% -appname "%appname%" -version "%versioninfo%" -filepath %scanfile2%
    pause
    goto menu
:opt5
    echo 5
    echo was selected
    pause
    goto menu
:opt6
    echo 6
    echo was selected
    pause
    goto menu
:opt7

    echo 7
    echo was selected
    echo [Making API call to get the list of all the application, response is in xml format]
    echo
    docker run -it --rm -v C:\Users\bhalpern\Documents\dev:/home/luser -v C:\Users\bhalpern\.veracode\credentials:/home/luser/.veracode/credentials veracode/api-wrapper-java:cmd -action GetAppList
    pause
    goto menu
:opt8
    echo 8
    echo was selected
    pause
    goto menu
:opt9

    echo 9
    echo was selected
    pause
    goto menu
:opt0
    echo 0
    echo was selected
    echo Pulling docker images

    docker pull veracode/api-wrapper-java
    docker pull veracode/api-signing
    docker pull veracode/pipeline-scan
    pause
    pause
    cls
    echo default
    pause
    exit


:default
pause
cls
echo default
pause
exit


:scanversion
pause
echo [Version of the Veracode Pipeline Scanner: ]
docker run -it --rm -v C:\Users\bhalpern\Documents\dev:/home/luser -v C:\Users\bhalpern\.veracode\credentials:/home/luser/.veracode/credentials veracode/pipeline-scan:cmd --version
pause
goto menu

:scanfile
cls
set /P scanfile=[ Enter a file to scan with the pipeline scanner: ] C:\Users\bhalpern\Documents\dev\
docker run -it --rm -v C:\Users\bhalpern\Documents\dev:/home/luser -v C:\Users\bhalpern\.veracode\credentials:/home/luser/.veracode/credentials veracode/pipeline-scan:cmd --file %scanfile%

pause
goto menu

cls

pause
goto default
