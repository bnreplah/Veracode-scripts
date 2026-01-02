#!/bin/bash
# The purpose of this application is to be a wrapper to the SCA Agent based scan and functionality
# This script requires that the SCA Agent is already installed on the system

shopt -s expand_aliases

INSTALL_SCA_URL="https://sca-downloads.veracode.com/install"

function install_sca{
    curl -sSL $INSTALL_SCA_URL | sh
}

# TODO: if SCA agent isn't installed, run the SCA agent, or install the latest each time

# Ensures that the SCA agent is installed
install_sca

