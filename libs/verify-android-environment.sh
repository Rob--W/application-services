#!/usr/bin/env bash

# shellcheck disable=SC2148
# Ensure the build toolchains are set up correctly for android builds.
#
# This file should be used via `./libs/verify-android-environment.sh`.

set -e

RUST_TARGETS=("aarch64-linux-android" "armv7-linux-androideabi" "i686-linux-android" "x86_64-linux-android")

if [[ ! -f "$(pwd)/libs/build-all.sh" ]]; then
  echo "ERROR: verify-android-environment.sh should be run from the root directory of the repo"
  exit 1
fi

"$(pwd)/libs/verify-common.sh"

# If you add a dependency below, mention it in building.md in the Android section!

if [[ -z "${ANDROID_HOME}" ]]; then
  echo "Could not find Android SDK:"
  echo 'Please install the Android SDK and then set ANDROID_HOME.'
  exit 1
fi

# NDK ez-install.
"$ANDROID_HOME/tools/bin/sdkmanager" "ndk;$(./gradlew -q printNdkVersion | tail -1)"

rustup target add "${RUST_TARGETS[@]}"

# Determine the Java command to use to start the JVM.
# Same implementation as gradlew
if [[ -n "$JAVA_HOME" ]] ; then
    if [[ -x "$JAVA_HOME/jre/sh/java" ]] ; then
        # IBM's JDK on AIX uses strange locations for the executables
        JAVACMD="$JAVA_HOME/jre/sh/java"
    else
        JAVACMD="$JAVA_HOME/bin/java"
    fi
    if [[ ! -x "$JAVACMD" ]] ; then
        die "ERROR: JAVA_HOME is set to an invalid directory: $JAVA_HOME

Please set the JAVA_HOME variable in your environment to match the
location of your Java installation."
    fi
else
    JAVACMD="java"
    command -v $JAVACMD >/dev/null 2>&1 || die "ERROR: JAVA_HOME is not set and no 'java' command could be found in your PATH.

Please set the JAVA_HOME variable in your environment to match the
location of your Java installation."
fi

JAVA_VERSION=$("$JAVACMD" -version 2>&1 | grep -i version | cut -d'"' -f2 | cut -d'.' -f1-2)
if [[ "${JAVA_VERSION}" != "1.8" ]]; then
  echo "Incompatible java version: ${JAVA_VERSION}. JDK 8 must be installed."
  exit 1
fi

# CI just downloads these libs anyway.
if [[ -z "${CI}" ]]; then
  if [[ ! -d "${PWD}/libs/android/arm64-v8a/nss" ]] || [[ ! -d "${PWD}/libs/android/arm64-v8a/sqlcipher" ]]; then
    pushd libs || exit 1
    ./build-all.sh android
    popd || exit 1
  fi
fi

echo "Looks good! Try building with ./gradlew assembleDebug"
