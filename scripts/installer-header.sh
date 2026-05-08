#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="${HOME}/.local/bin"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --prefix) INSTALL_DIR="$2"; shift 2 ;;
    --prefix=*) INSTALL_DIR="${1#--prefix=}"; shift ;;
    -h|--help)
      printf 'Usage: %s [--prefix DIR]\n' "${0##*/}"
      printf '  --prefix DIR  Install to DIR (default: ~/.local/bin)\n'
      exit 0 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; exit 1 ;;
  esac
done

printf 'Installing asciinema-rec_script __VERSION__ to %s ...\n' "${INSTALL_DIR}"
mkdir -p "${INSTALL_DIR}"

PAYLOAD_LINE=$(awk '/^__PAYLOAD__$/{print NR+1; exit}' "$0")
TMPDIR=$(mktemp -d)
tail -n +"${PAYLOAD_LINE}" "$0" | base64 -d | tar -xzf - -C "${TMPDIR}"
cp "${TMPDIR}"/bin/* "${INSTALL_DIR}/"
cp "${TMPDIR}"/home/* "${HOME}/"
rm -rf "${TMPDIR}"

printf 'Done.\n'

if [[ ":${PATH}:" != *":${INSTALL_DIR}:"* ]]; then
  printf '\n%s is not in your PATH. Add it with:\n' "${INSTALL_DIR}"
  printf '  export PATH="%s:${PATH}"\n' "${INSTALL_DIR}"
fi

exit 0
__PAYLOAD__
