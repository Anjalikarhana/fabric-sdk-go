#!/bin/bash
#
# Copyright SecureKey Technologies Inc. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

# This script fetches code used in the SDK originating from other Hyperledger Fabric projects
# These files are checked into internal paths.
# Note: This script must be adjusted as upstream makes adjustments

UPSTREAM_PROJECT="github.com/hyperledger/fabric"
UPSTREAM_BRANCH="master"
SCRIPTS_PATH="scripts/third_party_pins/fabric"
PATCHES_PATH="${SCRIPTS_PATH}/patches"

THIRDPARTY_FABRIC_API_PATH='api/third_party/fabric'
THIRDPARTY_FABRIC_BCCSP_PKG_PATH='pkg/third_party'
THIRDPARTY_INTERNAL_FABRIC_PATH='internal/github.com/hyperledger/fabric'

####
# Clone and patch packages into repo

# Clone original project into temporary directory
echo "Fetching upstream project ($UPSTREAM_PROJECT:$UPSTREAM_COMMIT) ..."
CWD=`pwd`
TMP=`mktemp -d 2>/dev/null || mktemp -d -t 'mytmpdir'`

TMP_PROJECT_PATH=$TMP/src/$UPSTREAM_PROJECT
mkdir -p $TMP_PROJECT_PATH
cd ${TMP_PROJECT_PATH}/..

git clone https://${UPSTREAM_PROJECT}.git
cd $TMP_PROJECT_PATH
git checkout $UPSTREAM_BRANCH
git reset --hard $UPSTREAM_COMMIT

echo "Patching upstream project ..."
git am ${CWD}/${PATCHES_PATH}/*

cd $CWD

# fabric client utils
echo "Pinning and patching fabric client utils..."
declare -a CLIENT_UTILS_IMPORT_SUBSTS=(
    's/\"github.com\/hyperledger\/fabric\/bccsp/\"github.com\/hyperledger\/fabric-sdk-go\/pkg\/third_party\/bccsp/g'
    's/\"github.com\/hyperledger\/fabric\/protos\//\"github.com\/hyperledger\/fabric-sdk-go\/api\/third_party\/fabric\/protos\//g'
    's/\"github.com\/hyperledger\/fabric\//\"github.com\/hyperledger\/fabric-sdk-go\/internal\/github.com\/hyperledger\/fabric\//g'
)
eval "INTERNAL_PATH=$THIRDPARTY_INTERNAL_FABRIC_PATH TMP_PROJECT_PATH=$TMP_PROJECT_PATH IMPORT_SUBSTS=\"${CLIENT_UTILS_IMPORT_SUBSTS[*]}\" $SCRIPTS_PATH/apply_fabric_client_utils.sh"

# bccsp
echo "Pinning and patching bccsp ..."
declare -a BCCSP_IMPORT_SUBSTS=(
    's/\"github.com\/hyperledger\/fabric\/bccsp/\"github.com\/hyperledger\/fabric-sdk-go\/pkg\/third_party\/bccsp/g'
)
eval "INTERNAL_PATH=$THIRDPARTY_FABRIC_BCCSP_PKG_PATH TMP_PROJECT_PATH=$TMP_PROJECT_PATH IMPORT_SUBSTS=\"${BCCSP_IMPORT_SUBSTS[*]}\" $SCRIPTS_PATH/apply_fabric_bccsp.sh"

# protos
echo "Pinning and patching protos ..."
declare -a PROTOS_IMPORT_SUBSTS=(
    's/\"github.com\/hyperledger\/fabric\/bccsp/\"github.com\/hyperledger\/fabric-sdk-go\/pkg\/third_party\/bccsp/g'
    's/\"github.com\/hyperledger\/fabric\/protos\//\"github.com\/hyperledger\/fabric-sdk-go\/api\/third_party\/fabric\/protos\//g'
    's/\"github.com\/hyperledger\/fabric\//\"github.com\/hyperledger\/fabric-sdk-go\/internal\/github.com\/hyperledger\/fabric\//g'
)
eval "INTERNAL_PATH=$THIRDPARTY_FABRIC_API_PATH TMP_PROJECT_PATH=$TMP_PROJECT_PATH IMPORT_SUBSTS=\"${PROTOS_IMPORT_SUBSTS[*]}\" $SCRIPTS_PATH/apply_fabric_protos.sh"

# proto utils
echo "Pinning and patching proto utils..."
declare -a PROTO_UTILS_IMPORT_SUBSTS=(
    's/\"github.com\/hyperledger\/fabric\/bccsp/\"github.com\/hyperledger\/fabric-sdk-go\/pkg\/third_party\/bccsp/g'
    's/\"github.com\/hyperledger\/fabric\/protos\//\"github.com\/hyperledger\/fabric-sdk-go\/api\/third_party\/fabric\/protos\//g'
    's/\"github.com\/hyperledger\/fabric\//\"github.com\/hyperledger\/fabric-sdk-go\/internal\/github.com\/hyperledger\/fabric\//g'
)
eval "INTERNAL_PATH=$THIRDPARTY_FABRIC_API_PATH TMP_PROJECT_PATH=$TMP_PROJECT_PATH IMPORT_SUBSTS=\"${PROTO_UTILS_IMPORT_SUBSTS[*]}\" $SCRIPTS_PATH/apply_fabric_proto_utils.sh"

# Cleanup temporary files from patch application
echo "Removing temporary files ..."
rm -Rf $TMP