#!/bin/bash

echo "######################################################"
echo "# Title: Architecture detection and execution script"
echo "# Author: Ralf Roeber"
echo "# Date: 2025-02-27"
echo "######################################################"
echo "# Usage: ./entrypoint.sh"
echo "######################################################"

# Get the script directory
SCRIPT_DIR="/code"

# Detect CPU architecture
echo "Detecting CPU architecture..."
ARCH=$(uname -m)

# Check if architecture is ARM or AMD/Intel
if [[ "$ARCH" == "aarch64" || "$ARCH" == "arm"* ]]; then
    # ARM architecture detected
    echo "ARM architecture detected: $ARCH"
    
    # Check if ARM script exists
    if [ -f "${SCRIPT_DIR}/entrypoint-arm.sh" ]; then
        echo "Executing entrypoint-arm.sh"
        echo "######################################################"
        # Make sure the script is executable
        chmod +x "${SCRIPT_DIR}/entrypoint-arm.sh"
        # Execute the ARM-specific script
        "${SCRIPT_DIR}/entrypoint-arm.sh"
    else
        echo "Error: entrypoint-arm.sh not found in ${SCRIPT_DIR}"
        echo "Please create an ARM-specific script first."
        exit 1
    fi
elif [[ "$ARCH" == "x86_64" || "$ARCH" == "amd64" ]]; then
    # AMD/Intel architecture detected
    echo "AMD/Intel architecture detected: $ARCH"
    
    # Check if AMD script exists
    if [ -f "${SCRIPT_DIR}/entrypoint-amd.sh" ]; then
        echo "Executing entrypoint-amd.sh"
        echo "######################################################"
        # Make sure the script is executable
        chmod +x "${SCRIPT_DIR}/entrypoint-amd.sh"
        # Execute the AMD-specific script
        "${SCRIPT_DIR}/entrypoint-amd.sh"
    else
        echo "Error: entrypoint-amd.sh not found in ${SCRIPT_DIR}"
        echo "Please ensure the AMD-specific script exists."
        exit 1
    fi
else
    # Unknown architecture
    echo "Unknown architecture detected: $ARCH"
    echo "This script supports only ARM and AMD/Intel architectures."
    echo "Please create a specific script for your architecture."
    exit 1
fi

# Script completed
echo "######################################################"
echo "Architecture-specific script execution completed."
echo "######################################################" 

echo "Copying mod_auth_openidc.so to /usr/local/apache2/modules/"
cp /code/dist/mod_auth_openidc.so /usr/local/apache2/modules/

echo "Creating auth_openidc.load file"
echo 'LoadModule auth_openidc_module /usr/local/apache2/modules/mod_auth_openidc.so' > /etc/apache2/mods-available/auth_openidc.load

echo "Enabling auth_openidc module"
a2enmod auth_openidc

echo "Restarting Apache"
apachectl restart

tail -f /etc/passwd