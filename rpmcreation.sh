#!/bin/bash

# Enable error-sensitive shell
set -e

cd $WORKSPACE/application
if [ -d SOURCES ]; then
    rm -r SOURCES
    mkdir SOURCES
fi
cp -rp SOURCE/. SOURCES
find SOURCES -name .git | sed -e 's/^://' -e 's/$//' | xargs rm -rf

if [ -d SPECS ]; then
    rm -r SPECS
    mkdir SPECS
fi
cp -rp SPEC/. SPECS
find SPECS -name .git | sed -e 's/^://' -e 's/$//' | xargs rm -rf

rpmbuild --define "_version $VERSION" --define "_release $BUILD_NUMBER" --define "_topdir $WORKSPACE/application" -bb SPECS/${PACKAGE_NAME}.spec

/usr/bin/createrepo_c $WORKSPACE/application/RPMS/noarch
