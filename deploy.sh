#!/bin/bash

TAGNAME=$1

git tag $TAGNAME 2> /dev/null && git push origin $TAGNAME

SCRIPT_PATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
RELEASE_DIR="/tmp/CDGRelease/CalmDownandGamble"
mkdir -p /tmp/CDGRelease

cp -rf "${SCRIPT_PATH}" "${RELEASE_DIR}"
rm -rf "${RELEASE_DIR}/.git"

zip -r CalmDownandGamble-${TAGNAME}.zip ${RELEASE_DIR}