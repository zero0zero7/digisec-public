#!/bin/sh -e

if [ -z ${GUAC_JSON_KEY} ]; then
    echo "Please set GUAC_JSON_KEY"
    exit 1
fi

echo "json-secret-key: ${GUAC_JSON_KEY}" >> /opt/guacamole-home/guacamole.properties

exec /opt/guacamole/bin/start.sh
