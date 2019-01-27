#!/bin/bash

lipo -remove i386 Frameworks/openssl.framework/openssl -o Frameworks/openssl.framework/openssl
lipo -remove x86_64 Frameworks/openssl.framework/openssl -o Frameworks/openssl.framework/openssl

lipo -remove i386 Frameworks/libssh2.framework/libssh2 -o Frameworks/libssh2.framework/libssh2
lipo -remove x86_64 Frameworks/libssh2.framework/libssh2 -o Frameworks/libssh2.framework/libssh2
