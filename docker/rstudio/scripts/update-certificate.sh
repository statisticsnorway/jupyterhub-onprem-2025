#!/bin/bash
# SSB Decrypt-CA so TLS intercept to GitHub/etc verifies (same as Lab start-notebook.d hook).
# Nexus is reachable on-prem; || true so local/GHA still boot without it.
set -e
TMP_CERT=$(mktemp)
curl -fsSL https://nexus.ssb.no/repository/certificate_repo/ssb/decrypt-ca.crt --output "$TMP_CERT" \
  && sudo -n install -m 644 "$TMP_CERT" /usr/local/share/ca-certificates/cert_Decrypt-CA.crt \
  || true
rm -f "$TMP_CERT"
sudo -n update-ca-certificates || update-ca-certificates || true
