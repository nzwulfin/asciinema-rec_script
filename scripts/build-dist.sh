#!/bin/bash
# Runs inside hi/core-runtime:latest-builder. Mounts: /src (ro), /dist (rw).
set -eu

dnf5 install -y --nodocs tar gzip && dnf5 clean all

VERSION=$(cat /src/version.txt)
ARCH=${ARCH:-$(uname -m)}

ASCIINEMA_VERSION=3.2.0
BAT_VERSION=0.26.1

case "${ARCH}" in
  x86_64)
    ASCIINEMA_BIN="asciinema-x86_64-unknown-linux-musl"
    BAT_TRIPLE="x86_64-unknown-linux-musl"
    ;;
  aarch64)
    ASCIINEMA_BIN="asciinema-aarch64-unknown-linux-gnu"
    BAT_TRIPLE="aarch64-unknown-linux-musl"
    ;;
  *) printf 'Unsupported ARCH: %s (use x86_64 or aarch64)\n' "${ARCH}" >&2; exit 1 ;;
esac

STAGE=$(mktemp -d)
trap 'rm -rf "${STAGE}"' EXIT
mkdir -p "${STAGE}/bin" "${STAGE}/home"

printf 'Downloading asciinema %s (%s)...\n' "${ASCIINEMA_VERSION}" "${ARCH}"
curl -fsSL \
  "https://github.com/asciinema/asciinema/releases/download/v${ASCIINEMA_VERSION}/${ASCIINEMA_BIN}" \
  -o "${STAGE}/bin/asciinema"
chmod +x "${STAGE}/bin/asciinema"

printf 'Downloading bat %s (%s)...\n' "${BAT_VERSION}" "${ARCH}"
TMP_BAT=$(mktemp -d)
curl -fsSL \
  "https://github.com/sharkdp/bat/releases/download/v${BAT_VERSION}/bat-v${BAT_VERSION}-${BAT_TRIPLE}.tar.gz" \
  | tar -xzf - -C "${TMP_BAT}"
cp "${TMP_BAT}"/*/bat "${STAGE}/bin/bat"
rm -rf "${TMP_BAT}"
chmod +x "${STAGE}/bin/bat"

printf 'Staging scripts...\n'
sed "s|export VERSION=.*|export VERSION=\"\${VERSION:-${VERSION}}\"|" \
  /src/bin/asciinema-rec_script > "${STAGE}/bin/asciinema-rec_script"
cp /src/bin/asciinema-gh /src/bin/upload.sh "${STAGE}/bin/"
chmod +x "${STAGE}/bin/asciinema-rec_script" "${STAGE}/bin/asciinema-gh" "${STAGE}/bin/upload.sh"

cp /src/screencasts/template.asc "${STAGE}/home/"

printf 'Building self-extracting archive...\n'
OUTPUT="/dist/asciinema-rec_script-${VERSION}-linux-${ARCH}.sh"
sed "s/__VERSION__/${VERSION}/g" /src/scripts/installer-header.sh > "${OUTPUT}"
tar -czf - -C "${STAGE}" . | base64 >> "${OUTPUT}"
chmod +x "${OUTPUT}"

printf 'Built: %s\n' "${OUTPUT}"
