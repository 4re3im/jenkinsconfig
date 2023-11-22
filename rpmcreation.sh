#!/bin/bash

# Enable error-sensitive shell
set -e

if [ -d SOURCES ]; then
    rm -r SOURCES
    mkdir SOURCES
fi
cp -rp $WORKSPACE/SOURCE/. SOURCES
find SOURCES -name .git | sed -e 's/^://' -e 's/$//' | xargs rm -rf

if [ -d SPECS ]; then
    rm -r SPECS
    mkdir SPECS
fi
cp -rp $WORKSPACE/SPEC/. SPECS
find SPECS -name .git | sed -e 's/^://' -e 's/$//' | xargs rm -rf

rpmbuild --define "_version ${VERSION}" --define "_release $BUILD_NUMBER" --define "_topdir $WORKSPACE" -bb SPECS/${PACKAGE_NAME}.spec
