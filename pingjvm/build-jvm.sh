#!/usr/bin/env sh
set -e
test "${VERBOSE}" = "true" && set -x

echo "✓ Chainguard JDK detected — skipping legacy JDK logic"

# Detect system Java
JAVA_BIN="$(readlink -f "$(command -v java)")"
JAVA_HOME="$(dirname "$(dirname "${JAVA_BIN}")")"
JAVA_BUILD_DIR="/opt/java"

# Create output path
mkdir -p "${JAVA_BUILD_DIR}"

# Copy system JDK to expected location
cp -a "${JAVA_HOME}/." "${JAVA_BUILD_DIR}/"

# Verify copied Java works
"${JAVA_BUILD_DIR}/bin/java" -version || exit 98

# Save version to file
"${JAVA_BUILD_DIR}/bin/java" -version 2>&1 | tee "${JAVA_BUILD_DIR}/_version"

# Self-delete script
rm -f "$0"

echo "✓ JVM staged at ${JAVA_BUILD_DIR}"
exit 0
