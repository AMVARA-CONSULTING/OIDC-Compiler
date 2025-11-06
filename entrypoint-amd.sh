#!/bin/bash

echo "######################################################"
echo "# Title: Entrypoint that will compile the source code"
echo "# Author: AMVARA CONSULTING S.L."
echo "# Date: 2021-12-28"
echo "######################################################"
echo "# Usage: ./entrypoint.sh"
echo "######################################################"
echo "# CHANGELOG:"
echo "# 2025-02-27  RRO Nicing the script"
echo "# 2021-12-28  Arslan Created this file."
echo "# 2025-11-06  Anand Kushwaha updated the script fixing debian outdated packages"
echo "######################################################"

# make dist folder if missing
DISTFOLDER="$(dirname ${0})/dist"
test ! -d "${DISTFOLDER}" && mkdir -p "${DISTFOLDER}"

echo "Updating packages..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y >/dev/null 2>&1

# install utilities and Perl support (for debconf)
echo "Installing basic utilities..."
apt-get install -y \
    apt-utils \
    dialog \
    perl \
    jq \
    curl \
    wget \
    unzip \
    pkg-config \
    build-essential \
    ca-certificates \
    autoconf \
    automake \
    libtool \
    git \
    >/dev/null 2>&1

# install Apache + APR dependencies (required for mod_auth_openidc)
echo "Installing Apache and build dependencies for mod_auth_openidc..."
apt-get install -y \
    apache2-dev \
    libapache2-mod-auth-openidc \
    libapr1-dev \
    libaprutil1-dev \
    libpcre2-dev \
    zlib1g-dev \
    libssl-dev \
    libjansson-dev \
    libcurl4-openssl-dev \
    libcjose-dev \
    check \
    gdb \
    lcov \
    valgrind \
    >/dev/null 2>&1

# clean up apt cache to keep image small
apt-get clean
rm -rf /var/lib/apt/lists/*

# get the latest releases version from mod_auth_openidc repository
echo "Getting released version from mod_auth_openidc repository"
curl https://api.github.com/repositories/18187508/releases --insecure -s -o /tmp/mod_auth_openidc_releases

# get basic information from the latest release like version number
echo -ne "Getting latest mod_auth_openidc version: "
LATEST_OIDC_VERSION=$(cat /tmp/mod_auth_openidc_releases | jq ".[0].tag_name" | xargs)
echo ${LATEST_OIDC_VERSION}
# generate the source code download URL
echo -ne "Generating source code download URL: "
SOURCE_CODE_URL="https://github.com/zmartzone/mod_auth_openidc/archive/refs/tags/${LATEST_OIDC_VERSION}.zip"
echo "${SOURCE_CODE_URL}"

# mod_auth filename with version
FILENAME="mod_auth_openidc-${LATEST_OIDC_VERSION:1}"
DOWNLOAD_NAME="/tmp/${FILENAME}"

# download source code for mod_auth_openidc
echo "Downloading source code to ${DOWNLOAD_NAME}.zip"
wget -q "${SOURCE_CODE_URL}" -O "${DOWNLOAD_NAME}.zip"

# unzip mod_auth_openidc compressed file
echo "Unzipping mod_auth_openidc source code..."
unzip -o "${DOWNLOAD_NAME}.zip" -d /tmp/

# cd into the unzipped folder
cd "/tmp/${FILENAME}" || { echo "❌ Failed to enter source directory"; exit 1; }

# run necessary commands to compile the module
echo "Compiling mod_auth_openidc module"
echo "-----------------------------------------------------"
./autogen.sh
./configure
make -j"$(nproc)"
make install
cd /code
# module path
MODULE_PATH="/usr/local/apache2/modules/mod_auth_openidc.so"
# get compiled module's version
COMPILED_VERSION=$(strings ${MODULE_PATH} | grep -E mod_auth_openidc-[0-9\.] | head -n1)

if [[ "${COMPILED_VERSION}" == "${FILENAME}" ]]; then
    echo "mod_auth_openidc module has been compiled successfuly."
    cp ${MODULE_PATH} ${DISTFOLDER}/mod_auth_openidc.so_${LATEST_OIDC_VERSION:1}
    echo "-----------------------------------------------------"
    echo "You can find mod_auth_openidc.so_${LATEST_OIDC_VERSION:1} in the dist folder."
    echo "-----------------------------------------------------"
    md5sum ${DISTFOLDER}/mod_auth_openidc.so_${LATEST_OIDC_VERSION:1}
else
    echo "Expecting version ${FILENAME} to be compiled but found ${COMPILED_VERSION}"
    echo "Something is not right, please check."
    exit 1
fi

