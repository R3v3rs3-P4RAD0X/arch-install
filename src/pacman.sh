#!/bin/bash

# This file will handle all pacman related operations


# Function: check_installed
#
# Description:
#   Checks if a package is installed using pacman.
#
# Parameters:
#   $1 - The name of the package to check.
#
# Returns:
#   0 - If the package is installed.
#   1 - If the package is not installed.
check_installed() {
    if pacman -Qs $1 > /dev/null; then
        return 0
    else
        return 1
    fi
}

# Function: install
#
# Description:
#   Installs a package using pacman.
#
# Parameters:
#   $1 - The name of the package to install.
#
# Returns:
#   0 - If the package is installed.
#   1 - If the package is not installed.
install() {
    if check_installed $1; then
        return 0
    else
        echo "Installing $1..."
        sudo pacman -S $1 --noconfirm --needed > /dev/null
        return $?
    fi
}
