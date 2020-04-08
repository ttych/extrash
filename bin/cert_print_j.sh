#!/bin/sh

for cert; do
    if [ ! -f "$cert" ]; then
        echo >&2 "$cert is not a file"
        continue
    fi

    if [ ! -r "$cert" ]; then
        echo >&2 "$cert is not readable"
        continue
    fi

    keytool -printcert -V -file $cert
done
