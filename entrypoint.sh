#!/bin/bash

######################################################
# Title: Entrypoint that will compile the source code
# Author: AMVARA CONSULTING S.L.
# Date: 2021-12-28
######################################################
# Usage: ./entrypoint.sh
######################################################
# CHANGELOG:
# 2021-12-28  Arslan  Created this file. 
######################################################

# update libraries
echo "Updating packages"
apt-get update
# install basic commands
echo "Installing basic packages to work with"
apt-get install -y curl jq wget unzip

# get the latest releases version from mod_auth_openidc repository
echo "Getting released version from mod_auth_openidc repository"
curl https://api.github.com/repos/zmartzone/mod_auth_openidc/releases --insecure -s -o /tmp/mod_auth_openidc_releases

# get basic information from the latest release like version number
echo -ne "Getting latest mod_auth_openidc version: "
LATEST_OIDC_VERSION=$(cat /tmp/mod_auth_openidc_releases | jq ".[0].tag_name" | xargs)
echo ${LATEST_OIDC_VERSION}
# generate the source code download URL
echo -ne "Generating source code download URL: "
SOURCE_CODE_URL="https://github.com/zmartzone/mod_auth_openidc/archive/refs/tags/${LATEST_OIDC_VERSION}.zip"
echo ${SOURCE_CODE_URL}
# mod_auth filename with version
FILENAME="mod_auth_openidc-${LATEST_OIDC_VERSION:1}"
# generate download name
DOWNLOAD_NAME="/tmp/${FILENAME}"

# download source code for mod_auth_openidc
echo "Downloading source code to ${DOWNLOAD_NAME}.zip"
wget -q ${SOURCE_CODE_URL} -O ${DOWNLOAD_NAME}.zip

# download all the dependencies needed for mod_auth_openidc
echo "Installing dependencies required for mod_auth_openidc"
apt-get install -y pkg-config make gcc gdb lcov valgrind
apt-get install -y autoconf automake libtool
apt-get install -y libssl-dev libjansson-dev libcurl4-openssl-dev check
apt-get install -y libpcre3-dev zlib1g-dev libapr1-dev libaprutil1-dev
cd /tmp
wget -q https://mod-auth-openidc.org/download/libcjose0_0.6.1.5-1~bionic+1_amd64.deb
wget -q https://mod-auth-openidc.org/download/libcjose-dev_0.6.1.5-1~bionic+1_amd64.deb
dpkg -i libcjose0_0.6.1.5-1~bionic+1_amd64.deb
dpkg -i libcjose-dev_0.6.1.5-1~bionic+1_amd64.deb

# unzip mod_auth_openidc compressed file
echo "Unzipping mod_auth_openidc source code"
unzip ${DOWNLOAD_NAME}.zip
# cd into the unzipped folder
cd ${DOWNLOAD_NAME}

# run necessary commands to compile the module
echo "Compiling mod_auth_openidc module"
./autogen.sh
./configure
make
make install

# module path
MODULE_PATH="/usr/local/apache2/modules/mod_auth_openidc.so"
# get compiled module's version
COMPILED_VERSION=$(strings ${MODULE_PATH} | grep -E mod_auth_openidc-[0-9\.] | head -n1)

if [[ "${COMPILED_VERSION}" == "${FILENAME}" ]]; then
    echo "mod_auth_openidc module has been compiled successfuly."
    cp ${MODULE_PATH} /code/dist/mod_auth_openidc.so_${LATEST_OIDC_VERSION:1}
    echo "You can find mod_auth_openidc.so_${LATEST_OIDC_VERSION:1} in the dist folder."
    md5sum /code/dist/mod_auth_openidc.so_${LATEST_OIDC_VERSION:1}
else
    echo "Expecting version ${FILENAME} to be compiled but found ${COMPILED_VERSION}"
    echo "Something is not right, please check."
    exit 1
fi