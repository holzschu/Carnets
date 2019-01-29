#!/bin/bash

IOS_SYSTEM_VER="2.3"
HHROOT="https://github.com/holzschu"

mkdir -p "${PWD}/Frameworks"
(cd "${PWD}/Frameworks"
# ios_system
echo "Downloading ios_system.framework and associated dylibs"
curl -OL $HHROOT/ios_system/releases/download/v$IOS_SYSTEM_VER/release.tar.gz
( tar -xzf release.tar.gz --strip 1 && rm release.tar.gz ) || { echo "ios_system failed to download"; exit 1; }
)
# Remove x86 & i386 archs from frameworks, if present:
./fix-framework-archs.sh
echo "Downloading header file:"
curl -OL $HHROOT/ios_system/releases/download/v$IOS_SYSTEM_VER/ios_error.h 

echo "Downloading python files:"
mkdir -p "${PWD}/Library"
(cd "${PWD}/Library" ; curl -OL https://github.com/holzschu/python3_ios/releases/download/v1.0/release.tar.gz ; tar xzf release.tar.gz ; rm release.tar.gz)
echo "Patching Javscript files:"
(cd "${PWD}/Library" ;  patch -p1 < ../Library.patch ; cd ..)

