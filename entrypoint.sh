#!/bin/bash

echo "######################################################"
echo "# Title: Architecture detection and execution script"
echo "# Author: Ralf Roeber, AMVARA CONSULTING S.L."
echo "# Date: 2025-02-27"
echo "######################################################"
# Get the script directory
SCRIPT_DIR="/code"

# Detect CPU architecture
echo -ne "Detecting CPU architecture ... "
ARCH=$(uname -m)
echo "$ARCH"
# Check if architecture is ARM or AMD/Intel
if [[ "$ARCH" == "aarch64" || "$ARCH" == "arm"* ]]; then
    # ARM architecture detected
    echo "ARM architecture detected: $ARCH"
    
    # Check if ARM script exists
    if [ -f "${SCRIPT_DIR}/entrypoint-arm.sh" ]; then
        echo "Executing entrypoint-arm.sh"
        echo "######################################################"
        # Execute the ARM-specific script
        bash "${SCRIPT_DIR}/entrypoint-arm.sh"
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
        # Execute the AMD-specific script
        bash "${SCRIPT_DIR}/entrypoint-amd.sh"
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


echo "Copying mod_auth_openidc.so to /usr/local/apache2/modules/ without version number"
cp /code/dist/mod_auth_openidc.so* /usr/local/apache2/modules/mod_auth_openidc.so

echo "Extract Version from mod_auth_openidc.so"
VERSION=$(strings /usr/local/apache2/modules/mod_auth_openidc.so | grep -E mod_auth_openidc-[0-9\.] | head -n1)
echo "Version: $VERSION"

echo "Creating auth_openidc.load file"
echo 'LoadModule auth_openidc_module /usr/local/apache2/modules/mod_auth_openidc.so' > /etc/apache2/mods-available/auth_openidc.load

echo -ne "Setting ServerName ... "
grep -q "ServerName localhost" /etc/apache2/apache2.conf && (echo " already set"; exit 0;) || (echo "ServerName localhost" >> /etc/apache2/apache2.conf && echo " done" || echo " failed"; exit 1; )

# Enable auth_openidc module
a2enmod auth_openidc || echo " failed"

echo -ne "Restarting Apache ... "
apache2ctl restart && echo " done" || echo " failed"

tail -f /dev/null