#!/bin/bash

# Set up
SCRIPT_PATH="$( cd "$(dirname "$0/..")" >/dev/null 2>&1 ; pwd -P )"
RELEASE_DIR="/mnt/c/temp/CDGRelease/"
rm -rf ${RELEASE_DIR}
mkdir -p ${RELEASE_DIR}

# Copy up 
cp -rf "${SCRIPT_PATH}" "${RELEASE_DIR}"
rm -rf "${RELEASE_DIR}/CalmDownandGamble/.git"
rm -rf "${RELEASE_DIR}/CalmDownandGamble/.gitignore"
rm -rf "${RELEASE_DIR}/CalmDownandGamble/deploy.sh"

# Zip up 
cd ${RELEASE_DIR}
zip -r CalmDownandGamble.zip CalmDownandGamble

# Cleanup
#cd -
#mv ${RELEASE_DIR}/*zip .
#rm -rf /tmp/CDGRelease