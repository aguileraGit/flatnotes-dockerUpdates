#!/bin/sh

set -e

echo "\
======================================
======== Welcome to flatnotes ========
======================================

If you enjoy using flatnotes, please
consider sponsoring the project at:

https://sponsor.flatnotes.io

It would really make my day 🙏.

──────────────────────────────────────
"

flatnotes_command="python -m \
                  uvicorn \
                  main:app \
                  --app-dir server \
                  --host 0.0.0.0 \
                  --port ${APP_PORT} \
                  --proxy-headers \
                  --forwarded-allow-ips '*'"

if [ `id -u` -eq 0 ] && [ `id -g` -eq 0 ]; then
    echo Setting file permissions...
    chown -R ${PUID}:${PGID} ${FLATNOTES_PATH}

    echo Starting flatnotes as user ${PUID}...
    exec ${EXEC_TOOL} ${PUID}:${PGID} ${flatnotes_command}
      
else
    echo "A user was set by docker, skipping file permission changes."
    echo Starting flatnotes as user $(id -u)...
    exec ${flatnotes_command}
fi
