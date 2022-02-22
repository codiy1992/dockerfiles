#!/bin/sh

set -eu

mkdir -p "${HOME}" "${DATA_PATH}" "${SYNCTHING_PATH}" "${STDISCOSRV_PATH}" "${STRELAYSRV_PATH}"

if [ "$(id -u)" = "0" ]; then
  chown "${PUID}:${PGID}" "${HOME}" "${DATA_PATH}" \
  "${SYNCTHING_PATH}" "${STDISCOSRV_PATH}" "${STRELAYSRV_PATH}" \
    && exec su-exec "${PUID}:${PGID}" \
       env HOME="$HOME" "$@"
else
  exec "$@"
fi
