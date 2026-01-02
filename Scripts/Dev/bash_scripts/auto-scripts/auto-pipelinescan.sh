#!/bin/bash
# Description:
# The purpose of this script is to run a static scan only on the things that have been changed in the diffential
# there will be 2 types of 2 modes
# a) Automatic
#   1) Attempting to see if the changes cause any new modules to be identified
#       1.1) If changes identified, default selects new modules as additional entry point
#       2.2) IF changes identified, use the previous defined selected modules
#   2) Scanning only the changes in the scanned files, and modules, and new data paths
# m) Manual 
#    1) Attempting to include the changed modules as entry points 
#    2) prompting for the selection of modules
#    3) only scan changes ( overlayed ( 2 scans ))