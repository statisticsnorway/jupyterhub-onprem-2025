#!/usr/bin/env bash
set -euo pipefail

# Oracle Instant Client base URL (can be overridden in Dockerfile with ARG/ENV)
BASE_URL="${ORACLE_CLIENT_URL:-https://download.oracle.com/otn_software/linux/instantclient/216000}"

# Version string
VER="21.6.0.0.0-1.x86_64"

# Packages to install
PKGS=(
  "oracle-instantclient-basic-${VER}.rpm"
  "oracle-instantclient-devel-${VER}.rpm"
  "oracle-instantclient-odbc-${VER}.rpm"
  "oracle-instantclient-jdbc-${VER}.rpm"
  "oracle-instantclient-tools-${VER}.rpm"
  "oracle-instantclient-sqlplus-${VER}.rpm"
)

TMP_DIR="/tmp"

echo ">> Downloading Oracle Instant Client RPMs into ${TMP_DIR}"
for pkg in "${PKGS[@]}"; do
  echo "   - ${pkg}"
  curl -fsSL "${BASE_URL}/${pkg}" -o "${TMP_DIR}/${pkg}"
done

echo ">> Installing RPMs using alien (except sqlplus)"
alien -i "${TMP_DIR}/oracle-instantclient-basic-${VER}.rpm"
alien -i "${TMP_DIR}/oracle-instantclient-devel-${VER}.rpm"
alien -i "${TMP_DIR}/oracle-instantclient-odbc-${VER}.rpm"
alien -i "${TMP_DIR}/oracle-instantclient-jdbc-${VER}.rpm"
alien -i "${TMP_DIR}/oracle-instantclient-tools-${VER}.rpm"

echo ">> Installing sqlplus manually"
cd "${TMP_DIR}"
rpm2cpio "oracle-instantclient-sqlplus-${VER}.rpm" | cpio -idmv
cp -r "${TMP_DIR}/usr/"* /usr/
rm -rf "${TMP_DIR}/usr"

echo ">> Running ldconfig"
ldconfig

echo ">> Cleaning up"
rm -rf "${TMP_DIR}/oracle-instantclient-"*

ln -s /ssb/share/etc/tnsnames.ora /usr/lib/oracle/21/client64/lib/network/tnsnames.ora

export OCI_INC=/usr/include/oracle/21/client64
export OCI_LIB=/usr/lib/oracle/21/client64/lib
export ORACLE_HOME=/usr/lib/oracle/21/client64
export TNS_ADMIN=/usr/lib/oracle/21/client64/lib/network
export LD_LIBRARY_PATH=/usr/lib/oracle/21/client64/lib

echo ">> Oracle Instant Client installation complete."
