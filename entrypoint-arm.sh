#!/bin/bash

# AUTHOR: Anand Kushwaha
# DATE: 2024-11-28 
# Use this script to build mod_auth_openidc for ARM platforms, this script should be run only on ARM machine


# Install required dependencies
echo "Installing required dependencies..."
apt-get update
apt-get install -y build-essential autoconf automake libtool autoconf-archive pkg-config \
    libssl-dev libjansson-dev libcurl4-openssl-dev libcjose-dev zlib1g-dev \
    libapr1-dev libaprutil1-dev libpcre3-dev wget curl jq unzip apache2 apache2-dev

# Fetch the latest release version of mod_auth_openidc from GitHub
echo "Getting the released version from the mod_auth_openidc repository..."
curl https://api.github.com/repositories/18187508/releases --insecure -s -o /tmp/mod_auth_openidc_releases

# Parse the latest release version
echo -ne "Getting latest mod_auth_openidc version: "
LATEST_OIDC_VERSION=$(cat /tmp/mod_auth_openidc_releases | jq ".[0].tag_name" | xargs)
echo "${LATEST_OIDC_VERSION}"

# Generate the source code download URL
echo -ne "Generating source code download URL: "
SOURCE_CODE_URL="https://github.com/zmartzone/mod_auth_openidc/archive/refs/tags/${LATEST_OIDC_VERSION}.zip"
echo "${SOURCE_CODE_URL}"

# Download and unzip the source code
echo "Downloading and extracting source code..."
wget ${SOURCE_CODE_URL} -O mod_auth_openidc.zip
unzip -q mod_auth_openidc.zip
cd mod_auth_openidc-*

# Prepare for building the module
echo "Running autogen.sh to prepare the build system..."
mkdir -p m4
sed -i '1im4_pattern_allow([AC_CHECK_HEADER])\nm4_pattern_allow([AC_DEFINE])\nm4_pattern_allow([AC_CHECK_LIB])' configure.ac
autoreconf -fi

# Configure the build
echo "Configuring the build..."
./configure LDFLAGS="-lpcre"

# Compile the library
echo "Compiling mod_auth_openidc..."
make clean
make

# Install the compiled module
echo "Installing mod_auth_openidc..."
make install

# Enable the module in Apache
echo "Enabling mod_auth_openidc in Apache..."
a2enmod auth_openidc

# Restart Apache to apply changes
echo "Restarting Apache..."
service apache2 restart

# Verify if the module is loaded
echo "Verifying mod_auth_openidc installation..."
apachectl -M | grep auth_openidc && echo "mod_auth_openidc is successfully installed and enabled!" || echo "mod_auth_openidc installation failed."

