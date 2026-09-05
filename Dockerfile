####################################################
# GOLANG BUILDER
####################################################
FROM golang:1.25-bookworm AS go_builder

COPY . /build/clamav/
WORKDIR /build/clamav

RUN go build -buildvcs=false -ldflags "-s -w -X main.Version=v$(cat VERSION) -X main.BuildTime=$(date -u +%Y%m%d)" -o /bin/avscan .

####################################################
# CLAMAV RUNTIME
####################################################
# Official ClamAV image: ships clamscan + freshclam and a bundled signature
# DB (main/daily/bytecode .cvd in /var/lib/clamav, refreshed at image build
# time). We keep clamscan/freshclam from this base and only add the avscan
# binary + entrypoint.
FROM clamav/clamav:1.5.4-debian

LABEL maintainer "https://github.com/blacktop"

LABEL malice.plugin.repository = "https://github.com/malice-plugins/clamav.git"
LABEL malice.plugin.category="av"
LABEL malice.plugin.mime="*"
LABEL malice.plugin.docker.engine="*"

# /malware is the read-only sample mount point (malice volume -> /malware:ro).
# /opt/malice holds the UPDATED marker read for the `updated` result field.
# The container runs as root (same as the old malice/clamav image, which had
# no USER directive): root can both read the clamav-owned /var/lib/clamav DB
# (drwx------) for clamscan and write it via freshclam, avoiding any
# permission edge case for a fire-and-forget scan.
RUN mkdir -p /malware /opt/malice

COPY --from=go_builder /bin/avscan /bin/avscan
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /malware

ENTRYPOINT ["/entrypoint.sh"]
CMD ["--help"]

####################################################
####################################################
