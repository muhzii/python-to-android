#!/bin/bash

ARCH=$1
ANDROID_NDK=$(cd $2; pwd)
PYTHON_PATH=$(cd $3; pwd)

srcdir=$(cd "$(dirname $0)"; pwd)

throw_error () {
  echo $1
  exit 1
}

# check arguments for errors
README_PATH="$PYTHON_PATH/README.rst"
if [ -f $README_PATH ]
then
  version=$(cat $README_PATH | grep -oP '3.7.[0-9]+')
  if [ -z "$version" ]
  then
    throw_error "ERROR: Python version doesn't match required version (v3.7), exiting..."
  fi
else
  throw_error "ERROR: incorret Python path, exiting..."
fi

NDK_PROP_PATH="$ANDROID_NDK/source.properties"
if [ -f $NDK_PROP_PATH ]
then
  version=$(cat $NDK_PROP_PATH | grep -oP '[0-9]+(?=[.])' | head -1)
  if [ $version != "19" ]
  then
    throw_error "NDK r19 is required, exiting..."
  fi
else
  throw_error "ERROR: incorret NDK path"
fi

# determine android target machine
if [ $ARCH == "x86" ]
then
  ANDROID_TARGET="i686-linux-android"
elif [ $ARCH == "x86_64" ]
then
  ANDROID_TARGET="x86_64-linux-android"
elif [ $ARCH == "arm" ]
then
  ANDROID_TARGET="armv7a-linux-androideabi"
  BIN_UTILS_PREFIX="arm-linux-androideabi"
elif [ $ARCH == "arm64" ]
then
  ANDROID_TARGET="aarch64-linux-android"
else
  throw_error "ERROR: specify correct architecture (x86, x86_64, arm, arm64)"
fi

# Default API version, compilation breaks for API < 21
ANDROID_API="21"

# set prefix for binary utilities
if [ -z "$BIN_UTILS_PREFIX" ]
then
  BIN_UTILS_PREFIX=$ANDROID_TARGET
fi

cd $PYTHON_PATH

PATCHES=("lld-compatibility.patch")

echo "Applying patches for cross-compilation..."
sleep 2

# copy the patch file and apply patches
for patch in $PATCHES
do
    cp "$srcdir/$patch" $PYTHON_PATH
    patch -p0 -i $patch
done

# paste config.site to python folder
cp "$srcdir/config.site" $PYTHON_PATH

# set environment variables for `configure`
export PATH="$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH"

export CC="${ANDROID_TARGET}${ANDROID_API}-clang"
export CXX="$CC++"

export LD="$BIN_UTILS_PREFIX-ld"

export AR="$BIN_UTILS_PREFIX-ar"
export AS="$BIN_UTILS_PREFIX-as"
export STRIP="$BIN_UTILS_PREFIX-strip"
export RANLIB="$BIN_UTILS_PREFIX-ranlib"
export READELF="$BIN_UTILS_PREFIX-readelf"

export CFLAGS="-fPIC"
export CXXFLAGS=$CFLAGS
export LDFLAGS="-fuse-ld=lld"

export CONFIG_SITE="config.site"

CONFIG_BUILD="$(uname -m)-linux-gnu"
CONFIG_ARGS="--disable-ipv6"

INSTALL_DIR="$PYTHON_PATH/output/$ARCH-android"

echo "Building for $ANDROID_TARGET"
sleep 2

autoreconf --install --verbose --force
./configure --prefix=/usr --host=$ANDROID_TARGET --build=$CONFIG_BUILD $CONFIG_ARGS
make 
make install DESTDIR=$INSTALL_DIR

echo ""
echo "-----"
echo "DONE!"
echo "Build output directory -> $INSTALL_DIR" 
