#!/bin/bash

find $1 -type f \( -iname "requirements.txt" -o -iname "pom.xml" -o -iname "build.gradle"  -o -iname "*.sln" -o -iname "config.xml" -o -iname "makefile" -o -iname "*.vcxproj" -o -iname "*.cbl" -o -iname "*.cob" -o -iname "composer.lock" -o -iname "package.json" -o -iname "*.PF" -o -iname "*.LF" -o -iname "*.DSPF" -o -iname "*.PRTF" -o -iname "*.ICF" -o -iname "*.php" -o -iname "*.xarchive" -o -iname "*.xcodeproj"  \)
