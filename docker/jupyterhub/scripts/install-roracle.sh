#!/usr/bin/env bash
set -euo pipefail

echo ">>> Detecting R home…"
R_HOME="$(R RHOME | tr -d '\r\n')"
: "${R_HOME:?Could not determine R_HOME}"
echo "R_HOME=${R_HOME}"

# --- libaio SONAME compat (Oracle client expects libaio.so.1) ---
echo ">>> Ensuring libaio SONAME that Oracle expects (libaio.so.1)…"
if ! ldconfig -p | grep -q 'libaio\.so\.1'; then
  if [ -e /lib/x86_64-linux-gnu/libaio.so.1t64 ] && [ ! -e /lib/x86_64-linux-gnu/libaio.so.1 ]; then
    ln -sf /lib/x86_64-linux-gnu/libaio.so.1t64 /lib/x86_64-linux-gnu/libaio.so.1
    ldconfig
  fi
fi

# --- Oracle Instant Client environment system-wide ---
echo ">>> Writing Oracle env to /etc/profile.d/oracle-instantclient.sh…"
cat >/etc/profile.d/oracle-instantclient.sh <<'EOF'
# Oracle Instant Client (system-wide)
export OCI_INC=/usr/include/oracle/21/client64
export OCI_LIB=/usr/lib/oracle/21/client64/lib
export ORACLE_HOME=/usr/lib/oracle/21/client64
export TNS_ADMIN=/usr/lib/oracle/21/client64/lib/network
# Ensure both the system libs and Oracle libs are visible to runtime linkers
case ":${LD_LIBRARY_PATH:-}:" in
  *:/lib/x86_64-linux-gnu:*) ;;
  *) export LD_LIBRARY_PATH="/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-}";;
esac
case ":${LD_LIBRARY_PATH:-}:" in
  *:/usr/lib/oracle/21/client64/lib:*) ;;
  *) export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:-}:/usr/lib/oracle/21/client64/lib";;
esac
EOF
chmod 0644 /etc/profile.d/oracle-instantclient.sh

# --- Site Makevars: pass OCI vars and relax format-security to warnings ---
echo ">>> Writing site Makevars to ${R_HOME}/etc/Makevars.site…"
cat >"${R_HOME}/etc/Makevars.site" <<'EOF'
# Site-wide Makevars for building packages against Oracle Instant Client
OCI_INC=/usr/include/oracle/21/client64
OCI_LIB=/usr/lib/oracle/21/client64/lib
OCI_LIB64=/usr/lib/oracle/21/client64/lib

# Downgrade format-security diagnostics from errors to warnings
CFLAGS += -Wno-error=format-security
CXXFLAGS += -Wno-error=format-security
CXX11FLAGS += -Wno-error=format-security
CXX14FLAGS += -Wno-error=format-security
CXX17FLAGS += -Wno-error=format-security
CPPFLAGS += -Wno-error=format-security
EOF
chmod 0644 "${R_HOME}/etc/Makevars.site"

# --- Site Rprofile: set default repo to PPM Noble (no env juggling) ---
echo ">>> Setting system-wide R repo to PPM Noble in ${R_HOME}/etc/Rprofile.site…"
cat >"${R_HOME}/etc/Rprofile.site" <<'EOF'
# Set default repo to Posit Public Package Manager (Ubuntu Noble)
local({
  repos <- getOption("repos")
  if (is.null(repos) || length(repos) == 0L) repos <- c(CRAN = "@CRAN@")
  repos["CRAN"] <- "https://packagemanager.posit.co/cran/__linux__/noble/latest"
  options(repos = repos)
})
EOF
chmod 0644 "${R_HOME}/etc/Rprofile.site"

# --- Ensure site library exists and is writable ---
SITE_LIB="/usr/local/lib/R/site-library"
echo ">>> Ensuring site library at ${SITE_LIB}…"
mkdir -p "${SITE_LIB}"
chmod 2775 "${SITE_LIB}" || true

# --- Install ROracle into site library (avoid renv autoload for the command) ---
echo ">>> Installing ROracle into the site library (renv autoload disabled)…"
RENV_CONFIG_AUTOLOADER_ENABLED=FALSE \
R_DEFAULT_PACKAGES=utils \
R_LIBS_USER="" \
R_LIBS_SITE="${SITE_LIB}" \
Rscript --vanilla - <<'EOF'
# ROracle ships source only, rely on site repo from Rprofile.site
install.packages("ROracle", type = "source", lib = "/usr/local/lib/R/site-library")
EOF

# --- Verify it loads from site library ---
echo ">>> Verifying load…"
RENV_CONFIG_AUTOLOADER_ENABLED=FALSE \
R_LIBS_USER="" \
R_LIBS_SITE="${SITE_LIB}" \
Rscript --vanilla - <<'EOF'
library(ROracle)
packageVersion("ROracle")
cat("ROracle loaded OK\n")
EOF

echo ">>> Done."
