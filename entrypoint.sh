#!/bin/sh
#
# Malice clamav engine entrypoint.
#
# Signature strategy: the base image (clamav/clamav:1.5.4-debian) bundles a
# signature DB that was refreshed when the image was built. For a
# fire-and-forget scan container we attempt a bounded freshclam update at
# container start; if it fails (no network, DNS failure, TLS reset) we fall
# back to the bundled signatures and still scan. A scan must never be blocked
# on a signature download.
#
# The (attempted) update date is recorded in /opt/malice/UPDATED, which the
# avscan binary reads for the `updated` result field (falls back to the build
# time if the file is absent).

if timeout 120 freshclam --quiet >/dev/null 2>&1; then
    echo "[clamav] freshclam: signatures updated"
else
    echo "[clamav] freshclam: update failed, using bundled signatures"
fi

printf '%s' "$(date -u +%Y%m%d)" > /opt/malice/UPDATED 2>/dev/null || true

exec /bin/avscan "$@"
