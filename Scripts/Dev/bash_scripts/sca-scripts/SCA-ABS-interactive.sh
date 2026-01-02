#!/bin/bash
# the purpose of this script is to allow for the user to use the results file from the srcclr agent based scans as a baseline
# allowing it to display net new vulnerabilities that are discovered between branches ( comparing scans )
# and showing those in a diff view of the branches
# it will also track down to the library and line where the main libraries may be imported ( so you can see their use )
# as well as have the ability to intensely analyze all the import and call paths and model the application from the SCA perspective
