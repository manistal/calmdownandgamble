#!/bin/bash

TAGNAME=$1

git tag $TAGNAME && git push origin $TAGNAME

SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
RELEASE_DIR="${SCRIPTPATH}/release/CalmDownandGamble"
mkdir -p ${RELEASE_DIR}

cp -rf ${SCRIPTPATH}/* ${RELEASE_DIR}/.
rm -rf ${RELEASE_DIR}/.git
rm -rf ${RELEASE_DIR}/release

zip -r CalmDownandGamble-${TAGNAME}.zip ${RELEASE_DIR}