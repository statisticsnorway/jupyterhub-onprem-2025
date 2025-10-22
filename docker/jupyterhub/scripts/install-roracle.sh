#!/usr/bin/env bash
# setup_roracle.sh — system-wide install of ROracle on Ubuntu (Docker)
set -euo pipefail

echo ">>> Detecting R home…"
R_HOME="$(R RHOME)"
echo "R_HOME=${R_HOME}"

echo ">>> Ensuring libaio SONAME that Oracle expects (libaio.so.1)…"
if [ ! -e /lib/x86_64-linux-gnu/libaio.so.1 ] && [ -e /lib/x86_64-linux-gnu/libaio.so.1t64 ]; then
  ln -sfn /lib/x86_64-linux-gnu/libaio.so.1t64 /lib/x86_64-linux-gnu/libaio.so.1
fi
ldconfig || true

echo ">>> Writing Oracle env to /etc/profile.d/oracle-instantclient.sh…"
cat >/etc/profile.d/oracle-instantclient.sh <<'EOF'
# Oracle Instant Client env (system-wide)
export OCI_INC=/usr/include/oracle/21/client64
export OCI_LIB=/usr/lib/oracle/21/client64/lib
export ORACLE_HOME=/usr/lib/oracle/21/client64
export TNS_ADMIN=/usr/lib/oracle/21/client64/lib/network

# Ensure runtime linker can find Oracle and system libs first
export LD_LIBRARY_PATH="/usr/lib/oracle/21/client64/lib:/lib/x86_64-linux-gnu${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
EOF
chmod 0644 /etc/profile.d/oracle-instantclient.sh

echo ">>> Writing site Makevars to ${R_HOME}/etc/Makevars.site…"
install -d "${R_HOME}/etc"
cat >"${R_HOME}/etc/Makevars.site" <<'EOF'
# System-wide Makevars for building packages that use Oracle OCI
OCI_INC=/usr/include/oracle/21/client64
OCI_LIB=/usr/lib/oracle/21/client64/lib
OCI_LIB64=/usr/lib/oracle/21/client64/lib

# Turn format-security from error into warning (ROracle uses dynamic messages)
CFLAGS     += -Wno-error=format-security
CXXFLAGS   += -Wno-error=format-security
CXX11FLAGS += -Wno-error=format-security
CXX14FLAGS += -Wno-error=format-security
CXX17FLAGS += -Wno-error=format-security
CPPFLAGS   += -Wno-error=format-security
EOF
chmod 0644 "${R_HOME}/etc/Makevars.site"

echo ">>> Setting system-wide R repo to your Nexus in ${R_HOME}/etc/Rprofile.site…"
cat >"${R_HOME}/etc/Rprofile.site" <<'EOF'
# System-wide R profile
local({
  # Prefer Posit Package Manager mirror on Nexus
  options(repos = c(CRAN = "https://nexus.ssb.no/repository/packagemanager-rstudio-noble/"))
})
EOF
chmod 0644 "${R_HOME}/etc/Rprofile.site"

echo ">>> Ensuring site library at /usr/local/lib/R/site-library…"
install -d /usr/local/lib/R/site-library
chmod 2775 /usr/local/lib/R/site-library || true

echo ">>> Installing ROracle into the site library (renv autoload disabled)…"
# Prevent renv from hijacking the install if a project is nearby
export RENV_CONFIG_AUTOLOADER_ENABLED=FALSE
# Also neutralize user profiles that might re-enable renv
export R_PROFILE_USER=""
export R_ENVIRON_USER=""

Rscript -e 'install.packages("ROracle", type="source", lib="/usr/local/lib/R/site-library")'

echo ">>> Verifying load…"
Rscript -e 'library(ROracle); cat("ROracle ", as.character(packageVersion("ROracle")), " loaded OK\n", sep="")'

echo ">>> Done."
