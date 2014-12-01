#!/bin/ksh


export DEVROOT=`xcode-select --print-path`
export SDKROOT=$DEVROOT/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk
 
# Set up relevant environment variables
export CPPFLAGS="-I$SDKROOT/usr/include/c++/4.2.1/ -I$SDKROOT/usr/include/ -miphoneos-version-min=8.1 -arch armv7"
export CFLAGS="$CPPFLAGS -arch armv7 -pipe -no-cpp-precomp -isysroot $SDKROOT"
export CXXFLAGS="$CFLAGS"

export LIB_SUFFIX=IOS
export LIBDIR=`pwd`/iOS-lib


make clean

./configure  --program-suffix=LIB_SUFFIX  --disable-shared --enable-static --disable-bin CXX=`xcrun -sdk iphoneos -find g++` CC=`xcrun -sdk iphoneos -find gcc` LD=`xcrun -sdk iphoneos -find ld` --host=arm-apple-darwin

if [[ $? != 0 ]]
then
    echo "ERROR: Quiting because of problems with running ./configure"
    exit 1
fi

make
if [[ $? != 0 ]]
then
    echo "ERROR: Problems building openfst library"
    exit 1
else
    cp src/lib/.libs/libfst.a libfst-ios.a
    echo
    echo "ios library is in libfst-ios.a. include files are under include/"
    echo
fi
