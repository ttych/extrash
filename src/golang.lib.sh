#!/bin/sh
# -*- mode: sh -*-

for home in "${HOME_ALT}" "${HOME}"; do
    if [ -d "$home" ]; then
        GOROOT="$home/local/$(uname -s)/$(uname -m)/go_root"
        GOPATH="$GOROOT/packages"
        break
    fi
done
export GOROOT GOPATH

if [ ! -d "$GOROOT" ]; then
    mkdir -p "$GOROOT"
fi
